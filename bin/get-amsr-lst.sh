#!/bin/bash
###################
# download AMSR LST research data from JAXA, combine and transform to grib for smartmet-server ingestion 
# Mikko Strahlendorff 2.2.2024
###################
eval "$(conda shell.bash hook)"
conda activate cdo
if [ $# -ne 0 ]
then
    d=${1:6:2}
    m=${1:4:2}
    y=${1:0:4}
    ymd=$1
else
    d=$(date -d '2 days ago' +%d)
    m=$(date -d '2 days ago' +%m)
    y=$(date -d '2 days ago' +%Y)
    ymd="$y$m$d"
fi
cd /home/ubuntu/data
mkdir -p amsr
if [ ! -s amsr/GW1AM2_${ymd}_01D_EQOA_L3RGLSTHU1100100.h5 ]
then
ftp <<EOF
open ftp.eorc.jaxa.jp
lcd amsr
cd AMSR2/LST/v100/L3/${y}_$m/
newer GW1AM2_${ymd}_01D_EQOD_L3RGLSTHU1100100.h5
newer GW1AM2_${ymd}_01D_EQOA_L3RGLSTHU1100100.h5
close
bye
EOF
fi

if [ ! -s grib/AMSR_20000101T000000_${ymd}_01D_EQOA_L3RGLSTHU1100100.grib ]
then
ncpdq --hdf_upk -P xst_new -v 'Geophysical Data' -a phony_dim_2,phony_dim_0,phony_dim_1 amsr/GW1AM2_${ymd}_01D_EQOA_L3RGLSTHU1100100.h5 amsr/GW1AM2_${ymd}_01D_EQOA_L3RGLSTHU1100100.nc &&\
ncwa -O -a phony_dim_2 amsr/GW1AM2_${ymd}_01D_EQOA_L3RGLSTHU1100100.nc amsr/GW1AM2_${ymd}_01D_EQOA_L3RGLSTHU1100100.nc &&\
ncrename -O -d .phony_dim_2,time -d phony_dim_1,lon -d phony_dim_0,lat amsr/GW1AM2_${ymd}_01D_EQOA_L3RGLSTHU1100100.nc amsr/GW1AM2_${ymd}_01D_EQOA_L3RGLSTHU1100100.nc &&\
cdo -f grb2 -b P15 copy -settime,12:00:00 -setdate,$ymd -setparam,17.0.0 -setgrid,amsr-g-grid -mulc,0.01 -setrtomiss,-32768,-32760 amsr/GW1AM2_${ymd}_01D_EQOA_L3RGLSTHU1100100.nc grib/AMSR_20000101T120000_${ymd}_01D_EQOA_L3RGLSTHU1100100.grib &&\
s3cmd put -Pq amsr/GW1AM2_${ymd}_01D_EQOA_L3RGLSTHU1100100.h5 s3://copernicus/amsr/lst/h5/ &&\
rm amsr/GW1AM2_${ymd}_01D_EQOA_L3RGLSTHU1100100.h5 amsr/GW1AM2_${ymd}_01D_EQOA_L3RGLSTHU1100100.nc
fi
if [ ! -s grib/AMSR_20000101T120000_${ymd}_01D_EQOD_L3RGLSTHU1100100.grib ]
then
ncpdq --hdf_upk -P xst_new -v 'Geophysical Data' -a phony_dim_2,phony_dim_0,phony_dim_1 amsr/GW1AM2_${ymd}_01D_EQOD_L3RGLSTHU1100100.h5 amsr/GW1AM2_${ymd}_01D_EQOD_L3RGLSTHU1100100.nc &&\
ncwa -O -a phony_dim_2 amsr/GW1AM2_${ymd}_01D_EQOD_L3RGLSTHU1100100.nc amsr/GW1AM2_${ymd}_01D_EQOD_L3RGLSTHU1100100.nc &&\
ncrename -O -d .phony_dim_2,time -d phony_dim_1,lon -d phony_dim_0,lat amsr/GW1AM2_${ymd}_01D_EQOD_L3RGLSTHU1100100.nc amsr/GW1AM2_${ymd}_01D_EQOD_L3RGLSTHU1100100.nc &&\
cdo -f grb2 -b P15 copy -settime,00:00:00 -setdate,$ymd -setparam,17.0.0 -setgrid,amsr-g-grid -mulc,0.01 -setrtomiss,-32768,-32760 amsr/GW1AM2_${ymd}_01D_EQOD_L3RGLSTHU1100100.nc grib/AMSR_20000101T000000_${ymd}_01D_EQOD_L3RGLSTHU1100100.grib&&\
s3cmd put -Pq amsr/GW1AM2_${ymd}_01D_EQOD_L3RGLSTHU1100100.h5 s3://copernicus/amsr/lst/h5/ &&\
rm amsr/GW1AM2_${ymd}_01D_EQOD_L3RGLSTHU1100100.h5 amsr/GW1AM2_${ymd}_01D_EQOD_L3RGLSTHU1100100.nc
fi

#sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0
