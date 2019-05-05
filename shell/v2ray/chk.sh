#!/bin/bash
count=`ps -ef | grep 'nginx' |wc -l`
count=1
if [ $count != 1 ]
then
        echo $count
        echo "停止keepalived"
        service keepalived stop
        killall keepalived
fi
