#!/usr/bin/env bash
#/bin/bash
#date 2019-5-1
#author zjj
# 监控vlutr的使用率，达到290G时候暂停keepalived服务
KEY="API-Key: R336LW2OYPBDWOAYEPYUKD6EX4ZS37RHFQBA"
while true
do
        MONITOR_IP=`cat /etc/v2ray/config.json | grep "address"| sed -n '1p' | awk -F '"' '{print$4}'`
        echo "本地使用的v2ray服务器地址为 $MONITOR_IP												`date +"%Y-%m-%d %H:%M:%S"`"

        curl -H "$KEY" https://api.vultr.com/v1/server/list | python -m json.tool | grep  -E "\blabel\b|\bSUBID\b|\bmain_ip\b" | awk '{print$1 $2}' > serverlist.log

        MONITOR_SUBID=`cat serverlist.log | grep -E "\bSUBID\b|\bmain_ip\b" |sed -n "/$MONITOR_IP/{x;p};h" | awk -F '"' '{print$4}'`
        echo "本地使用的v2ray服务器的subid为$MONITOR_SUBID											`date +"%Y-%m-%d %H:%M:%S"`"
	rm serverlist.log

        BANDWIDTH=`curl -H "$KEY" https://api.vultr.com/v1/server/bandwidth?SUBID=$MONITOR_SUBID | python -m json.tool | tail -4| sed -n '1p' | awk -F '"' '{print$2}'`
        echo "v2ray服务器的宽带使用率为 $BANDWIDTH 字节												`date +"%Y-%m-%d %H:%M:%S"`"
        if [ -z "$BANDWIDTH" ]
        then
            echo "跳出本次监控"
            sleep 5
            continue
        else
            BANDUSAGE=`expr $BANDWIDTH / 1024 / 1024 / 1024`
            echo "宽带使用率为$BANDUSAGE G													`date +"%Y-%m-%d %H:%M:%S"`"

            if [ $BANDUSAGE -gt 250 ]
            then
                echo "触发暂停keepalived条件，keepalived服务将停用										`date +"%Y-%m-%d %H:%M:%S"`"
		service keepalived stop
		echo "keepalived服务暂停成功													`date +"%Y-%m-%d %H:%M:%S"`"
            else
		echo "重启keepalived服务													`date +"%Y-%m-%d %H:%M:%S"`"
		service keepalived restart
                echo "流量小于250GG,进行下一次监控循环												`date +"%Y-%m-%d %H:%M:%S"`"
            fi
        fi
        echo "此次检测完成,开始睡眠时间3600秒													`date +"%Y-%m-%d %H:%M:%S"`"
        sleep	3600
	echo "睡眠完成，开始检测														`date +"%Y-%m-%d %H:%M:%S"`"
done
