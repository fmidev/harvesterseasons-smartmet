#!/bin/bash
#
# daily script for XGBoost prediction for SWI2 for ECENS data in ERA5-Land grid 
# give year month day as cmd
# ouput is ECXENS product
# (AK 2025)
eval "$(conda shell.bash hook)"

conda activate xgb
TMPDIR=/home/smartmet/data/tmp
year=$1
month=$2
day=$3

DATE=${year}-${month}-${day}
EDATE=$(date -d "$DATE +14 days" +%Y-%m-%d)
echo $DATE $EDATE

cd /home/smartmet/data

abr='nd'
era='era5l'

# separete swvl2 from swvls (easier to read in in xarray)
echo 'separate swvl2 from swvls'
[ -s ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-swvls-nd-50.grib ] && ! [ -s ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-swvl2-nd-50.grib ] && \
 seq 0 50 | parallel --tmpdir /home/ubuntu/data/tmp cdo -b P12 -O --eccodes \
 selname,swvl2 ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-swvls-nd-{}.grib ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-swvl2-nd-{}.grib \
|| echo 'not swvl2 - already done or no input files'

# laihv lailv swi2clim
echo 'shift laihv lailv swi2clim dates'
! [ -s ec-ens/ECC_${year}${month}${day}T000000_laihv-nd-day.grib ] && ! [ -s ec-ens/ECC_${year}${month}${day}T000000_lailv-nd-day.grib ] && ! [ -s ec-ens/SWIC_${year}${month}${day}T000000_2020_2015-2022_swis-ydaymean-nd-9km-fixed.grib ] && \
    diff=$(($year - 2020)) && \
    cdo seldate,$DATE,$EDATE -shifttime,${diff}years -shifttime,-12hour ECC_20000101T000000_laihv-nd-day.grib ec-ens/ECC_${year}${month}${day}T000000_laihv-nd-day.grib && \
    cdo seldate,$DATE,$EDATE -shifttime,${diff}years -shifttime,-12hour ECC_20000101T000000_lailv-nd-day.grib ec-ens/ECC_${year}${month}${day}T000000_lailv-nd-day.grib && \
    cdo seldate,$DATE,$EDATE -shifttime,${diff}years SWIC_20000101T000000_2020_2015-2022_swis-ydaymean-nd-9km-fixed.grib ec-ens/SWIC_${year}${month}${day}T000000_2020_2015-2022_swis-ydaymean-nd-9km-fixed.grib || echo 'not shifting'
#seldate,$DATE,$EDATE


# 2t/2d/stl1/rsn/sde
input1=ec-ens/ensmems/ECENS_${year}${month}${day}T000000_${era}_sfc-all+sde-nd-{}.grib
# swvl2
input2=ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-swvl2-nd-{}.grib
# e,tp,slhf,sshf,ro,str,strd,ssr,ssrd,sf
input3=ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-disacc-nd-{}.grib
# laihv
input4=ec-ens/ECC_${year}${month}${day}T000000_laihv-nd-day.grib
#lailv
input5=ec-ens/ECC_${year}${month}${day}T000000_lailv-nd-day.grib
# swi2clim
input6=ec-ens/SWIC_${year}${month}${day}T000000_2020_2015-2022_swis-ydaymean-nd-9km-fixed.grib

output=ec-ens/ECXENS_${year}${month}${day}_swi2_${era}_nd-out-{}.nc

# XGBoost prediction
echo 'start xgb predict'
! [ -s ec-ens/ECXENS_${year}${month}${day}_swi2_${era}_nd-out-50.nc ] && \
 seq 0 0 | parallel --tmpdir /home/ubuntu/data/tmp -j20 python /home/ubuntu/bin/xgb-predict-swi2-${era}-ecens.py $input1 $input2 $input3 $input4 $input5 $input6 $output || echo 'not predicting - already done'

# netcdf to grib
echo 'netcdf to grib'
[ -s ec-ens/ECXENS_${year}${month}${day}_swi2_${era}_nd-out-50.nc ] && ! [ -s ec-ens/ECXENS_${year}${month}${day}_swi2-${era}-nd-out-50.grib ] && seq 0 50 | parallel --tmpdir /home/ubuntu/data/tmp cdo -b 16 -f grb2 copy -setparam,41.228.192 -setmissval,-9.e38 ec-ens/ECXENS_${year}${month}${day}_swi2_${era}_nd-out-{}.nc ec-ens/ECXENS_${year}${month}${day}_swi2-${era}-nd-out-{}.grib || echo "NO input or already netcdf to grib"

# fix grib attributes
echo 'fix grib attributes'
[ -s ec-ens/ECXENS_${year}${month}${day}_swi2-${era}-nd-out-50.grib ] && ! [ -s ec-ens/ECXENS_${year}${month}${day}_swi2-${era}-nd-out-50-fixed.grib ] && seq 0 50 | parallel --tmpdir /home/ubuntu/data/tmp grib_set -r -s centre=86,productDefinitionTemplateNumber=1,totalNumber=51,number={} ec-ens/ECXENS_${year}${month}${day}_swi2-${era}-nd-out-{}.grib ec-ens/ECXENS_${year}${month}${day}_swi2-${era}-nd-out-{}-fixed.grib || echo "NOT fixing swi2 grib attributes - no input or already produced"

# join ensemble members and move to grib folder
echo 'join ensemble members and move to grib folder'
[ -s ec-ens/ECXENS_${year}${month}${day}_swi2-${era}-nd-out-50-fixed.grib ] && ! [ -s grib/ECXENS_${year}${month}${day}T000000_swi2-${era}-nd.grib ] && grib_copy ec-ens/ECXENS_${year}${month}${day}_swi2-${era}-nd-out-*-fixed.grib grib/ECXENS_${year}${month}${day}T000000_swi2-${era}-nd.grib || echo "NOT joining ens members - no input or already done"

echo 'done'
#wait 
