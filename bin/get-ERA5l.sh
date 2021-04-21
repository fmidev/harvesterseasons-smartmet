#!/bin/bash
#
# monthly script for fetching ERA5 Land reanalysis data from cdsapi
# and setting it up in the smartmet-server
#
# 14.1.2020 Mikko Strahlendorff
if [ $# -ne 0 ]
then
    year=$1
    month=$2
else
    year=$(date -d '3 months ago' +%Y)
    month=$(date -d '3 months ago' +%m)
fi
cd /home/smartmet/data
echo "y: $year m: $month"
cds-era5l.py $year $month

mv era5l-$year$month-sfc-12h.grib grib/ERA5L_${year}0101T000000_$year${month}01T000000_euro_1h.grib
#sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0
