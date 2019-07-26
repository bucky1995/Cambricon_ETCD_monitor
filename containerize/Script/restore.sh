#!/bin/bash
#written by niuxinbo niuxinbo@cambricon.com
#All rights reserved by Cambricon
export ETCDCTL_API=3
ETCD_NAME=$(grep -oP 'ETCD_NAME=\K\S+' /etc/etcd.env)
ETCD_ADVERTISE_CLIENT_URLS=$(grep -oP 'ETCD_ADVERTISE_CLIENT_URLS=\K\S+' /etc/etcd.env)
ETCD_CERT_FILE=$(grep -oP 'ETCD_CERT_FILE=\K\S+' /etc/etcd.env)
ETCD_KEY_FILE=$(grep -oP 'ETCD_KEY_FILE=\K\S+' /etc/etcd.env)
ETCD_TRUSTED_CA_FILE=$(grep -oP 'ETCD_TRUSTED_CA_FILE=\K\S+' /etc/etcd.env)
ETCD_INITIAL_CLUSTER=$(grep -oP 'ETCD_INITIAL_CLUSTER=\K\S+' /etc/etcd.env)
ETCD_INITIAL_ADVERTISE_PEER_URLS=$(grep -oP 'ETCD_INITIAL_ADVERTISE_PEER_URLS=\K\S+' /etc/etcd.env)
ETCD_INITIAL_CLUSTER_TOKEN=$(grep -oP 'ETCD_INITIAL_CLUSTER_TOKEN=\K\S+' /etc/etcd.env)
ETCD_DATA_DIR=$(grep -oP 'ETCD_DATA_DIR=\K\S+' /etc/etcd.env)

function restore-local(){

    mv $ETCD_DATA_DIR /

    etcdctl snapshot restore /etcd/member/snap/db \
    --name=$ETCD_NAME \
    --endpoints $ETCD_ADVERTISE_CLIENT_URLS \
    --cert=$ETCD_CERT_FILE \
    --key=$ETCD_KEY_FILE \
    --cacert=$ETCD_TRUSTED_CA_FILE \
    --initial-cluster $ETCD_INITIAL_CLUSTER \
    --initial-advertise-peer-urls $ETCD_INITIAL_ADVERTISE_PEER_URLS \
    --initial-cluster-token $ETCD_INITIAL_CLUSTER_TOKEN \
    --data-dir=$ETCD_DATA_DIR \
    --skip-hash-check=1
    if [ $? -ne 0 ]; then
    echo "etcd restore from auto backup fail"
    exit 1
    else
        echo "etcd restore from auto backup success"
	rm -rf /etcd
    fi
}

function restore-fetch(){
    rm -rf $ETCD_DATA_DIR 	
    
    etcdctl  snapshot restore /var/lib/etcd-buffer/db \
    --name=$ETCD_NAME \
    --endpoints $ETCD_ADVERTISE_CLIENT_URLS \
    --cert=$ETCD_CERT_FILE \
    --key=$ETCD_KEY_FILE \
    --cacert=$ETCD_TRUSTED_CA_FILE \
    --initial-cluster $ETCD_INITIAL_CLUSTER \
    --initial-advertise-peer-urls $ETCD_INITIAL_ADVERTISE_PEER_URLS \
    --initial-cluster-token $ETCD_INITIAL_CLUSTER_TOKEN \
    --data-dir=$ETCD_DATA_DIR \
    --skip-hash-check=true
    if [ $? -ne 0 ]; then
    echo "etcd restore from received backup fail"
    exit 1
    else
        echo "restore from  received backup success"
    fi
}

#judge if etcd.env is in the correct path
if [ ! -f "/etc/etcd.env" ];then
    exit 1
fi
if [ "$1" == "1" ]; then
    if [ ! -f "/var/lib/etcd/member/snap/db" ];then
        restore-fetch
    else
        restore-local
    fi
elif [ "$1" == "2" ]; then
    restore-fetch
fi
