#!/bin/bash
# Usage: ./get-knmi.sh <date>
# Fetch one day of data from the KNMI API with a YYMMDD date string

date=$1
#ymd=$(date -d "$date" +"%y%m%d")
cd  /home/ubuntu/data/knmi
# Fetch one day of KNMI data (replace URL with actual API endpoint if different)
query=$(curl -s -X GET "https://api.dataplatform.knmi.nl/open-data/v1/datasets/RAD_OPERA_24H_RAINFALL_ACCUMULATION_EURADCLIM/versions/2.0/files/RAD_OPERA_24H_RAINFALL_ACCUMULATION_EURADCLIM_${date}_0002.zip/url" \
    -H "Authorization: eyJvcmciOiI1ZTU1NGUxOTI3NGE5NjAwMDEyYTNlYjEiLCJpZCI6IjJlYmZiYjA0Nzc2ODQxM2FhNTVkNDU2MDJhYzNkYjI1IiwiaCI6Im11cm11cjEyOCJ9")
durl=$(echo "$query"| jq -r .temporaryDownloadUrl)
#wget -O "EURADCLIM_24H_RAINFALL_ACCUMULATION_${date}_0002.zip" "$durl"
unzip -d . "EURADCLIM_24H_RAINFALL_ACCUMULATION_${date}_0002.zip"
parallel ncpdq -3 --hdf_upk -P all_new -g dataset1/data1 -o {.}.nc {} ::: *.h5 && rm *.h5
parallel ncrename -O -d phony_dim_0,projection_x_coordinate -d phony_dim_1,projection_y_coordinate {} {} ::: *.nc
# The data is now in the current directory as NetCDF files
# You can process the data further with NCO or other tools
parallel cdo -f grb1 -b P12 copy -setname,tp -setgrid,../knmi-eu-grid RAD_OPERA_24H_RAINFALL_ACCUMULATION_$date{}0000.nc KNMI_200001010000_$date{}0000_tp-daily.grib ::: `seq -w 01 31`