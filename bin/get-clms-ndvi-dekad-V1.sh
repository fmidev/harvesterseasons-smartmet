#!/bin/bash
# Fetch NDVI_300m_V1 from Copernicus Land Monitoring System 
# give yearmonthday as cmd (2014-2021)

#if [[ $# -gt 0 ]]; then
#    yday=`date -d $1 +%Y%m%d`
#else
#    yday=`date -d '8 days ago' +%Y%m%d`
#    yday={$yday:0:-1}1
#fi
yday=`date -d $1 +%Y%m%d`
incoming=/home/smartmet/data/copernicus
mkdir -p $incoming
year=`date -d $yday +%Y`
month=`date -d $yday +%m`
day=`date -d $yday +%d`
echo $yday

cd $incoming
# https://land.copernicus.vgt.vito.be/PDF/datapool/Vegetation/Soil_Water_Index/10-daily_SWI_12.5km_Global_V3/2021/03/21/SWI10_202103211200_GLOBE_ASCAT_V3.1.1/c_gls_SWI10_202103211200_GLOBE_ASCAT_V3.1.1.nc
#url="https://mstrahl:Hehec3po@land.copernicus.vgt.vito.be/PDF/datapool/Vegetation/Soil_Water_Index/10-daily_SWI_12.5km_Global_V3/$year/$month/$day/SWI10_${year}${month}${day}1200_GLOBE_ASCAT_V$version/c_gls_SWI10_${year}${month}${day}1200_GLOBE_ASCAT_V$version.nc"
#metaurl="https://mstrahl:Hehec3po@land.copernicus.vgt.vito.be/PDF/datapool/Vegetation/Soil_Water_Index/10-daily_SWI_12.5km_Global_V3/$year/$month/$day/SWI10_${year}${month}${day}1200_GLOBE_ASCAT_V$version/c_gls_SWI10_PROD-DESC_${year}${month}${day}1200_GLOBE_ASCAT_V$version.xml"
#ncfile="c_gls_SWI10_${yday}1200_GLOBE_ASCAT_V$version.nc"
#meta="c_gls_SWI10_PROD-DESC_${yday}1200_GLOBE_ASCAT_V$version.xml"
url="https://mstrahl:Hehec3po@land.copernicus.vgt.vito.be/PDF/datapool/Vegetation/Indicators/NDVI_300m_V1/$year/$month/$day/NDVI300_${year}${month}${day}0000_GLOBE_PROBAV_V1.0.1/c_gls_NDVI300_${year}${month}${day}0000_GLOBE_PROBAV_V1.0.1.nc"
metaurl="https://mstrahl:Hehec3po@land.copernicus.vgt.vito.be/PDF/datapool/Vegetation/Indicators/NDVI_300m_V1/$year/$month/$day/NDVI300_${year}${month}${day}0000_GLOBE_PROBAV_V1.0.1/c_gls_NDVI300_PROD-DESC_${year}${month}${day}0000_GLOBE_PROBAV_V1.0.1.xml"
ncIn="c_gls_NDVI300_${year}${month}${day}0000_GLOBE_PROBAV_V1.0.1.nc"
ncfile="c_gls_NDVI300_${year}${month}${day}0000_EU_PROBAV_V1.0.1.nc"
meta="c_gls_NDVI300_PROD-DESC_${year}${month}${day}0000_GLOBE_PROBAV_V1.0.1.xml"
fileFix=${ncfile:0:-3}-NDVI-V1-eu.grib
file=${ncfile:0:-3}-NDVI-V1-eu-fix.grib
#ceph="https://copernicus.data.lit.fmi.fi/land/gl_swi12.5km/$ncfile"

#wget -q --method=HEAD $ceph && wget -q $ceph && upload=grb || 
[ ! -s "$ncIn" ] && echo "Downloading from vito" && wget -q --random-wait $url && \
     wget -q --random-wait $metaurl
#nfile=${ncfile:0:-3}-swi_noise.tif
#cog="${file:0:-4}_cog.tif"
#ncog="${nfile:0:-4}_cog.tif"
nc_ok=$(cdo xinfon $ncIn)

if [ -z "$nc_ok" ]
then
    echo "Downloading failed: $ncIn $url" 
else 
  ncea -d lat,25.0,75.0 -d lon,-30.0,50.0 $ncIn $ncfile 
  cdo -f grb2 -s -b P8 copy -setparam,31.0.2 -setvrange,0,1 $ncfile $fileFix
  grib_set -r -s centre=224,dataDate=$yday,jScansPositively=0 $fileFix $file
  s3cmd put -q -P --no-progress $ncIn s3://copernicus/land/gl_ndvi300m/ &&\
     s3cmd put -q -P --no-progress $file s3://copernicus/land/gl_ndvi300m_grb/ &&\
       s3cmd put -q -P --no-progress $meta s3://copernicus/land/gl_ndvi300m_meta/
    rm $ncIn $ncfile $meta $fileFix
    mv $file ../grib/CLMS_20000101T000000_${file:14:8}T000000_NDVI-V1-eu.grib
fi
#sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0
