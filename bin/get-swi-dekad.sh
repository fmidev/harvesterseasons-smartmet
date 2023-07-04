#!/bin/bash
# give yearmonthday and version as cmd
#eval "$(conda shell.bash hook)"
#conda activate xr
if [[ $# -gt 1 ]]; then
    version=$2
else
    version='3.2.1'
fi
if [[ $# -gt 0 ]]; then
    yday=`date -d $1 +%Y%m%d`
else
    yday=`date -d '8 days ago' +%Y%m%d`
    yday={$yday:0:-1}1
fi
incoming=/home/smartmet/data/copernicus
mkdir -p $incoming
year=`date -d $yday +%Y`
month=`date -d $yday +%m`
day=`date -d $yday +%d`
echo $year $month $day

cd $incoming
# https://land.copernicus.vgt.vito.be/PDF/datapool/Vegetation/Soil_Water_Index/10-daily_SWI_12.5km_Global_V3/2021/03/21/SWI10_202103211200_GLOBE_ASCAT_V3.1.1/c_gls_SWI10_202103211200_GLOBE_ASCAT_V3.1.1.nc
url="https://mstrahl:Hehec3po@land.copernicus.vgt.vito.be/PDF/datapool/Vegetation/Soil_Water_Index/10-daily_SWI_12.5km_Global_V3/$year/$month/$day/SWI10_${year}${month}${day}1200_GLOBE_ASCAT_V$version/c_gls_SWI10_${year}${month}${day}1200_GLOBE_ASCAT_V$version.nc"
metaurl="https://mstrahl:Hehec3po@land.copernicus.vgt.vito.be/PDF/datapool/Vegetation/Soil_Water_Index/10-daily_SWI_12.5km_Global_V3/$year/$month/$day/SWI10_${year}${month}${day}1200_GLOBE_ASCAT_V$version/c_gls_SWI10_PROD-DESC_${year}${month}${day}1200_GLOBE_ASCAT_V$version.xml"
ncfile="c_gls_SWI10_${yday}1200_GLOBE_ASCAT_V$version.nc"
meta="c_gls_SWI10_PROD-DESC_${yday}1200_GLOBE_ASCAT_V$version.xml"
fileFix=${ncfile:0:-3}-swi-fix.grib
file=${ncfile:0:-3}-swi.grib
ceph="https://copernicus.data.lit.fmi.fi/land/gl_swi12.5km/$ncfile"

#wget -q --method=HEAD $ceph && wget -q $ceph && upload=grb || 
[ ! -s "$ncfile" ] && echo "Downloading from vito" && wget -q --random-wait $url && \
     wget -q --random-wait $metaurl
#nfile=${ncfile:0:-3}-swi_noise.tif
#cog="${file:0:-4}_cog.tif"
#ncog="${nfile:0:-4}_cog.tif"
nc_ok=$(cdo xinfon $ncfile)

if [ -z "$nc_ok" ]
then
    echo "Downloading failed: $ncfile $url" 
else 
  cdo -f grb -s -b P8 copy -chparam,-17,40.228,-20,41.228,-21,42.228,-23,43.228 -selname,SWI_005,SWI_015,SWI_060,SWI_100 $ncfile $fileFix
  grib_set -r -s centre=224,jScansPositively=0 $fileFix $file
  s3cmd put -q -P --no-progress $ncfile s3://copernicus/land/gl_swi12.5km/ &&\
     s3cmd put -q -P --no-progress $file s3://copernicus/land/gl_swi12.5km_grb/ &&\
       s3cmd put -q -P --no-progress $meta s3://copernicus/land/gl_swi12.5km_meta/
    rm $ncfile $meta $fileFix
    mv $file ../grib/SWI10_20000101T000000_${file:12:8}T${file:20:4}00_swis.grib
fi
#sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0
