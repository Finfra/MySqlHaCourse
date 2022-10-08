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

# Network 확인
```
docker network inspect replicanet
  # IPv4Address키 확인
docker exec -it master  ls yum install -y net-tools
docker exec -it master ifconfig|grep inet
```

# 접속 테스트
```
docker exec -it slave mysql -h 172.18.0.2 -u root -pmypass --port 3306 -e "SHOW DATABASES;"
```

# HaProxy Container 생성, 설정 및 구동
```
docker rm -f haproxy
docker run -it --name haproxy -p 20000:20000 --net=replicanet centos:centos7 /bin/bash
  yum -y install haproxy
```
* HaProxy.cfg 파일 수정
```
vi /etc/haproxy/haproxy.cfg
  # 수정할
  # mode tcp
  # option tcplog
  # 추가할
  #  listen mysql_cluster 0.0.0.0:20000
  #    mode tcp
  #    balance roundrobin
  #    #option mysql-check user haproxy
  #    server  node1 172.xx.0.2:3306 weight 2 check
  #    server  node2 172.xx.0.3:3306 weight 1 check
 haproxy -f /etc/haproxy/haproxy.cfg -db -V
```

# HaProxy 작동 확인
```
docker exec -it slave mysql -h 172.18.0.4 -u root -pmypass --port 20000 -e "show variables like 'server_id';"
```

# HaProxy 연습
```
docker run -d --rm --name n1 --net=replicanet -p 8081:80 nginx
docker run -d --rm --name n2 --net=replicanet -p 8082:80 nginx

docker run -it --name haproxy2 -p 20080:20080 --net=replicanet centos:centos7 /bin/bash
  yum -y install haproxy

  vi /etc/haproxy/haproxy.cfg
    # 수정할
    # mode tcp
    # option tcplog
    # 추가할
    #  listen mysql_cluster 0.0.0.0:20080
    #    mode tcp
    #    balance roundrobin
    #    #option mysql-check user haproxy
    #    server  node1 172.18.0.5:80 weight 2 check
    #    server  node2 172.18.0.6:80 weight 1 check
   haproxy -f /etc/haproxy/haproxy.cfg -db -V
docker exec -it n1 bash
  echo 1 > /usr/share/nginx/html/index.html
docker exec -it n1 bash
  echo 2 > /usr/share/nginx/html/index.html

# 브라우저 :
```
127.0.0.1:20080
```
# cf) vi 못쓰시는 분 복붙하세요.
echo "
#---------------------------------------------------------------------
# Example configuration for a possible web application.  See the
# full configuration options online.
#
#   http://haproxy.1wt.eu/download/1.4/doc/configuration.txt
#
#---------------------------------------------------------------------

#---------------------------------------------------------------------
# Global settings
#---------------------------------------------------------------------
global
    # to have these messages end up in /var/log/haproxy.log you will
    # need to:
    #
    # 1) configure syslog to accept network log events.  This is done
    #    by adding the '-r' option to the SYSLOGD_OPTIONS in
    #    /etc/sysconfig/syslog
    #
    # 2) configure local2 events to go to the /var/log/haproxy.log
    #   file. A line like the following can be added to
    #   /etc/sysconfig/syslog
    #
    #    local2.*                       /var/log/haproxy.log
    #
    log         127.0.0.1 local2

    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    user        haproxy
    group       haproxy
    daemon

    # turn on stats unix socket
    stats socket /var/lib/haproxy/stats

#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
    mode                    tcp
    log                     global
    option                  tcplog
    option                  dontlognull
    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 3000

listen mysql_cluster 0.0.0.0:20000
  mode tcp
  balance roundrobin
  #option mysql-check user haproxy
  server  node1 172.18.0.2:3306 weight 2 check
  server  node2 172.18.0.3:3306 weight 1 check



#---------------------------------------------------------------------
# main frontend which proxys to the backends
#---------------------------------------------------------------------
frontend  main *:5000
    acl url_static       path_beg       -i /static /images /javascript /stylesheets
    acl url_static       path_end       -i .jpg .gif .png .css .js

    use_backend static          if url_static
    default_backend             app

#---------------------------------------------------------------------
# static backend for serving up images, stylesheets and such
#---------------------------------------------------------------------
backend static
    balance     roundrobin
    server      static 127.0.0.1:4331 check

"   > /etc/haproxy/haproxy.cfg
