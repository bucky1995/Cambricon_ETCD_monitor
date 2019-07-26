#!/bin/bash
#written by niuxinbo xinbo1995@outlook.com

#source /code/run_scan.sh

content_temp=$(<"/code/etcdStatus")
content=()
while read line
do
    content+=("$line")
done <<< "$content_temp"
cp /code/hosts /code/node
echo $mode
touch /code/node
echo "  "  >> /code/node
echo "[error_node]" >> /code/node
for node in ${content[1]}
do
    echo $node >> /code/node
done

echo "  "  >> /code/node
echo "[normal_node]" >> /code/node
for node in ${content[2]}
do
    echo $node >> /code/node
done

if [ "$mode" == "1" ]; then
    source /code/run_backup.sh
    echo "1"
elif [ "$mode" == "0" ]; then
    exit 0
fi

file_count=$(ls -l /code/backup-file|grep "^-"|wc -l)
if [ "$file_count" == "0" ];then
    if [ ! -f "/code/leader" ];then
	if [ "${content[2]}" == "" ];then
            fetch_node=(${content[1]// / })
        else
            fetch_node=(${content[2]// / })
        fi
    else
        fetch_node=$(cat /code/leader)
    fi
    echo "  "
    echo "[fetch_node]" >> /code/node
    echo "${fetch_node[0]}" >> /code/node
	ansible-playbook -i "/code/node" /code/playbook/restore.yml
else
    backup_file=$(ls -t /code/backup-file| head -n1)
    mv /code/backup-file/$backup_file /code/backup-file/db
    ansible-playbook -i "/code/node" /code/playbook/restore.yml
    mv /code/backup-file/db /code/backup-file/$backup_file
fi

rm /code/node
