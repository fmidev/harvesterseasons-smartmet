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
predictand=$4

grid='era5'
bsf='B2SF'

eval "$(conda shell.bash hook)"

conda activate xgb
TMPDIR=/home/smartmet/data/tmp
cd /home/smartmet/data

echo $year $month $harbor $predictand 

# bbox from config file
JSON_FILE="MLmodels/OCEANIDS/${harbor}_bbox_config.json"
min_lat=$(jq '.min_lat' "$JSON_FILE")
max_lat=$(jq '.max_lat' "$JSON_FILE")
min_lon=$(jq '.min_lon' "$JSON_FILE")
max_lon=$(jq '.max_lon' "$JSON_FILE")
bbox="${min_lon},${max_lon},${min_lat},${max_lat}"
echo "$bbox"

# single level data (bias adjusted for most vars)
[ -s ens/ec-${bsf}_$year${month}_bias_sl-all-$abr-50-fix.grib ] && ! [ -s ens/ec-${bsf}_${year}${month}_bias_sl-all-${harbor}-50.grib ] && \
seq 0 50 | parallel cdo --eccodes -O -b P8 sellonlatbox,$bbox ens/ec-${bsf}_$year${month}_bias_sl-all-$abr-{}-fix.grib ens/ec-${bsf}_${year}${month}_bias_sl-all-${harbor}-{}.grib || echo "NOT remap sl to harbor - no input or already produced"

# bias-adjusted pl 00 850hPa z q t u v kx
[ -f ens/ec-${bsf}_$year${month}_bias_pl-all-$abr-50-fix.grib ] && ! [ -f ens/ec-${bsf}_${year}${month}_pl850-pp-${harbor}-50.grib ] && \
seq 0 50 | parallel cdo --eccodes -O -b P8 sellonlatbox,$bbox -selname,z,q,t,u,v,kx -sellevel,85000 ens/ec-${bsf}_$year${month}_bias_pl-all-$abr-{}-fix.grib ens/ec-${bsf}_${year}${month}_pl850-pp-${harbor}-{}.grib || echo "NOT remap pl to harbor - no input or already produced"

# fix gribs 
seq 0 50 | parallel grib_set -r -s jScansPositively=0 ens/ec-${bsf}_${year}${month}_bias_sl-all-${harbor}-{}.grib ens/ec-${bsf}_${year}${month}_bias_sl-all-${harbor}-{}-fix.grib || echo "NOT fixing unbound pl-pp gribs attributes - no input or already produced"
seq 0 50 | parallel grib_set -r -s jScansPositively=0 ens/ec-${bsf}_${year}${month}_pl850-pp-${harbor}-{}.grib ens/ec-${bsf}_${year}${month}_pl850-pp-${harbor}-{}-fix.grib || echo "NOT fixing unbound pl-pp gribs attributes - no input or already produced"


# Land-sea mask to ERA5 grid, and fitting grid points
#[ -s ens/lsm_sf_fix_50.grib ] && ! [ -s ens/lsm-fix-${harbor}-50.grib ] && \
#seq 0 50 | parallel cdo -b P8 -O --eccodes sellonlatbox,$bbox -remap,$grid-$abr-grid,ec-sf-$grid-$abr-weights.nc ens/lsm_sf_fix_{}.grib ens/lsm-fix-${harbor}-{}.grib
# shif timesteps to sf timesteps ($year $month)
#[ -s ens/lsm-fix-${harbor}-50.grib ] && ! [ -s ens/lsm-${year}${month}-${harbor}-50.grib ] && \
#seq 0 50 | parallel cdo --eccodes settaxis,${year}-${month}-02,00:00:00,1day ens/lsm-fix-${harbor}-{}.grib ens/lsm-${year}${month}-${harbor}-{}.grib
#echo "Land-sea mask to ERA5 grid, and fitting grid points done"

input1=ens/ec-${bsf}_${year}${month}_bias_sl-all-${harbor}-{}-fix.grib
input2=ens/ec-${bsf}_${year}${month}_pl850-pp-${harbor}-{}-fix.grib
#input3=ens/lsm-${year}${month}-${harbor}-{}.grib # lsm omitted from predictors
output=OCEANIDS/ens/ECXSF_${year}${month}_${predictand}_${harbor}-{}.csv

# XGBoost prediction (ouput is XGBoost SF timeseries as a csv file for harbor point location for each ens member)
[ -s ens/ec-${bsf}_${year}${month}_bias_sl-all-${harbor}-50-fix.grib ] && [ -s ens/ec-${bsf}_${year}${month}_pl850-pp-${harbor}-50-fix.grib ] &&  ! [ -s OCEANIDS/ECXSF_${year}${month}_${predictand}_${harbor}.csv ] && \
seq 0 50 | parallel python /home/ubuntu/bin/xgb-predict-oceanids.py $input1 $input2 {} $predictand $harbor $output || echo "NOT predicting - no input or already produced"

# join csv files (keep datetime in ensmember 0)
[ -s OCEANIDS/ens/ECXSF_${year}${month}_${predictand}_${harbor}-50.csv ] && \
    seq 1 50 | parallel "cut -f2 -d, OCEANIDS/ens/ECXSF_${year}${month}_${predictand}_${harbor}-{}.csv | sed 's:\(.*\),\(.*\):\2 \1:' > OCEANIDS/ens/ECXSF_${year}${month}_${predictand}_${harbor}-{}-fix.csv" && \
    seq 1 50 | parallel rm OCEANIDS/ens/ECXSF_${year}${month}_${predictand}_${harbor}-{}.csv && \
    paste -d ',' OCEANIDS/ens/ECXSF_${year}${month}_${predictand}_${harbor}-*.csv > OCEANIDS/ECXSF_${year}${month}_${predictand}_${harbor}.csv && \
    rm OCEANIDS/ens/ECXSF_${year}${month}_${predictand}_${harbor}-*.csv || echo "NOT joining - no input or already produced"