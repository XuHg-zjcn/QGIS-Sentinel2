#!/usr/bin/bash
########################################################################
# Sentinel-2 imagery batch process
# Copyright (C) 2025  Xu Ruijun
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
