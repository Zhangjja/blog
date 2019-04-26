#!/bin/bash

#date 2019-4-23
#author zjj
#describe deploy、update、rollback、next
#1、脚本依赖git commit 、git tag 、docker_harbor
#2、频繁更新的服务要在git提交后设置git tag，并且生成的镜像版本以tag标记
#3、可以直接通过脚本部署指定的release版本（前提是必须要有release版本），包括一键更新、一键回滚、发布指定版本等，不需要使用env编辑版本号

#相关约定
#1：脚本依赖于git仓库
#2：版本控制依赖于git的release版本
#3：docker_harbor的镜像名称使用目前在用名称，使用脚本时候，使用的服务模块名以目前服务镜像名为准

usage(){
        echo "\$1 \$2 \$3"
        echo "\$1 : s/S d/D u/U r/R n/N"
        echo "\$2 : 服务模块名称"
        echo "\$3 : 版本号"
        echo "$0 s fed        列出fed服务在本地部署的版本和fed服务在git上所有的版本"
        echo "$0 d fed v2.0   部署fed服务的v2.0版本"
        echo "$0 u fed        更新到fed模块到最新版本"
        echo "$0 r fed        回退到fed模块当前版本的上一版本"
        echo "$0 n fed        更新到fed模块的下一版本"
	exit 0
}

#环境变量
docker_harbor="docker.hz.ulsee.com"
compose="docker-compose.yml"
git_url=""

#获取项目信息
servicenames=`cat $compose |grep "$docker_harbor"| awk '{print$2}'|awk -F'/' '{print$3}'|awk -F ':' '{print$1}'`
#fed
#face-reco
#manager
#dahua_config
#mariadb
#auth
#devices-srv
#door-server
#minio
#storage


#获取远程仓库版本信息
#git_tags=`git ls-remote --tags $git_manager |grep -v "{}" | awk '{print$2}'|awk -F '/' '{print$3}'`
#v1.0
#v2.0
#v3.0
judge(){
	if [ -z "$2" ]
	then
		usage
	fi
}
get_git_url(){
	if [ "$2" == "fed" ]
	then
		git_url="git@git.ulsee-ai.com:system/hkeye/hawkeye-manage-fed.git"
	elif [ "$2" == "face-reco" ]
	then
		git_url="git@git.ulsee-ai.com:system/hkeye/hawkeye-manage-fed.git"
	elif [ "$2" == "manager" ]
	then
		git_url="git@git.ulsee-ai.com:system/hkeye/manager.git"
	elif [ "$2" == "dahua_config" ]
	then
		git_url="git@git.ulsee-ai.com:system/hkeye/dahua_config.git"
	elif [ "$2" == "auth" ]
	then
		git_url="git@tools.ulsee.com:system/base/service/auth.git"
	elif [ "$2" == "devices-srv" ]
	then
		git_url="git@tools.ulsee.com:system/base/service/devices.git"
	elif [ "$2" == "door-server" ]
	then
		git_url="git@tools.ulsee.com:system/base/service/config-server.git"
	elif [ "$2" == "minio" ]
	then
		git_url="git@git.ulsee-ai.com:system/hkeye/minio.git"
	elif [ "$2" == "storage" ]
	then
		git_url="git@tools.ulsee.com:system/base/service/storage.git"
	else
		echo "NULL"
	fi
	return 0
}


show(){
	if [ -z "$2" ]
	then
		for service in $servicenames
		do
			get_git_url $1 $service
			echo "$service正在使用的版本："
			echo "`cat $compose |grep "$docker_harbor\/hkeye\/$service"| awk '{print$2}'|awk -F '/' '{print$3}'`"
			echo $git_url
			echo "`git ls-remote --tags $git_url |grep -v "{}" | awk '{print$2}'|awk -F '/' '{print$3}'`"
		done
		
	else
		get_git_url $1 $2
		echo "$2正在使用的版本："
		echo "`cat $compose |grep "$docker_harbor\/hkeye\/$2"| awk '{print$2}'|awk -F '/' '{print$3}'`"
		echo "git仓库中$2 的版本："
		echo "`git ls-remote --tags $git_url |grep -v "{}" | awk '{print$2}'|awk -F '/' '{print$3}'`"
	fi
}

deploy(){
	get_git_url $1 $2
	service_tag=`cat $compose |grep "$docker_harbor\/hkeye\/$2"| awk '{print$2}'|awk -F '/' '{print$3}'|awk -F ':' '{print$2}'`
	git_tags=`git ls-remote --tags $git_url |grep -v "{}" | awk '{print$2}'|awk -F '/' '{print$3}'`
	tag=`echo "${git_tags[@]}" | grep -wq "$3" &&  echo "Yes" || echo "No"`
	if [ $tag == "Yes" ]
	then
		sed -i "s/$docker_harbor\/hkeye\/$2\:$service_tag/$docker_harbor\/hkeye\/$2\:$3/" $compose
		echo "发布 $3 完成"
	else
		echo "$3版本没有release版本"
	fi
#	echo "重启服务"	docker-compose down &&  docker-compose up -d && echo "重启成功"
}

update(){
	get_git_url $1 $2
	service_tag=`cat $compose |grep "$docker_harbor\/hkeye\/$2"| awk '{print$2}'|awk -F '/' '{print$3}'|awk -F ':' '{print$2}'`
	latest_version=`git ls-remote --tags $git_url |grep -v "{}" | awk '{print$2}'|awk -F '/' '{print$3}'| sed -n '$p'`
	if [ $latest_version != $service_tag ]
	then
#		echo $latest_version
		sed -i "s/$docker_harbor\/hkeye\/$2\:$service_tag/$docker_harbor\/hkeye\/$2\:$latest_version/" $compose
		echo "更新 $2 到最新版"
	else
		echo "已经是最新版本"
	fi
#	echo "重启服务"	docker-compose down &&  docker-compose up -d && echo "重启成功"
}

rollback(){
	get_git_url $1 $2
	service_tag=`cat $compose |grep "$docker_harbor\/hkeye\/$2"| awk '{print$2}'|awk -F '/' '{print$3}'|awk -F ':' '{print$2}'`
	git_tags=`git ls-remote --tags $git_url |grep -v "{}" | awk '{print$2}'|awk -F '/' '{print$3}'`
	
	echo $service_tag
	echo $git_tags
	echo $git_url
	
	git_version=`git ls-remote --tags $git_url |grep -v "{}" | awk '{print$2}'|awk -F '/' '{print$3}' >  git_version`
	oldest_version=`cat git_version | sed -n '1p'`
	if [ $oldest_version != $service_tag  ]
	then
		back_version=`sed -n "/$service_tag/{x;p};h" git_version`
		echo $back_version
		sed -i "s/$docker_harbor\/hkeye\/$2\:$service_tag/$docker_harbor\/hkeye\/$2\:$back_version/" $compose
		echo "回滚到上一版本"
	else
		echo "已经是最老版本"
	fi
	rm git_version
#	echo "重启服务"	docker-compose down &&  docker-compose up -d && echo "重启成功"
}

next(){
        get_git_url $1 $2
        service_tag=`cat $compose |grep "$docker_harbor\/hkeye\/$2"| awk '{print$2}'|awk -F '/' '{print$3}'|awk -F ':' '{print$2}'`
        git_tags=`git ls-remote --tags $git_url |grep -v "{}" | awk '{print$2}'|awk -F '/' '{print$3}'`
        next_version=`git ls-remote --tags $git_url |grep -v "{}" | awk '{print$2}'|awk -F '/' '{print$3}' |awk "/$service_tag/{getline;print}"`

	if [ $next_version != $service_tag  ]
        then
	        echo $next_version
		sed -i "s/$docker_harbor\/hkeye\/$2\:$service_tag/$docker_harbor\/hkeye\/$2\:$next_version/" $compose
		echo "更新到下一版本"
	else
		echo "已经是最新版本"
        fi
#	echo "重启服务" docker-compose down &&  docker-compose up -d && echo "重启成功"
}


if [ -n $1 ]
then
	case $1 in
		[s/S]*)
			echo "show/Show:列出服务模块正在使用的版本和列出git仓库发布的版本"
			show $1 $2
			;;
	        [d/D]*)
			judge $1 $2
	                echo "deploy/Deploy:发布指定版本"
			if [ -n $3 ]
			then
	                	deploy $1 $2 $3
			else
				usage
			fi
	                ;;
	        [u/U]*)
			judge $1 $2
	                echo "update/Update:更新到最新版本"
	                update $1 $2
	                ;;
	        [r/R]*)
			judge $1 $2
	                echo "rollback/Rollback:回退到上一版本"
			rollback $1 $2
	                ;;
		[n/N]*)
			judge $1 $2
			echo "next/Next:更新到下一版本"
			next $1 $2
			;;
		*)
			usage
			;;
	esac
else
	usage
fi
