***
#先决条件(requirements)
-  配置好yum仓库Completing configuration of yum repository
-  确保已经有一个主节点正常运行 There have a database server running as primary node

#可选先决条件(Option)
-  所有节点完成互信(All server ssh connectivity have been completed)
-  如果没准备，可以在执行安装的时候手动执行(You can input root password when you execute auto install script )

***
#使用说明(using manual)
-  当前自动安装脚本适用于红帽家族 8.9 系统，其它版本未做测试，请根据环境自己测试
-  The current auto-install scripts are compatible with Red Hat family OS version 8.9. Other versions have not been verified, so please test it when using on those.


####配置文件(configuration files)
-  配置文件包括两个，一个日志配置文件，一个环境配置文件，日志配置文件不用做任何改动，环境配置文件需要手动配置。
There are two files in the conf folder: one for log configuration and one for environment settings. You do not need to change the log configuration file, but you need to modify the parameter values in the environment file.
***

#使用步骤(using steps)
1. 使用 root 用户上传文件到任意目录
Upload  files to any directory using root user
```bash
[root@server ~]# ls pg-onekey-ps-install-v1.0.tar.gz 
pg-onekey-ps-install-v1.0.tar.gz
[root@server ~]# 
```

2. 解压脚本文件(uncompressing script file)

```bash
[root@server ~]# tar -zxf pg-onekey-ps-install-v1.0.tar.gz 
[root@server ~]# 

```
3. 编辑 conf/env.cnf 文件

```bash
[root@server ~]# cd pg-onekey-ps-install
[root@server pg-onekey-ps-install]# cd conf/
[root@server conf]# vi env.cnf 
#Define Install Name
INSTALL_NAME="PostgreSQL Database Primary Standby Deploying"  #specifying any string

#[source host configuration parameter]

SOURCE_IPADDR=10.10.20.41 #specifying source host ipaddr

#Define PG_HOME,which is an install destination for PostgreSQL product on source host
SOURCE_PG_HOME=/usr/local/pgsql

#Define data directory,which is a database cluster directory on source host
SOURCE_PG_DATA=/data2/pgdata #must be specifying

#Define database port
SOURCE_PGPORT=5432 #must be specifying

#Define running os user
INSTALL_USER=postgres #must be specifying

#Define running os user password
INSTALL_USER_PASS=postgres #must be specifying

#Define superadmin user
SUPERADMIN=postgres #must be specify

#Define logfile
LOGFILE=/tmp/logfile

#Define replication user
REPLICATION_USER=repluser

#Define replication password
REPLICATION_PASSWD=Bigdata_123

#Define root password
ROOT_PASSWORD=redhat #must be specifying

#Define archive path
ARCHIVE_PATH=/data2/wal

#Define archive_command
ARCHIVE_COMMAND="cp %p ${ARCHIVE_PATH}/%f"

#Define subnet
SUBNET=10.10.20.0/24 #must be specify

####################################################################################################################################


#[target host configuration parameter]
#Define target host ip or hostname
TARGET_IPADDR=10.10.20.42,10.10.20.43 #what IP addresses or hostname to standby host,comma-separated list of addresses

#Define target host software path
TARGET_PG_HOME=/usr/local/pgsql

#Define target host database cluster path
TARGET_PG_DATA=/data2/pgdata

#Define target port
TARGET_PGPORT= #if the value is empty,default 5432

```

4. 切换到bin目录执行 sh install.sh 
***注意*** :
- 在第9步的时候需要手动确认重启主节点 (In step 9, you need to confirm restart primary server node )


```bash
[root@server bin]# sh install.sh
 Command usage:
 ------------------------------------------------
 | sh install.sh install or ./install.sh install|
 | sh install.sh clean   or ./install.sh clean  |
 ------------------------------------------------
[root@server bin]# sh install.sh install
[2024-09-17 PM 19:51:49]  ########################### [PostgreSQL Database Primary Standby Deploying] Begin install ########################### 
[2024-09-17 PM 19:51:49]  1. Configuring autossh begin 
root@10.10.20.42's password: 
root@10.10.20.42's password: 
root@10.10.20.43's password: 
root@10.10.20.43's password: 
[2024-09-17 PM 19:52:19]     Configuring autossh end 
[2024-09-17 PM 19:52:19]  2. Checking target host environment begin 
[2024-09-17 PM 19:52:19]     Checking target host environment end 
[2024-09-17 PM 19:52:19]  3. Checking running os user postgres autossh begin 
[2024-09-17 PM 19:52:27]     Checking running os user postgres autossh end 
[2024-09-17 PM 19:52:28]  4. Checking firwalld begin 
[2024-09-17 PM 19:52:29]     Checking firwalld end 
[2024-09-17 PM 19:52:29]  5. Checking selinux begin 
[2024-09-17 PM 19:52:29]     Checking selinux end 
[2024-09-17 PM 19:52:29]  6. Checking target host selinux and resource limit begin 
[2024-09-17 PM 19:52:31]     Checking target host selinux and resource limit end 
[2024-09-17 PM 19:52:31]  7. Installing dependency packages on target host begin 
[2024-09-17 PM 19:56:45]     Installing dependency packages on target host end 
[2024-09-17 PM 19:56:45]  8. Checking replication parameter on source host begin 
[2024-09-17 PM 19:56:45]        Archive mode doesn't enable and will be enabled
[2024-09-17 PM 19:56:45]        Archive path already exists 
[2024-09-17 PM 19:56:45]        Current wal level is replica
[2024-09-17 PM 19:56:45]        Setting listener addresses
[2024-09-17 PM 19:56:45]        Creating replication user
[2024-09-17 PM 19:56:45]        Configuring hba file
[2024-09-17 PM 19:56:45]     Checking replication parameter on source host end 
[2024-09-17 PM 19:56:45]  9. Restart source host database server begin 
Please confirm restart server,default y/Y: y
[2024-09-17 PM 19:57:25]  10.Preparing soft package on source host begin 
[2024-09-17 PM 19:57:31]     Preparing soft package on source host end 
[2024-09-17 PM 19:57:31]  11.Deploying standby on target host begin 
[2024-09-17 PM 19:57:33]     Deploying standby on target host end 
[2024-09-17 PM 19:57:33]  12.Verify sync state begin 
[2024-09-17 PM 19:57:33]        standby host 10.10.20.42 state is normal:async
[2024-09-17 PM 19:57:33]        standby host 10.10.20.43 state is normal:async
[2024-09-17 PM 19:57:33]  13.Verify sync state end 
[2024-09-17 PM 19:57:33]  ########################### [PostgreSQL Database Primary Standby Deploying] End install   ########################### 
Running cost time: 344.72 seconds,Tue Sep 17 19:57:33 CST 2024 
[root@server bin]# su - postgres
Last login: Tue Sep 17 19:57:30 CST 2024 on pts/2
```

6. 验证(Verifying)
```
[root@server conf]# su - postgres
Last login: Wed Sep 18 14:07:07 CST 2024 on pts/0
[postgres@server ~]$ psql
psql (17rc1)
Type "help" for help.

postgres=# \x
Expanded display is on.
postgres=# select * from pg_stat_replication;
-[ RECORD 1 ]----+------------------------------
pid              | 52680
usesysid         | 16388
usename          | repluser
application_name | walreceiver
client_addr      | 10.10.20.42
client_hostname  | 
client_port      | 9944
backend_start    | 2024-09-17 19:57:32.656436+08
backend_xmin     | 
state            | streaming
sent_lsn         | 0/4000168
write_lsn        | 0/4000168
flush_lsn        | 0/4000168
replay_lsn       | 0/4000168
write_lag        | 
flush_lag        | 
replay_lag       | 
sync_priority    | 0
sync_state       | async
reply_time       | 2024-09-18 14:08:26.481275+08
-[ RECORD 2 ]----+------------------------------
pid              | 53031
usesysid         | 16388
usename          | repluser
application_name | walreceiver
client_addr      | 10.10.20.43
client_hostname  | 
client_port      | 39794
backend_start    | 2024-09-18 13:49:55.790377+08
backend_xmin     | 
state            | streaming
sent_lsn         | 0/4000168
write_lsn        | 0/4000168
flush_lsn        | 0/4000168
replay_lsn       | 0/4000168
write_lag        | 
flush_lag        | 
replay_lag       | 
sync_priority    | 0
sync_state       | async
reply_time       | 2024-09-18 14:08:26.480268+08

```


