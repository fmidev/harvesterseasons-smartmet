#!/bin/bash
# Fetch LAI_300m_V1 from Copernicus Land Monitoring System 
# USAGE: get-clms-lai-dekad.sh [yearmonthday] [version] [lai]
# use 10 20 30 31 28 or 29 as final day of dekad
eval "$(conda shell.bash hook)"
conda activate xgb
if [[ $# -gt 0 ]]; then
    yday=`date -d $1 +%Y%m%d`
else
    yday=`date -d '10 days ago' +%Y%m%d`
    yday={$yday:0:-1}0
fi
if [[ $# -gt 2 ]]; then
  version=$2
  lai=$3
elif [[ $# -gt 2 ]]; then
  version=$2
  lai="LAI300-RT6"
elif [[ $yday -gt 20210501 ]]; then
    version="OLCI_V1.1.2"
    lai="LAI300-RT6"
elif [[ $yday -gt 20200701 ]]; then
    version="OLCI_V1.1.1"
    lai="LAI300-RT6"
else
    lai="LAI300-RT0"
    version="OLCI_V1.1.2"
fi
yday=`date -d $1 +%Y%m%d`
incoming=/home/smartmet/data/copernicus
mkdir -p $incoming
year=`date -d $yday +%Y`
month=`date -d $yday +%m`
day=`date -d $yday +%d`
echo $yday
cd $incoming
#url="https://land.copernicus.vgt.vito.be/PDF/datapool/Vegetation/Properties/LAI_300m_V1/$year/$month/$day/${lai}_${year}${month}${day}0000_GLOBE_$version/c_gls_${lai}_${year}${month}${day}0000_GLOBE_$version.nc"
url="https://globalland.vito.be/download/netcdf/leaf_area_index/lai_300m_v1_10daily/${year}/${year}${month}${day}/c_gls_${lai}_${year}${month}${day}0000_GLOBE_$version.nc"
#metaurl="https://land.copernicus.vgt.vito.be/PDF/datapool/Vegetation/Properties/LAI_300m_V1/$year/$month/$day/${lai}_${year}${month}${day}0000_GLOBE_$version/c_gls_${lai}_PROD-DESC_${year}${month}${day}0000_GLOBE_$version.xml"
ncIn="c_gls_${lai}_${year}${month}${day}0000_GLOBE_$version.nc"
ncfile="c_gls_${lai}_${year}${month}${day}0000_EU_$version.nc"
#meta="c_gls_${lai}_PROD-DESC_${year}${month}${day}0000_GLOBE_$version.xml"
fileFix=${ncfile:0:-3}-LAI-V1-eu.grib
file=${ncfile:0:-3}-LAI-V1-eu-fix.grib
#ceph="https://copernicus.data.lit.fmi.fi/land/gl_swi12.5km/$ncfile"

#wget -q --method=HEAD $ceph && wget -q $ceph && upload=grb || 
[ ! -s "$ncIn" ] && echo "Downloading from vito" && wget -q -c --random-wait $url #&& \
#     wget -q --random-wait $metaurl
#nfile=${ncfile:0:-3}-swi_noise.tif
#cog="${file:0:-4}_cog.tif"
#ncog="${nfile:0:-4}_cog.tif"
nc_ok=$(cdo sinfon $ncIn)

if [ -z "$nc_ok" ]
then
    echo "Downloading failed: $ncIn $url" 
    rm $ncIn #$meta
else 
  ncea -d lat,25.0,75.0 -d lon,-30.0,50.0 $ncIn $ncfile 
  cdo -f grb2 -s -b P12 copy -setparam,28.0.2 -setvrange,0,7 -selname,LAI $ncfile $fileFix
  grib_set -r -s centre=224,dataDate=$yday,jScansPositively=0 $fileFix $file
  mv $file ../grib/CLMS_20000101T000000_${year}${month}${day}T000000_LAI-V1-eu.grib
  s3cmd put -q -P --no-progress $ncIn s3://copernicus/land/gl_lai300m/ &&\
     s3cmd put -q -P --no-progress $file s3://copernicus/land/gl_lai300m_grb/ 
     #&&\
  #     s3cmd put -q -P --no-progress $meta s3://copernicus/land/gl_lai300m_meta/
  rm $ncIn $ncfile $fileFix #$meta
fi
#sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0