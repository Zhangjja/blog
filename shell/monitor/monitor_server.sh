#!/bin/bash

#author zjj
#date 201904110
#email junjie.zhang@ulsee.com
#version 1.0


#用法

if [ $# -ne 1 ]
then
	echo "Usage:sh $0 {3306|53|80}"
	exit
fi

#时间
date=`date`
ip=`hostname -I`
#判断服务的端口号是否存在
check=`netstat -tunlp | grep $1 |wc -l`
#判断守护者进程是否存在，如果存在则无法启用脚本
count=`ps -ef | grep "$0 $1"| grep -v "grep"|wc -l`


echo $count
if [ $count -gt 2 ]
then
	echo -e "\nERROR: There is already have a same monitoring!"
	exit 1
fi

function downMail(){
	echo " $1 ---- $ip----down  $date" > ./$1.log
	mail -s "$1----$ip----down" 124173026@qq.com < ./$1.log
}

function upMail(){
	echo "$ip-$1-switch-success  $date"  > ./$1.log
	mail -s "$ip-$1-switch-success" 124173026@qq.com < ./$1.log
}

function switchMail(){
	echo "$ip-$1-swithc-failed  $date"	> ./$1.log
	mail -s "$ip-$1-switch-failed" 1241730267@qq.com < ./$1.log
}

function loopMonitor(){
if [ $check -eq 0 ]
then
	echo "$1 is not listening !  pls input again !"
	exit 1
else
	while true
	do
		if [ `netstat -tunlp | grep $1 |wc -l` -eq 0 ]
		then
			echo "server port $1 is breaking!"
			downMail $1
			case "$1" in
			3306)
				echo "the server is mysql server"
				service mysql restart
				if [ $? -eq 0 ]
				then
					echo "重启mysql服务成功！"
				else
					echo "重启mysql服务失败！" >$1.log && switchMail $1 <$1.log
				fi
				;;
			80)
				echo "the server is http server"
				service nginx restart || service apache2 restart || service httpd restart
				if [ $? -eq 0 ]
                                then
                                        echo "重启web服务成功！"
                                else
                                        echo "重启web服务失败！" >$1.log && switchMail $1 <$1.log
                                fi

				;;
			53)
				echo "the server is dns server"
				service dnsmasq restart || service bind9 restart
                                if [ $? -eq 0 ]
                                then
                                        echo "重启dns服务成功！"
                                else
                                        echo "重启dns服务失败！" >$1.log &&  switchMail $1 <$1.log
					
                                fi
			esac

			if [ `netstat -tunlp | grep $1 |wc -l` -eq 0 ]
			then
				switchMail $1
				continue
			else
				upMail $1
				continue
			fi
		else
			sleep 10
		fi
	done
fi
}

loopMonitor $1
