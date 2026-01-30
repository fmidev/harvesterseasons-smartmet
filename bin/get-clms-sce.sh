#!/bin/bash

yday=$(date -d "yesterday" '+%Y%m%d')
outpath=/home/ubuntu/data/CGLC2_SCE/
if [[ $# -eq 2 ]] 
then
    outpath=$2 
    yday=$1
elif [[ $# -eq 1 ]]
then
    yday=$1
else
    yday=$yday
fi
mkdir -p $outpath

cd /home/ubuntu/data/

ftp_site=litdb.fmi.fi
username=globland_admin
passwd=JyFWTMoTjEQ72
#inpath=/SWE_NH_5km/
inpath=/SCE_NH_1km/

ftp -p -inv <<EOF
open $ftp_site
user $username $passwd
lcd $outpath
binary
cd $inpath
mget *$yday*.nc
ls *$yday*.nc
close
bye
EOF

cdo --eccodes -s -f grb2 copy -setparam,42.1.0 -setname,snowc -selname,sce CGLC2_SCE/c_gls_SCE_${yday}0000_NHEMI_SLSTR_V*.nc CGLC2_SCE/CLMS_20000101T000000_${yday}T000000_sce_SLSTR.grib &&\
 grib_set -s centre=86 CGLC2_SCE/CLMS_20000101T000000_${yday}T000000_sce_SLSTR.grib CGLC2_SCE/gribfix/CLMS_20000101T000000_${yday}T000000_sce_SLSTR.grib && rm CGLC2_SCE/CLMS_20000101T000000_${yday}T000000_sce_SLSTR.grib && rm CGLC2_SCE/c_gls_SCE_${yday}0000_NHEMI_SLSTR_V*.nc

cdo --eccodes -s -f grb2 copy -setparam,42.1.0 -setname,snowc -selname,sce CGLC2_SCE/c_gls_SCE_${yday}0000_NHEMI_VIIRS_V*.nc CGLC2_SCE/CLMS_20000101T000000_${yday}T000000_sce_VIIRS.grib &&\
 grib_set -s centre=86 CGLC2_SCE/CLMS_20000101T000000_${yday}T000000_sce_VIIRS.grib CGLC2_SCE/gribfix/CLMS_20000101T000000_${yday}T000000_sce_VIIRS.grib && rm CGLC2_SCE/CLMS_20000101T000000_${yday}T000000_sce_VIIRS.grib && rm CGLC2_SCE/c_gls_SCE_${yday}0000_NHEMI_VIIRS_V*.nc
#cdo --eccodes -s -f grb1 copy -setparam,141.128 -setname,sd -mulc,0.001 -selname,swe CGLC2_SWE/c_gls_SWE5K_${yday}0000_NHEMI_SSMIS_V*.nc CLMS_20000101T000000_${yday}T000000_swe.grib &&\
# grib_set -s centre=86 CLMS_20000101T000000_${yday}T000000_swe.grib grib/CLMS_20000101T000000_${yday}T000000_swe.grib && rm CLMS_20000101T000000_${yday}T000000_swe.grib && rm CGLC2_SWE/c_gls_SWE5K_${yday}0000_NHEMI_SSMIS_V*.nc
##cdo --eccodes -s -f grb1 copy -setparam,141.128 -setname,sd -mulc,0.001 -selname,swe_var CGLC2_SWE/c_gls_SWE5K_${yday}0000_NHEMI_SSMIS_V*.nc CLMS_${yday:0:4}0101T000000_${yday}T000000_swevar.grib
##grib_set -s centre=86,type=ea CLMS_${yday:0:4}0101T000000_${yday}T000000_swevar.grib grib/CLMS_${yday:0:4}0101T000000_${yday}T000000_swevar.grib && rm CLMS_${yday:0:4}0101T000000_${yday}T000000_swevar.grib

#sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /etc/smartmet/libraries/tools-grid/filesys-to-smartmet.cfg 0

echo "Done"
