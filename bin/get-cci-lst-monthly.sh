#!/bin/env bash
# get ESA CCI LST data from CEDA
# syntax: get-esa-cci-lst.sh <YYYYMM>
ymon=$1
urlbase=https://dap.ceda.ac.uk/thredds/dodsC/neodc/esacci/land_surface_temperature/data/MULTISENSOR_IRCDR/L3S/0.01/v3.00
cd /home/ubuntu/data/
cdo -O -a -s -f grb2 -b P12 copy -setname,skt -settime,12:00:00\
 $urlbase/monthly/${ymon:0:4}/${ymon:4:2}/ESACCI-LST-L3S-LST-IRCDR_-0.01deg_1MONTHLY_DAY-${ymon}01000000-fv3.00.nc?time[0:1:0],lat[11500:1:16500],lon[15000:1:23000],lst[0:1:0][11500:1:16500][15000:1:23000]\
 cci/CCIC_${ymon}01120000_skt-mon-eu.grib &
cdo -O -a -s -f grb2 -b P12 copy -setname,skt -settime,00:00:00\
 $urlbase/monthly/${ymon:0:4}/${ymon:4:2}/ESACCI-LST-L3S-LST-IRCDR_-0.01deg_1MONTHLY_NIGHT-${ymon}01000000-fv3.00.nc?time[0:1:0],lat[11500:1:16500],lon[15000:1:23000],lst[0:1:0][11500:1:16500][15000:1:23000]\
 cci/CCIC_${ymon}01000000_skt-mon-eu.grib
cdo -O -a -s -f grb2 -b P12 copy -setparam,63.128.192 -settime,12:00:00\
 $urlbase/monthly/${ymon:0:4}/${ymon:4:2}/ESACCI-LST-L3S-LST-IRCDR_-0.01deg_1MONTHLY_DAY-${ymon}01000000-fv3.00.nc?time[0:1:0],lat[11500:1:16500],lon[15000:1:23000],dtime[0:1:0][11500:1:16500][15000:1:23000]\
 cci/CCIC_${ymon}01120000_stsktd-mon-eu.grib &
cdo -O -a -s -f grb2 -b P12 copy -setparam,63.128.192 -settime,00:00:00\
 $urlbase/monthly/${ymon:0:4}/${ymon:4:2}/ESACCI-LST-L3S-LST-IRCDR_-0.01deg_1MONTHLY_NIGHT-${ymon}01000000-fv3.00.nc?time[0:1:0],lat[11500:1:16500],lon[15000:1:23000],dtime[0:1:0][11500:1:16500][15000:1:23000]\
 cci/CCIC_${ymon}01000000_stsktd-mon-eu.grib

#sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0