# 셋팅
```
ls *.yml
docker-compose up -d
```

# 테스트
```
docker exec -it  galera_node1_1  mysql -uroot -ptest -e "create database xx;"
docker exec -it  galera_node2_1   mysql -uroot -ptest -e "show databases;"
```



## cf) docker run version
### node1

```sh
docker run -d \
  --name node1 \
  --hostname node1 \
  -p 13306:3306 \
  -e MYSQL_ROOT_PASSWORD=test \
  -e REPLICATION_PASSWORD=test \
  -e MYSQL_DATABASE=maria \
  -e MYSQL_USER=maria \
  -e MYSQL_PASSWORD=test \
  -e GALERA=On \
  -e NODE_NAME=node1 \
  -e CLUSTER_NAME=maria_cluster \
  -e CLUSTER_ADDRESS=gcomm:// \
  hauptmedia/mariadb:10.1 \
  --wsrep-new-cluster
```

### node2

```sh
docker run -d \
  --name node2 \
  --hostname node2 \
  --link node1 \
  -p 23306:3306 \
  -e REPLICATION_PASSWORD=test \
  -e GALERA=On \
  -e NODE_NAME=node2 \
  -e CLUSTER_NAME=maria_cluster \
  -e CLUSTER_ADDRESS=gcomm://node1 \
  hauptmedia/mariadb:10.1
```

### node3

```sh
docker run -d \
  --name node3 \
  --hostname node3 \
  --link node1 \
  -p 33306:3306 \
  -e REPLICATION_PASSWORD=test \
  -e GALERA=On \
  -e NODE_NAME=node3 \
  -e CLUSTER_NAME=maria_cluster \
  -e CLUSTER_ADDRESS=gcomm://node1 \
  hauptmedia/mariadb:10.1
```

