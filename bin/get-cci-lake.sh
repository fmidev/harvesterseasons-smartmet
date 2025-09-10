#!/bin/env bash
# get ESA CCI LST data from CEDA
# syntax: get-esa-cci-lst.sh <date>
y=$1
m=$2
d=$3
cd /home/ubuntu/data/
cdo -O -s -f grb2 -b P12 copy -setname,lmlt -settime,12:00:00\
 https://dap.ceda.ac.uk/thredds/dodsC/neodc/esacci/lakes/data/lake_products/L3S/v2.1/merged_product/$y/$m/ESACCI-LAKES-L3S-LK_PRODUCTS-MERGED-$y$m$d-fv2.1.0.nc?time[0:1:0],lat[13800:1:19800],lon[18000:1:27600],lat_bounds[13800:1:19800][0:1:1],lon_bounds[18000:1:27600][0:1:1],lake_surface_water_temperature[0:1:0][13800:1:19800][18000:1:27600],crs\
 cci/CCI_$y$m${d}120000_lake-eu.grib &

# no useful data in two variables, cut off request
# ,lake_ice_cover_class[0:1:0][13800:1:19800][18000:1:27600],water_surface_height_above_reference_datum[0:1:0][13800:1:19800][18000:1:27600],lake_surface_water_extent[0:1:0][13800:1:19800][18000:1:27600] 
