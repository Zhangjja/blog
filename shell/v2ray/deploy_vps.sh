#!/bin/bash
vps=""
if [ -z "$1" ]
then
	vps="default"
else
	vps="$1"
fi

curl -H 'API-Key: R336LW2OYPBDWOAYEPYUKD6EX4ZS37RHFQBA' https://api.vultr.com/v1/server/create --data 'DCID=5' --data 'VPSPLANID=201' --data 'OSID=193' --data 'SSHKEYID=5cc15103d9f4d' --data "label=$vps" > subid.txt
echo "installing server......"

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
		ssh root@$ip "ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa -q"
		if [ $? -eq 0 ]
			break
		then
			ssh root@$ip "ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa -q"
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
