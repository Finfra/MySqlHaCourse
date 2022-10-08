# MySQL DB준비
```
docker rm -f master
docker rm -f slave1
docker rm -f slave2



# Create containers
docker run -d --rm --name=master --net=replicanet --hostname=master \
 -e MYSQL_ROOT_PASSWORD=mypass \
  mysql:5.7 \
  --server-id=1 \
  --log-bin='mysql-bin-1.log'

docker run -d --rm --name=slave1 --net=replicanet --hostname=slave \
   -e MYSQL_ROOT_PASSWORD=mypass \
  mysql:5.7 \
  --server-id=2

  docker run -d --rm --name=slave2 --net=replicanet --hostname=slave \
     -e MYSQL_ROOT_PASSWORD=mypass \
    mysql:5.7 \
    --server-id=3


# Configure Master
docker exec -it master mysql -uroot -pmypass \
  -e "CREATE USER 'repl'@'%' IDENTIFIED BY 'slavepass';" \
  -e "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';" \
  -e "SHOW MASTER STATUS;"

# Configure Slave
docker exec -it slave1 mysql -uroot -pmypass  -e "CHANGE MASTER TO MASTER_HOST='master', MASTER_USER='repl',       MASTER_PASSWORD='slavepass', MASTER_LOG_FILE='mysql-bin-1.000003';"
docker exec -it slave1 mysql -uroot -pmypass -e "START SLAVE;"

docker exec -it slave2 mysql -uroot -pmypass  -e "CHANGE MASTER TO MASTER_HOST='master', MASTER_USER='repl',       MASTER_PASSWORD='slavepass', MASTER_LOG_FILE='mysql-bin-1.000003';"
docker exec -it slave2 mysql -uroot -pmypass -e "START SLAVE;"


# Test
docker exec -it slave1 mysql -uroot -pmypass -e "SHOW SLAVE STATUS\G"
docker exec -it slave2 mysql -uroot -pmypass -e "SHOW SLAVE STATUS\G"
docker exec -it master mysql -uroot -pmypass -e "CREATE DATABASE TEST; SHOW DATABASES;"
docker exec -it slave2 mysql -uroot -pmypass  -e "SHOW DATABASES;"

```
