# Docker Run Command (Simple)
```
docker run -d --name mysql -e MYSQL_ROOT_PASSWORD=mypass mysql

docker exec -it mysql  bash
  #  mysql -u root -p
      # mypass   (비번 입력)
      # exit # mysql 종료
  # exit # Container 나가기

docker ps
docker rm -f mysql
docker ps

```

# Docker Run Command (General)
```
mkdir -p ~/df/Mysql/data
mkdir -p ~/df/Mysql/work
rm  -rf ~/df/Mysql/data/*
docker run                           \
    -d                               \
    --rm                             \
    --name mysql                     \
    -p 8081:8080                     \
    -p 3307:3306                     \
    -v ~/df/Mysql/data:/var/lib/mysql/   \
    -v ~/df/Mysql/work:/root/work        \
    -e MYSQL_ROOT_PASSWORD=mypass    \
    mysql
```


# 실습 데이터 설치
```
ls ../data
docker cp ../../data/empdept.sql mysql:/root/
docker exec -it mysql  ls /root
docker exec -it mysql /usr/bin/mysql -uroot -pmypass -e "source /root/empdept.sql"
```

# cf) Docker Command
## Docker 설치 후 초간단 테스트
```
docker images                       # 이미지 리스트 확인 : 현재 없음.
docker run -it hello-world          # 테스트용 이미지로 컨테이너 실행
docker images                       # 이미지 리스트 확인 : hello-world라는 이미지가 자동으로 생성되었음.
docker ps -a                        # 모든 컨테이너 리스트 확인(-a옵션은 shutdown된 컨테이너도 확인)
docker rm 컨테이너명이나컨테이너ID  # 해당 컨테이너 지우기
docker rmi hello-world              # 테스트때 다운 받아진 이미지를 지우기.
```

## docker 명령 자체
- 명령 옵션을 볼수가 있다.
- docker run --help⏎

## docker search
* docker images를 데 사용.
* ex
```
docker search ubuntu
```

## docker run
```
docker run -it --name u1 ubuntu
```

* option
- -it : 터미널 접속
- -d  : detach [실행되는 데몬이 있으면 실행하는 목]
* port forwarding
```
docker run -d -p 8888:80 --name n1 --rm nginx
```
  * Browser에서 접근 가능 : http://127.0.0.1:8888
  * 8888:80의 의미: host os 의 8888요청을 guest os의 80으로 보내줌.

* volume Mapping
```
cd
md xx #windows
mkdir xx #linux or mac
docker run -d -v ~/xx:/xx -p 8888:80 --name n1 --rm nginx
    touch /xx/aaa # guest os
```
   - 않되면 절대 Path를 적되 \ → \\ 로 바꿀 것.
     - "share it" message에서 ok안하면,
     - 강제로 할때는 도커 gui창에서 volumes 에서 지정
     - mac이나 linux유저는 해당 없음(잘 됨)
* 다른 터미널
```
dir xx #windows
ls xx  #linux or mac
```

## docker ps
docker ps -a # shutdown container 포함
docker ps    # up container 확인

## docker start/stop
docker start 컨테이너명혹은id
docker stop 컨테이너명혹은id

## docker exec
* 컨테이너로 명령을 전달
```
docker exec -it u1 mkdir /xx
docker exec -it u1 ls /
```

## docker attach
* Start된 container에 붙이기.
* 주의 1개만 2개부터는 TT
  - "docker exec -it 컨테이너명이나id  bash"명령을 권장

## docker rm
```
docker rm -f u1
```
= "docker stop u1" + "docker rm u1"

## dockerr rmi
```
docker rmi ubuntu
```
* 주의 사용중인 컨테이너가 있으면 지우고 실행.

## load and save
* commit이 필요 (container로 image를 생성 )
```
docker commit -m test n1 nowage/n1:1
```
  -- nowage는 docker hub 계정명
  -- n1이미지 명
  -- 1 : tag(버전 표시 용도)
* docker save
```
 docker save -o n1.docker nowage/n1:1
```

* docker load
```
docker load -i n1.docker
docker images
```
  -- 기존 이미지 제거 필요


## docker push and pull
* pull
```
docker pull nginx
```

* push
  - docker hub 계정 필요.
  - "docker login"명령 실행
```
docker push 아이디/이미지명:태그

### example : docker push nowage/n1:1
```
  - docker hub 사이트(https://hub.docker.com)에서 확인 가능하고, 추가 설명도 달 수 있어요.
```
