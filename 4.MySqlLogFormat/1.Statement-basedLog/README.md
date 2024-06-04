# Statement-based binlog 실습
```
docker rm -f mysql
docker run -d --rm --name mysql --hostname=mysql -e MYSQL_ROOT_PASSWORD=mypass mysql:5.7 --server-id=1 --log-bin='mysql-bin-1.log' --binlog_format='STATEMENT'

# 10초 기다리세요.
docker exec -it mysql /usr/bin/mysql -uroot -pmypass  -e "show variables like '%binlog_format%';"
```

# 로그 포멧 위치 확인
* Shell
```
docker exec -it mysql cat /etc/my.cnf |grep datadir
docker exec -it mysql /usr/bin/mysql -uroot -pmypass -e "show variables like 'log_bin%';"
```

# binlog_format 지정 및 확인
* 세션 다시 시작 해야 적용 됨 
```
set global binlog_format = 'MIXED';
show variables like 'binlog_format%';
set global binlog_format = 'ROW';
show variables like 'binlog_format%';
set global binlog_format = 'STATEMENT';
show variables like 'binlog_format%';

```
# binlog 내용 확인
## STATEMENT
```
docker exec -it mysql /usr/bin/mysql -uroot -pmypass
  use mysql
  create table x (x varchar(20),d date);
  insert into x values('aaaaaa',sysdate());
  insert into x select * from x;
  insert into x select * from x; #여러번
  insert into x select * from x; # 아래 다른 창 뛰워 놓고 한번 더 실행
```
* 다른 창 뛰워 놓고 실행 : binlog 크게 늘지 않는 것 확인
```
docker exec -it mysql find / 2>>/dev/null |grep mysql-bin-1
docker exec -it mysql tail -f /var/lib/mysql/mysql-bin-1.000003
```
