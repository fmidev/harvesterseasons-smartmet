#!/bin/bash
#
# monthly script for fetching seasonal data from cdsapi, cutting out the European domain
# and setting it up in the smartmet-server
#
# 14.1.2020 Mikko Strahlendorff
if [ $# -ne 0 ]
then
    year=$1
    month=$2
else
    year=$(date +%Y)
    month=$(date +%m)
fi
cd /home/smartmet/data
echo "y: $year m: $month"
cds-sf-all-24h.py $year $month

grib_set -s edition=2 ec-sf-$year$month-all-24h.grib grib/EC-SF-${year}${month}01T0000-all-24h.grib2
#cdo sellonlatbox,-22,45,27,72 ec-sf-$year$month-all-24h.grib EC-SF_$year${month}01T0000_all-24h-euro+y.grib
#grib_set  -s jScansPositively=0,numberOfForecastsInEnsemble=51 -w jScansPositively=1,numberOfForecastsInEnsemble=0 EC-SF_$year${month}01T0000_all-24h-euro+y.grib grib/EC-SF_$year${month}01T0000_all-24h-euro.grib
sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0
