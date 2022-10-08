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
