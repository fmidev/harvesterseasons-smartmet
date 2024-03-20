#!/bin/bash
###################
# download SMOS data from FMI, combine and transform to grib for smartmet-server ingestion 
# Mikko Strahlendorff 28.11.2023
###################
#eval "$(conda shell.bash hook)"
eval "$(/home/ubuntu/mambaforge/bin/conda shell.bash hook)"
conda activate cdo
if [ $# -ne 0 ]
then
    if [ $# -gt 1 ]
    then
     or=$2
    else
     or=o_v301
    fi
    d=${1:6:2}
    m=${1:4:2}
    y=${1:0:4}
    ymd=$1
else
    or=o
    d=$(date -d yesterday +%d)
    m=$(date -d yesterday +%m)
    y=$(date -d yesterday +%Y)
    ymd="$y$m$d"
fi
cd /home/ubuntu/data
echo "fetching $ymd $2 $or"
wget -c --no-check-certificate -q https://litdb.fmi.fi/outgoing/SMOS-FTService/OperationalFT/$y/$m/W_XX-ESA,SMOS,NH_25KM_EASE2_${ymd}_${or}_01_l3soilft.nc && \
 cdo -f grb2 -b P8 -setdate,$y-$m-$d -remapdis,era5-eu-grid -setgrid,ease2-nh-grid -selname,slta -aexpr,'slta=(QF_asc > QF_dsc)?L3FT_asc:L3FT_dsc' \
  W_XX-ESA,SMOS,NH_25KM_EASE2_${ymd}_${or}_01_l3soilft.nc grib/SMOS_20000101T000000_${ymd}_ft-day-eu.grib && \
  rm W_XX-ESA,SMOS,NH_25KM_EASE2_${ymd}_${or}_01_l3soilft.nc || echo "download or processing failed"

#sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0
