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
python=/home/ubuntu/mambaforge/envs/xgb/bin/python
if [ $# -ne 0 ]
then
    date=$1
else
    date=$(date -d yesterday +%Y%m%d)
    ## remove previous month files
    tooold=$(date -d "$date 46 days ago" +%Y%m%d)
    rm grib/EDTE_${tooold}T*.grib
fi
tooold=$(date -d "$date 46 days ago" +%Y%m%d)
olddate=$(date -d "$date 16 days ago" +%Y%m%d)
olddam=$(date -d "$date 16 days ago" +%Y-%m-%d)T00:00:00
sdate=$(date -d "$date" +%Y-%m-%d)T00:00:00
edate=$(date -d "$date 4 days" +%Y-%m-%d)T00:00:00
dam1=$(date -d "$date 1 days ago" +%Y%m%d)T000000
dam2=$(date -d "$date 2 days ago" +%Y%m%d)T000000
dam3=$(date -d "$date 3 days ago" +%Y%m%d)T000000
dam4=$(date -d "$date 4 days ago" +%Y%m%d)T000000
dam5=$(date -d "$date 5 days ago" +%Y%m%d)T000000

cd /home/smartmet/data
echo 'fetch 3h variables'
! [ -s grib/EDTE_${date}T000000_sfc-$abr.grib ] &&  \
 sed s:2023-10-10:$date:g ../mars/edte-sfc.mars | /home/smartmet/bin/mars && \
 cdo -P 64 --eccodes -s -O aexprf,ec-sde.instr edte_${date}_sfc-$abr.grib grib/EDTE_${date}T000000_sfc-$abr.grib || echo "EDTE sfc Data already downloaded"
echo 'disaccumulate 24h and shifttime' #,swi-edte-$abr-weights.nc
! [ -s ens/edte_${date}_disacc-$abr.grib ] && cdo -P 64 -s --eccodes -O shifttime,-1d \
 -deltat -selname,e,tp,slhf,sshf,ro,str,strd,ssr,ssrd,sf,skt -seltime,00:00:00 grib/EDTE_${date}T000000_sfc-$abr.grib ens/edte_${date}_disacc-$abr.grib \
 || echo "EDTE sfc Data already disaccumulated"

echo 'fetch fg/24h variables'
! [ -s grib/EDTE_${date}T000000_fg-$abr.grib ] && sed s:2023-10-10:$date:g ../mars/edte-fg.mars | /home/smartmet/bin/mars && \
 mv edte_${date}_fg-$abr.grib grib/EDTE_${date}T000000_fg-$abr.grib || echo "EDTE fg Data already downloaded"
echo 'calculate/remap runsums' #,swi-edte-$abr-weights.nc
! [ -s ens/edte_${date}_runsums-$abr.grib ] && cdo -P 64 --eccodes -S --timestat_date last \
 seldate,$sdate,$edate -runsum,15 -mergetime \
 -remap,edte-$abr-grid,edte-era5l-$abr-weights.nc -shifttime,-1d -selname,e,tp,ro grib/ERA5L_20000101T000000_${olddate:0:6}01T000000_accumulated.grib \
 -shifttime,-1d -seltimestep,5 -selname,e,tp,ro grib/EDTE_${dam5}_sfc-$abr.grib \
 -shifttime,-1d -seltimestep,5 -selname,e,tp,ro grib/EDTE_${dam4}_sfc-$abr.grib \
 -shifttime,-1d -seltimestep,5 -selname,e,tp,ro grib/EDTE_${dam3}_sfc-$abr.grib \
 -shifttime,-1d -seltimestep,5 -selname,e,tp,ro grib/EDTE_${dam2}_sfc-$abr.grib \
 -shifttime,-1d -seltimestep,5 -selname,e,tp,ro grib/EDTE_${dam1}_sfc-$abr.grib \
 -shifttime,-1d -deltat -seltime,00:00:00 -selname,e,tp,ro grib/EDTE_${date}T000000_sfc-$abr.grib ens/edte_${date}_runsums-$abr.grib || echo "EDTE runsum Data already calculated" &

echo 'remap swvls'
[ -s ens/edte_${date}_swvls-$abr.grib ] && echo "EDTE swvls Data already calculated" || \
 cdo -P 64 -s --eccodes seldate,$sdate,$edate -shifttime,-1d -selname,swvl2 -seltime,00:00:00 grib/EDTE_${date}T000000_sfc-$abr.grib \
 ens/edte_${date}_swvls-$abr.grib &

echo 'remap sl00'
[ -s ens/edte_${date}_sl00-$abr.grib ] && echo "EDTE sl00 Data already calculated" || \
 cdo -P 64 -s --eccodes seldate,$sdate,$edate -selname,2d,2t,rsn,sd,sde,stl1,10u,10v -seltime,00:00:00 grib/EDTE_${date}T000000_sfc-$abr.grib \
 ens/edte_${date}_sl00-$abr.grib &
echo 'remap stl2'
 cdo -P 64 -s --eccodes seldate,$sdate,$edate -selname,stl2 -seltime,00:00:00 grib/EDTE_${date}T000000_sfc-$abr.grib \
 ens/edte_${date}_stl2-$abr.grib &

echo 'shift climate dates'
y=$(date -d $date +%Y)
yd=$(echo "$y - 2020" | bc)
[ -s ens/ECC_${date}T000000_laihv-$abr-edte-day.grib ] && echo "EDTE laihv Data already chopped" || \
 cdo -P 64 -s --eccodes -seldate,$sdate,$edate -shifttime,${yd}year grib/ECC_20000101T000000_laihv-$abr-edte-day.grib ens/ECC_${date}T000000_laihv-$abr-edte-day.grib &
[ -s ens/ECC_${date}T000000_lailv-$abr-edte-day.grib ] && echo "EDTE lailv Data already chopped" || \
 cdo -P 64 -s --eccodes -seldate,$sdate,$edate -shifttime,${yd}year grib/ECC_20000101T000000_lailv-$abr-edte-day.grib ens/ECC_${date}T000000_lailv-$abr-edte-day.grib &
[ -s ens/SWIC_${date}T000000_swi-day.grib ] && echo "EDTE SWIC Data already chopped" || \
 cdo -P 64 -s --eccodes -seldate,$sdate,$edate -shifttime,${yd}year grib/SWIC_20000101T000000_2020_2015-2023_swis-ydaymean-eu-edte.grib ens/SWIC_${date}T000000_swi-day.grib &
[ -s ens/LSASAFC_${date}_sktn.grib ] && echo "EDTE LSASAFC Data already chopped" || \
 cdo -P 64 -s --eccodes -seldate,$sdate,$edate -shifttime,${yd}year grib/LSASAFC_20000101T000000_ydmean_nights-eu-de.grib ens/LSASAFC_${date}_sktn.grib &

wait
