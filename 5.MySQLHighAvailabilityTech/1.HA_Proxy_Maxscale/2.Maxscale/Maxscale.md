# MySQL DB준비
```
docker network create replicanet

docker rm -f master
docker rm -f slave


# Create containers
docker run -d --rm --name=master --net=replicanet --hostname=master \
 -e MYSQL_ROOT_PASSWORD=mypass \
  mysql:5.7 \
  --server-id=1 \
  --log-bin='mysql-bin-1.log'

docker run -d --rm --name=slave --net=replicanet --hostname=slave \
   -e MYSQL_ROOT_PASSWORD=mypass \
  mysql:5.7 \
  --server-id=2

sleep 10

# Configure Master
  docker exec -it master mysql -uroot -pmypass \
    -e "CREATE USER 'repl'@'%' IDENTIFIED BY 'slavepass';" \
    -e "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';" \
    -e "SHOW MASTER STATUS;"

# Configure Slave
docker exec -it slave mysql -uroot -pmypass \
  -e "CHANGE MASTER TO MASTER_HOST='master', MASTER_USER='repl', \
    MASTER_PASSWORD='slavepass', MASTER_LOG_FILE='mysql-bin-1.000003';"
# Start Slave
docker exec -it slave mysql -uroot -pmypass -e "START SLAVE;"

# Test
docker exec -it slave mysql -uroot -pmypass -e "SHOW SLAVE STATUS\G"

docker exec -it master mysql -uroot -pmypass -e "CREATE DATABASE TEST; SHOW DATABASES;"

docker exec -it slave mysql -uroot -pmypass  -e "SHOW DATABASES;"
```

# Maxscale User 생성
```
docker exec -it master  mysql -uroot -pmypass -e "
    CREATE USER 'maxscale'@'%' IDENTIFIED BY '1';
    GRANT SELECT ON mysql.user TO 'maxscale'@'%';
    GRANT SELECT ON mysql.db TO 'maxscale'@'%';
    GRANT SELECT ON mysql.tables_priv TO 'maxscale'@'%';
    GRANT SELECT ON mysql.columns_priv TO 'maxscale'@'%';
    GRANT SELECT ON mysql.proxies_priv TO 'maxscale'@'%';
    GRANT SHOW DATABASES ON *.* TO 'maxscale'@'%';
    GRANT REPLICATION CLIENT,REPLICATION SLAVE,SUPER,RELOAD on *.* to 'maxscale'@'%';
    flush privileges;
"
```


# Maxscale Container 생성, 설정 및 구동
```
docker rm -f mxs
docker run -d -p 8989:8989 -p3306:3306 --name mxs --net=replicanet mariadb/maxscale:latest
curl -u admin:mariadb http://localhost:8989/v1/maxscale
```
* maxscale.cfg 파일 수정
```
docker exec -it mxs  bash
echo "
[maxscale]
admin_secure_gui=false
threads=1
admin_host=0.0.0.0

[server1]
type=server
address=master
port=3306
protocol=MariaDBBackend

[server2]
type=server
address=slave
port=3306
protocol=MariaDBBackend

[MariaDB-Monitor]
replication_password=1
replication_user=maxscale
module=mariadbmon
password=1
servers=server1,server2
type=monitor
user=maxscale

[Splitter-Service]
password=1
router=readwritesplit
type=service
user=maxscale
targets=server1,server2

[Splitter-Listener]
port=3306
service=Splitter-Service
type=listener
" >  /etc/maxscale.cnf


```
# Maxscale 재시작
```
docker exec -it mxs   maxscale-restart
```
# Test
```
docker exec -it master bash
  mysql -umaxscale -p1 -P3306 -h172.18.0.4  -e "use mysql;show tables;"
```

# Mini Workshop
* slave3를 추가해 보세요. (20분)
```
docker rm -f slave2

docker run -d --rm --name=slave2 --net=replicanet --hostname=slave2 \
   -e MYSQL_ROOT_PASSWORD=mypass \
  mysql:5.7 \
  --server-id=3

docker exec -it slave2 mysql -uroot -pmypass \
  -e "CHANGE MASTER TO MASTER_HOST='master', MASTER_USER='repl', \
    MASTER_PASSWORD='slavepass', MASTER_LOG_FILE='mysql-bin-1.000003';"
# Start Slave
docker exec -it slave2 mysql -uroot -pmypass -e "START SLAVE;"
docker exec -it slave2 mysql -uroot -pmypass  -e "SHOW DATABASES;"


docker exec -it mxs  bash
echo "
[server3]
type=server
address=172.18.0.5
port=3306
protocol=MariaDBBackend">>  /etc/maxscale.cnf
maxscale-restart



#나머지는 GUI화면에서....

```









## https://yunhyeonglee.tistory.com/57
