#!/usr/bin/env bash
#/bin/bash
#date 2019-4-30
#author zjj
#describe 监控vlutr的使用率，达到290G时候自动重新搭建服务器，销毁老服务器，建立新服务器



while true
do

    MONITOR_IP=`ansible gw -m shell -a 'cat /etc/v2ray/config.json' | grep "address"|sed -n '1p' |awk -F '"' '{print$4}'`

    echo "$MONITOR_IP"

    curl -H 'API-Key: R336LW2OYPBDWOAYEPYUKD6EX4ZS37RHFQBA' https://api.vultr.com/v1/server/list | python -m json.tool | grep  -E "\blabel\b|\bSUBID\b|\bmain_ip\b" |awk '{print$1 $2}' > serverlist.log

    MONITOR_SUBID=`cat serverlist.log | grep -E "\bSUBID\b|\bmain_ip\b" |sed -n "/$MONITOR_IP/{x;p};h" |awk -F '"' '{print$4}'`

    echo "$MONITOR_SUBID"

    LABEL=`cat serverlist.log | grep -E "\blabel\b|\bmain_ip\b" |sed -n "/$MONITOR_IP/{x;p};h" |awk -F '"' '{print$4}'`

    echo "$LABEL"

    BANDWIDTH=`curl -H 'API-Key: R336LW2OYPBDWOAYEPYUKD6EX4ZS37RHFQBA' https://api.vultr.com/v1/server/bandwidth?SUBID=$MONITOR_SUBID | python -m json.tool |tail -4|sed -n '1p'|awk -F '"' '{print$2}'`

    echo "BAND : $BANDWIDTH"
    BANDWIDTH=2
    BANDUSAGE=`expr $BANDWIDTH / 1024 / 1024 / 1024`
    BANDUSAGE=`expr $BANDWIDTH / 1 / 1 / 1`

    echo "$BANDUSAGE"

    if [ $BANDWIDTH -lt 3 ]
    then
        echo 'edit the triger'
#        service nginx stop
        ansible gw -m shell -a 'service keepalived stop'
        curl -H 'API-Key: R336LW2OYPBDWOAYEPYUKD6EX4ZS37RHFQBA' https://api.vultr.com/v1/server/destroy --data "SUBID=$MONITOR_SUBID"
        echo "等待删除VPS"
        sleep 30
        echo "删除vps"
        echo "$LABEL"


        #reinstall


        curl -H 'API-Key: R336LW2OYPBDWOAYEPYUKD6EX4ZS37RHFQBA' https://api.vultr.com/v1/server/create --data 'DCID=5' --data 'VPSPLANID=201' --data 'OSID=193' --data 'SSHKEYID=5cc15103d9f4d' --data "label=$LABEL" > subid.txt

        cat subid.txt
        echo "installing server......"
        
        INSTALL_SUBID=`cat subid.txt | awk -F '"' '{print$4}'`
        echo $INSTALL_SUBID
        
        ip=""
        while true
        do
            ip=`curl -H 'API-Key: R336LW2OYPBDWOAYEPYUKD6EX4ZS37RHFQBA' https://api.vultr.com/v1/server/list?SUBID=$INSTALL_SUBID | python -m json.tool | grep -E "\bmain_ip\b"  |awk -F '"' '{print$4}'`
            if [ $ip == "0.0.0.0" ]
            then	
                echo $ip
                echo "getting ip......"
                sleep 5
                ip=`curl -H 'API-Key: R336LW2OYPBDWOAYEPYUKD6EX4ZS37RHFQBA' https://api.vultr.com/v1/server/list?SUBID=$INSTALL_SUBID | python -m json.tool | grep -E "\bmain_ip\b"  |awk -F '"' '{print$4}'`
            else
                echo $ip
                break
            fi	
        done
        
        
        pwd=""
        while true
        do
            pwd=`curl -H 'API-Key: R336LW2OYPBDWOAYEPYUKD6EX4ZS37RHFQBA' https://api.vultr.com/v1/server/list?SUBID=$INSTALL_SUBID  | python -m json.tool | grep -E  "\bdefault_password\b" |awk -F '"' '{print$4}'`
            if [ -z $pwd ]
            then
                echo $pwd
                echo "getting pwd......"
                sleep 5
                pwd=`curl -H 'API-Key: R336LW2OYPBDWOAYEPYUKD6EX4ZS37RHFQBA' https://api.vultr.com/v1/server/list?SUBID=$INSTALL_SUBID  | python -m json.tool | grep -E  "\bdefault_password\b" |awk -F '"' '{print$4}'`
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
        if [ $? -eq 0 ]
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

            jugde=`cat /etc/ansible/hosts | grep -E "\b$LABEL\b"| wc -l`
            if [ $jugde -gt 0 ]
            then
                echo "$LABEL已存在"
                sed  -i "/$LABEL/{n;d}" /etc/ansible/hosts
                sed -i "/$LABEL/a$ip ansible_ssh_user=root ansible_sudo_pass=$pwd" /etc/ansible/hosts
            else
                echo "$LABEL不存在"
                sed -i "\$a\\[$LABEL\]" /etc/ansible/hosts
                        sed -i "/$LABEL/a$ip ansible_ssh_user=root ansible_sudo_pass=$pwd" /etc/ansible/hosts
            fi
            echo "主控端配置完毕！"
            echo "------------"
            echo "测试ansible被控端"
            ansible $LABEL -m ping
            command=`ansible $LABEL -m ping | grep "SUCCESS"|wc -l`
            if [ $command -gt 0 ]
            then
                echo "主控端配置成功！"
            else
                echo "主控端配置失败！"
                exit 1
            fi
        
            echo "-------------------"
            echo "开始安装v2ray服务端"
            #配置v2ray服务端脚本,使用ansible script模块路径为./v2ray_server_install.sh
            #安装v2ray服务端
            ansible $LABEL -m script -a "./v2ray_server_install.sh"
            ansible $LABEL -m copy -a "src=./server_config.json dest=/etc/v2ray/config.json owner=root group=root mode=0644"
            echo "v2ray服务端安装完毕！"
            echo "-------------------"
            echo "开始配置v2ray服务端配置文件"
            ip=`ansible $LABEL -m shell -a "ifconfig" | sed -n '3p'|awk '{print$2}'|awk -F ':' '{print$2}'`
            echo "修改配置文件的ip，port，id"
            port=`ansible $LABEL -m shell -a "cat /root/config.json.bak" |sed -n '4p'`
            id=`ansible $LABEL -m shell -a "cat /root/config.json.bak" |sed -n '9p'`
            ansible $LABEL -m shell -a "cat  /root/config.json.bak"
            ansible $LABEL -m shell -a "cat  /etc/v2ray/config.json"
            echo "$ip"
            echo "$port"
            echo "$id"
            echo "正在修改------"
            ansible $LABEL -m shell -a "sed -i '8i\\$port' /etc/v2ray/config.json"
            ansible $LABEL -m shell -a "sed -i '9d' /etc/v2ray/config.json"
            ansible $LABEL -m shell -a "sed -i '13i\\$id' /etc/v2ray/config.json"
            ansible $LABEL -m shell -a "sed -i '14d' /etc/v2ray/config.json"
            echo "修改完毕-----------"
            echo "v2ray服务端配置成功!"
            echo "重启v2ray服务器"
            ansible $LABEL -m shell -a "reboot"
            echo "重启成功！"
            echo "-------------------"
        else
            echo "ip error, please contiue"
            exit 1
        fi
        
        echo "一键更新局域网的网关和DNS服务"
        echo "选择需要更新的GW_DNS和vps组名,将此GW_DNS配置成为使用此VPS的科学上外网关"

        GW_DNS="gw"
        echo "您输入的GW_DNS分组为"$GW_DNS",正在验证GW_DNS分组是否存在,请稍后..."
        count1=`ansible "$GW_DNS" -m ping|grep SUCCESS|wc -l`
        if [ $count1 -gt 0 ]
        then
            echo "验证成功GW_DNS分组存在！分组名为"$GW_DNS""
        else
            echo "GW_DNS分组不存在，请重新输入......"
            exit 1
        fi
        
        echo "您输入的vps分组为$LABEL,正在验证VPS分组是否存在,请稍后..."
        count2=`ansible $LABEL -m ping|grep SUCCESS|wc -l`
        if [ $count2 -gt 0 ]
        then
            echo "验证成功vps分组存在！分组名为$LABEL"
        else
            echo "vps分组不存在，请重新输入......"
            exit 1
        fi

        server_address=`ansible $LABEL -m shell -a "ifconfig" | sed -n '3p'|awk '{print$2}'|awk -F ':' '{print$2}'`
        echo "v2ray_server的IP是$server_address"
        server_port=`ansible $LABEL -m shell -a "cat /etc/v2ray/config.json" | grep port | sed -n '1p'`
        echo "$server_port"
        server_id=`ansible $LABEL -m shell -a "cat /etc/v2ray/config.json" | grep id`
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

        break
    else
        echo "流量小于300G,进行下一次监控循环"
        ansible gw -m shell -a'service keepalived stop'
        sleep 20
    fi
done