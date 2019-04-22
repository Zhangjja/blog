#!/bin/bash

#date:2019-4-22
#author zjj
#describe 监控数据库主从复制状态
#mail 124173026@qq.com


CODE=(
1158
1159
1008
1007
1062
2003
)
fun_Base(){
#1.定义变量

#1.1 抓取IP地址
IP=`ifconfig ens160 |awk 'NR==2{print $2}'`

#1.2 获取slave IO和SQL状态，Err代码
My_SQL=`mysql --defaults-extra-file=./config.cnf -e "show slave status\G" |egrep "SQL_Running:" |awk '{print $NF}'`
My_IO=`mysql --defaults-extra-file=./config.cnf -e "show slave status\G" |egrep "IO_Running:" |awk '{print $NF}'`
My_CODE=`mysql --defaults-extra-file=./config.cnf -e "show slave status\G" |egrep "Last_IO_Errno:" |awk '{print $NF}'`

#1.3 定时时间变量
Time=`date +%F-%H:%M:%S`

#1.4 定义log目录
DIR=/tmp/slave_${Time}
Status_Log=$DIR/slave_status_${Time}.log
Check_log=$DIR/slave_check_${Time}.log
Erro_log=$DIR/slave_err_${Time}.log
#1.5 定义邮箱
Total="$IP slave status $Time"
Mail_Rec="124173026@qq.com"

#2.将slave的状态保存到log文件中
[ -d $DIR ] || mkdir $DIR -p
mysql --defaults-extra-file=./config.cnf -e "show slave status\G" >$Status_Log
}

#3.判断slave状态的错误代码
fun_Status(){
RETVAL=0
for  ((i=0;i<${#CODE[*]};i++))
do
    if [ $My_CODE -eq ${CODE[i]}  ];then
       mysql --defaults-extra-file=./config.cnf -e "stop slave;" && RETVAL=$?
       [ $RETVAL -eq 0 ] && mysql --defaults-extra-file=./config.cnf -e "SET GLOBAL SQL_SLAVE_SKIP_COUNTER = 1;" && RETVAL=$?
       [ $RETVAL -eq 0 ] && mysql --defaults-extra-file=./config.cnf -e "start slave;" && RETVAL=$?
       [ $RETVAL -eq 0 ] && echo "slave errno code is successful." >$Erro_log
       [ $RETVAL -eq 0 ] && mail -s "$Total" $Mail_Rec <$Status_Log && mail -s "$Total" $Mail_Rec <$Erro_log
    fi
done
}

#4.判断IO和SQL线程是否正常
fun_Check(){
  if [ "$My_SQL" == "Yes" -a "$My_IO" == "Yes" ];then
    echo "slave status is successful." 
    echo "slave status is successful." >$Check_log
  else
    echo "slave status is failed."
    echo "slave status is failed." >>$Check_log
    mail -s "$Total" $Mail_Rec <$Status_Log
    mail -s "$Total" $Mail_Rec <$Check_log
 fi
}

#5.主体函数
main(){

while true
do
 fun_Base
 fun_Status
 fun_Check
 sleep 300
done
}

main
