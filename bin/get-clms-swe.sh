#!/bin/bash
#=====#################################################################
# NAME:
#		download_swe_ftp_clms.sh
# CALLING SEQUENCE:
# 		./download_swe_ftp_clms.sh $pattern $outpath
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

if [[ $# -eq 2 ]] 
then
    outpath=$2 
    pattern=$1
    mkdir -p $outpath
elif [[ $# -eq 1 ]]
then
    outpath=/home/ubuntu/data/CGLC2_SWE/
    pattern=$1
    mkdir -p $outpath
else
    outpath=/home/ubuntu/data/CGLC2_SWE/
    mkdir -p $outpath
    pattern=*$yday*.nc
fi

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
mget $pattern
close
bye
EOF