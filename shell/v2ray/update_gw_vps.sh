#!/bin/bash

#2019-4-15
#author zhangjunjie
echo "一键更新局域网的网关和DNS服务"
echo "选择需要更新的GW_DNS和VPS组名,将此GW_DNS配置成为使用此VPS的科学上外网关"

#while true
#do
#	read -p "请输入需要更新的局域网网关或者DNS的ansible分组名：" GW_DNS
	GW_DNS="$1"
	echo "您输入的GW_DNS分组为$GW_DNS,正在验证GW_DNS分组是否存在,请稍后..."
	count1=`ansible $GW_DNS -m ping|grep SUCCESS|wc -l`
	if [ $count1 -gt 0 ]
	then
		echo "验证成功GW_DNS分组存在！分组名为$GW_DNS"
#		break
	else
		echo "GW_DNS分组不存在，请重新输入......"
		exit 1
	fi
#done

#while true
#do
#        read -p "请输入需要更新的局域网需要使用的VPS服务器分组名：" VPS
	VPS="$2"
        echo "您输入的VPS分组为$VPS,正在验证VPS分组是否存在,请稍后..."
        count2=`ansible $VPS -m ping|grep SUCCESS|wc -l`
        if [ $count2 -gt 0 ]
        then
                echo "验证成功VPS分组存在！分组名为$VPS"
#                break
        else
                echo "VPS分组不存在，请重新输入......"
		exit 1

        fi
#done
#获取v2ray服务端的IP，PORT，ID
server_address=`ansible $VPS -m shell -a "ifconfig" | sed -n '3p'|awk '{print$2}'|awk -F ':' '{print$2}'`
echo "v2ray_server的IP是$server_address"
server_port=`ansible $VPS -m shell -a "cat /etc/v2ray/config.json" | grep port | sed -n '1p'`
echo "$server_port"
server_id=`ansible $VPS -m shell -a "cat /etc/v2ray/config.json" | grep id`
echo "$server_id"

echo "下一步需要修改gw和dns组的配置文件，现在正在形成参数"
echo "修改gw的配置文件/etc/v2ray/config.json,/opt/v2ray-firewall"
echo "1.拼接ip地址"
address="                \"address\"":"\"$server_address\"",""
echo $address
echo "2.拼接端口号"
port="            "$server_port
echo $port
echo "3.拼接id"
id="          "$server_id
echo $id

echo "执行修改局域网GW或DNS的配置文件"
echo "配置ip地址"
ansible $GW_DNS -m shell -a "sed -i '13i\\$address' /etc/v2ray/config.json"
ansible $GW_DNS -m shell -a "sed -i '14d' /etc/v2ray/config.json"

echo "配置端口"
ansible $GW_DNS -m shell -a "sed -i '14i\\$port' /etc/v2ray/config.json"
ansible $GW_DNS -m shell -a "sed -i '15d' /etc/v2ray/config.json"

echo "配置id"
ansible $GW_DNS -m shell -a "sed -i '17i\\$id' /etc/v2ray/config.json"
ansible $GW_DNS -m shell -a "sed -i '18d' /etc/v2ray/config.json"

echo "配置防火墙"
echo "1.拼接防火墙"
fire_wall="iptables -t nat -A V2RAY -d  $server_address -j RETURN"
echo $fire_wall
ansible $GW_DNS -m shell -a "sed -i '14i\\$fire_wall' /opt/v2ray-firewall"
ansible $GW_DNS -m shell -a "sed -i '15d' /opt/v2ray-firewall"

echo "重启GW_DNS的v2ray服务"
ansible $GW_DNS -m shell -a "reboot"
echo "服务重启成功！"
echo "配置完毕！"
