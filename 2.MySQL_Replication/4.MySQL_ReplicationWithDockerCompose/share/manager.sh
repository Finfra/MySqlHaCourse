echo "----------------------"
sleep 10

while : ; do
    x=$(mysqladmin ping -uroot -pmypass -h10.0.0.11 -P3306|grep alive)
    echo "Wait for slave"
    sleep 1
    if [ ${#x} -ne 0 ];then
      break
    fi
done
sleep 3

echo "--- master setting ---"
mysql -uroot -pmypass -h10.0.0.10 -P3306 \
  -e "CREATE USER 'repl'@'%' IDENTIFIED BY 'slavepass';" \
  -e "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';" \
  -e "SHOW MASTER STATUS;"
sleep 3

echo "--- slave setting ---"
mysql -uroot -pmypass -h10.0.0.11 -P3306 -e "CHANGE MASTER TO MASTER_HOST='10.0.0.10', MASTER_USER='repl',       MASTER_PASSWORD='slavepass', MASTER_LOG_FILE='mysql-bin-1.000002';"
mysql -uroot -pmypass -h10.0.0.11 -P3306 -e "START SLAVE;"
sleep 3

echo "--- Test -----"
mysql -uroot -pmypass -h10.0.0.11 -P3306 -e "SHOW SLAVE STATUS\G"
mysql -uroot -pmypass -h10.0.0.10 -P3306 -e "CREATE DATABASE TEST; SHOW DATABASES;"
mysql -uroot -pmypass -h10.0.0.11 -P3306 -e "SHOW DATABASES;"


sleep 10000000
