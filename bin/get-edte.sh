#!/bin/bash
#
# monthly script for fetching seasonal data from cdsapi, doing bias corrections and
# and setting up data in the smartmet-server, bias adjustment can be done based on ERA5 Land (default) or ERA5
# add era5 as a third attribute on the command line for this and you have to define year and month for this case
#
# 11.10.2023 Mikko Strahlendorff

source ~/.smart

eval "$(conda shell.bash hook)"
conda activate xgb
if [ $# -ne 0 ]
then
    date=$1
    olddate=$(date -d "$1 1 month ago" +%Y%m%d)
    olddam=$(date -d "$1 21 days ago" +%Y-%m-%d)T00:00:00
else
    date=$(date -d yesterday +%Y%m%d)
    ## remove previous month files
    olddate=$(date -d '1 month ago' +%Y%m%d)
    olddam=$(date -d '21 days ago' +%Y-%m-%d)T00:00:00
    rm grib/EDTE_${olddate}T*.grib
fi
sdate=$(date -d "$date" +%Y-%m-%d)T00:00:00
edate=$(date -d "$date 5 days" +%Y-%m-%d)T00:00:00
dam1=$(date -d '2 day ago' +%Y%m%d)T000000
dam2=$(date -d '3 day ago' +%Y%m%d)T000000
dam3=$(date -d '4 day ago' +%Y%m%d)T000000
dam4=$(date -d '5 day ago' +%Y%m%d)T000000
dam5=$(date -d '6 day ago' +%Y-%m-%d)T00:00:00

cd /home/smartmet/data
echo 'fetch 3h variables and disaccumulate'
[ -f grib/EDTE_${date}T000000_sfc-eu.grib ] && echo "EDTE sfc Data already downloaded" || sed s:2023-10-10:$date:g ../mars/edte-sfc.mars | /home/smartmet/bin/mars && \
 mv edte_${date}_sfc-$abr.grib grib/EDTE_${date}T000000_sfc-$abr.grib }
[ -f grib/EDTE_${date}T000000_sfc-eu.grib ] && echo "EDTE sfc Data already downloaded" || cdo -s --eccodes -O remap,swi-eu-grid,swi-edte-eu-weights.nc -mergetime -seltimestep,1 -selname,e,tp,slhf,sshf,ro,str,strd,ssr,ssrd,sf edte_${date}_sfc-$abr.grib \
 -deltat -selname,e,tp,slhf,sshf,ro,str,strd,ssr,ssrd,sf grib/EDTE_${date}T000000_sfc-$abr.grib ens/edte_${date}_disacc-swi.grib
echo 'fetch fg/24h variables'
[ -f grib/EDTE_${date}T000000_fg-eu.grib ] && echo "EDTE fg Data already downloaded" || sed s:2023-10-10:$date:g ../mars/edte-fg.mars | /home/smartmet/bin/mars && \
 mv edte_${date}_fg-$abr.grib grib/EDTE_${date}T000000_fg-eu.grib 
echo 'calculate/remap runsums'
[ -f ens/edte_${date}_runsums-$abr.grib ] && echo "EDTE runsum Data already calculated" || { CDO_TIMESTAT_DATE=last && \
 cdo --eccodes shifttime,-1d -remap,swi-eu-grid,swi-edte-eu-weights.nc -runsum,15 -mergetime -seldate,$olddam,$dam5 [ -mergetime \
 -remap,edte-eu-grid,edte-era5l-eu-weights.nc -selname,e,tp,ro grib/ERA5L_20000101T000000_${olddate:0:6}01T000000_accumulated.grib \
 -remap,edte-eu-grid,edte-era5l-eu-weights.nc -selname,e,tp,ro grib/ERA5L_20000101T000000_${date:0:6}01T000000_accumulated.grib ] \
 -seltimestep,5 -selname,e,tp,ro grib/EDTE_${dam4}_sfc-$abr.grib -seltimestep,5 -selname,e,tp,ro grib/EDTE_${dam3}_sfc-$abr.grib \
 -seltimestep,5 -selname,e,tp,ro grib/EDTE_${dam2}_sfc-$abr.grib -seltimestep,5 -selname,e,tp,ro grib/EDTE_${dam1}_sfc-$abr.grib \
 ens/edte_${date}_runsums-$abr.grib }

echo 'remap swvls'
[ -f ens/edte_${date}_swvls-$abr.grib ] && echo "EDTE swvls Data already calculated" || \
 cdo remap,swi-eu-grid,swi-edte-eu-weights.nc -selname,swvl1,swvl2,swvl3,swvl4 -seltime,00:00:00 grib/EDTE_${date}T000000_sfc-$abr.grib \
 ens/edte_${date}_swvls-$abr.grib

echo 'remap sl00'
[ -f ens/edte_${date}_sl00-$abr.grib ] && echo "EDTE sl00 Data already calculated" || \
 cdo remap,swi-eu-grid,swi-edte-eu-weights.nc -selname,2d,2t,rsn,sde,stl1 -seltime,00:00:00 grib/EDTE_${date}T000000_sfc-$abr.grib \
 ens/edte_${date}_sl00-$abr.grib

echo 'shift climate dates'
y=$(date -d $date +%Y)
yd=$(echo "$y - 2020" | bc)
[ -f ens/ECC_${date}T000000_laihv-eu-swi-day.grib ] && echo "EDTE laihv Data already chopped" || \
 cdo -seldate,$sdate,$edate -shifttime,${yd}year grib/ECC_20000101T000000_2020-21_laihv-eu-swi-day.grib ens/ECC_${date}T000000_laihv-eu-swi-day.grib
[ -f ens/ECC_${date}T000000_lailv-eu-swi-day.grib ] && echo "EDTE lailv Data already chopped" || \
 cdo -seldate,$sdate,$edate -shifttime,${yd}year grib/ECC_20000101T000000_2020-21_lailv-eu-swi-day.grib ens/ECC_${date}T000000_lailv-eu-swi-day.grib
[ -f ens/SWIC_${date}T000000_swi-day.grib ] && echo "EDTE lailv Data already chopped" || \
 cdo -seldate,$sdate,$edate -shifttime,${yd}year grib/SWIC_20000101T000000_2020_2015-2022_swis-ydaymean.grib ens/SWIC_${date}T000000_swi-day.grib

echo 'start xgb predict'
python /home/ubuntu/bin/xgb-predict-swi2-edte.py ens/edte_${date}_swvls-$abr.grib \
 ens/edte_${date}_sl00-$abr.grib ens/edte_${date}_runsums-$abr.grib \
 ens/edte_${date}_disacc-$abr.grib ens/ECC_${date}T000000_laihv-$abr-swi-day.grib \
 ens/ECC_${date}T000000_lailv-$abr-swi-day.grib \
 ens/SWIC_${date}T000000_swi-day.grib \
 ens/EDTE_${date}_swi2_out.nc

echo 'netcdf to grib'
# netcdf to grib
cdo -b 16 -f grb2 copy -setparam,41.228.192 -setmissval,-9.e38 -seltimestep,9/209 ens/EDTE_${date}_swi2_out.nc \
 ens/EDTE_${date}_swi2_out.grib #|| echo "NO input or already netcdf to grib1"

echo 'grib fix'
# fix grib attributes
grib_set -r -s centre=86,productDefinitionTemplateNumber=1,totalNumber=51,number={} ens/EDTE_${date}_swi2_out.grib \
 grib/EDTE_${date}_swi2-eu.grib

#sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0