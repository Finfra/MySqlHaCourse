# Statement-based binlog 실습
```
docker rm -f mysql
rm -rf $PWD/d0
mkdir -rf $PWD/d0
docker run                           \
    -d                               \
    --rm                             \
    --name mysql                     \
    --net=replicanet                 \
    --hostname=mysql                \
    -p 8081:8080                     \
    -v $PWD/d0:/var/lib/mysql        \
    -e MYSQL_ROOT_PASSWORD=mypass    \
    mysql:5.7                            \
    --server-id=1                    \
    --log-bin='mysql-bin-1.log' \
    --binlog_format='MIXED'

# 10초 기다리세요.
docker exec -it mysql \
    mysql -uroot -pmypass \
    -e "show variables like '%binlog_format%';"
```

# binlog 내용 확인
```
mysql -uroot -p
  create table x (x varchar(20));
  insert into x values('aaaaaa');
  insert into x select * from x;
  insert into x select * from x; #여러번
```
* 다른 창 뛰워 놓고 실행

```
ls -als |grep mysql-bin-1
tail -f /var/lib/mysql/mysql-bin-1.000003;
```
* binlog 크게 늘지 않는 것 확인
