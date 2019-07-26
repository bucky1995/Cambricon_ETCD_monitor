#!/bin/bash
#written by niuxinbo niuxinbo@cambricon.com
#All rights reserved by Cambricon

rm -rf ~/.ssh/
expect <<EOF
spawn ssh-keygen -t rsa
expect {
"Enter file in which to save the key (/root/.ssh/id_rsa)" { send "\r" ; exp_continue}
"Enter passphrase (empty for no passphrase)" { send "\r" ; exp_continue}
"Enter same passphrase again:" { send "\r" ; exp_continue}
}
EOF

temp=$(<"/code/hosts")
ETCD_ip=()
while read line
do
    ETCD_ip+=("$line")
done <<< "$temp"
ETCD_ip_number=${#ETCD_ip[@]}
for i in $(seq 1 $[ETCD_ip_number-1]);
do
sshpass -p root123 ssh-copy-id -f -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa.pub ubuntu@${ETCD_ip[i]}
done

service cron start
crontab -l > mycron
#every two hours run scan error
echo "0 */2 * * * ./code/run_scan.sh" >> mycron
#every 12 hours run backup
echo "0 */12 * * * ./code/run_backup.sh" >> mycron
crontab mycron
rm mycron

while [ "1" = "1" ]
do
sleep 1
done
