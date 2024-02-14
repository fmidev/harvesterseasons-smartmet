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
eval "$(conda shell.bash hook)"
conda activate cdo

yday=$(date -d "3 days ago" '+%Y%m%d')
outpath=/home/ubuntu/data/CGLC2_SWE
if [[ $# -eq 2 ]] 
then
    outpath=$2 
    yday=$1
elif [[ $# -eq 1 ]]
then
    yday=$1
fi
mkdir -p $outpath
echo $yday
cd $outpath
version=1.0.2
ftp_site=ftp.globalland.cls.fr
username=mstrahl
passwd=Hehec3po
inpath=Core/CRYOSPHERE/dataset-fmi-swe-nh-5km/

if [ ! -s $outpath/c_gls_SWE5K_${yday}0000_NHEMI_SSMIS_V$version.nc ]
then
    ftp -inv ftp://$username:$passwd@$ftp_site <<EOF
cd $inpath
mget c_gls_SWE5K_${yday}0000_*.nc
close
bye
EOF
fi

cdo --eccodes -s -f grb1 copy -setparam,141.128 -setname,sd -mulc,0.001 -selname,swe c_gls_SWE5K_${yday}0000_NHEMI_SSMIS_V$version.nc CLMS_20000101T000000_${yday}T000000_swe.grib && rm c_gls_SWE5K_${yday}0000_NHEMI_SSMIS_V$version.nc &&\
 grib_set -s centre=86 CLMS_20000101T000000_${yday}T000000_swe.grib ../grib/CLMS_20000101T000000_${yday}T000000_swe.grib && rm CLMS_20000101T000000_${yday}T000000_swe.grib
#cdo --eccodes -s -f grb1 copy -setparam,141.128 -setname,sd -mulc,0.001 -selname,swe_var CGLC2_SWE/c_gls_SWE5K_${yday}0000_NHEMI_SSMIS_V*.nc CLMS_${yday:0:4}0101T000000_${yday}T000000_swevar.grib
#grib_set -s centre=86,type=ea CLMS_${yday:0:4}0101T000000_${yday}T000000_swevar.grib grib/CLMS_${yday:0:4}0101T000000_${yday}T000000_swevar.grib && rm CLMS_${yday:0:4}0101T000000_${yday}T000000_swevar.grib

#sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0