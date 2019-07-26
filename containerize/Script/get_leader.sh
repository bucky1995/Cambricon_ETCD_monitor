#!/bin/bash
#written by niuxinbo xinbo1995@outlook.com
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

etcd=()

#获取所有节点ip
function getnode(){
    split=(${ETCD_INITIAL_CLUSTER//,/ })
    i=0
    for var in ${split[@]}
    do
            temp1=(${var//=/ })
            temp2=(${temp1[1]//:/ })
            temp3=(${temp2[1]///// })
            etcd[i]=${temp3[2]}
            ((i=i+1))
    done
    ((i=i-1))
    #所在cluster的最大容错数量
    max_error=`expr $i / 2 `
}

#获取所有节点的状态
function getLeader(){
    for node in ${etcd[@]}
    do
    
   result_temp=$(etcdctl --endpoints=https://$node:2379 --cert=$ETCD_CERT_FILE \
        --key=$ETCD_KEY_FILE \
        --cacert=$ETCD_TRUSTED_CA_FILE \
        endpoint status 2>&1)
    result=(${result_temp//,/})
    if [ ${result[5]} == "true" ]; then
        echo $node
    fi
    unset result
    unset result_temp
    done
}
getnode
getLeader

