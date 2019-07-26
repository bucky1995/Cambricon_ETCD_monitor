#!/bin/bash
#written by niuxinbo niuxinbo@cambricon.com
#All rights reserved by Cambricon
export ETCDCTL_API=3

ETCD_CERT_FILE=$(grep -oP 'ETCD_CERT_FILE=\K\S+' /etc/etcd.env)
ETCD_KEY_FILE=$(grep -oP 'ETCD_KEY_FILE=\K\S+' /etc/etcd.env)
ETCD_TRUSTED_CA_FILE=$(grep -oP 'ETCD_TRUSTED_CA_FILE=\K\S+' /etc/etcd.env)
ETCD_ADVERTISE_CLIENT_URLS=$(grep -oP 'ETCD_ADVERTISE_CLIENT_URLS=\K\S+' /etc/etcd.env)

function etcd-backup(){
    etcdctl --endpoints $ETCD_ADVERTISE_CLIENT_URLS \
    --cert=$ETCD_CERT_FILE \
    --key=$ETCD_KEY_FILE \
    --cacert=$ETCD_TRUSTED_CA_FILE \
    snapshot save /var/lib/etcd-buffer/db-temp 
    if [ -f "/var/lib/etcd-buffer/db" ];then
      rm /var/lib/etcd-buffer/db
    fi
    mv /var/lib/etcd-buffer/db-temp /var/lib/etcd-buffer/db
    if [ $? -ne 0 ]; then
        exit 1
    fi
}

#main
if [ ! -f "/etc/etcd.env" ];then
    echo "file 'etcd.env' doesn't exist"
    exit 1
fi

#judge if etcd is running
if ! ps -ef|grep "etcd"|egrep -v grep >/dev/null ;then
    exit 1
else
    etcd-backup
fi