# MySQL DB준비
```
docker rm -f slave3



# Create containers
  docker run -d --rm --name=slave3 --net=replicanet --hostname=slave \
     -e MYSQL_ROOT_PASSWORD=mypass \
    mysql:5.7 \
    --server-id=4



# Configure Slave
docker exec -it slave3 mysql -uroot -pmypass  -e "CHANGE MASTER TO MASTER_HOST='master', MASTER_USER='repl',       MASTER_PASSWORD='slavepass', MASTER_LOG_FILE='mysql-bin-1.000003';"
docker exec -it slave3 mysql -uroot -pmypass -e "START SLAVE;"


# Test
docker exec -it slave3 mysql -uroot -pmypass -e "SHOW SLAVE STATUS\G"

```
