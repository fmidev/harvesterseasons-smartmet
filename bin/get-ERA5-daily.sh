#!/bin/bash
#
# monthly script for fetching ERA5 Land reanalysis data from cdsapi, cutting out the Nordic domain
# and setting it up in the smartmet-server
#
# 14.1.2020 Mikko Strahlendorff
if [ $# -ne 0 ]
then
    year=$1
    month=$2
    day=$3
else
    year=$(date -d '5 days ago' +%Y)
    month=$(date -d '5 days ago' +%m)
    day=$(date -d '5 days ago' +%d)
fi
cd /home/smartmet/data
echo "fetch ERA5 for y: $year m: $month d: $day"
cds-era5.py $year $month $day

#sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0
