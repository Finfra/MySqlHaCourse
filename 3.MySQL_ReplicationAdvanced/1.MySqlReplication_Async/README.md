# 비동기의 문제점 파악.
1. Master에 empdept.sql파일 실행
2. 아래 질의 실행
```
create table e as select * from emp;
```
3. Master에 생성도 되는 row가 700만개 이상 되도록 아래 질의를 계속 실행
```
create talbe e select * from e;
```
4. Master에서 다음 질의 실행
```
select count(*) from e;
```
5. 바로 slave에서 위 4번 질의 시행

6. 위 4번과 5번의 결과가 다름을 확인 같을 경우 3번 질의를 한번더 실행하고 위 4번과 5번을 반복.
