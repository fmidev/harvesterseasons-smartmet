#!/bin/bash
###################
# download Sentinel 3 Synergy data from CreoDIAS, combine and transform to grib for smartmet-server ingestion 
# Mikko Strahlendorff 20.4.2022
###################
#eval "$(conda shell.bash hook)"
eval "$(/home/ubuntu/mambaforge/bin/conda shell.bash hook)"
conda activate cdo
if [ $# -ne 0 ]
then
    d=${1:6:2}
    m=${1:4:2}
    y=${1:0:4}
    ymd=$1
else
    d=$(date -d yesterday +%d)
    m=$(date -d yesterday +%m)
    y=$(date -d yesterday +%Y)
    ymd="$y$m$d"
fi
cd /home/ubuntu/data/lsasaf
# testing with thredds, but not allowing large enough requests
#trpa=https://thredds.lsasvcs.ipma.pt/thredds/dodsC/EPS/EDLST/NETCDF/$y/$m/$d
wget -c --no-check-certificate -r -np -nd -q -A '*.nc' https://datalsasaf.lsasvcs.ipma.pt/PRODUCTS/EPS/EDLST/NETCDF/$y/$m/$d/ && \
 cdo --eccodes -s -f grb2 -z aec -b P8 setname,skt -selname,LST-day NETCDF4_LSASAF_M01-AVHR_EDLST-DAY_GLOBE_${ymd}0000.nc ../grib/LSASAF_20000101T120000_${ymd}_lst-day-gl.grib && \
  cdo --eccodes -s -f grb2 -z aec -b P8 setname,skt -selname,LST-night NETCDF4_LSASAF_M01-AVHR_EDLST-NIGHT_GLOBE_${ymd}0000.nc ../grib/LSASAF_20000101T000000_${ymd}_lst-night-gl.grib && \
#   s3cmd put -Pq NETCDF4_LSASAF_M01-AVHR_EDLST-*_GLOBE_${ymd}0000.nc s3://copernicus/lsasaf/edlst/ &&\
    rm NETCDF4_LSASAF_M01-AVHR_EDLST-*_GLOBE_${ymd}0000.nc

#sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0
