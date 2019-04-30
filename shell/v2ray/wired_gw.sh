#!/bin/bash
vps=""
if [ -z "$1" ]
then
	vps="default"
else
	vps="$1"
fi

#while true
#do
	curl -H 'API-Key: R336LW2OYPBDWOAYEPYUKD6EX4ZS37RHFQBA' https://api.vultr.com/v1/server/create --data 'DCID=5' --data 'VPSPLANID=201' --data 'OSID=193' --data 'SSHKEYID=5cc15103d9f4d' --data "label=$vps" > subid.txt
#	count=`cat subid.txt | wc -l`
#	if [ $count -eq 0 ]
#	then
#		sleep 5
#	else
		cat subid.txt
		echo "installing server......"
#		break
#	fi
#done

SUBID=`cat subid.txt | awk -F '"' '{print$4}'`
echo $SUBID


ip=""
while true
do
	ip=`curl -H 'API-Key: R336LW2OYPBDWOAYEPYUKD6EX4ZS37RHFQBA' https://api.vultr.com/v1/server/list?SUBID=$SUBID | python -m json.tool | grep -E "\bmain_ip\b"  |awk -F '"' '{print$4}'`
	if [ $ip == "0.0.0.0" ]
	then	
		echo $ip
		echo "getting ip......"
		sleep 5
		ip=`curl -H 'API-Key: R336LW2OYPBDWOAYEPYUKD6EX4ZS37RHFQBA' https://api.vultr.com/v1/server/list?SUBID=$SUBID | python -m json.tool | grep -E "\bmain_ip\b"  |awk -F '"' '{print$4}'`
	else
		echo $ip
		break
	fi	
done


pwd=""
while true
do
	pwd=`curl -H 'API-Key: R336LW2OYPBDWOAYEPYUKD6EX4ZS37RHFQBA' https://api.vultr.com/v1/server/list?SUBID=$SUBID  | python -m json.tool | grep -E  "\bdefault_password\b" |awk -F '"' '{print$4}'`
	if [ -z $pwd ]
	then
		echo $pwd
		echo "getting pwd......"
		sleep 5
		pwd=`curl -H 'API-Key: R336LW2OYPBDWOAYEPYUKD6EX4ZS37RHFQBA' https://api.vultr.com/v1/server/list?SUBID=$SUBID  | python -m json.tool | grep -E  "\bdefault_password\b" |awk -F '"' '{print$4}'`
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
#	echo "将本地密钥拷贝到腾讯云上"
#	ssh-copy-id -i /root/.ssh/id_rsa.pub ubuntu@118.89.139.53
#	echo "远程v2ray服务器，并配置v2ray与腾讯云的免密ssh登录"
#	ssh -t root@$ip  "ssh-copy-id -i /root/.ssh/id_rsa.pub ubuntu@118.89.139.53"
#	echo "将本地密钥拷贝到v2ray服务端"
#	ssh-copy-id -i /root/.ssh/id_rsa.pub root@$ip
#	echo "添加密钥成功！"
	echo "------------"
	echo "正在配置ansible主控端"
#	read -p "请输入被控端密码：" pwd
#	count=`sed -n "/$ip/p" /etc/ansible/hosts | wc -l`
#	if [ $count -ge 0 ]
#	then
#		echo "$ip exsiting in /etc/ansible/hosts"
#		sed -i /$ip/d /etc/ansible/hosts
#	fi
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
#	echo "配置腾讯云与vps的免密认证"
#	ubuntu_key=`ansible tx -m shell -a "cat /home/ubuntu/.ssh/id_rsa.pub " |grep ubuntu@VM-0-7-ubuntu`
#	echo "$ubuntu_key"
#	count=`ansible $vps -m shell -a "cat /root/.ssh/authorized_keys" |grep ubuntu@VM-0-7-ubuntu | wc -l`
#	echo "$count"
#	if [ $count -gt 0 ]
#	then
#		echo "vps已经存在腾讯云的密钥！"
#		echo "删除vps已存在的腾讯云密钥！"
#		ansible $vps -m shell -a "sed -i '/ubuntu@VM-0-7-ubuntu/d' /root/.ssh/authorized_keys"
#	fi
#	echo "配置vps中的腾讯云密钥"
#	ansible $vps -m shell -a "sed -i '\$a\\$ubuntu_key' /root/.ssh/authorized_keys"
#	echo "vps密钥配置成功！"
#	echo "vps与腾讯云的免密认证"
#	vps_key=`ansible $vps -m shell -a "cat /root/.ssh/id_rsa.pub " | grep root@`
#	echo "$vps_key"
#	tag=`ansible $vps -m shell -a 'cat /root/.ssh/id_rsa.pub' | sed -n '/ssh-rsa/p' |awk '{print $3}'`
#	count=`ansible tx -m shell -a "cat /home/ubuntu/.ssh/authorized_keys" | grep "$tag" | wc -l`
#	echo "$count"
#	if [ $count -gt 0 ]
#	then
#		echo "腾讯云已经存在ps的密钥！"
#		echo "删除腾讯云已存在的vps密钥！"
#		ansible tx -m shell -a "sed -i "/$tag/d" /home/ubuntu/.ssh/authorized_keys"
#	fi
#	echo "配置腾讯云中的vps密钥"
#	ansible tx -m shell -a "sed -i '\$a\\$vps_key' /home/ubuntu/.ssh/authorized_keys"
#	echo "腾讯云密钥配置成功！"

	echo "-------------------"
	echo "开始安装v2ray服务端"
	#配置v2ray服务端脚本,使用ansible script模块路径为./v2ray_server_install.sh
	#安装v2ray服务端
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
	echo "$ip"
	echo "$port"
	echo "$id"
	echo "正在修改------"
	ansible $vps -m shell -a "sed -i '8i\\$port' /etc/v2ray/config.json"
	ansible $vps -m shell -a "sed -i '9d' /etc/v2ray/config.json"
	ansible $vps -m shell -a "sed -i '13i\\$id' /etc/v2ray/config.json"
	ansible $vps -m shell -a "sed -i '14d' /etc/v2ray/config.json"
	echo "修改完毕-----------"
	echo "v2ray服务端配置成功!"
	echo "重启v2ray服务器"
	ansible $vps -m shell -a "reboot"
	echo "重启成功！"
	echo "-------------------"
else
	echo "ip error, please contiue"
	exit 1
fi

echo "一键更新局域网的网关和DNS服务"
echo "选择需要更新的GW_DNS和vps组名,将此GW_DNS配置成为使用此VPS的科学上外网关"


#while true
#do
#	read -p "请输入需要更新的局域网网关或者DNS的ansible分组名：" GW_DNS
GW_DNS="gw"
echo "您输入的GW_DNS分组为"$GW_DNS",正在验证GW_DNS分组是否存在,请稍后..."
count1=`ansible "$GW_DNS" -m ping|grep SUCCESS|wc -l`
if [ $count1 -gt 0 ]
then
	echo "验证成功GW_DNS分组存在！分组名为"$GW_DNS""
#	break
else
	echo "GW_DNS分组不存在，请重新输入......"
	exit 1
fi
#done

#while true
#do
#        read -p "请输入需要更新的局域网需要使用的vps服务器分组名：" vps

echo "您输入的vps分组为$vps,正在验证VPS分组是否存在,请稍后..."
count2=`ansible $vps -m ping|grep SUCCESS|wc -l`
if [ $count2 -gt 0 ]
then
	echo "验证成功vps分组存在！分组名为$vps"
#	break
else
	echo "vps分组不存在，请重新输入......"
	exit 1
fi
#done
#获取v2ray服务端的IP，PORT，ID
server_address=`ansible $vps -m shell -a "ifconfig" | sed -n '3p'|awk '{print$2}'|awk -F ':' '{print$2}'`
echo "v2ray_server的IP是$server_address"
server_port=`ansible $vps -m shell -a "cat /etc/v2ray/config.json" | grep port | sed -n '1p'`
echo "$server_port"
server_id=`ansible $vps -m shell -a "cat /etc/v2ray/config.json" | grep id`
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
ansible "$GW_DNS" -m shell -a "sed -i '13i\\$address' /etc/v2ray/config.json"
ansible "$GW_DNS" -m shell -a "sed -i '14d' /etc/v2ray/config.json"

echo "配置端口"
ansible "$GW_DNS" -m shell -a "sed -i '14i\\$port' /etc/v2ray/config.json"
ansible "$GW_DNS" -m shell -a "sed -i '15d' /etc/v2ray/config.json"

echo "配置id"
ansible "$GW_DNS" -m shell -a "sed -i '17i\\$id' /etc/v2ray/config.json"
ansible "$GW_DNS" -m shell -a "sed -i '18d' /etc/v2ray/config.json"

echo "配置防火墙"
echo "1.拼接防火墙"
fire_wall="iptables -t nat -A V2RAY -d  $server_address -j RETURN"
echo $fire_wall
ansible "$GW_DNS" -m shell -a "sed -i '14i\\$fire_wall' /opt/v2ray-firewall"
ansible "$GW_DNS" -m shell -a "sed -i '15d' /opt/v2ray-firewall"

echo "重启GW_DNS的v2ray服务"
ansible "$GW_DNS" -m shell -a "reboot"
echo "服务重启成功！"
echo "配置完毕！"
