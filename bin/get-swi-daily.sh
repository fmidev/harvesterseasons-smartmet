#!/bin/bash
eval "$(conda shell.bash hook)"
conda activate xr
if [[ $# -gt 0 ]]; then
    yday=`date -d $1 +%Y%m%d`
else
    yday=`date -d '14 days ago' +%Y%m%d`
fi
incoming=/home/smartmet/data/copernicus
mkdir -p $incoming
year=`date -d $yday +%Y`
month=`date -d $yday +%m`
day=`date -d $yday +%d`

cd $incoming
# https://land.copernicus.vgt.vito.be/PDF/datapool/Vegetation/Soil_Water_Index/Daily_SWI_1km_Europe_V1/2020/10/11/SWI1km_202010111200_CEURO_SCATSAR_V1.0.1/c_gls_SWI1km_202010111200_CEURO_SCATSAR_V1.0.1.nc
url="https://mstrahl:Hehec3po@land.copernicus.vgt.vito.be/PDF/datapool/Vegetation/Soil_Water_Index/Daily_SWI_1km_Europe_V1/$year/$month/$day/SWI1km_${year}${month}${day}1200_CEURO_SCATSAR_V1.0.1/c_gls_SWI1km_${year}${month}${day}1200_CEURO_SCATSAR_V1.0.1.nc"
meta=${url:0:-3}.xml
ncfile="c_gls_SWI1km_${yday}1200_CEURO_SCATSAR_V1.0.1.nc"
file=${ncfile:0:-3}-swi.grib
ceph="https://copernicus.data.lit.fmi.fi/land/eu_swi1km/$ncfile"

#wget -q --method=HEAD $ceph && wget -q $ceph && upload=grb || 
[ ! -s "$ncfile" ] && echo "Downloading from vito" && wget -q --random-wait $url && \
     wget -q --random-wait $meta
#nfile=${ncfile:0:-3}-swi_noise.tif
#cog="${file:0:-4}_cog.tif"
#ncog="${nfile:0:-4}_cog.tif"
nc_ok=$(cdo xinfon $ncfile)

if [ -z "$nc_ok" ]
then
    echo "Downloading failed: $ncfile $url" 
else 
  cdo --eccodes -f grb -s -b P8 copy -chparam,-4,40.228,-8,41.228,-14,42.228,-16,43.228 -selname,SWI_005,SWI_015,SWI_060,SWI_100 $ncfile $file && \
    s3cmd put -q -P --no-progress $ncfile s3://copernicus/land/eu_swi1km/ &&\
     s3cmd put -q -P --no-progress $file s3://copernicus/land/eu_swi1km_grb/ &&\
       s3cmd put -q -P --no-progress ${ncfile:0:-3}.xml s3://copernicus/land/eu_swi1km_meta/
    rm $ncfile ${ncfile:0:-3}.xml
    mv $file ../grib/SWI_${file:13:6}01T120000_${file:13:8}T${file:21:4}_swis.grib

#sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0
