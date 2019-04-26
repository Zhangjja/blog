#!/bin/bash

deploy(){
zip=(pc h5)
for i in ${zip[@]}
do
       if [ -e $i.zip ]
       then
               scp $i.zip ubuntu@118.89.139.53:/home/ubuntu/deploy/nginx/faceyunstatic/test/
               echo "静态文件上传成功！"
       else
               echo "$i.zip 不存在！请检查当前目录是否有$i.zip文件！"
       fi
done

ssh ubuntu@118.89.139.53 'cd /home/ubuntu/deploy/nginx/faceyunstatic/  && ./deploy.sh'
}

displayVersions()
{
	ssh ubuntu@118.89.139.53 'cd /home/ubuntu/deploy/nginx/faceyunstatic/  && ./versions.sh'
}

read -p "查看目前发布所有版本请选择[ sS ],如果要发布新版本代码？请选择 [yY or nN] :" input

case $input in
	[sS]*)
		echo "当前发布的所有版本如下："
		displayVersions
		;;
	[yY]*)
		echo "发布开始！"
		deploy
		echo "发布完成！"
		echo "请浏览器打开 ucloudvision.ulsee-ai.com  或者 ucloudvision-h5.ulsee-ai.com 查看最新发布状态！"
		;;
	[nN]*)
		exit
		;;
	*)
		echo "Just enter y or n , please."
		exit
		;;
esac

