#!/bin/bash

function config_autossh(){
    print_log "1. Configuring autossh begin"
    AUTOSSH_TOOLS=${TOPLEVEL_DIR}/tools/ssh-keys-main.zip
    TOOLS_PATH=$(dirname ${AUTOSSH_TOOLS})
    cd ${TOOLS_PATH}
    #source host install expect tool
    rpm -ivh --force ${TOOLS_PATH}/tcl-8.6.8-2.el8.x86_64.rpm ${TOOLS_PATH}/expect-5.45.4-5.el8.x86_64.rpm >>${ERROR_LOG} 2>&1 >>${SUCCESS_LOG}
    rm -rf ${TOOLS_PATH}/ssh-keys-main
    unzip ssh-keys-main.zip >>${ERROR_LOG} 2>&1 >>${SUCCESS_LOG}
    DEPS_PKG=${TOOLS_PATH}/*.rpm
    #scp expect tool to target host
    >${TOOLS_PATH}/ssh-keys-main/iplist
    #writting source ip addr
    echo ${SOURCE_IPADDR} >>${TOOLS_PATH}/ssh-keys-main/iplist

    if [[ "${TARGET_IPADDR}" == "" ]];then
        print_error_log "TARGET_IPADDR is empty,please checking it"
        exit 99
    else
        IFS=','
        read -ra IPADDR <<< ${TARGET_IPADDR}
        for target_ip in ${IPADDR[@]};do
            echo ${target_ip} >>${TOOLS_PATH}/ssh-keys-main/iplist
            scp ${DEPS_PKG} root@${target_ip}:/tmp/ >>${ERROR_LOG} 2>&1 >>${SUCCESS_LOG}
            ssh ${target_ip} "cd /tmp;rpm -ivh --force /tmp/tcl-8.6.8-2.el8.x86_64.rpm expect-5.45.4-5.el8.x86_64.rpm;" >>${ERROR_LOG} 2>&1 >>${SUCCESS_LOG}
        done
    fi
    #execute root user autossh configuration
    cd ${TOOLS_PATH}/ssh-keys-main
    sh autoexssh.sh root ${ROOT_PASSWORD} >>${ERROR_LOG} 2>&1 >>${SUCCESS_LOG}
    print_log "   Configuring autossh end"
}


function config_target_env(){
    print_log "2. Checking target host environment begin"
    for target_ip in ${IPADDR[@]};do
        ssh root@${target_ip} " \
        useradd -u 3000 ${INSTALL_USER} ; \
        echo ${INSTALL_USER_PASS} | passwd --stdin ${INSTALL_USER}
        if [[  -d ${TARGET_PG_DATA} ]];then \
            echo 'The data directory ${TARGET_PG_DATA} already exists';
            chown ${INSTALL_USER}.${INSTALL_USER} -R ${TARGET_PG_DATA}; \
            chmod 0700 ${TARGET_PG_DATA}; \
        else
            echo 'The data directory ${TARGET_PG_DATA} will be created'; \
            mkdir -p ${TARGET_PG_DATA}; \
            chown ${INSTALL_USER}.${INSTALL_USER} -R ${TARGET_PG_DATA}; \
            chmod 0700 ${TARGET_PG_DATA}; \
            echo 'The data directory ${TARGET_PG_DATA} has been created'; \
        fi" >>${ERROR_LOG} 2>&1 >>${SUCCESS_LOG}
    done
    print_log "   Checking target host environment end"
}

    

function config_run_osuser_autossh(){
    print_log "3. Checking running os user ${INSTALL_USER} autossh begin"
    ALLIP=${SOURCE_IPADDR},${TARGET_IPADDR}
    IFS=','
    read -ra ALL_IPADDR <<< ${ALLIP}
    for all_ip in ${ALL_IPADDR[@]};do
        ssh root@${all_ip} "cd /tmp/;rm -f remote_ssh"
    done
    if [[ "${INSTALL_USER}" == "" ]];then
        print_error_log "INSTALL_USER is empty,please checking it"
    else
        cp -fnr ${TOOLS_PATH}/ssh-keys-main /home/${INSTALL_USER}
        chown ${INSTALL_USER}.${INSTALL_USER} -R /home/${INSTALL_USER}/ssh-keys-main
        su - ${INSTALL_USER} -c "cd /home/${INSTALL_USER}/ssh-keys-main;sh autoexssh.sh ${INSTALL_USER} ${INSTALL_USER_PASS} " >>${ERROR_LOG} 2>&1 >>${SUCCESS_LOG}
    fi
    print_log "   Checking running os user ${INSTALL_USER} autossh end"
}

function config_firewalld(){
    print_log "4. Checking firwalld begin"

    for target_ip in ${IPADDR[@]};do
        ssh root@${target_ip} "systemctl stop firewalld ; systemctl disable firewalld ;" >>${ERROR_LOG} 2>&1 >>${SUCCESS_LOG}
    done
    print_log "   Checking firwalld end"

}

function config_selinux(){
    print_log "5. Checking selinux begin"
    for target_ip in ${IPADDR[@]};do
        ssh root@${target_ip} "sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config ; setenforce 0 ;" >>${ERROR_LOG} 2>&1 >>${SUCCESS_LOG}
    done
    print_log "   Checking selinux end"
}


function config_kernel_limit(){
    print_log "6. Checking target host selinux and resource limit begin"
    for target_ip in ${IPADDR[@]};do
        scp /etc/sysctl.d/97-postgres-database-sysctl.conf  root@${target_ip}:/etc/sysctl.d/ >>${ERROR_LOG} 2>&1 >>${SUCCESS_LOG}
        scp /etc/security/limits.conf root@${target_ip}:/etc/security/ >>${ERROR_LOG} 2>&1 >>${SUCCESS_LOG}
        scp ${TOPLEVEL_DIR}/lib/pkglist root@${target_ip}:/tmp >>${ERROR_LOG} 2>&1 >>${SUCCESS_LOG}
        ssh root@${target_ip} "sysctl --system"  >>${ERROR_LOG} 2>&1 >>${SUCCESS_LOG}
    done
    print_log "   Checking target host selinux and resource limit end"
}


function config_deps_pkg(){
    print_log "7. Installing dependency packages on target host begin"
    for target_ip in ${IPADDR[@]};do
        ssh root@${target_ip} "while read line;do \
        dnf install -y \${line} ;\
        done</tmp/pkglist" >>${ERROR_LOG} 2>&1 >>${SUCCESS_LOG}
    done
    print_log "   Installing dependency packages on target host end"
}

