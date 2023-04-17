#!/bin/bash
###################
# download Sentinel 3 Synergy data from CreoDIAS, combine and transform to grib for smartmet-server ingestion 
# Mikko Strahlendorff 20.4.2022
###################
eval "$(conda shell.bash hook)"
if [ $# -ne 0 ]
then
    d=${1:6:2}
    m=${1:4:2}
    y=${1:0:4}
fi
cd /home/ubuntu/data
wget -qcO https://mstrahl:Hehe-c3po@datalsasaf.lsasvcs.ipma.pt/PRODUCTS/EPS/EDLST/NETCDF/$y/$d/$m/NETCDF4_LSASAF_M01-AVHR_EDLST-DAY_GLOBE_${1}0000.nc
wget -qcO https://mstrahl:Hehe-c3po@datalsasaf.lsasvcs.ipma.pt/PRODUCTS/EPS/EDLST/NETCDF/$y/$d/$m/NETCDF4_LSASAF_M01-AVHR_EDLST-NIGHT_GLOBE_${1}0000.nc

cdo --eccodes -f grb2 -b P8 setname,skt -selname,LST-day NETCDF4_LSASAF_M01-AVHR_EDLST-DAY_GLOBE_${1}0000.nc LSASAF_${1}T120000_lst-day-gl.grib
cdo --eccodes -f grb2 -b P8 setname,skt -selname,LST-day NETCDF4_LSASAF_M01-AVHR_EDLST-DAY_GLOBE_${1}0000.nc LSASAF_${1}T000000_lst-day-gl.grib
#sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0