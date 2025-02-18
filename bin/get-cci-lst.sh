#!/bin/env bash
# get ESA CCI LST data from CEDA
# syntax: get-esa-cci-lst.sh <date>
date=$1
cd /home/ubuntu/data/
cdo -f grb2 copy -setname,skt -settime,12:00:00\
 https://dap.ceda.ac.uk/thredds/dodsC/neodc/esacci/land_surface_temperature/data/MULTISENSOR_IRCDR/L3S/0.01/v2.00/daily/${date:0:4}/${date:4:2}/${date:6:2}/ESACCI-LST-L3S-LST-IRCDR_-0.01deg_1DAILY_DAY-${date}000000-fv2.00.nc?time[0:1:0],lat[11500:1:16500],lon[15000:1:23000],lst[0:1:0][11500:1:16500][15000:1:23000]\
 cci/CCI_${date}120000_skt-eu.grib &
cdo -f grb2 copy -setname,skt -settime,00:00:00\
 https://dap.ceda.ac.uk/thredds/dodsC/neodc/esacci/land_surface_temperature/data/MULTISENSOR_IRCDR/L3S/0.01/v2.00/daily/${date:0:4}/${date:4:2}/${date:6:2}/ESACCI-LST-L3S-LST-IRCDR_-0.01deg_1DAILY_NIGHT-${date}000000-fv2.00.nc?time[0:1:0],lat[11500:1:16500],lon[15000:1:23000],lst[0:1:0][11500:1:16500][15000:1:23000]\
 cci/CCI_${date}000000_skt-eu.grib
