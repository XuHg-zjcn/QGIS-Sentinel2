#!/usr/bin/bash
if [ -z $1 ];then
    echo 'usage: `./batch.sh PATH`, `PATH` is a directory contain Sentinel-2 imagery zip archive'
    exit
fi

if [ ! -e $1 ];then #文件或文件夹不存在
    echo $1 is not exists
    exit
fi

for path in $(ls $1/S2?_MSIL??_*.zip)
do
	./merge.sh $path
done
