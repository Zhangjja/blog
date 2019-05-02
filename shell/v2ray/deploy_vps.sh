#!/bin/bash
key="API-Key: R336LW2OYPBDWOAYEPYUKD6EX4ZS37RHFQBA"
vps=""
if [ -z "$1" ]
then
	vps="default"
else
	vps="$1"
fi

curl -H "$key" https://api.vultr.com/v1/server/create --data 'DCID=5' --data 'VPSPLANID=201' --data 'OSID=193' --data 'SSHKEYID=5cc15103d9f4d' --data "label=$vps" > subid.txt
cat subid.txt
echo "installing server......"

SUBID=`cat subid.txt | awk -F '"' '{print$4}'`
echo $SUBID

ip=""
while true
do
	ip=`curl -H "$key" https://api.vultr.com/v1/server/list?SUBID=$SUBID | python -m json.tool | grep -E "\bmain_ip\b"  |awk -F '"' '{print$4}'`
	if [ $ip == "0.0.0.0" ]
	then	
		echo $ip
		echo "getting ip......"
		sleep 5
		ip=`curl -H "$key" https://api.vultr.com/v1/server/list?SUBID=$SUBID | python -m json.tool | grep -E "\bmain_ip\b"  |awk -F '"' '{print$4}'`
	else
		echo $ip
		break
	fi	
done


pwd=""
while true
do
	pwd=`curl -H "$key" https://api.vultr.com/v1/server/list?SUBID=$SUBID  | python -m json.tool | grep -E  "\bdefault_password\b" |awk -F '"' '{print$4}'`
	if [ -z $pwd ]
	then
		echo $pwd
		echo "getting pwd......"
		sleep 5
		pwd=`curl -H "$key" https://api.vultr.com/v1/server/list?SUBID=$SUBID  | python -m json.tool | grep -E  "\bdefault_password\b" |awk -F '"' '{print$4}'`
	else
		echo $pwd
		break
	fi
done

rm subid.txt

while true
do
	i=1
	ping -c 1 -W 2 $ip >/dev/null
	if [ $? -eq 0 ]
	then
		break
	else
		sleep 5
		i=$(expr $i + 1)
		echo "$i"
	fi
done

ping -c 2 -W 2 $ip >> /dev/null
if [ $? = 0 ]
then
	echo "ip地址存在！"
	echo "------------"
	echo "清理$ip已经存在的密钥"
	ssh-keygen -f "/root/.ssh/known_hosts" -R $ip
	echo "正在添加密钥！"
	#静默安装本地ssh密钥
	echo "v2ray_server安装ssh密钥"
	while true
	do
		ssh -o stricthostkeychecking=no root@$ip "ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa -q"
		if [ $? -eq 0 ]
			break
		then
			ssh -o stricthostkeychecking=no root@$ip "ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa -q"
		fi
	done

	echo "------------"
	echo "正在配置ansible主控端"

	jugde=`cat /etc/ansible/hosts | grep -E "\b$vps\b"| wc -l`
	if [ $jugde -gt 0 ]
	then
		echo "$vps已存在"
		sed  -i "/$vps/{n;d}" /etc/ansible/hosts
		sed -i "/$vps/a$ip ansible_ssh_user=root ansible_sudo_pass=$pwd" /etc/ansible/hosts
	else
		echo "$vps不存在"
		sed -i "\$a\\[$vps\]" /etc/ansible/hosts
                sed -i "/$vps/a$ip ansible_ssh_user=root ansible_sudo_pass=$pwd" /etc/ansible/hosts
	fi
	echo "主控端配置完毕！"
	echo "------------"
	echo "测试ansible被控端"
	ansible $vps -m ping
	command=`ansible $vps -m ping | grep "SUCCESS"|wc -l`
	if [ $command -gt 0 ]
	then
		echo "主控端配置成功！"
	else
		echo "主控端配置失败！"
		exit 1
	fi

	echo "开始安装v2ray服务端"
	#配置v2ray服务端脚本,使用ansible script模块路径为./v2ray_server_install.sh,开始安装v2ray服务端
	ansible $vps -m script -a "./v2ray_server_install.sh"
	ansible $vps -m copy -a "src=./server_config.json dest=/etc/v2ray/config.json owner=root group=root mode=0644"
	echo "v2ray服务端安装完毕！"
	echo "-------------------"
	echo "开始配置v2ray服务端配置文件"
	ip=`ansible $vps -m shell -a "ifconfig" | sed -n '3p'|awk '{print$2}'|awk -F ':' '{print$2}'`
	echo "修改配置文件的ip，port，id"
	port=`ansible $vps -m shell -a "cat /root/config.json.bak" |sed -n '4p'`
	id=`ansible $vps -m shell -a "cat /root/config.json.bak" |sed -n '9p'`
	ansible $vps -m shell -a "cat  /root/config.json.bak"
	ansible $vps -m shell -a "cat  /etc/v2ray/config.json"
	echo "$ip"  "$port"   "$id"
	echo "正在修改-----------"
	ansible $vps -m shell -a "sed -i '8i\\$port' /etc/v2ray/config.json"
	ansible $vps -m shell -a "sed -i '9d' /etc/v2ray/config.json"
	ansible $vps -m shell -a "sed -i '13i\\$id' /etc/v2ray/config.json"
	ansible $vps -m shell -a "sed -i '14d' /etc/v2ray/config.json"
	echo "修改完毕-----------"
	echo "v2ray服务端配置成功!开始重启v2ray服务器"
	ansible $vps -m shell -a "reboot"
	echo "重启成功！"
	echo "-------------------"
else
	echo "ip error, please check"
	exit 1
fi
