#!/bin/bash
#written by niuxinbo xinbo1995@outlook.com
file_content=()
files_temp=$(ls /code/return/*.txt)
files=(${files_temp// / })
file_number=${#files[@]}
((file_number=file_number-1))
i=0
while [ $i -lt $file_number ]
do
file1=$(cat "${files[i]}")
((i=i+1))
file2=$(cat "${files[i]}")
if [ "$file1" != "$file2" ];then
    echo "etcd error different return:" >> /var/log/etcd_abnormal_record.log
    find  /code/return -name  "*.txt" | xargs cat >> /var/log/etcd_abnormal_record.log
    echo "===============================================================" >> /var/log/etcd_abnormal_record.log
    exit 1
fi
done
