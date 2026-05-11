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
    version="OLCI_V2.0.1"
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
#url="https://globalland.vito.be/download/netcdf/leaf_area_index/lai_300m_v1_10daily/${year}/${year}${month}${day}/c_gls_${lai}_${year}${month}${day}0000_GLOBE_$version.nc"
#metaurl="https://land.copernicus.vgt.vito.be/PDF/datapool/Vegetation/Properties/LAI_300m_V1/$year/$month/$day/${lai}_${year}${month}${day}0000_GLOBE_$version/c_gls_${lai}_PROD-DESC_${year}${month}${day}0000_GLOBE_$version.xml"
ncfile="c_gls_${lai}_${year}${month}${day}0000_GLOBE_OLCI_$version.nc"
ncpath="c_gls_${lai}_${year}${month}${day}0000_GLOBE_OLCI_${version}_nc"
s3="s3://eodata/CLMS/bio-geophysical/vegetation_properties/lai_global_300m_10daily_v2/$year/$month/$day/$ncpath/$ncfile"
#meta="c_gls_${lai}_PROD-DESC_${year}${month}${day}0000_GLOBE_$version.xml"
fileFix=${ncfile:0:-3}-LAI-V2-eu.grib
file=${ncfile:0:-3}-LAI-V2-eu-fix.grib
#ceph="https://copernicus.data.lit.fmi.fi/land/gl_swi12.5km/$ncfile"

#wget -q --method=HEAD $ceph && wget -q $ceph && upload=grb || 
[ ! -s "$ncfile" ] && echo "Downloading from s3 eodata" && s3cmd -c ~/.s3cfg.cdse get $s3 #&& \
#     wget -q --random-wait $metaurl
#nfile=${ncfile:0:-3}-swi_noise.tif
#cog="${file:0:-4}_cog.tif"
#ncog="${nfile:0:-4}_cog.tif"
nc_ok=$(cdo sinfon $ncfile)

if [ -z "$nc_ok" ]
then
    echo "Downloading failed: $ncfile $url" 
    rm $ncfile #$meta
else 
#  ncea -d lat,25.0,75.0 -d lon,-30.0,50.0 $ncfile $ncfilec 
  cdo -f grb2 -s -b P8 copy -setparam,28.0.2 -setvrange,0,7 -sellonlatbox,-30,50,25,75 -selname,LAI $ncfile $fileFix
  grib_set -r -s centre=224,dataDate=$yday,jScansPositively=0 $fileFix $file
  mv $file ../grib/CLMS_20000101T000000_${year}${month}${day}T000000_LAI-V2-eu.grib
  s3cmd put -q -P --no-progress $ncfile s3://copernicus/land/gl_lai300m/ &&\
     s3cmd put -q -P --no-progress $file s3://copernicus/land/gl_lai300m_grb/ 
     #&&\
  #     s3cmd put -q -P --no-progress $meta s3://copernicus/land/gl_lai300m_meta/
  rm $ncfile $ncfilec $fileFix #$meta
fi
#sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /etc/smartmet/libraries/tools-grid/filesys-to-smartmet.cfg 0