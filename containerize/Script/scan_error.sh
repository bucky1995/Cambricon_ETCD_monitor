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

etcd=()
etcd_error_node=() #错误节点ip存放
etcd_normal_node=() #正常节点ip存放
error_count=0 #错误节点数量
normal_count=0 #正常节电数量
max_error=0 #最大容错量

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
function getStatus(){
    for node in ${etcd[@]}
    do
    echo $node
    etcdctl --endpoints=https://$node:2379 --cert=$ETCD_CERT_FILE \
        --key=$ETCD_KEY_FILE \
        --cacert=$ETCD_TRUSTED_CA_FILE \
        endpoint status
        if [ $? -ne 0 ]; then
            etcd_error_node[error_count]=${node}
            echo "node: ${etcd_error_node[error_count]} error"
            ((error_count=error_count+1))

        else
            etcd_normal_node[normal_count]=${node}
            echo "node: ${etcd_normal_node[normal_count]} normal"
            ((normal_count=normal_count+1))
        fi
    done
}

#重置所有变量
function resetVar(){
    unset etcd_error_node
    unset etcd_normal_node
    error_count=0
    normal_count=0
    max_error=0
}

#循环检测
function loopScan(){
    for((i=1;i<=12;i++));
    do
        for node in ${etcd[@]}
        do
            echo $node
            etcdctl --endpoints=https://$node:2379 --cert=$ETCD_CERT_FILE \
                    --key=$ETCD_KEY_FILE \
                    --cacert=$ETCD_TRUSTED_CA_FILE \
                endpoint status
            if [ $? -ne 0 ]; then
                ((temp_error=temp_error+1))
            else
                ((temp_normal=temp_normal+1))
            fi
        done
        if [ $temp_error -ne $error_count ]; then
            resetVar
            getStatus
        fi
        temp_error=0
        temp_normal=0
        if [ $error_count -ne 0 ]; then
            sleep 5
        else
            break
        fi
    done
}

function getLeader(){
    for node in ${etcd[@]}
    do
    
   result_temp=$(etcdctl --endpoints=https://$node:2379 --cert=$ETCD_CERT_FILE \
        --key=$ETCD_KEY_FILE \
        --cacert=$ETCD_TRUSTED_CA_FILE \
        endpoint status 2>&1)
    result=(${result_temp//,/})
    if [ ${result[5]} == "true" ]; then
        echo $node >> /var/lib/etcd-buffer/$ETCD_NAME.txt
    fi
    unset result
    unset result_temp
    done
}

#少于容错数量
function restoreSingle(){
    echo "1" > /var/lib/etcd-buffer/$ETCD_NAME.txt
    echo ${etcd_error_node[@]} >> /var/lib/etcd-buffer/$ETCD_NAME.txt
    echo ${etcd_normal_node[@]} >> /var/lib/etcd-buffer/$ETCD_NAME.txt
    echo ${ETCD_DATA_DIR} >> /var/lib/etcd-buffer/$ETCD_NAME.txt
    getLeader
}
#大于容错数量
function restoreMulti(){
    echo "2" > /var/lib/etcd-buffer/$ETCD_NAME.txt
    echo ${etcd_error_node[@]} >> /var/lib/etcd-buffer/$ETCD_NAME.txt
    echo ${etcd_normal_node[0]} >> /var/lib/etcd-buffer/$ETCD_NAME.txt
    echo ${ETCD_DATA_DIR} >> /var/lib/etcd-buffer/$ETCD_NAME.txt
}


################
#main
################
#获取所有节点ip

touch /var/lib/etcd-buffer/$ETCD_NAME.txt

getnode
#获取所有节点的状态
getStatus


if [ $error_count -eq 0 ];then
    echo "0" > /var/lib/etcd-buffer/$ETCD_NAME.txt
    getLeader
    exit 0 
else
    loopScan
fi
if [ $error_count -eq 0 ];then
    echo "0" > /var/lib/etcd-buffer/$ETCD_NAME.txt
    getLeader
    exit 0
else
    #少于容错数量
    if [ $error_count -le $max_error ];then
        restoreSingle
    #大于容错数量
    elif [ $error_count -gt $max_error ];then
        restoreMulti
    fi
fi


