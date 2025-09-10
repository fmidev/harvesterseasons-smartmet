#!/bin/env bash
# get ESA CCI LST data from CEDA
# syntax: get-esa-cci-lst.sh <date>
date=$1

# Determine satellite based on date (SSMI13 before 2009, SSMI17 from 2009 onwards)
year=${date:0:4}
if [ $year -lt 2009 ]; then
    satellite="SSMI13"
else
    satellite="SSMI17"
fi

echo "Using satellite: $satellite for year $year"

cd /home/ubuntu/data/
[[ -s cci/CCI-SSMI_${date}120000_skt-eu.grib ]] && echo "LST-day $date already downloaded" || cdo -O -a -s -f grb2 -b P12 copy -setname,skt -settime,12:00:00\
  https://dap.ceda.ac.uk/thredds/dodsC/neodc/esacci/land_surface_temperature/data/SSMI_SSMIS/L3C/v2.33/daily/${date:0:4}/${date:4:2}/${date:6:2}/ESACCI-LST-L3C-LST-${satellite}-0.25deg_1DAILY_ASC-${date}000000-fv2.33.nc?time[0:1:0],lat[460:1:660],lon[600:1:920],lst[0:1:0][460:1:660][600:1:920]\
  cci/CCI-SSMI_${date}120000_skt-eu.grib &
[[ -s cci/CCI-SSMI_${date}000000_skt-eu.grib ]] && echo "LST-night $date already downloaded" || cdo -O -a -s -f grb2 -b P12 copy -setname,skt -settime,00:00:00\
  https://dap.ceda.ac.uk/thredds/dodsC/neodc/esacci/land_surface_temperature/data/SSMI_SSMIS/L3C/v2.33/daily/${date:0:4}/${date:4:2}/${date:6:2}/ESACCI-LST-L3C-LST-${satellite}-0.25deg_1DAILY_DES-${date}000000-fv2.33.nc?time[0:1:0],lat[460:1:660],lon[600:1:920],lst[0:1:0][460:1:660][600:1:920]\
  cci/CCI-SSMI_${date}000000_skt-eu.grib
[[ -s cci/CCI-SSMI_${date}120000_stsktd-eu.grib ]] && echo "DTIME-day $date already downloaded" || cdo -O -a -s -f grb2 -b P12 copy -setparam,63.128.192 -settime,12:00:00\
 https://dap.ceda.ac.uk/thredds/dodsC/neodc/esacci/land_surface_temperature/data/SSMI_SSMIS/L3C/v2.33/daily/${date:0:4}/${date:4:2}/${date:6:2}/ESACCI-LST-L3C-LST-${satellite}-0.25deg_1DAILY_ASC-${date}000000-fv2.33.nc?time[0:1:0],lat[460:1:660],lon[600:1:920],dtime[0:1:0][460:1:660][600:1:920]\
 cci/CCI-SSMI_${date}120000_stsktd-eu.grib &
[[ -s cci/CCI-SSMI_${date}000000_stsktd-eu.grib ]] && echo "DTIME-night $date already downloaded" || cdo -O -a -s -f grb2 -b P12 copy -setparam,63.128.192 -settime,00:00:00\
 https://dap.ceda.ac.uk/thredds/dodsC/neodc/esacci/land_surface_temperature/data/SSMI_SSMIS/L3C/v2.33/daily/${date:0:4}/${date:4:2}/${date:6:2}/ESACCI-LST-L3C-LST-${satellite}-0.25deg_1DAILY_DES-${date}000000-fv2.33.nc?time[0:1:0],lat[460:1:660],lon[600:1:920],dtime[0:1:0][460:1:660][600:1:920]\
 cci/CCI-SSMI_${date}000000_stsktd-eu.grib

 #sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0