#!/usr/bin/bash
########################################################################
# Sentinel-2 imagery uncompress and merge to gdal vrt script
# Copyright (C) 2024-2025  Xu Ruijun
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
########################################################################
uncomp_path=""
if [ ! -e $1 ];then #文件或文件夹不存在
    echo $1 is not exists
    exit
elif [[ -f $1 && ${1##*.} = 'zip' ]];then #第一个参数是zip压缩包路径
    uncomp_path=`basename ${1%.zip}`
    if [ "${uncomp_path##*.}" != 'SAFE' ];then
        uncomp_path=$uncomp_path.SAFE #有些压缩包没有带SAFE，解压文件却带SAFE
    fi
    if [ ! -d $uncomp_path ];then #解压路径不是一个文件夹
        unzip $1 #进行解压
    else
        echo already decompressed in $uncomp_path
    fi
elif [ ! -d $1 ];then
    echo $1 is not directory or zip file
    exit
else
    uncomp_path=$1
fi

buildvrt() {
    uncomp_path=$1
    output_path=$2
    name=""
    for dir in $(ls $uncomp_path/GRANULE)
    do
        path=$uncomp_path/GRANULE/$dir
        if [ ! -d $path ];then
            continue
        fi
        if [ ! -z $name ];then
            echo mutiliy dirctory in $uncomp_path/GRANULE
            exit
        else
            name="$dir"
        fi
    done

    img_dir=$uncomp_path/GRANULE/$name/IMG_DATA
    if [ -d $img_dir/R10m ];then
        ls -1 -f $img_dir/R20m/*_B01_20m.jp2\
                 $img_dir/R10m/*_B02_10m.jp2\
                 $img_dir/R10m/*_B03_10m.jp2\
                 $img_dir/R10m/*_B04_10m.jp2\
                 $img_dir/R20m/*_B05_20m.jp2\
                 $img_dir/R20m/*_B06_20m.jp2\
                 $img_dir/R20m/*_B07_20m.jp2\
                 $img_dir/R10m/*_B08_10m.jp2\
                 $img_dir/R60m/*_B09_60m.jp2\
                 $img_dir/R60m/*_WVP_60m.jp2\
                 $img_dir/R20m/*_B11_20m.jp2\
                 $img_dir/R20m/*_B12_20m.jp2\
                 $img_dir/R20m/*_B8A_20m.jp2\
        > input_files.txt
    else
        ls $img_dir/*_B*.jp2 > input_files.txt
    fi

    count=$(wc -l input_files.txt)
    if [ ${count% *} -ne "13" ];
    then
        echo not 13 files
        exit
    fi

    echo "using these files:"
    cat input_files.txt

    echo

    echo "ouput path:" $output_path

    gdalbuildvrt -overwrite -resolution highest -separate -r cubic -input_file_list input_files.txt $output_path
}

output_path=$uncomp_path/$(echo $uncomp_path | awk  '{print substr($uncomp_path,1,3)"_"substr($uncomp_path,12,8)}').vrt

#TODO: 应识别上次构建时是否中断，并重建
if [ ! -f $output_path ];then
    buildvrt $uncomp_path $output_path
else
    echo "already build vrt"
fi

if [ ! -f $output_path.ovr ];then
    gdaladdo $output_path -r average -ro 2 4 8 16
else
    echo "already build ovr"
fi
