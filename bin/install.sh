#!/bin/bash

###################################################################
# Program Name: Oracle Auto Install scripts                       #
# Author: Devhonor                                                #
# Date: 2024-08-11                                                #
###################################################################

#Define return status
set -o pipefail

#Define Current Directory 
CURRENT_DIR=$(cd "$(dirname $0)";pwd)

#Define Toplevel Directory
TOPLEVEL_DIR=$(cd ${CURRENT_DIR}/..;pwd)

#Loading config
. ${TOPLEVEL_DIR}/exec/.main.lst

argscnt=$#
execType=${1}
function install_db(){
if [ ${argscnt} -eq 1 ];then
    if [ "${execType}" = "install" ];then
    print_log "########################### [${INSTALL_NAME}] Begin install ###########################"
        begin_time=`date +%s.%N`
        . ${TOPLEVEL_DIR}/exec/.load
        end_time=`date +%s.%N`
        cost_time=`echo "${end_time}-${begin_time}"|bc`
        
    print_log "########################### [${INSTALL_NAME}] End install   ###########################"
    printf "Running cost time: %.2f seconds,`date` \n" ${i} ${cost_time}
    fi
else
    printHelp
fi
}

function main(){
    install_db $*
}

main
