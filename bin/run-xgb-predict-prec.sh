#!/bin/bash
#
# monthly script for XGBoost prediction for precipitation in ERA5 grid
# give year month as cmd

source ~/.smart
eval "$(conda shell.bash hook)"

conda activate xgb

year=$1
month=$2

cd /home/smartmet/data

grid='era5'
bsf='B2SF'

echo $year $month $grid

conda activate xgb

# remap to era5
### pl 00 z q t u v kx
[ -f ens/ec-sf_$year${month}_pl-pp-12h-$abr-50.grib ] && ! [ -f ens/ec-sf-${grid}_$year${month}_pl-pp-12h-$abr-50.grib ] && \
seq 0 50 | parallel cdo --eccodes -O -b P12 \
    remap,$grid-$abr-grid,ec-sf-$grid-$abr-weights.nc -sellevel,85000,70000,50000 -selname,t,q,z,u,v,kx ens/ec-sf_$year${month}_pl-pp-12h-$abr-{}.grib \
    ens/ec-sf-${grid}_$year${month}_pl-pp-12h-$abr-{}.grib || echo "NOT remap pl - no input or already produced"
### sl 00 10u,10v,2d,2t,msl,tcc,sd,rsn,mx2t24,mn2t24
[ -f ens/ec-sf_$year${month}_all-24h-$abr-50.grib ] && ! [ -f ens/ec-sf-${grid}_$year${month}_all-24h-$abr-50.grib ] && \
seq 0 50 | parallel cdo --eccodes -O -b P12 \
    remap,$grid-$abr-grid,ec-sf-$grid-$abr-weights.nc -selname,10u,10v,2d,2t,msl,tcc,sd,rsn,mx2t24,mn2t24 ens/ec-sf_$year${month}_all-24h-$abr-{}.grib \
    ens/ec-sf-${grid}_$year${month}_all-24h-$abr-{}.grib || echo "NOT remap sl - no input or already produced"
### disacc tp,e,slhf,sshf,ro,str,strd,ssr,ssrd,sf,tsr,ttr
[ -f ens/disacc-$year${month}-50.grib ] && ! [ -f ens/ec-sf-${grid}_$year${month}_disacc-$abr-50.grib ] && \
seq 0 50 | parallel cdo --eccodes -O -b P12 \
    remap,$grid-$abr-grid,ec-sf-$grid-$abr-weights.nc ens/disacc-$year${month}-{}.grib \
    ens/ec-sf-${grid}_$year${month}_disacc-$abr-{}.grib || echo "NOT remap disacc - no input or already produced"

# era5 orography XGB-era5-orography-200001-eu.grib
diff=$(( ($year - 2000) * 12 + (10#$month - 10#1) ))
[ -f XGB-${grid}-orography-200001-${abr}.grib ] && ! [ -f ens/$grid-orography-$year${month}-$abr.grib ] && \
cdo shifttime,${diff}months XGB-${grid}-orography-200001-${abr}.grib ens/$grid-orography-$year${month}-$abr.grib  || echo "NOT current date era5 orography - no input or already produced" 

echo 'start prediction'
[ -f ens/ec-sf-${grid}_$year${month}_pl-pp-12h-$abr-50.grib ] && [ -f ens/ec-sf-${grid}_$year${month}_all-24h-$abr-50.grib ] && [ -f ens/$grid-orography-$year${month}-$abr.grib ] && [ -f ens/ec-sf-${grid}_$year${month}_disacc-$abr-50.grib ] && ! [ -f ens/ECX${bsf}_$year${month}_tp-$abr-disacc-50.nc ] && \
seq 0 50 | parallel -j5 python3 /home/ubuntu/bin/xgb-predict-prec.py ens/ec-sf-${grid}_$year${month}_disacc-$abr-{}.grib ens/ec-sf-${grid}_$year${month}_pl-pp-12h-$abr-{}.grib ens/ec-sf-${grid}_$year${month}_all-24h-$abr-{}.grib ens/$grid-orography-$year${month}-$abr.grib ens/ECX${bsf}_$year${month}_tp-$abr-disacc-{}.nc || echo "NO input or already produced GB files"

# tp netcdf to grib 
[ -f ens/ECX${bsf}_$year${month}_tp-$abr-disacc-50.nc ] && ! [ -f ens/ECX${bsf}_$year${month}_tp-$abr-disacc-50.grib ] && \
seq 0 50 | parallel cdo -b 16 -f grb copy -setparam,128.228 -setmissval,-9.e38 ens/ECX${bsf}_$year${month}_tp-$abr-disacc-{}.nc ens/ECX${bsf}_$year${month}_tp-$abr-disacc-{}.grib || echo "NO input or already netcdf to grib1"

# tp disacc to accumulated
[ -f ens/ECX${bsf}_$year${month}_tp-$abr-disacc-50.grib ] && ! [ -f ens/ECX${bsf}_$year${month}_tp-acc-$abr-50.grib ] && \
seq 0 50 | parallel cdo -s --eccodes -b P8 timcumsum ens/ECX${bsf}_$year${month}_tp-$abr-disacc-{}.grib ens/ECX${bsf}_$year${month}_tp-acc-$abr-{}.grib || echo "NOT adj xgb-acc - input missing or already produced"

# fix grib attributes for tp and pl-pp 
[ -f ens/ECX${bsf}_$year${month}_tp-acc-$abr-50.grib ] && ! [ -f ens/ECX${bsf}_$year${month}_tp-acc-$abr-50-fixed.grib ] && \
seq 0 50 | parallel grib_set -r -s table2Version=128,indicatorOfParameter=228,centre=98,setLocalDefinition=1,localDefinitionNumber=15,totalNumber=51,number={} ens/ECX${bsf}_$year${month}_tp-acc-$abr-{}.grib \
ens/ECX${bsf}_$year${month}_tp-acc-$abr-{}-fixed.grib || echo "NOT fixing tp grib attributes - no input or already produced"
    
# join ensemble members
[ -f ens/ECX${bsf}_$year${month}_tp-acc-$abr-50-fixed.grib  ] && ! [ -f grib/ECX${bsf}_$year${month}01T000000_tp-acc-$abr.grib  ] && \
grib_copy ens/ECX${bsf}_$year${month}_tp-acc-$abr-*-fixed.grib grib/ECX${bsf}_$year${month}01T000000_tp-acc-$abr.grib || echo "NOT joining tp ensemble members - no input or already produced"

