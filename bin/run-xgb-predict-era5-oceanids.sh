#!/bin/bash
#
# monthly script for XGBoost prediction for OCEANIDS ML in ERA5 grid
# get-seasonal.sh must be run first to get the predictors
# give year, month, and harbor name as cmd
# (AK 2025)
#set -e

source ~/.smart

year=$1
month=$2
harbor=$3
predictand=$4 # WG_PT24H_MAX TA_PT24H_MAX TA_PT24H_MIN TP_PT24H_ACC

grid='era5'
bsf='B2SF'

eval "$(conda shell.bash hook)"

conda activate xgb
TMPDIR=/home/smartmet/data/tmp
cd /home/smartmet/data

echo $year $month $harbor $predictand 

# Read predictors for predictand from JSON config file
#JSON_PRED_FILE="MLmodels/OCEANIDS/${predictand}_training_preds.json"
#predictors00=$(jq -r '.predictors00' "$JSON_PRED_FILE")
#predictorsDSUM=$(jq -r '.predictorsDSUM' "$JSON_PRED_FILE")
#echo $predictors00 $predictorsDSUM

# Read predictors for predictand from JSON config file
#JSON_PRED_FILE="MLmodels/OCEANIDS/training_preds.json"
#predictors00=$(jq -r '.predictors00' "$JSON_PRED_FILE")
#predictorsDSUM=$(jq -r '.predictorsDSUM' "$JSON_PRED_FILE")
#predictorsPL=$(jq -r '.predictorsPL' "$JSON_PRED_FILE")
#echo $predictors00 $predictorsDSUM $predictorsPL

# bbox from config file
JSON_FILE="MLmodels/OCEANIDS/${harbor}_bbox_config.json"
min_lat=$(jq '.min_lat' "$JSON_FILE")
max_lat=$(jq '.max_lat' "$JSON_FILE")
min_lon=$(jq '.min_lon' "$JSON_FILE")
max_lon=$(jq '.max_lon' "$JSON_FILE")
bbox="${min_lon},${max_lon},${min_lat},${max_lat}"
#echo "$bbox"

# bias-adjusted pl 00 850hPa z q t u v kx
[ -f ens/ec-${bsf}_$year${month}_pl-pp-unbound-24h-$abr-50.grib ] && ! [ -f ens/ec-${bsf}_${year}${month}_pl850-pp-${harbor}-50.grib ] && \
seq 0 50 | parallel cdo --eccodes -O -b P8 sellonlatbox,$bbox -selname,z,q,t,u,v,kx -sellevel,85000 ens/ec-${bsf}_$year${month}_pl-pp-unbound-24h-$abr-{}.grib ens/ec-${bsf}_${year}${month}_pl850-pp-${harbor}-{}.grib || echo "NOT remap pl - no input or already produced"

# bias-adjusted unbound (2d,2t,msl,tclw,tcwv,10u,10v) to fitting grid points
[ -s ens/ec-${bsf}_$year${month}_unbound-24h-$abr-50.grib ] && ! [ -s ens/ec-${bsf}_${year}${month}_unbound-${harbor}-50.grib ] && \
seq 0 50 | parallel cdo -b P8 -O --eccodes sellonlatbox,$bbox ens/ec-${bsf}_$year${month}_unbound-24h-$abr-{}.grib ens/ec-${bsf}_${year}${month}_unbound-${harbor}-{}.grib || echo "NOT remap unbound - no input or already produced"

# bias-adjusted mx2t24
[ -s ens/ec-${bsf}_$year${month}_mx2t24-unbound-24h-$abr-50.grib ] && ! [ -s ens/ec-${bsf}_${year}${month}_mx2t24-unbound-${harbor}-50.grib ] && \
seq 0 50 | parallel cdo -b P8 -O --eccodes sellonlatbox,$bbox ens/ec-${bsf}_$year${month}_mx2t24-unbound-24h-$abr-{}.grib ens/ec-${bsf}_${year}${month}_mx2t24-unbound-${harbor}-{}.grib || echo "NOT remap mx2t24 - no input or already produced"

# bias-adjusted mn2t24
[ -s ens/ec-${bsf}_$year${month}_mn2t24-unbound-24h-$abr-50.grib ] && ! [ -s ens/ec-${bsf}_${year}${month}_mn2t24-unbound-${harbor}-50.grib ] && \
seq 0 50 | parallel cdo -b P8 -O --eccodes sellonlatbox,$bbox ens/ec-${bsf}_$year${month}_mn2t24-unbound-24h-$abr-{}.grib ens/ec-${bsf}_${year}${month}_mn2t24-unbound-${harbor}-{}.grib || echo "NOT remap mn2t24 - no input or already produced"

# Instantaneous (10fg,tcc) at 00 UTC to ERA5 grid, and fitting grid points
[ -s ens/ec-sf_${year}${month}_all-24h-eu-50.grib ] && ! [ -s ens/ec-sf_${year}${month}_inst-${harbor}-50.grib ] && \
seq 0 50 | parallel cdo -b P8 -O --eccodes sellonlatbox,$bbox -remap,$grid-$abr-grid,ec-sf-$grid-$abr-weights.nc -selname,10fg,tcc ens/ec-sf_${year}${month}_all-24h-eu-{}.grib ens/ec-sf_${year}${month}_inst-${harbor}-{}.grib || echo "NOT remap sl - no input or already produced"
#echo "Instantaneous parameters at 00 UTC to ERA5 grid, and fitting grid points done"

# bias-adjusted disaccumulated, unbound (sshf,slhf,str,strd,nsss,ewss)
[ -s ens/ec-${bsf}_$year${month}_disacc-24h-$abr-50.grib ] && ! [ -s ens/ec-${bsf}_${year}${month}_dailysums-unbound-${harbor}-50.grib ] && \
seq 0 50 | parallel cdo -b P8 -O --eccodes sellonlatbox,$bbox ens/ec-${bsf}_$year${month}_disacc-24h-$abr-{}.grib ens/ec-${bsf}_${year}${month}_dailysums-unbound-${harbor}-{}.grib || echo "NOT unbound disacc - no input or already produced"
#echo "Disaccumulated daily sums to ERA5 grid, and fitting grid points done"

# Disaccumulated daily sums to ERA5 grid, and fitting grid points
[ -s ens/ec-sf_$year${month}_disacc-${grid}-$abr-50.grib ] && ! [ -s ens/ec-sf_${year}${month}_dailysums-${harbor}-50.grib ] && \
seq 0 50 | parallel cdo -b P8 -O --eccodes sellonlatbox,$bbox -selname,ssr,ssrd,tp,e,ttr ens/ec-sf_$year${month}_disacc-${grid}-$abr-{}.grib ens/ec-sf_${year}${month}_dailysums-${harbor}-{}.grib || echo "NOT remap disacc - no input or already produced"
#echo "Disaccumulated daily sums to ERA5 grid, and fitting grid points done"

# Land-sea mask to ERA5 grid, and fitting grid points
#[ -s ens/lsm_sf_fix_50.grib ] && ! [ -s ens/lsm-fix-${harbor}-50.grib ] && \
#seq 0 50 | parallel cdo -b P8 -O --eccodes sellonlatbox,$bbox -remap,$grid-$abr-grid,ec-sf-$grid-$abr-weights.nc ens/lsm_sf_fix_{}.grib ens/lsm-fix-${harbor}-{}.grib
# shif timesteps to sf timesteps ($year $month)
#[ -s ens/lsm-fix-${harbor}-50.grib ] && ! [ -s ens/lsm-${year}${month}-${harbor}-50.grib ] && \
#seq 0 50 | parallel cdo --eccodes settaxis,${year}-${month}-02,00:00:00,1day ens/lsm-fix-${harbor}-{}.grib ens/lsm-${year}${month}-${harbor}-{}.grib
#echo "Land-sea mask to ERA5 grid, and fitting grid points done"

# input & output files for XGBoost prediction
input1=ens/ec-${bsf}_${year}${month}_pl850-pp-${harbor}-{}.grib
input2=ens/ec-sf_${year}${month}_inst-${harbor}-{}.grib
input3=ens/ec-sf_${year}${month}_dailysums-${harbor}-{}.grib
input4=ens/ec-${bsf}_${year}${month}_unbound-${harbor}-{}.grib
input5=ens/ec-${bsf}_${year}${month}_dailysums-unbound-${harbor}-{}.grib
input6=ens/ec-${bsf}_${year}${month}_mx2t24-unbound-${harbor}-{}.grib
input7=ens/ec-${bsf}_${year}${month}_mn2t24-unbound-${harbor}-{}.grib
#input4=ens/lsm-${year}${month}-${harbor}-{}.grib # lsm omitted from predictors
output=OCEANIDS/ECXSF_${year}${month}_${predictand}_${harbor}-{}.csv

# XGBoost prediction (ouput is XGBoost SF timeseries as a csv file for harbor point location for each ens member)
#[ -s ens/ec-sf_${year}${month}_pl850-pp-${harbor}-50.grib ] && [ -s ens/ec-sf_${year}${month}_inst-${harbor}-50.grib ] && [ -s ens/ec-sf_${year}${month}_dailysums-${harbor}-50.grib ] && ! [ -s OCEANIDS/ECXSF_${year}${month}_${predictand}_${harbor}-50.csv ] && \
    seq 0 50 | parallel python /home/ubuntu/bin/xgb-predict-era5-oceanids.py $input1 $input2 $input3 $input4 $input5 $input6 $input7 {} $predictand $harbor $output || echo "NOT predicting - no input or already produced"

# join csv files (keep datetime in ensmember 0)
[ -s OCEANIDS/ECXSF_${year}${month}_${predictand}_${harbor}-50.csv ] && \
    seq 1 50 | parallel "cut -f2 -d, OCEANIDS/ECXSF_${year}${month}_${predictand}_${harbor}-{}.csv | sed 's:\(.*\),\(.*\):\2 \1:' > OCEANIDS/ECXSF_${year}${month}_${predictand}_${harbor}-{}-fix.csv" && \
    seq 1 50 | parallel rm OCEANIDS/ECXSF_${year}${month}_${predictand}_${harbor}-{}.csv && \
    paste -d ',' OCEANIDS/ECXSF_${year}${month}_${predictand}_${harbor}-*.csv > OCEANIDS/ECXSF_${year}${month}_${predictand}_${harbor}.csv && \
    rm OCEANIDS/ECXSF_${year}${month}_${predictand}_${harbor}-*.csv || echo "NOT joining - no input or already produced"