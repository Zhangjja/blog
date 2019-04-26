#!/bin/bash

show_version(){
v=(pc h5)        
for i in ${v[@]}
        do
        echo "================"
        echo "$i的所有发布版本："
        awk -F "=" '{print $2} ' $i"_versions"
        echo "================"
        done

}

show_version
