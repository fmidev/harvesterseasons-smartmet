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

wget -c --no-check-certificate -r -np -nd -q --user=mstrahl --password='Hehe-c3po' -R '*.html' https://datalsasaf.lsasvcs.ipma.pt/PRODUCTS/EPS/EDLST/NETCDF/$y/$m/$d/ && \
 cdo --eccodes -s -f grb2 -z aec -b P8 setname,skt -selname,LST-day NETCDF4_LSASAF_M01-AVHR_EDLST-DAY_GLOBE_${1}0000.nc grib/LSASAF_${1:0:4}0101T120000_${1}_lst-day-gl.grib && \
  cdo --eccodes -s -f grb2 -z aec -b P8 setname,skt -selname,LST-night NETCDF4_LSASAF_M01-AVHR_EDLST-NIGHT_GLOBE_${1}0000.nc grib/LSASAF_${1:0:4}0101T000000_${1}_lst-night-gl.grib && \
   s3cmd put -Pq NETCDF4_LSASAF_M01-AVHR_EDLST-*_GLOBE_${1}0000.nc s3://copernicus/lsasaf/edlst/ && rm NETCDF4_LSASAF_M01-AVHR_EDLST-*_GLOBE_${1}0000.nc

#sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0
