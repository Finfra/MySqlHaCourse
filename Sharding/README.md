# Mysql Sahrding
* Docker 환경에서 MySQL Sharding을 구현하려면 각 MySQL 인스턴스를 별도의 Docker 컨테이너로 실행하고, 동일한 네트워크(replicanet)에서 상호 연결되도록 해야 함. 다음은 이를 설정하는 과정:

## Example
### 1. Docker 네트워크 생성
* Docker 네트워크를 생성함:

```sh
docker network create replicanet
```

### 2. MySQL 컨테이너 생성

* 세 개의 MySQL 컨테이너를 생성함:

```sh
docker run -d --name m1 --network replicanet -e MYSQL_ROOT_PASSWORD=mypass mysql:latest
docker run -d --name m2 --network replicanet -e MYSQL_ROOT_PASSWORD=mypass mysql:latest
docker run -d --name m3 --network replicanet -e MYSQL_ROOT_PASSWORD=mypass mysql:latest
```

### 3. Python 컨테이너 생성 및 실행

* Python 컨테이너를 실행하여 MySQL 샤딩을 설정하는 스크립트를 실행함:

```sh
docker run --rm --name pyshard --network replicanet python:3.9-slim bash -c "python3 - << 'EOF'
import mysql.connector

# MySQL 서버 정보
shards = [
    {'host': 'm1', 'user': 'root', 'password': 'mypass'},
    {'host': 'm2', 'user': 'root', 'password': 'mypass'},
    {'host': 'm3', 'user': 'root', 'password': 'mypass'}
]

# 샤드 초기화
def initialize_shard(shard):
    conn = mysql.connector.connect(
        host=shard['host'],
        user=shard['user'],
        password=shard['password']
    )
    cursor = conn.cursor()
    cursor.execute("CREATE DATABASE IF NOT EXISTS shard_db")
    cursor.execute("USE shard_db")
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        username VARCHAR(255) NOT NULL,
        email VARCHAR(255) NOT NULL
    )
    """)
    conn.commit()
    cursor.close()
    conn.close()

# 모든 샤드 초기화
for shard in shards:
    initialize_shard(shard)

print("Shards initialized successfully")
EOF"
```

### 실행 명령어 정리

1. Docker 네트워크 생성:

    ```sh
    docker network create replicanet
    ```

2. MySQL 컨테이너 생성:

    ```sh
    docker run -d --name m1 --network replicanet -e MYSQL_ROOT_PASSWORD=mypass mysql:latest
    docker run -d --name m2 --network replicanet -e MYSQL_ROOT_PASSWORD=mypass mysql:latest
    docker run -d --name m3 --network replicanet -e MYSQL_ROOT_PASSWORD=mypass mysql:latest
    ```

3. Python 컨테이너 실행하여 샤딩 설정:

```sh
    docker run --rm -dt --name pyshard --network replicanet python:3.9-slim
```

4. Apt install
```bash
docker exec -it pyshard  bash -c "apt-get update && apt-get install -y gcc pkg-config libmysqlclient-dev ; pip install mysql-connector-python "
```

5. code 실행 : docker exec -it pyshard  python3 실행
```bash
docker exec -i pyshard  python3 - << 'EOF'
import mysql
import mysql.connector

# MySQL 서버 정보
shards = [
    {'host': 'm1', 'user': 'root', 'password': 'mypass'},
    {'host': 'm2', 'user': 'root', 'password': 'mypass'},
    {'host': 'm3', 'user': 'root', 'password': 'mypass'}
]

# 샤드 초기화
def initialize_shard(shard):
    conn = mysql.connector.connect(
        host=shard['host'],
        user=shard['user'],
        password=shard['password']
    )
    cursor = conn.cursor()
    cursor.execute('CREATE DATABASE IF NOT EXISTS shard_db')
    cursor.execute('USE shard_db')
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        username VARCHAR(255) NOT NULL,
        email VARCHAR(255) NOT NULL
    )
    ''')
    conn.commit()
    cursor.close()
    conn.close()

# 데이터 삽입
def insert_user(shard, username, email):
    conn = mysql.connector.connect(
        host=shard['host'],
        user=shard['user'],
        password=shard['password'],
        database='shard_db'
    )
    cursor = conn.cursor()
    cursor.execute('INSERT INTO users (username, email) VALUES (%s, %s)', (username, email))
    conn.commit()
    cursor.close()
    conn.close()

# 데이터 조회
def select_users(shard):
    conn = mysql.connector.connect(
        host=shard['host'],
        user=shard['user'],
        password=shard['password'],
        database='shard_db'
    )
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM users')
    rows = cursor.fetchall()
    for row in rows:
        print(row)
    cursor.close()
    conn.close()

# 모든 샤드 초기화
for shard in shards:
    initialize_shard(shard)

# 데이터 삽입 예제
insert_user(shards[0], 'user1', 'user1@example.com')
insert_user(shards[1], 'user2', 'user2@example.com')
insert_user(shards[2], 'user3', 'user3@example.com')

# 데이터 조회 예제
for shard in shards:
    print(f'Users in shard {shard["host"]}:')
    select_users(shard)
EOF
```
