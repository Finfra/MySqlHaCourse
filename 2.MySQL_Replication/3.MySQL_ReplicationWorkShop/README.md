# Replication with Docker MySQL Images
Docker MySQL 이미지로 MySQL 복제 Master ⭢ Slave1 및 Master ⭢ Slave2 설정

#### 복제를 통해 하나의 MySQL 데이터베이스 서버(마스터)의 데이터를 하나 이상의 MySQL 데이터베이스 서버(슬레이브)로 복사



## 1. Overview

먼저 ***replicanet***이라는 Docker 네트워크를 만든 다음 Docker Hub(https://hub.docker.com/r/mysql/mysql-server/)에서 **mysql 5.7**을 가져올 것입니다. ) 다른 호스트에 3개의 노드(마스터 1개 및 슬레이브 2개)가 있는 복제 토폴로지를 만듭니다.

## 2. Pull MySQL Sever Image [생략 가능]

To download the *MySQL Community Edition image*, the command is:
```
docker pull mysql/mysql-server:tag
```
If `:tag` is omitted, the latest tag is used, and the image for the latest GA version of MySQL Server is downloaded.

Examples:
```
docker pull mysql/mysql-server:5.7
```


## 3. Creating a Docker network
Fire the following command to create a network:
```
$ docker network create replicanet
```
You just need to create it once, unless you remove it from Docker.

To see all Docker networks:
```
$ docker network ls
```
## 4. Creating 3 MySQL containers

Run the commands below in a terminal.
```
docker run -d --rm --name=master --net=replicanet --hostname=master \
 -e MYSQL_ROOT_PASSWORD=mypass \
  mysql:5.7 \
  --server-id=1 \
  --log-bin='mysql-bin-1.log'

docker run -d --rm --name=slave1 --net=replicanet --hostname=slave1 \
   -e MYSQL_ROOT_PASSWORD=mypass \
  mysql:5.7 \
  --server-id=2

docker run -d --rm --name=slave2 --net=replicanet --hostname=slave2 \
 -e MYSQL_ROOT_PASSWORD=mypass \
  mysql:5.7 \
  --server-id=3
```
It's possible to see whether the containers are started by running:
```
$ docker ps -a
```
```console
CONTAINER ID        IMAGE                    COMMAND                  CREATED             STATUS                            PORTS                 NAMES
b2b855652b3b        mysql/mysql-server:5.7   "/entrypoint.sh --se…"   3 seconds ago       Up 3 seconds (health: starting)   3306/tcp, 33060/tcp   slave2
8a10c0c92350        mysql/mysql-server:5.7   "/entrypoint.sh --se…"   7 seconds ago       Up 5 seconds (health: starting)   3306/tcp, 33060/tcp   slave1
8f8ceffd4580        mysql/mysql-server:5.7   "/entrypoint.sh --se…"   7 seconds ago       Up 7 seconds (health: starting)   3306/tcp, 33060/tcp   master
```
Servers are still with status **(health: starting)**, wait till they are with state **(healthy)** before running the following commands.
```console
CONTAINER ID        IMAGE                    COMMAND                  CREATED             STATUS                    PORTS                 NAMES
b2b855652b3b        mysql/mysql-server:5.7   "/entrypoint.sh --se…"   30 seconds ago      Up 30 seconds (healthy)   3306/tcp, 33060/tcp   slave2
8a10c0c92350        mysql/mysql-server:5.7   "/entrypoint.sh --se…"   34 seconds ago      Up 32 seconds (healthy)   3306/tcp, 33060/tcp   slave1
8f8ceffd4580        mysql/mysql-server:5.7   "/entrypoint.sh --se…"   34 seconds ago      Up 34 seconds (healthy)   3306/tcp, 33060/tcp   master
```

Now we’re ready start our instances and configure replication.

## 5. Configuring Master

Let's configure the **master node**.

Configuring **master node** replication user and get the initial replication co-ordinates
```
docker exec -it master mysql -uroot -pmypass \
  -e "CREATE USER 'repl'@'%' IDENTIFIED BY 'slavepass';" \
  -e "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';" \
  -e "SHOW MASTER STATUS;"
```
Output:
```console
mysql: [Warning] Using a password on the command line interface can be insecure.
+--------------------+----------+--------------+------------------+-------------------+
| File               | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set |
+--------------------+----------+--------------+------------------+-------------------+
| mysql-bin-1.000003 |      595 |              |                  |                   |
+--------------------+----------+--------------+------------------+-------------------+
```
### 6. Slaves
Let’s continue with the **slave nodes**.


이전 단계에서 캡처한 replication co-ordinate를 변경합니다(다른 경우):
* **MASTER_LOG_FILE='mysql-bin-1.000003'**

, before running the below command.
```
for N in 1 2
  do docker exec -it slave$N mysql -uroot -pmypass \
    -e "CHANGE MASTER TO MASTER_HOST='master', MASTER_USER='repl', \
      MASTER_PASSWORD='slavepass', MASTER_LOG_FILE='mysql-bin-1.000003';"

  docker exec -it slave$N mysql -uroot -pmypass -e "START SLAVE;"
done
```
Checking slave replication status on **slave1**:
```
$ docker exec -it slave1 mysql -uroot -pmypass -e "SHOW SLAVE STATUS\G"
```
Slave1 output:
```console
*************************** 1. row ***************************
               Slave_IO_State: Checking master version
                  Master_Host: master
                  Master_User: repl
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mysql-bin-1.000003
          Read_Master_Log_Pos: 595
               Relay_Log_File: slave1-relay-bin.000001
                Relay_Log_Pos: 4
        Relay_Master_Log_File: mysql-bin-1.000003
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
                             ...
```
Checking slave replication status on **slave2**:
```
$ docker exec -it slave2 mysql -uroot -pmypass -e "SHOW SLAVE STATUS\G"
```
Slave2 output:
```console
*************************** 1. row ***************************
               Slave_IO_State: Checking master version
                  Master_Host: master
                  Master_User: repl
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mysql-bin-1.000003
          Read_Master_Log_Pos: 595
               Relay_Log_File: slave2-relay-bin.000001
                Relay_Log_Pos: 4
        Relay_Master_Log_File: mysql-bin-1.000003
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
                             ...
```
## 7. 데이터 삽입 테스트

Now it's time to test whether data is replicated to slaves.
We are going to create a new database named "TEST" in master.
```
$ docker exec -it master mysql -uroot -pmypass -e "CREATE DATABASE TEST; SHOW DATABASES;"
```
Output:
```console
mysql: [Warning] Using a password on the command line interface can be insecure.
+--------------------+
| Database           |
+--------------------+
| information_schema |
| TEST               |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
```

Run the code below to check whether the database was replicated.
```
for N in 1 2
  do docker exec -it slave$N mysql -uroot -pmypass \
  -e "SHOW VARIABLES WHERE Variable_name = 'hostname';" \
  -e "SHOW DATABASES;"
done
```
Output:
```console
mysql: [Warning] Using a password on the command line interface can be insecure.
+---------------+--------+
| Variable_name | Value  |
+---------------+--------+
| hostname      | slave1 |
+---------------+--------+
+--------------------+
| Database           |
+--------------------+
| information_schema |
| TEST               |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
mysql: [Warning] Using a password on the command line interface can be insecure.
+---------------+--------+
| Variable_name | Value  |
+---------------+--------+
| hostname      | slave2 |
+---------------+--------+
+--------------------+
| Database           |
+--------------------+
| information_schema |
| TEST               |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
```

## 8. Cleaning up: stopping containers, removing created network and image

#### To stop the running containers:
```
$ docker stop master slave1 slave2
```
#### To remove the data directories created (they are located in the folder were the containers were run):
```
$ sudo rm -rf d0 d1 d2
```
#### To remove the created network:
```
$ docker network rm replicanet
```
#### To remove MySQL image:
```
$ docker rmi mysql/mysql-server:5.7
```

## References
- https://github.com/wagnerjfr/mysql-master-slaves-replication-docker/blob/master/README.md
- https://dev.mysql.com/doc/refman/8.0/en/replication.html
- https://github.com/wagnerjfr/docker-machine-master-slave-mysql-replication
