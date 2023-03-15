#!/bin/bash
###################
# download Sentinel 3 Synergy data from WEkEO, combine and transform to grib for smartmet-server ingestion 
# Mikko Strahlendorff 12.3.2023
###################
#eval "$(conda shell.bash hook)"
#conda activate xr
if [ $# -ne 0 ]
then
    d=$1
    e=$(date -d "$d 9 days" +%Y%m%d)
else
    d=$(date -d '9 days ago' +%Y%m%d)
    d=${d:0:-1}1
    e=$(date -d "$d 9 days" +%Y%m%d)
fi
if [ ${d:6:2} == "21" ] 
then 
    e=${e:0:6}`date -d "${e:4:2}/1 + 1 month - 1 day" +%d`
fi
echo $e
sdate="${d:0:4}-${d:4:2}-${d:6:2}"
edate="${e:0:4}-${e:4:2}-${e:6:2}"
cd /home/smartmet/data/sen3
hda-S3-V10.py $sdate $edate
cd ..
parallel cdo -s -O -f grb2 -b P12 ensmean -{1} sen3/S3A_SY_2_V10____${d}T*_{\2}_*.SEN3/'{=1 s:.*selname,:: =}'.nc\
 -{1} sen3/S3B_SY_2_V10____${d}T*_{\2}_*.SEN3/'{=1 s:.*selname,:: =}'.nc\
 sen3/S3SY_${d:0:4}0101T000000_${e}T000000_'{=1 s:.*selname,:: =}'_{\2}.grib :::: sen3/sen3codes.lst ::: EUROPE AFRICA NORTH_AMERICA NORTH_ASIA WEST_ASIA\
  && rm -rf S3?_SY_2_V10____*.SEN3

parallel grib_set -r -s centre=97,dataDate=$e sen3/S3SY_${d:0:4}0101T000000_${e}T000000_{\1}_{\2}.grib\
 grib/S3SY_${d:0:4}0101T000000_${e}T000000_97_{\1}_{\2}.grib ::: B0 B2 B3 MIR NDVI ::: EUROPE AFRICA NORTH_AMERICA NORTH_ASIA WEST_ASIA\
  && rm sen3/S3SY_${d:0:4}0101T000000_${e}T000000_[BMN]*.grib

#sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0