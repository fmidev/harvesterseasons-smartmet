#!/bin/bash
#
# XGBoost bias-adjusting and downscaling for seasonal forecast data from ECMWF
# First tried method lost spread in ensemble, let's try another approach
# 1. calculate ensemble mean
# 2. run xgboost on ensemble mean
# 3. calculate difference of each original member to ensemble mean
# 4. add the difference to xgboost prediction
# (AK 2025)

#source ~/.smart
abr='nd'
area='3,33,53,73' # nordic domain
era='era5'

#eval "$(conda shell.bash hook)"
eval "$(/home/ubuntu/mambaforge/bin/conda shell.bash hook)"
cd /home/smartmet/data

# give year month or else use current
if [ $# -ne 0 ]
then
    year=$1
    month=$2
else
    year=2025 #$(date +%Y)
    month=02 #$(date +%m)
fi
eyear=$(date -d "$year${month}01 7 months" +%Y)
emonth=$(date -d "$year${month}01 7 months" +%m)

xsf='XSF'
era='era5'

target='2t'

echo "$xsf $era y: $year m: $month ending $eyear-$emonth area: $area abr: $abr"

slsf=ec-sf-202502-all-24h-eu.grib
plsf=ec-sf-202502-pl-12h-eu.grib

slpreds=2t,2d,10u,10v,10fg,tp,e,rsn,mx2t24,mn2t24,msl,slhf,sshf,ssr,str,strd,tcc
plpreds=z,q,v,u,t
target=2t

# split sl/pl to ensemble members
[ -s ens/ec-sf-202502-all-24h-eu-50.grib ] && echo "Ensemble member sl files ready" || grib_copy ec-sf-202502-all-24h-eu.grib ens/ec-sf-202502-all-24h-eu-[number].grib
[ -s ens/ec-sf-202502-pl-12h-eu-50.grib ] && echo "Ensemble member pl files ready" || grib_copy ec-sf-202502-pl-12h-eu.grib ens/ec-sf-202502-pl-12h-eu-[number].grib

# remap to era5 grid, and choose pl 850 and 925 hPa
[ -s ens/ec-sf-202502-all-24h-eu-50.grib ] && ! [ -s ens/ec-sf-${era}-202502-all-24h-eu-50.grib ] && \
 seq 0 50 | parallel cdo -s -b P8 -O --eccodes -remap,$era-eu-grid,ec-sf-$era-eu-weights.nc -selname,${slpreds} ens/ec-sf-202502-all-24h-eu-{}.grib ens/ec-sf-${era}-202502-all-24h-eu-{}.grib || echo "NOT remap sl - seasonal forecast input missing or already produced"
[ -s ens/ec-sf-202502-pl-12h-eu-50.grib ] && ! [ -s ens/ec-sf-${era}-202502-pl-12h-eu-50.grib ] && \
 seq 0 50 | parallel cdo -s -b P8 -O --eccodes -remap,$era-eu-grid,ec-sf-$era-eu-weights.nc -selhour,0 -sellevel,85000,92500 ens/ec-sf-202502-pl-12h-eu-50.grib ens/ec-sf-${era}-202502-pl-12h-eu-{}.grib || echo "NOT remap pl - seasonal forecast input missing or already produced"

# select Nordic domain
[ -s ens/ec-sf-${era}-202502-all-24h-eu-50.grib ] && ! [ -s ens/ec-sf-${era}-202502_all-24h-$abr-50.grib ] && \
seq 0 50 | parallel cdo -s -b P8 -O --eccodes sellonlatbox,${area} ens/ec-sf-${era}-202502-all-24h-eu-{}.grib ens/ec-sf-${era}-202502_all-24h-$abr-{}.grib || echo "NOT selecting area sl - seasonal forecast input missing or already produced"
[ -s ens/ec-sf-${era}-202502-pl-12h-eu-50.grib ] && ! [ -s ens/ec-sf-${era}-202502_pl-12h-$abr-50.grib ] && \
seq 0 50 | parallel cdo -s -b P8 -O --eccodes sellonlatbox,${area} ens/ec-sf-${era}-202502-pl-12h-eu-{}.grib ens/ec-sf-${era}-202502_pl-12h-$abr-{}.grib || echo "NOT selecting area pl - seasonal forecast input missing or already produced"

# fix grids
[ -s ens/ec-sf-${era}-202502_all-24h-$abr-50.grib ] && ! [ -s ens/ec-sf-${era}-202502_all-24h-$abr-50-fix.grib ] && \
seq 0 50 | parallel grib_set -r -s jScansPositively=0 ens/ec-sf-${era}-202502_all-24h-$abr-{}.grib ens/ec-sf-${era}-202502_all-24h-$abr-{}-fix.grib || echo "NOT fixing sl gribs attributes - already produced or no input"
[ -s ens/ec-sf-${era}-202502_pl-12h-$abr-50.grib ] && ! [ -s ens/ec-sf-${era}-202502_pl-12h-$abr-50-fix.grib ] && \
seq 0 50 | parallel grib_set -r -s jScansPositively=0 ens/ec-sf-${era}-202502_pl-12h-$abr-{}.grib ens/ec-sf-${era}-202502_pl-12h-$abr-{}-fix.grib || echo "NOT fixing pl gribs attributes - already produced or no input"

# calculate ensemble mean
[ -s ens/ec-sf-${era}-202502_all-24h-$abr-50-fix.grib ] && ! [ -s ens/ec-sf-${era}-202502_all-24h-$abr-ensmean.grib ] && \
cdo -s -b P8 -O --eccodes ensmean ens/ec-sf-${era}-202502_all-24h-$abr-*-fix.grib ens/ec-sf-${era}-202502_all-24h-$abr-ensmean.grib || echo "NOT calculating sl ensemble mean - already produced or no input"
[ -s ens/ec-sf-${era}-202502_pl-12h-$abr-50-fix.grib ] && ! [ -s ens/ec-sf-${era}-202502_pl-12h-$abr-ensmean.grib ] && \
cdo -s -b P8 -O --eccodes ensmean ens/ec-sf-${era}-202502_pl-12h-$abr-*-fix.grib ens/ec-sf-${era}-202502_pl-12h-$abr-ensmean.grib ||

# calculate difference of each member to ensemble mean
[ -s ens/ec-sf-${era}-202502_all-24h-$abr-50-fix.grib ] && [ -s ens/ec-sf-${era}-202502_all-24h-$abr-ensmean.grib ] && ! [ -s ens/ec-sf-${era}-202502_all-24h-$abr-diff-50.grib ] && \
seq 0 50 | parallel cdo -s -b P8 -O --eccodes sub ens/ec-sf-${era}-202502_all-24h-$abr-{}.grib ens/ec-sf-${era}-202502_all-24h-$abr-ensmean.grib ens/ec-sf-${era}-202502_all-24h-$abr-diff-{}.grib || echo "NOT calculating sl difference to ensemble mean - already produced or no input"
[ -s ens/ec-sf-${era}-202502_pl-12h-$abr-50-fix.grib ] && [ -s ens/ec-sf-${era}-202502_pl-12h-$abr-ensmean.grib ] && ! [ -s ens/ec-sf-${era}-202502_pl-12h-$abr-diff-50.grib ] && \
seq 0 50 | parallel cdo -s -b P8 -O --eccodes sub ens/ec-sf-${era}-202502_pl-12h-$abr-{}.grib ens/ec-sf-${era}-202502_pl-12h-$abr-ensmean.grib ens/ec-sf-${era}-202502_pl-12h-$abr-diff-{}.grib || echo "NOT calculating pl difference to ensemble mean - already produced or no input"

# era5 orography
# difference in months
diff=$(( ($year - 2000) * 12 + (10#$month - 10#1) ))
# this will cast warning if not leap year but can just be ignored
[ -s XGB-${era}-orography-200001-eu.grib ] && ! [ -s ens/$era-orography-$year${month}-$abr.grib ] && \
cdo -s -b P8 -O --eccodes shifttime,${diff}months XGB-${era}-orography-200001-eu.grib ens/$era-orography-$year${month}-$abr.grib || echo "NOT current date era5 orography - no input or already produced"
[ -s ens/$era-orography-$year${month}-$abr.grib ] && ! [ -s ens/$era-orography-$year${month}-$abr-fix.grib ] && \
cdo -s -b P8 -O --eccodes sellonlatbox,${area} ens/$era-orography-$year${month}-$abr.grib ens/$era-orography-$year${month}-$abr-fix.grib || echo "NOT selecting area orography - no input or already produced"

input1=ens/ec-sf-${era}-202502_all-24h-$abr-ensmean.grib #ens/ec-sf-${era}-202502_all-24h-$abr-{}-fix.grib
input2=ens/ec-sf-${era}-202502_pl-12h-$abr-ensmean.grib #ens/ec-sf-${era}-202502_pl-12h-$abr-{}-fix.grib
input3=ens/$era-orography-$year${month}-$abr-fix.grib
output=ens/EC${xsf}_202502_${target}_${abr}-ensmean.nc # ens/EC${xsf}_202502_${target}_${abr}-{}.nc

# xgboost
conda activate xgb
[ -s $input1 ] && [ -s $input2 ] && [ -s $input3 ] && ! [ -s $output ] && \
python /home/ubuntu/bin/xgb-predict-bias.py $input1 $input2 $input3 $target $output || echo "NOT predicting - no input or already produced"
#seq 0 50 | parallel -j15 python /home/ubuntu/bin/xgb-predict-bias.py $input1 $input2 $input3 {} $target $output || echo "NOT predicting - no input or already produced"

cdo -b 16 -f grb copy -setparam,167.128 -setmissval,-9.e38 $output ens/EC${xsf}_$year${month}_${target}-$abr-ensmean.grib
grib_set -r -s table2Version=128,indicatorOfParameter=167,jScansPositively=0 ens/EC${xsf}_$year${month}_${target}-$abr-ensmean.grib ens/EC${xsf}_$year${month}_${target}-$abr-ensmean-fix.grib

# add ensemble mean difference to xgboost ensemble mean prediction
seq 0 50 | parallel cdo -s -b P8 -O --eccodes add ens/EC${xsf}_202502_${target}-${abr}-ensmean-fix.grib -selname,2t ens/ec-sf-${era}-202502_all-24h-$abr-diff-{}.grib ens/EC${xsf}_202502_${target}_${abr}-diffadded-{}.grib || echo "NOT adding difference to xgboost prediction - no input or already produced"  

seq 0 50 | parallel grib_set -r -s table2Version=128,indicatorOfParameter=167,jScansPositively=0,centre=98,setLocalDefinition=1,localDefinitionNumber=15,totalNumber=51,number={} ens/EC${xsf}_$year${month}_${target}_$abr-diffadded-{}.grib ens/EC${xsf}_$year${month}_${target}-$abr-{}-fixed.grib

grib_copy ens/EC${xsf}_$year${month}_${target}-$abr-*-fixed.grib grib/EC${xsf}_$year${month}01T000000_${target}-$abr.grib || echo "NOT joining ensemble members - no input or already produced"

#sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0