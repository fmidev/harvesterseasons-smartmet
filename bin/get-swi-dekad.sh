#!/bin/bash
eval "$(conda shell.bash hook)"
conda activate xr
if [[ $# -gt 0 ]]; then
    yday=`date -d $1 +%Y%m%d`
else
    yday=`date -d '1 month ago' +%Y%m%d`
fi
incoming=/home/smartmet/data/copernicus
mkdir -p $incoming
year=`date -d $yday +%Y`
month=`date -d $yday +%m`
day=`date -d $yday +%d`

cd $incoming
# https://land.copernicus.vgt.vito.be/PDF/datapool/Vegetation/Soil_Water_Index/10-daily_SWI_12.5km_Global_V3/2021/03/21/SWI10_202103211200_GLOBE_ASCAT_V3.1.1/c_gls_SWI10_202103211200_GLOBE_ASCAT_V3.1.1.nc
url="https://mstrahl:Hehec3po@land.copernicus.vgt.vito.be/PDF/datapool/Vegetation/Soil_Water_Index/10-daily_SWI_12.5km_Global_V3/$year/$month/$day/SWI10_${year}${month}${day}1200_GLOBE_ASCAT_V3.1.1/c_gls_SWI10_${year}${month}${day}1200_GLOBE_ASCAT_V3.1.1.nc"
metaurl="https://mstrahl:Hehec3po@land.copernicus.vgt.vito.be/PDF/datapool/Vegetation/Soil_Water_Index/10-daily_SWI_12.5km_Global_V3/$year/$month/$day/SWI10_${year}${month}${day}1200_GLOBE_ASCAT_V3.1.1/c_gls_SWI10_PROD-DESC_${year}${month}${day}1200_GLOBE_ASCAT_V3.1.1.xml"
ncfile="c_gls_SWI10_${yday}1200_GLOBE_ASCAT_V3.1.1.nc"
meta="c_gls_SWI10_PROD-DESC_${yday}1200_GLOBE_ASCAT_V3.1.1.xml"
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
  cdo -f grb -s -b P8 copy -chparam,-17,40.228,-20,41.228,-21,42.228,-23,43.228 -selname,SWI_005,SWI_015,SWI_060,SWI_100 $ncfile $file && \
    s3cmd put -q -P --no-progress $ncfile s3://copernicus/land/gl_swi12.5km/ &&\
     s3cmd put -q -P --no-progress $file s3://copernicus/land/gl_swi12.5km_grb/ &&\
       s3cmd put -q -P --no-progress $meta s3://copernicus/land/gl_swi12.5km_meta/
    rm $ncfile $meta
    mv $file ../grib/SWI10_${file:13:4}0101T120000_${file:13:8}T${file:21:4}_swis.grib
fi
#sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0
