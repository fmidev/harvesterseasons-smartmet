#!/bin/bash
#
# daily script for XGBoost prediction for SWI2 for ECENS data in ERA5-Land grid 
# give year month day as cmd
# ouput is ECXENS product
# (AK 2025)
eval "$(/home/ubuntu/mambaforge/bin/conda shell.bash hook)"

conda activate xgb
TMPDIR=/home/smartmet/data/tmp
year=$1
month=$2
day=$3

DATE=${year}-${month}-${day}
SWIDATE=$(date -d "$DATE 1 days ago" +%Y-%m-%d)
SWIDATET=$(date -d "$DATE 2 days ago" +%Y%m%d)
SWIDATES=$(date -d "$DATE 1 days ago" +%Y%m%d)
EDATE=$(date -d "$DATE +14 days" +%Y-%m-%d)
echo $DATE $EDATE

cd /home/smartmet/data

abr='nd'
era='era5l'

# laihv lailv swi2clim
echo 'shift laihv lailv swi2clim dates'
! [ -s ec-ens/ECC_${year}${month}${day}T000000_laihv-nd-day.grib ] && ! [ -s ec-ens/ECC_${year}${month}${day}T000000_lailv-nd-day.grib ] && ! [ -s ec-ens/SWIC_${year}${month}${day}T000000_2020_2015-2022_swis-ydaymean-nd-9km-fixed.grib ] && \
    diff=$(($year - 2020)) && \
    cdo -s seldate,$DATE,$EDATE -shifttime,${diff}years -shifttime,-12hour ECC_20000101T000000_laihv-nd-day.grib ec-ens/ECC_${year}${month}${day}T000000_laihv-nd-day.grib && \
    cdo -s seldate,$DATE,$EDATE -shifttime,${diff}years -shifttime,-12hour ECC_20000101T000000_lailv-nd-day.grib ec-ens/ECC_${year}${month}${day}T000000_lailv-nd-day.grib && \
    cdo -s seldate,$DATE,$EDATE -shifttime,${diff}years SWIC_20000101T000000_2020_2015-2022_swis-ydaymean-nd-9km-fixed.grib ec-ens/SWIC_${year}${month}${day}T000000_2020_2015-2022_swis-ydaymean-nd-9km-fixed.grib || echo 'not shifting'
#seldate,$DATE,$EDATE

# fix grib attributes for laihv,lailv and swi2clim
grib_set -r -s jScansPositively=0 ec-ens/ECC_${year}${month}${day}T000000_laihv-nd-day.grib ec-ens/ECC_${year}${month}${day}T000000_laihv-nd-day-fixed.grib
grib_set -r -s jScansPositively=0 ec-ens/ECC_${year}${month}${day}T000000_lailv-nd-day.grib ec-ens/ECC_${year}${month}${day}T000000_lailv-nd-day-fixed.grib
grib_set -r -s jScansPositively=0 ec-ens/SWIC_${year}${month}${day}T000000_2020_2015-2022_swis-ydaymean-nd-9km-fixed.grib ec-ens/SWIC_${year}${month}${day}T000000_2020_2015-2022_swis-ydaymean-nd-9km-fixed-fixed.grib

input1=ec-ens/ensmems/ECENS_${year}${month}${day}T000000_${era}_sfc+sde-nd-{}.grib
input2=ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-disacc-nd-{}.grib
input3=ec-ens/ECC_${year}${month}${day}T000000_laihv-nd-day-fixed.grib
input4=ec-ens/ECC_${year}${month}${day}T000000_lailv-nd-day-fixed.grib
input5=ec-ens/SWIC_${year}${month}${day}T000000_2020_2015-2022_swis-ydaymean-nd-9km-fixed-fixed.grib

output=ec-ens/ECXENS_${year}${month}${day}_swi2_${era}_nd-out-{}.nc

# XGBoost prediction
echo 'start xgb predict'
! [ -s ec-ens/ECXENS_${year}${month}${day}_swi2_${era}_nd-out-50.nc ] && \
 seq 0 50 | parallel --tmpdir /home/ubuntu/data/tmp -j20 python /home/ubuntu/bin/xgb-predict-swi2-${era}-ecens.py $input1 $input2 $input3 $input4 $input5 $output || echo 'not predicting - already done'

# netcdf to grib and remove first/last date (all nan)
echo 'netcdf to grib'
#[ -s ec-ens/ECXENS_${year}${month}${day}_swi2_${era}_nd-out-50.nc ] && ! [ -s ec-ens/ECXENS_${year}${month}${day}_swi2-${era}-nd-out-50.grib ] && \
seq 0 50 | parallel --tmpdir /home/ubuntu/data/tmp cdo -s -b P8 -f grb2 copy -setparam,41.228.192 -setmissval,-9.e38 -delete,timestep=1 -delete,timestep=-1 ec-ens/ECXENS_${year}${month}${day}_swi2_${era}_nd-out-{}.nc ec-ens/ECXENS_${year}${month}${day}_swi2-${era}-nd-out-{}.grib || echo "NO input or already netcdf to grib"

# fix grib attributes
echo 'fix grib attributes'
[ -s ec-ens/ECXENS_${year}${month}${day}_swi2-${era}-nd-out-50.grib ] && ! [ -s ec-ens/ECXENS_${year}${month}${day}_swi2-${era}-nd-out-50-fixed.grib ] && \
seq 0 50 | parallel --tmpdir /home/ubuntu/data/tmp grib_set -r -s edition=1,setLocalDefinition=1,localDefinitionNumber=15,centre=98,totalNumber=51,number={} ec-ens/ECXENS_${year}${month}${day}_swi2-${era}-nd-out-{}.grib ec-ens/ECXENS_${year}${month}${day}_swi2-${era}-nd-out-{}-fixed.grib || echo "NOT fixing swi2 grib attributes - no input or already produced"
#seq 0 50 | parallel --tmpdir /home/ubuntu/data/tmp grib_set -r -s productDefinitionTemplateNumber=11,centre=86,totalNumber=51,number={} ec-ens/ECXENS_${year}${month}${day}_swi2-${era}-nd-out-{}.grib ec-ens/ECXENS_${year}${month}${day}_swi2-${era}-nd-out-{}-fixed.grib || echo "NOT fixing swi2 grib attributes - no input or already produced"

# adjust here the starting SWI2 to the last obs-fc difference and that fc up to this day
 cdo --eccodes sub -remapdis,era5l-nordic-grid -selname,swi2 grib/SWI_20000101T000000_${SWIDATES}T120000_swis.grib \
  -seldate,$SWIDATE -ensmean [ ec-ens/ECXENS_${SWIDATET}_swi2-${era}-nd-out-*-fixed.grib ] \
  ec-ens/ecxens-adjust-${SWIDATES}.grib

# add adjustment to each ens member
seq 0 50 | parallel --tmpdir /home/ubuntu/data/tmp cdo -s add \
 ec-ens/ECXENS_${year}${month}${day}_swi2-${era}-nd-out-{}-fixed.grib  ec-ens/ecxens-adjust-${SWIDATES}.grib \
 ec-ens/ECXENS_${year}${month}${day}_swi2-${era}-nd-out-{}-fixed2.grib || echo "NO input or already adjusted ens members"

# fix grib attributes
echo 'fix grib attributes'
[ -s ec-ens/ECXENS_${year}${month}${day}_swi2-${era}-nd-out-50-fixed2.grib ] && ! [ -s ec-ens/ECXENS_${year}${month}${day}_swi2-${era}-nd-out-50-fixed3.grib ] && \
seq 0 50 | parallel --tmpdir /home/ubuntu/data/tmp grib_set -r -s edition=1,setLocalDefinition=1,localDefinitionNumber=15,centre=98,totalNumber=51,number={} ec-ens/ECXENS_${year}${month}${day}_swi2-${era}-nd-out-{}-fixed2.grib ec-ens/ECXENS_${year}${month}${day}_swi2-${era}-nd-out-{}-fixed3.grib || echo "NOT fixing swi2 grib attributes - no input or already produced"
#seq 0 50 | parallel --tmpdir /home/ubuntu/data/tmp grib_set -r -s productDefinitionTemplateNumber=11,centre=86,totalNumber=51,number={} ec-ens/ECXENS_${year}${month}${day}_swi2-${era}-nd-out-{}.grib ec-ens/ECXENS_${year}${month}${day}_swi2-${era}-nd-out-{}-fixed.grib || echo "NOT fixing swi2 grib attributes - no input or already produced"

# join ensemble members and move to grib folder
echo 'join ensemble members and move to grib folder'
[ -s ec-ens/ECXENS_${year}${month}${day}_swi2-${era}-nd-out-50-fixed2.grib ] && ! [ -s grib/ECXENS_${year}${month}${day}T000000_swi2-${era}-nd.grib ] && \
 grib_copy ec-ens/ECXENS_${year}${month}${day}_swi2-${era}-nd-out-*-fixed3.grib grib/ECXENS_${year}${month}${day}T000000_swi2-${era}-nd.grib \
 || echo "NOT joining ens members - no input or already done"

echo 'done'
#wait 

echo 'add to smartmet server'
sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0