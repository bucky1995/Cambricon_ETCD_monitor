# ETCD集群状态检测，备份与灾难恢复

## ETCD集群状态检测

* 默认设置cronjob每两小时运行一次scanner，scanner每次运行结果储存在/code/etcdStatus文件内
    *  文件第一行：
    *  etcd集群状态
       *  0：正常
       *  1：少于ETCD容错率节点故障
       *  2：大于ETCD容错率节点故障
    *  文件第二行：
       * 当etcd集群正常为当前etcd集群leader节点ip
       * 当etcd故障，则为故障节点ip
    *  文件第三行（当且仅当etcd集群出现故障才有）：
       *  etcd正常节点
    *  文件第四行：
       *  ETCD_DATA_DIR位置
    *  文件第五行：
    *  当etcd集群少于ETCD容错率节点故障，存在的leader节点ip
* 历史错误记录储存在/var/log/etcd_abnormal_record.log
* 手动运行etcd scanner
  * 执行/code/run_scan.sh，结果存于/code/etcdStatus中
* 每次执行scanner后储存leader节点ip于/code/leader文件下


## ETCD集群备份
* 默认设置cronjob每十二小时运行一次backup，自动储存leader节点backupfile在pod，/code/backup-file中
* 手动运行backup
  * 执行/code/run_backup.sh


## ETCD集群灾难恢复
* 运行方式为手动运行，执行/code/run_restore.sh
* 运行逻辑
  * 少于ETCD容错率节点故障：
    * 执行备份功能，保存leader节点备份文件至pod，分发该备份文件至错误节点
  * 大于ETCD容错率节点故障：
    * 判断pod上/code/backup-file目录下是否存在备份文件：
      * 存在：分发备份文件至错误节点，执行恢复
      * 不存在：从最后一次cluster正常情况下leader节点提取备份至pod，分发备份文件至错误节点，执行恢复
