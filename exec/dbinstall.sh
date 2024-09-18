#!/bin/bash
function checking_rep_env(){
    print_log "8. Checking replication parameter on source host begin"
    ARCHIVE_MODE=$(su - ${INSTALL_USER} -c "psql -U ${SUPERADMIN} -d postgres -p ${SOURCE_PGPORT} -Atq -c 'show archive_mode'")
    if [[ "${ARCHIVE_MODE}" == "off" ]];then
        print_sub_log "Archive mode doesn't enable and will be enabled"
        su - ${INSTALL_USER} -c "psql -U ${SUPERADMIN} -d postgres -p ${SOURCE_PGPORT} -Atq -c 'ALTER SYSTEM SET archive_mode = on'" >>${ERROR_LOG} 2>&1 >>${SUCCESS_LOG}
    else
        print_sub_log "Archive mode has been enabled"
    fi

    if [[ -d ${ARCHIVE_PATH} ]];then
        print_sub_log "Archive path already exists "
        chown ${INSTALL_USER}.${INSTALL_USER} -R ${ARCHIVE_PATH}
        ${SOURCE_PG_HOME}/bin/psql -U ${SUPERADMIN} -d postgres -p ${SOURCE_PGPORT} -Atq -c "ALTER SYSTEM SET archive_command = '${ARCHIVE_COMMAND}'"  >>${ERROR_LOG} 2>&1 >>${SUCCESS_LOG}
    else
        print_sub_log "Archive path doesn't exists and will be created"
        mkdir -p ${ARCHIVE_PATH}
        chown ${INSTALL_USER}.${INSTALL_USER} -R ${ARCHIVE_PATH}
        ${SOURCE_PG_HOME}/bin/psql -U ${SUPERADMIN} -d postgres -p ${SOURCE_PGPORT} -Atq -c "ALTER SYSTEM SET archive_command = '${ARCHIVE_COMMAND}'"  >>${ERROR_LOG} 2>&1 >>${SUCCESS_LOG}
    fi

    WAL_LEVEL=$(su - ${INSTALL_USER} -c "psql -U ${SUPERADMIN} -d postgres -p ${SOURCE_PGPORT} -Atq -c 'show wal_level'") >>${ERROR_LOG} 2>&1 >>${SUCCESS_LOG}

    if [[ "${WAL_LEVEL}" != "minimal" ]];then
        print_sub_log "Current wal level is ${WAL_LEVEL}"
    else
        print_error_log "Current wal_level is ${WAL_LEVEL},Please guaranting wal_level is replica or logical"
         ${SOURCE_PG_HOME}/bin/psql -U ${SUPERADMIN} -d postgres -p ${SOURCE_PGPORT} -Atq -c "ALTER SYSTEM SET wal_level = 'replica'" >>${ERROR_LOG} 2>&1 >>${SUCCESS_LOG}
    fi
    print_sub_log "Setting listener addresses"
    ${SOURCE_PG_HOME}/bin/psql -U ${SUPERADMIN} -d postgres -p ${SOURCE_PGPORT} -Atq -c "ALTER SYSTEM SET listen_addresses = '*' "
    
    #Checking replication user
    REPLUSER=$(${SOURCE_PG_HOME}/bin/psql -U ${SUPERADMIN} -d postgres -p ${SOURCE_PGPORT} -Atq -c "select usename from pg_user where usename='${REPLICATION_USER}'")
    if [[ "${REPLUSER}" == "${REPLICATION_USER}" ]];then
        print_sub_log "Replication user ${REPLICATION_USER} already exists"
        ${SOURCE_PG_HOME}/bin/psql -U ${SUPERADMIN} -d postgres -p ${SOURCE_PGPORT} -Atq -c "ALTER USER ${REPLICATION_USER} WITH ENCRYPTED PASSWORD '${REPLICATION_PASSWD}' "
    else
        print_sub_log "Creating replication user"
        ${SOURCE_PG_HOME}/bin/psql -U ${SUPERADMIN} -d postgres -p ${SOURCE_PGPORT} -Atq -c "CREATE USER ${REPLICATION_USER} WITH SUPERUSER REPLICATION ENCRYPTED PASSWORD '${REPLICATION_PASSWD}' "
    fi

    print_sub_log "Configuring hba file"

    R_SUBNET=RSUBNET=$(echo "$SUBNET" | cut -d'/' -f1)
    su - ${INSTALL_USER} -c "sed -i '/${R_SUBNET}/d' ${SOURCE_PG_DATA}/pg_hba.conf"
    echo -e "host \t\t all \t\t all \t\t ${SUBNET} \t\t trust">> ${SOURCE_PG_DATA}/pg_hba.conf
    echo -e "host \t\t replication \t\t all \t\t ${SUBNET} \t\t trust" >>${SOURCE_PG_DATA}/pg_hba.conf

    chown ${INSTALL_USER}.${INSTALL_USER} ${SOURCE_PG_DATA}/pg_hba.conf
    print_log "   Checking replication parameter on source host end"
}

function restart_source(){
    print_log "9. Restart source host database server begin"
    read -p "Please confirm restart server,default y/Y: " ISRESTART
    if [[ "${ISRESTART}" == "" || "${ISRESTART}" == "y" || "${ISRESTART}" == "Y" ]];then
        su - ${INSTALL_USER} -c "pg_ctl restart -D ${SOURCE_PG_DATA} "  >>${ERROR_LOG} 2>&1 >>${SUCCESS_LOG}
    else
        print_error_log "Exit because user cancel"
        exit 99
    fi
}

function prepare_soft_pkg(){
    print_log "10.Preparing soft package on source host begin"
    if [[ -d ${SOURCE_PG_HOME} ]];then
        PARENTSOFT=$(dirname ${SOURCE_PG_HOME})
        SOFTPKGNAME=$(basename ${SOURCE_PG_HOME})
        cd ${PARENTSOFT}
        tar -zcf ${SOFTPKGNAME}.tar.gz  ${SOFTPKGNAME}/*
        for target_ip in ${IPADDR[@]};do
            scp pgsql.tar.gz root@${target_ip}:${PARENTSOFT} >>${ERROR_LOG} 2>&1 >>${SUCCESS_LOG}
            su  - postgres -c "scp /home/${INSTALL_USER}/.bashrc ${INSTALL_USER}@${target_ip}:/home/${INSTALL_USER}"  >>${ERROR_LOG} 2>&1 >>${SUCCESS_LOG}
            ssh root@${target_ip} "cd /usr/local;tar -zxvf pgsql.tar.gz" >>${ERROR_LOG} 2>&1 >>${SUCCESS_LOG}
        done
    fi
    print_log "   Preparing soft package on source host end"
}


function deploy_standby(){
    print_log "11.Deploying standby on target host begin"
    for target_ip in ${IPADDR[@]};do
        ssh root@${target_ip} "su - postgres -c 'rm -rf ${TARGET_PG_DATA}/*;pg_basebackup -h ${SOURCE_IPADDR} -U ${REPLICATION_USER} -p ${SOURCE_PGPORT} -D ${TARGET_PG_DATA} -Fp -c fast -R -Xs -Pv' " >>${ERROR_LOG} 2>&1 >>${SUCCESS_LOG}
        ssh root@${target_ip} "su - postgres -c 'pg_ctl start -D ${TARGET_PG_DATA} -l ${LOGFILE}' " >>${ERROR_LOG} 2>&1 >>${SUCCESS_LOG}
    done
    print_log "   Deploying standby on target host end"
}

function verify_standby_status(){
    print_log "12.Verify sync state begin"
    for target_ip in ${IPADDR[@]};do   
        REPL_STATUS=$(${SOURCE_PG_HOME}/bin/psql -U ${SUPERADMIN} -d postgres -p ${SOURCE_PGPORT} -Atq -c "select sync_state from pg_stat_replication where client_addr='${target_ip}'") >>${ERROR_LOG} 2>&1 >>${SUCCESS_LOG}
        print_sub_log "standby host ${target_ip} state is normal:${REPL_STATUS}"
    done
    print_log "   Verify sync state end"
}
