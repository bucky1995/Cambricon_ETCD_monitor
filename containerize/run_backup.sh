#!/bin/bash
#written by niuxinbo niuxinbo@cambricon.com
#All rights reserved by Cambricon

source /code/run_scan.sh

temp=$(cat /code/etcdStatus)
etcdStatus=(${temp//\n/})
if [ ${etcdStatus[0]} == "2" ];then
    exit 1
else
    ansible-playbook -i "/code/hosts" /code/playbook/backup.yml
fi

mv /code/backup-file/db /code/backup-file/etcd-backup-`date "+%Y-%m-%d-%H:%M"`.db

source /code/script/prune.sh
