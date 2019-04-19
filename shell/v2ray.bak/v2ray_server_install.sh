#!/bin/bash

echo "安装v2ray服务端"
echo "bash <(curl -L -s https://install.direct/go.sh)"
bash <(curl -L -s https://install.direct/go.sh)
echo "cp /etc/v2ray/config.json /root/"
cp /etc/v2ray/config.json /root/
echo "mv config.json config.json.bak"
mv config.json config.json.bak
echo "scp ubuntu@118.89.139.53:/home/ubuntu/v2ray/server_config.json /etc/v2ray/config.json"
scp ubuntu@118.89.139.53:/home/ubuntu/v2ray/server_config.json /etc/v2ray/config.json

