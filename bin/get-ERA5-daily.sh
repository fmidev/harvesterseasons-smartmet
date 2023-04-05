#!/bin/bash
#
# monthly script for fetching ERA5 Land reanalysis data from cdsapi, cutting out the Nordic domain
# and setting it up in the smartmet-server
#
# 14.1.2020 Mikko Strahlendorff
eval "$(conda shell.bash hook)"

source ~/.smart 

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
cd /home/smartmet/data
echo "fetch ERA5 for y: $year m: $month d: $day"
[ -f ERA5_$year$month${day}T000000_base+soil.grib ] || ../bin/cds-era5.py $year $month $day $abr $area
#conda activate xr
/home/smartmet/anaconda3/envs/xr/bin/cdo -f grb2 --eccodes selname,sde -exprf,ec-sde.instr ERA5_$year$month${day}T000000_base+soil.grib grib/ERA5_${year}0101T000000_$year$month${day}T000000_sde.grib
mv ERA5_$year$month${day}T000000_base+soil.grib grib/ERA5_${year}0101T000000_$year$month${day}T000000_base+soil.grib
#sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0
