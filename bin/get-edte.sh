#!/bin/bash
#
# monthly script for fetching seasonal data from cdsapi, doing bias corrections and
# and setting up data in the smartmet-server, bias adjustment can be done based on ERA5 Land (default) or ERA5
# add era5 as a third attribute on the command line for this and you have to define year and month for this case
#
# 11.10.2023 Mikko Strahlendorff

source ~/.smart

#eval "$(conda shell.bash hook)"
eval "$(/home/ubuntu/mambaforge/bin/conda shell.bash hook)"

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
# poly-edte-sfc.mars $date && \
# cdo -P 64 --eccodes -s -O aexprf,ec-sde.instr -remapnn,edte-eu-grid edte_${date}_sfc-$abr.grib grib/EDTE_${date}T000000_sfc-$abr.grib || echo "EDTE sfc Data already downloaded"
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
 -remap,edte-$abr-grid,edte-era5l-$abr-weights.nc -shifttime,-1d -selname,e,tp,ro grib/ERA5LD_20000101T000000_${olddate:0:6}01T000000_accumulated.grib \
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
 cdo -P 64 -s --eccodes aexprf,ec-sde.instr -seldate,$sdate,$edate -selname,2d,2t,rsn,sd,sde,stl1,10u,10v -seltime,00:00:00 grib/EDTE_${date}T000000_sfc-$abr.grib \
 ens/edte_${date}_sl00-$abr.grib &
echo 'remap stl2'
[ -s ens/edte_${date}_stl2-$abr.grib ] && echo "EDTE sl00 Data already calculated" || \
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
[ -s ens/edte_${date}_AMSRC_skt.grib ] && echo "EDTE AMSRC skt 00 UTC data already chopped" || \
 cdo -P 64 -s --eccodes -seldate,$sdate,$edate -shifttime,${yd}year grib/AMSRC_20000101T000000_2013-2023_daymean-skt-edte-eu.grib ens/edte_${date}_AMSRC_skt.grib &
[ -s ens/CLMSC_${date}_clmsc.grib ] && echo "EDTE CLMSC Data already chopped" || \
cdo -P 64 -s --eccodes -seldate,$sdate,$edate -shifttime,${yd}year grib/CLMSC_20000101T000000_2006-23_swe-edte.grib ens/CLMSC_${date}clmsc.grib &

wait
echo 'start xgb predict soil wetness'
[ -s ens/EDTE_${date}_swi2_out.nc ] && echo "EDTE swi2 Data already calculated" || \
$python /home/ubuntu/bin/xgb-predict-swi2-edte.py ens/edte_${date}_swvls-$abr.grib \
 ens/edte_${date}_sl00-$abr.grib ens/edte_${date}_runsums-$abr.grib \
 ens/edte_${date}_disacc-$abr.grib ens/ECC_${date}T000000_laihv-$abr-edte-day.grib \
 ens/ECC_${date}T000000_lailv-$abr-edte-day.grib \
 ens/SWIC_${date}T000000_swi-day.grib \
 ens/EDTE_${date}_swi2_out.nc

echo 'netcdf to grib'
# netcdf to grib
[ -s ens/EDTE_${date}_swi2_out.grib ] && echo "EDTE swi2 Data already reformatted" || \
 cdo -P 64 -b 16 -f grb2 copy -setparam,41.228.192 -setmissval,-9.e38 ens/EDTE_${date}_swi2_out.nc \
 ens/EDTE_${date}_swi2_out.grib 

echo 'grib fix'
# fix grib attributes
[ -s grib/EDTE_${date}T000000_swi2-$abr.grib ] && echo "EDTE swi2 Data already fixed" || \
grib_set -r -s centre=86,jScansPositively=1 ens/EDTE_${date}_swi2_out.grib grib/EDTE_${date}T000000_swi2-$abr.grib

echo 'start xgb predict soil temp'
# calc soil temp 
[ -s ens/EDTE_${date}_stl1_out.nc ] && echo "EDTE stl1 Data already calculated" || \
$python /home/ubuntu/bin/xgb-predict-soiltemp-edte.py ens/edte_${date}_swvls-$abr.grib \
  ens/edte_${date}_sl00-$abr.grib ens/edte_${date}_disacc-$abr.grib ens/LSASAFC_${date}_sktn.grib ens/ECC_${date}T000000_laihv-$abr-edte-day.grib \
  ens/ECC_${date}T000000_lailv-$abr-edte-day.grib ens/edte_${date}_stl2-$abr.grib ens/edte_${date}_AMSRC_skt.grib ens/EDTE_${date}_stl1_out.nc  
echo 'netcdf to grib'
# netcdf to grib
[ -s ens/EDTE_${date}_stl1_out.grib ] && echo "EDTE stl1 Data already reformatted" || \
cdo -P 64 -b 16 -f grb2 copy -setparam,139.174.192 -setmissval,-9.e38 ens/EDTE_${date}_stl1_out.nc \
 ens/EDTE_${date}_stl1_out.grib #|| echo "NO input or already netcdf to grib1"
echo 'grib fix'
# fix grib attributes
[ -s grib/EDTE_${date}T000000_stl1-$abr.grib ] && echo "EDTE stl1 Data already fixed" || \
grib_set -r -s centre=86,jScansPositively=1 ens/EDTE_${date}_stl1_out.grib grib/EDTE_${date}T000000_stl1-$abr.grib

echo 'start xgb predict snow depth'
# calc snow depth
[ -s ens/EDTE_${date}_sd_out.nc ] && echo "EDTE sd Data already calculated" || \
$python /home/ubuntu/bin/xgb-predict-snowdepth-edte.py ens/edte_${date}_swvls-$abr.grib \
  ens/edte_${date}_sl00-$abr.grib ens/edte_${date}_disacc-$abr.grib ens/ECC_${date}T000000_laihv-$abr-edte-day.grib \
  ens/ECC_${date}T000000_lailv-$abr-edte-day.grib ens/CLMSC_${date}clmsc.grib ens/EDTE_${date}_sd_out.nc 
echo 'netcdf to grib'
# netcdf to grib
[ -s ens/EDTE_${date}_sd_out.grib ] && echo "EDTE sd Data already reformatted" || \
cdo -P 64 -b 16 -f grb2 copy -setparam,11.1.0 -setmissval,-9.e38 ens/EDTE_${date}_sd_out.nc \
 ens/EDTE_${date}_sd_out.grib #|| echo "NO input or already netcdf to grib1"
echo 'grib fix'
# fix grib attributes
[ -s grib/EDTE_${date}T000000_sd-$abr.grib ] && echo "EDTE sd Data already fixed" || \
grib_set -r -s centre=86,jScansPositively=1,typeOfFirstFixedSurface=1 ens/EDTE_${date}_sd_out.grib grib/EDTE_${date}T000000_hsnow-$abr.grib

#sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0
