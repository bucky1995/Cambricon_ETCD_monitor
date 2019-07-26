#!/bin/bash
#written by niuxinbo niuxinbo@cambricon.com
#All rights reserved by Cambricon
if [ ! -d "/code/return/" ];then
    mkdir /code/return/
fi

ansible-playbook -i "/code/hosts" /code/playbook/scan_error.yml

source /code/script/compare.sh

if [ $? -ne 0 ]; then
    echo "wrong return"
else
    file_content=()
    files_temp=$(ls /code/return/*.txt)
    files=(${files_temp// / })
    content_temp=$(<"${files[0]}")
    echo "$content_temp"
    echo "$content_temp" > /code/etcdStatus
    content=()
    while read line
    do
        content+=("$line")
    done <<< "$content_temp"
    if [ ${content[0]} != "0" ];then
        if [ ! -f "/var/log/etcd_abnormal_record.log" ];then
            touch /var/log/etcd_abnormal_record.log
        fi
        echo `date "+%Y-%m-%d-%H:%M:%S"`", error node: ${content[1]}" >> /var/log/etcd_abnormal_record.log
        if [  ${content[0]} == "1" ];then
            echo "less than max_error" >> /var/log/etcd_abnormal_record.log
        elif [  ${content[0]} == "2" ];then
            echo "less than max_error" >> /var/log/etcd_abnormal_record.log
        fi
        echo "===============================================================" >> /var/log/etcd_abnormal_record.log
    elif [ "${content[0]}" != "2" ];then
	if [ "${content[0]}" == "0" ];then
            echo "${content[1]}" > /code/leader
	elif [ "${content[0]}" == "1" ];then
            echo "${content[4]}" > /code/leader
	fi
    fi
    rm -rf /code/return/
fi
