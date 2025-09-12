#!/bin/bash
# Fetch NDVI_300m_V2 from Copernicus Land Monitoring System  (VITO directly as CLMS has changed 21.7.2024)
# USAGE: get-clms-ndvi-dekad-V2.sh [yearmonthday] [version]
# (valid for data from July 2020 -> ) dekad day are 01 11 21
#eval "$(conda shell.bash hook)"
eval "$(/home/ubuntu/mambaforge/bin/conda shell.bash hook)"
conda activate cdo
version="V2.0.1"
#version="V2.0.2"
if [[ $# -gt 0 ]]; then
    yday=`date -d $1 +%Y%m%d`
    if [[ $# -gt 1 ]]; then
        version=$2
    fi
else
    yday=`date -d '10 days ago' +%Y%m%d`
    yday=${yday:0:-1}1
fi
incoming=/home/smartmet/data/clms
mkdir -p $incoming
year=`date -d $yday +%Y`
month=`date -d $yday +%m`
day=`date -d $yday +%d`
echo $yday

cd $incoming
#url="https://land.copernicus.vgt.vito.be/PDF/datapool/Vegetation/Indicators/NDVI_300m_V2/$year/$month/$day/NDVI300_${year}${month}${day}0000_GLOBE_OLCI_$version/c_gls_NDVI300_${year}${month}${day}0000_GLOBE_OLCI_$version.nc"
url="https://globalland.vito.be/download/netcdf/ndvi/ndvi_300m_v2_10daily/$year/${year}${month}${day}/c_gls_NDVI300_${year}${month}${day}0000_GLOBE_OLCI_$version.nc"
#metaurl="https://land.copernicus.vgt.vito.be/PDF/datapool/Vegetation/Indicators/NDVI_300m_V2/$year/$month/$day/NDVI300_${year}${month}${day}0000_GLOBE_OLCI_$version/c_gls_NDVI300_PROD-DESC_${year}${month}${day}0000_GLOBE_OLCI_$version.xml"
ncIn="c_gls_NDVI300_${year}${month}${day}0000_GLOBE_OLCI_$version.nc"
ncfile="c_gls_NDVI300_${year}${month}${day}0000_EU_OLCI_$version.nc"
#meta="c_gls_NDVI300_PROD-DESC_${year}${month}${day}0000_GLOBE_OLCI_$version.xml"
fileFix=${ncfile:0:-3}-NDVI-V2-eu.grib
file=${ncfile:0:-3}-NDVI-V2-eu-fix.grib
#ceph="https://copernicus.data.lit.fmi.fi/land/gl_swi12.5km/$ncfile"
mani=$(wget -q -c https://globalland.vito.be/download/manifest/ndvi_300m_v2_10daily_netcdf/manifest_clms_global_ndvi_300m_v2_10daily_netcdf_latest.txt)
url=$(grep "$year$month${day}0000_GLOBE" manifest_clms_global_ndvi_300m_v2_10daily_netcdf_latest.txt)

#wget -q --method=HEAD $ceph && wget -q $ceph && upload=grb || 
[ ! -s "$ncIn" ] && echo "Downloading from vito" && wget -q -c $url
nc_ok=$(cdo xinfon $ncIn)

if [ -z "$nc_ok" ]
then
    echo "Downloading failed: $ncIn $url" 
    exit 1
else
  ncea -d lat,25.0,75.0 -d lon,-30.0,50.0 $ncIn $ncfile 
  cdo -f grb2 -s -b P8 copy -setvrange,0,1 -setparam,31.0.2 -settime,12:00:00 -selname,NDVI $ncfile $fileFix
  grib_set -r -s centre=224,dataDate=$yday,forecastTime=0,jScansPositively=0 $fileFix $file
  s3cmd put -q -P --no-progress $ncIn s3://copernicus/land/gl_ndvi300m/ &&\
     s3cmd put -q -P --no-progress $file s3://copernicus/land/gl_ndvi300m_grb/ 
     #&&\
    #     s3cmd put -q -P --no-progress $meta s3://copernicus/land/gl_ndvi300m_meta/
  rm $ncIn $ncfile $fileFix #$meta
  mv $file ../grib/CLMS_20000101T000000_${file:14:8}T000000_NDVI-V2-eu.grib
fi

#sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0