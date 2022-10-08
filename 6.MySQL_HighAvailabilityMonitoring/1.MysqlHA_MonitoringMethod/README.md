# 기본적인 OS Resource Monitoring
```
# Memory
free -h

# Disk
df -h

# Process
top
ps -ef|grep 프로세스명

```

# 일반적인 MySQL 모니터링 방법
```
show global status like 'aborted_connects'
show processlist ;
```

# 일반적 MySQL High availability Monitoring
```
show slave status;  # execute on slave
show master status; # execute on master
```
