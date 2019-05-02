#!/usr/bin/env bash
#/bin/bash
#date 2019-4-30
#author zjj
#describe 监控vlutr的使用率，达到290G时候自动重新搭建服务器，销毁老服务器，建立新服务器

key="API-Key: R336LW2OYPBDWOAYEPYUKD6EX4ZS37RHFQBA"
while true
do
    gws=("gw" "ggww" "blesswire" "blesswiredbak")
    for gw in ${gws[@]}
    do
        echo "检测的网关名为$gw"															`date +"%Y-%m-%d %H:%M:%S"`
	echo "获取v2ray服务器的IP地址"
        MONITOR_IP=`ansible $gw -m shell -a 'cat /etc/v2ray/config.json' | grep "address"|sed -n '1p' |awk -F '"' '{print$4}'`
        echo "获取的v2ray服务器IP地址为$MONITOR_IP"													`date +"%Y-%m-%d %H:%M:%S"`

	echo "收集vultr的服务器列表"
        curl -H "$key" https://api.vultr.com/v1/server/list | python -m json.tool | grep  -E "\blabel\b|\bSUBID\b|\bmain_ip\b" |awk '{print$1 $2}' > serverlist.log

	echo "获取v2ray服务器的subid"
        MONITOR_SUBID=`cat serverlist.log | grep -E "\bSUBID\b|\bmain_ip\b" | sed -n "/$MONITOR_IP/{x;p};h" | awk -F '"' '{print$4}'`
        echo "获取的v2ray服务器subid为 $MONITOR_SUBID" 													`date +"%Y-%m-%d %H:%M:%S"`
	
	echo "获取v2ray服务器的label"
        LABEL=`cat serverlist.log | grep -E "\blabel\b|\bmain_ip\b" |sed -n "/$MONITOR_IP/{x;p};h" |awk -F '"' '{print$4}'`
        echo "获取的v2ray服务器label为$LABEL"														`date +"%Y-%m-%d %H:%M:%S"`
	
	rm serverlist.log

	echo "获取v2ray服务器的宽带使用率"
        BANDWIDTH=`curl -H "$key" https://api.vultr.com/v1/server/bandwidth?SUBID=$MONITOR_SUBID | python -m json.tool | tail -4| sed -n '1p'|awk -F '"' '{print$2}'`
	echo "获取v2ray服务器宽带使用率为$BANDWIDTH字节"         											`date +"%Y-%m-%d %H:%M:%S"`

        if [ -z "$BANDWIDTH" ]
        then
            echo "跳出本次监控"																`date +"%Y-%m-%d %H:%M:%S"`
            sleep 5
            continue
        else

            BANDUSAGE=`expr $BANDWIDTH / 1024 / 1024 / 1024`
            echo "获取的宽带使用率为$BANDUSAGE G"													`date +"%Y-%m-%d %H:%M:%S"`
            if [ $BANDUSAGE -gt 250 ]
            then
                echo "触发重新搭建服务器条件,同时将keepalived服务停用"           									`date +"%Y-%m-%d %H:%M:%S"`
		echo "正在停用keepalived服务"														`date +"%Y-%m-%d %H:%M:%S"`
                ansible $gw -m shell -a 'service keepalived stop'
		echo "$gw的keepalived服务停用成功"
		echo "正在销毁v2ray服务器"
                curl -H "$key" https://api.vultr.com/v1/server/destroy --data "SUBID=$MONITOR_SUBID"
                echo "等待删除VPS"                                                                                                                      `date +"%Y-%m-%d %H:%M:%S"`
                sleep 30
                echo "删除vps成功"															`date +"%Y-%m-%d %H:%M:%S"`
                echo "获取$gw使用的v2ray服务器的label	$LABEL"												`date +"%Y-%m-%d %H:%M:%S"`

                #reinstall
		echo "重新安装v2ray服务器"														`date +"%Y-%m-%d %H:%M:%S"`
                curl -H "$key" https://api.vultr.com/v1/server/create --data 'DCID=5' --data 'VPSPLANID=201' --data 'OSID=193' --data 'SSHKEYID=5cc15103d9f4d' --data "label=$LABEL" > subid.txt
                cat subid.txt
                echo "installing server......"														`date +"%Y-%m-%d %H:%M:%S"`
                INSTALL_SUBID=`cat subid.txt | awk -F '"' '{print$4}'`
                echo "正在安装的v2ray服务器的subid为$INSTALL_SUBID"											`date +"%Y-%m-%d %H:%M:%S"`

                ip=""
                while true
                do
                    ip=`curl -H "$key" https://api.vultr.com/v1/server/list?SUBID=$INSTALL_SUBID | python -m json.tool | grep -E "\bmain_ip\b"  |awk -F '"' '{print$4}'`
                    if [ $ip == "0.0.0.0" ]
                    then
                        echo $ip															`date +"%Y-%m-%d %H:%M:%S"`
                        echo "getting ip......"
                        sleep 5
                        ip=`curl -H "$key" https://api.vultr.com/v1/server/list?SUBID=$INSTALL_SUBID | python -m json.tool | grep -E "\bmain_ip\b"  |awk -F '"' '{print$4}'`
                    else
                        echo "新建的v2ray服务器IP地址为$ip"												`date +"%Y-%m-%d %H:%M:%S"`
                        break
                    fi
                done

                pwd=""
                while true
                do
                    pwd=`curl -H "$key" https://api.vultr.com/v1/server/list?SUBID=$INSTALL_SUBID  | python -m json.tool | grep -E  "\bdefault_password\b" |awk -F '"' '{print$4}'`
                    if [ -z $pwd ]
                    then
                        echo $pwd															`date +"%Y-%m-%d %H:%M:%S"`
                        echo "getting pwd......"
                        sleep 5
                        pwd=`curl -H "$key" https://api.vultr.com/v1/server/list?SUBID=$INSTALL_SUBID  | python -m json.tool | grep -E  "\bdefault_password\b" |awk -F '"' '{print$4}'`
                    else
                        echo "获取的v2ray服务器的秘密为$pwd"												`date +"%Y-%m-%d %H:%M:%S"`
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
        	    echo "新建的v2ray服务器重启成功"													`date +"%Y-%m-%d %H:%M:%S"`
                done

                ping -c 2 -W 2 $ip >> /dev/null
                if [ $? -eq 0 ]
                then
                    echo "检查v2ray服务器ip地址存在！"													`date +"%Y-%m-%d %H:%M:%S"`
                    echo "------------"
                    echo "清理本地已经存在$ip的密钥"
                    ssh-keygen -f "/root/.ssh/known_hosts" -R $ip
                    echo "重新添加$ip的密钥，正在添加密钥！"
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
                    echo "正在配置ansible主控端"													 `date +"%Y-%m-%d %H:%M:%S"`

                    jugde=`cat /etc/ansible/hosts | grep -E "\b$LABEL\b"| wc -l`
                    if [ $jugde -gt 0 ]
                    then
                        echo "$LABEL已存在"														`date +"%Y-%m-%d %H:%M:%S"`	
                        sed  -i "/$LABEL/{n;d}" /etc/ansible/hosts
                        sed -i "/$LABEL/a$ip ansible_ssh_user=root ansible_sudo_pass=$pwd" /etc/ansible/hosts
                    else
                        echo "$LABEL不存在"														`date +"%Y-%m-%d %H:%M:%S"`
                        sed -i "\$a\\[$LABEL\]" /etc/ansible/hosts
                                sed -i "/$LABEL/a$ip ansible_ssh_user=root ansible_sudo_pass=$pwd" /etc/ansible/hosts
                    fi
                    echo "主控端配置完毕！"														`date +"%Y-%m-%d %H:%M:%S"`
                    echo "------------"
                    echo "测试ansible被控端"														`date +"%Y-%m-%d %H:%M:%S"`
                    ansible $LABEL -m ping
                    command=`ansible $LABEL -m ping | grep "SUCCESS"|wc -l`
                    if [ $command -gt 0 ]
                    then
                        echo "主控端配置成功！"														`date +"%Y-%m-%d %H:%M:%S"`
                    else
                        echo "主控端配置失败！"														`date +"%Y-%m-%d %H:%M:%S"`
                        exit 1
                    fi

                    echo "-------------------"
                    echo "开始安装v2ray服务端,并且进行配置，使用ansible的script模块拷贝配置文件"							`date +"%Y-%m-%d %H:%M:%S"`
                    ansible $LABEL -m script -a "./v2ray_server_install.sh"
                    ansible $LABEL -m copy -a "src=./server_config.json dest=/etc/v2ray/config.json owner=root group=root mode=0644"
                    echo "v2ray服务端安装完毕！"													`date +"%Y-%m-%d %H:%M:%S"`
		    echo "获取v2ray服务器的IP\PORT\ID"													`date +"%Y-%m-%d %H:%M:%S"`
                    ip=`ansible $LABEL -m shell -a "ifconfig" | sed -n '3p'|awk '{print$2}'|awk -F ':' '{print$2}'`
                    port=`ansible $LABEL -m shell -a "cat /root/config.json.bak" |sed -n '4p'`
                    id=`ansible $LABEL -m shell -a "cat /root/config.json.bak" |sed -n '9p'`
                    ansible $LABEL -m shell -a "cat  /root/config.json.bak"
                    ansible $LABEL -m shell -a "cat  /etc/v2ray/config.json"
                    echo "$ip" "$port"  "$id"														`date +"%Y-%m-%d %H:%M:%S"`
                    echo "正在修改-----------------"
                    ansible $LABEL -m shell -a "sed -i '8i\\$port' /etc/v2ray/config.json"
                    ansible $LABEL -m shell -a "sed -i '9d' /etc/v2ray/config.json"
                    ansible $LABEL -m shell -a "sed -i '13i\\$id' /etc/v2ray/config.json"
                    ansible $LABEL -m shell -a "sed -i '14d' /etc/v2ray/config.json"
                    echo "修改完毕，v2ray服务端配置成功!重启v2ray服务器"										`date +"%Y-%m-%d %H:%M:%S"`
                    ansible $LABEL -m shell -a "reboot"
                    echo "v2ray服务器重启成功！"													`date +"%Y-%m-%d %H:%M:%S"`
                    echo "-------------------"
                else
                    echo "ip error, please contiue"
                    exit 1
                fi

                echo "更新局域网的网关服务"														`date +"%Y-%m-%d %H:%M:%S"`
                echo "正在验证$gw分组是否存在,请稍后..."												`date +"%Y-%m-%d %H:%M:%S"`
                count1=`ansible "$gw" -m ping|grep SUCCESS|wc -l`
                if [ $count1 -gt 0 ]
                then
                    echo "验证成功gw分组存在！分组名为$gw"												`date +"%Y-%m-%d %H:%M:%S"`
                else
                    echo "gw分组不存在，请重新输入......"												`date +"%Y-%m-%d %H:%M:%S"`
                    exit 1
                fi

                echo "正在验证$VPS分组是否存在,请稍后..."												`date +"%Y-%m-%d %H:%M:%S"`
                count2=`ansible $LABEL -m ping|grep SUCCESS|wc -l`
                if [ $count2 -gt 0 ]
                then
                    echo "验证成功$vps分组存在！分组名为$LABEL"												`date +"%Y-%m-%d %H:%M:%S"`
                else
                    echo "$vps分组不存在，请重新输入......"												`date +"%Y-%m-%d %H:%M:%S"`
                    exit 1
                fi

                server_address=`ansible $LABEL -m shell -a "ifconfig" | sed -n '3p'|awk '{print$2}'|awk -F ':' '{print$2}'`
                echo "v2ray_server的IP是$server_address"												`date +"%Y-%m-%d %H:%M:%S"`
                server_port=`ansible $LABEL -m shell -a "cat /etc/v2ray/config.json" | grep port | sed -n '1p'`
                echo "$server_port"															`date +"%Y-%m-%d %H:%M:%S"`
                server_id=`ansible $LABEL -m shell -a "cat /etc/v2ray/config.json" | grep id`
                echo "$server_id"															`date +"%Y-%m-%d %H:%M:%S"`

                echo "下一步需要修改$gw组的配置文件，现在正在形成参数"											`date +"%Y-%m-%d %H:%M:%S"`
                echo "修改gw的配置文件/etc/v2ray/config.json,/opt/v2ray-firewall"									`date +"%Y-%m-%d %H:%M:%S"`
                echo "1.拼接ip地址"
                address="                \"address\"":"\"$server_address\"",""
                echo $address
                echo "2.拼接端口号"
                port="            "$server_port
                echo $port
                echo "3.拼接id"
                id="          "$server_id
                echo $id

                echo "执行修改局域网GW的配置文件"
                echo "配置ip地址"
                ansible "$gw" -m shell -a "sed -i '13i\\$address' /etc/v2ray/config.json"
                ansible "$gw" -m shell -a "sed -i '14d' /etc/v2ray/config.json"

                echo "配置端口"
                ansible "$gw" -m shell -a "sed -i '14i\\$port' /etc/v2ray/config.json"
                ansible "$gw" -m shell -a "sed -i '15d' /etc/v2ray/config.json"

                echo "配置id"
                ansible "$gw" -m shell -a "sed -i '17i\\$id' /etc/v2ray/config.json"
                ansible "$gw" -m shell -a "sed -i '18d' /etc/v2ray/config.json"

                echo "配置防火墙"
                echo "1.拼接防火墙"
                fire_wall="iptables -t nat -A V2RAY -d  $server_address -j RETURN"
                echo $fire_wall
                ansible "$gw" -m shell -a "sed -i '14i\\$fire_wall' /opt/v2ray-firewall"
                ansible "$gw" -m shell -a "sed -i '15d' /opt/v2ray-firewall"

                echo "重启gw的v2ray服务"														`date +"%Y-%m-%d %H:%M:%S"`
                ansible "$gw" -m shell -a "service keepalived restart"
                ansible "$gw" -m shell -a "reboot"
                echo "服务重启成功！"															`date +"%Y-%m-%d %H:%M:%S"`
                echo "配置完毕！"															`date +"%Y-%m-%d %H:%M:%S"`

            else
                echo "流量小于250G,进行下一次监控循环"													`date +"%Y-%m-%d %H:%M:%S"`
            fi
        fi
        echo "睡眠1小时,正在睡眠等待中………………" 														`date +"%Y-%m-%d %H:%M:%S"`
        sleep 60
        echo "睡眠时间到，开始检测…………………………" 														`date +"%Y-%m-%d %H:%M:%S"`
    done
done
