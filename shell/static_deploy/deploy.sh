#!/bin/bash
cd test
l=(h5 pc)
for i in ${l[@]}
do
	if [ -e $i.zip ]
	then
		unzip $i.zip
		rm $i.zip
		version=`cat ./$i/env | awk '{print $3}'`
		echo $version

		if [ -e $i"_versions" ]
		then
			echo "version=$version" >> $i"_versions"
		else
			touch $i"_versions"
                        echo "version=$version" >> $i"_versions"
		fi

		new_dir=$i"_"$version
		echo $new_dir

		if [ ! -d $new_dir ]
		then
			cp -r $i $new_dir
			rm -rf $i
		else
			echo "$new_dir new version esxited"
		fi

		if [ -L $i ]
		then
			rm -rf $i
                        ln -s $new_dir $i
		else
			ln -s $new_dir $i
		echo "create $i symbolic link"
		fi

	else
		echo "请确定$i存在！"
	fi
done
cd -
