#!/bin/bash
#=====#################################################################
# NAME:
#		download_swe_ftp_clms.sh
# CALLING SEQUENCE:
# 		./download_swe_ftp_clms.sh $yday $outpath
# EAMPLE:
#       download_swe_ftp_clms.sh *20140101*.nc /home/ubuntu/data/CGLC2_SWE/
#       download_swe_ftp_clms.sh *20140101*.nc
# PURPOSE:
#		download Globland SWE data from CLMS
# AUTHOR:
#		written by Golda 
# PROJECT:
#		HarvesterDestinE
#
# INFO:
#=====#################################################################

yday=$(date -d "yesterday" '+%Y%m%d')
outpath=/home/ubuntu/data/CGLC2_SWE/
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
inpath=/SWE_NH_5km/

ftp -p -inv <<EOF
open $ftp_site
user $username $passwd
lcd $outpath
binary
cd $inpath
mget *$yday*.nc
close
bye
EOF

cdo --eccodes -s -f grb1 copy -setparam,141.128 -setname,sd -mulc,0.001 -selname,swe CGLC2_SWE/c_gls_SWE5K_${yday}0000_NHEMI_SSMIS_V*.nc CLMS_20000101T000000_${yday}T000000_swe.grib &&\
 grib_set -s centre=86 CLMS_20000101T000000_${yday}T000000_swe.grib grib/CLMS_20000101T000000_${yday}T000000_swe.grib && rm CLMS_20000101T000000_${yday}T000000_swe.grib && rm CGLC2_SWE/c_gls_SWE5K_${yday}0000_NHEMI_SSMIS_V*.nc
#cdo --eccodes -s -f grb1 copy -setparam,141.128 -setname,sd -mulc,0.001 -selname,swe_var CGLC2_SWE/c_gls_SWE5K_${yday}0000_NHEMI_SSMIS_V*.nc CLMS_${yday:0:4}0101T000000_${yday}T000000_swevar.grib
#grib_set -s centre=86,type=ea CLMS_${yday:0:4}0101T000000_${yday}T000000_swevar.grib grib/CLMS_${yday:0:4}0101T000000_${yday}T000000_swevar.grib && rm CLMS_${yday:0:4}0101T000000_${yday}T000000_swevar.grib

#sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0