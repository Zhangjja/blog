#!/bin/bash
count=`ps -ef | grep "v2ray" |grep -v "grep" |wc -l`

if [ "$count" == "1" ]
then
        echo "v2ray服务正常运行"
else
        echo "v2ray服务异常"
        service keepalived stop
        killall keepalived
fi
