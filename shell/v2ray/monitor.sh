#/bin/bash
#date 2019-4-30
#author zjj
#describe 监控vlutr的使用率，达到290G时候自动重新搭建服务器，销毁老服务器，建立新服务器

IP=`ansible gw -m shell -a 'cat /etc/v2ray/config.json' | grep "address"|sed -n '1p' |awk -F '"' '{print$4}'`



curl -H 'API-Key: R336LW2OYPBDWOAYEPYUKD6EX4ZS37RHFQBA' https://api.vultr.com/v1/server/list | python -m json.tool | grep  -E "\blabel\b|\bSUBID\b|\bmain_ip\b" |awk '{print$1 $2}' > serverlist.log

SUBID=`cat serverlist.log | grep -E "\bSUBID\b|\bmain_ip\b" |sed -n "/$IP/{x;p};h"`
LABEL=`cat serverlist.log | grep -E "\blabel\b|\bmain_ip\b" |sed -n "/$IP/{x;p};h"`



BANDWIDTH=`curl -H 'API-Key: YOURKEY' https://api.vultr.com/v1/server/bandwidth?SUBID=$SUBID | python -m json.tool |tail -4|sed -n '1p'|awk -F '"' '{print$2}'`

BANDUSAGE=`expr $BANDWIDTH / 1024 / 1024 / 1024`

if [[ "$BANDUSAGE" -gt 300 ]]
then
    service keepalived stop
    curl -H 'API-Key: R336LW2OYPBDWOAYEPYUKD6EX4ZS37RHFQBA' https://api.vultr.com/v1/server/destroy --data "SUBID=$SUBID"
    sleep 120
    ./w
