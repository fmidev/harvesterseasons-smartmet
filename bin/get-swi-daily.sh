#!/bin/bash
# VITO discontinued the service 2024-7-1
# daily script for fetching SWI 1km data now from CLMS
# new download method with EU-login and apikey not implemented as not working, 
# using MANIFEST urls directly to VITO instead 2024-07-20
# 12.7.2025 onwards the downloaded nc has different set of variables, so the script needs to be updated 
# to select only the SWI variables from nc first and then grib convert
# USAGE: get-swi-daily.sh [yearmonthday] [version]
# Mikko Strahlendorff / Anni Kröger

eval "$(/home/ubuntu/mambaforge/bin/conda shell.bash hook)"
conda activate cdo

if [[ $# -gt 0 ]]; then
    yday=`date -d $1 +%Y%m%d`
    version=$2
else
    yday=`date -d '1 days ago' +%Y%m%d`
    version=2.1.1 # new version 2.1.1. since 20260223, older vas 2.0.1 / AK
fi

incoming=~/data/swi1km
mkdir -p $incoming
year=`date -d $yday +%Y`
month=`date -d $yday +%m`
day=`date -d $yday +%d`

echo $year $month $day

cd $incoming

# "Obtaining JWT access tokens for CLMS ..."
#token=$(clms-grant.py)

# https://land.copernicus.vgt.vito.be/PDF/datapool/Vegetation/Soil_Water_Index/Daily_SWI_1km_Europe_V1/2020/10/11/SWI1km_202010111200_CEURO_SCATSAR_V1.0.1/c_gls_SWI1km_202010111200_CEURO_SCATSAR_V1.0.1.nc
#url="https://land.copernicus.vgt.vito.be/PDF/datapool/Vegetation/Soil_Water_Index/Daily_SWI_1km_Europe_V1/$year/$month/$day/SWI1km_${year}${month}${day}1200_CEURO_SCATSAR_V$version/c_gls_SWI1km_${year}${month}${day}1200_CEURO_SCATSAR_V$version.nc"

#maniurl="https://globalland.vito.be/download/manifest/swi_1km_v2_daily_netcdf/manifest_clms_global_swi_1km_v2_daily_netcdf_latest.txt"
#meta=${url:0:-3}.xml

ncfile="c_gls_SWI1km_${yday}1200_CEURO_SCATSAR_V$version.nc"
ncpath="c_gls_SWI1km_${yday}1200_CEURO_SCATSAR_V${version}_nc"
ncfixfile="c_gls_SWI1km_${yday}1200_CEURO_SCATSAR_V${version}_fix.nc"
fileFix=${ncfile:0:-3}-swi-fix.grib
file=${ncfile:0:-3}-swi.grib
ceph="https://copernicus.data.lit.fmi.fi/land/eu_swi1km/$ncfile"
#s3="s3://eodata/CLMS/bio-geophysical/soil_water_index/swi_europe_1km_daily_v1/$year/$month/$day/$ncpath/$ncfile"
s3="s3://eodata/CLMS/bio-geophysical/soil_water_index/swi_europe_1km_daily_v2/$year/$month/$day/$ncpath/$ncfile"
#manifest=$(wget -q -c --random-wait $maniurl)
#url=$(grep "$year$month${day}1200_CEURO" manifest_clms_global_swi_1km_v2_daily_netcdf_latest.txt)
#echo $url
#url="https://globalland.vito.be/download/netcdf/soil_water_index/swi_1km_v1_daily/${year}/${year}${month}${day}/c_gls_SWI1km_${year}${month}${day}1200_CEURO_SCATSAR_V$version.nc"
#wget -q --method=HEAD $ceph && wget -q $ceph && upload=grb || 
#[ ! -s "$ncfile" ] && echo "Downloading from vito" && wget -q -c --random-wait $url || echo "already downloaded"
[ ! -s "$ncfile" ] && echo "Downloading from CDSE" && s3cmd -c ~/.s3cfg.cdse get $s3 || echo "already downloaded"
#nfile=${ncfile:0:-3}-swi_noise.tif
#cog="${file:0:-4}_cog.tif"
#ncog="${nfile:0:-4}_cog.tif"

nc_ok=$(cdo filedes $ncfile)

if [ -z "$nc_ok" ]
then
    echo "Downloading failed: $ncfile $url" 
    exit 1
else     
    # ensure only SWI variables are in the nc file
    cdo -selname,SWI_005,SWI_015,SWI_060,SWI_100 $ncfile $ncfixfile
    # convert to grib
    cdo --eccodes -O -f grb2 -s -b P8 copy -chparam,-1,40.228.192,-2,41.228.192,-3,42.228.192,-4,43.228.192 $ncfixfile $fileFix
    grib_set -s centre=224,jScansPositively=0 $fileFix $file
    s3cmd put -q -P --no-progress $ncfile s3://copernicus/land/eu_swi1km/ &&\
     s3cmd put -q -P --no-progress $file s3://copernicus/land/eu_swi1km_grb/
#       s3cmd put -q -P --no-progress ${ncfile:0:-3}.xml s3://copernicus/land/eu_swi1km_meta/
    rm $ncfile $ncfixfile $fileFix manifest_clms_global_swi_1km_v1_daily_netcdf_latest.*
    mv $file ../grib/SWI_20000101T000000_${file:13:8}T${file:21:4}00_swis.grib
fi
echo "Done"
#sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /etc/smartmet/libraries/tools-grid/filesys-to-smartmet.cfg 0