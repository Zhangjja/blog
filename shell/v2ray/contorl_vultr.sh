#!/bin/bash




curl -H 'API-Key: R336LW2OYPBDWOAYEPYUKD6EX4ZS37RHFQBA' https://api.vultr.com/v1/server/list | python -m json.tool | grep  -E "\blabel\b|\bSUBID\b|\bmain_ip\b" |awk '{print$1 $2}' > logfile

cat logfile

while true
do
	read -p "选择要删除的服务器SUBID : " subid
	count=`cat logfile | grep -E "\b$subid\b" |wc -l`
	if [ $count -gt 0 ]
	then
		curl -H 'API-Key: R336LW2OYPBDWOAYEPYUKD6EX4ZS37RHFQBA' https://api.vultr.com/v1/server/destroy --data "SUBID=$subid"
		echo "SUBID: $subid 删除成功"
		break
	else
		echo "$subid 不存在"
	fi
done

rm logfile
