#!/bin/bash

#date 2019-4-23
#author zjj
#describe deploy、update、rollback deployment

#环境变量
docker_harbor="docker.hz.ulsee.com"
git="git@git.ulsee-ai.com:system/hkeye/manager.git"
compose="docker-compose.yml"

#获取项目信息
services=`cat $compose |grep "$docker_harbor"| awk '{print$2}'|awk -F'/' '{print$3}'`
#ulsee-log-srv:v1.0
#fed:v10.0
#manager:v20.0
#mariadb:v30.0
#door-server:v40.0
#minio:v50.0
#storage:v60.0


#获取远程仓库版本信息

git_tags=`git ls-remote --tags $git |grep -v "{}" | awk '{print$2}'|awk -F '/' '{print$3}'`
#v1.0
#v2.0
#v3.0


for service in $services
do
	service_name=`echo $service | awk -F ':' '{print$1}'`
	echo $service_name
	service_tag=`echo $service | awk -F ':' '{print$2}'`
	echo $service_tag
done
