#!/bin/bash
###################
# download GLDAS data from eodis.nasa, combine and transform to grib for smartmet-server ingestion 
# Mikko Strahlendorff 12.2.2024
###################
eval "$(conda shell.bash hook)"
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
dy=$(date -d $ymd +%j)
cd /home/ubuntu/data/GLDAS

! [ -s GLDAS_NOAH025_3H.A$ymd.1800.021.nc4 ] && \
 wget -c --no-check-certificate -r -np -nd -q -A '*.nc4' https://hydro1.gesdisc.eosdis.nasa.gov/data/GLDAS/GLDAS_NOAH025_3H.2.1/$y/$dy/ && \
 cdo -s -f grb2 -b P15 selname,sd,sde,skt,swvl1,swvl2,swvl3,swvl4,stl1,stl2,stl3,stl4 -aexprf,gldas2ec-soils.instr  \
    [ -mergetime GLDAS_NOAH025_3H.A$ymd.*00.021.nc4 ] ../grib/GLDAS_20000101T000000_${ymd}_noah-gl.grib && \
 s3cmd put -Pq GLDAS_NOAH025_3H.A$ymd.*00.021.nc4 s3://copernicus/gldas/noah/ && rm GLDAS_NOAH025_3H.A$ymd.*00.021.nc4

#sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0
