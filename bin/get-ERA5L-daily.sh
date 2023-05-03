#!/bin/bash
#
# monthly script for fetching ERA5 Land reanalysis data from cdsapi, cutting out the Nordic domain
# and setting it up in the smartmet-server
#
# 14.1.2020 Mikko Strahlendorff
eval "$(conda shell.bash hook)"
if [ $# -ne 0 ]
then
    year=$1
    month=$2
    day=$3
else
    year=$(date -d '6 days ago' +%Y)
    month=$(date -d '6 days ago' +%m)
    day=$(date -d '6 days ago' +%d)
fi
source ~/.smart 
cd /home/smartmet/data
echo "fetch ERA5 for y: $year m: $month d: $day"
[ -f ERA5L_$year$month${day}T000000_sfc-1h.grib ] || ../bin/cds-era5l.py $year $month $day $abr $area
mv ERA5L_$year$month${day}T000000_sfc-1h.grib grib/ERA5L_${year}0101T000000_$year$month${day}T000000_base+soil.grib
#cdo -f grb2 --eccodes selname,sde -exprf,ec-sde.instr ERA5L_$year$month${day}T000000_base+soil.grib grib/ERA5L_${year}0101T000000_$year$month${day}T000000_sde.grib
#sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0
