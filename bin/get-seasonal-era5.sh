#!/bin/bash
#
# Monthly script for fetching seasonal data from cdsapi, doing bias corrections.
# Bias adjustments done based on ERA5 reanalysis. 
# XGBoost downscaling for OCEANIDS project.
# (AK 2025)

source ~/.smart

#eval "$(conda shell.bash hook)"
eval "$(/home/ubuntu/mambaforge/bin/conda shell.bash hook)"
cd /home/smartmet/data

# give year month or else use current
if [ $# -ne 0 ]
then
    year=$1
    month=$2
else
    year=$(date +%Y)
    month=$(date +%m)
fi
eyear=$(date -d "$year${month}01 7 months" +%Y)
emonth=$(date -d "$year${month}01 7 months" +%m)

bsf='B2SF'
era='era5'

echo "$bsf $era y: $year m: $month ending $eyear-$emonth area: $area abr: $abr"

## Fetch seasonal data from CDS-API
[ -s ec-sf-$year$month-all-24h-$abr.grib ] && echo "SF Data file already downloaded" || /home/smartmet/bin/cds-sf-all-24h.py $year $month $area $abr
[ -s ec-sf-$year$month-pl-12h-$abr.grib ] && echo "SF pressurelevel Data already downloaded" || /home/smartmet/bin/cds-sf-pl-12h.py $year $month $area $abr

# split sl/pl to ensemble members
[ -s ens/ec-sf_$year${month}_all-24h-$abr-50.grib ] && echo "Ensemble member sl files ready" || \
    grib_copy ec-sf-$year$month-all-24h-$abr.grib ens/ec-sf_$year${month}_all-24h-$abr-[number].grib
[ -s ens/ec-sf_$year${month}_pl-12h-$abr-50.grib ] && echo "Ensemble member pl files ready" || \
    grib_copy ec-sf-$year$month-pl-12h-$abr.grib ens/ec-sf_$year${month}_pl-12h-$abr-[number].grib

# remap to era5 grid
[ -s ens/ec-sf_$year${month}_all-24h-$abr-50.grib ] && ! [ -s ens/ec-${bsf}_$year${month}_all-24h-$abr-50.grib ] && \
 seq 0 50 | parallel cdo -s -b P8 -O --eccodes -remap,$era-$abr-grid,ec-sf-$era-$abr-weights.nc ens/ec-sf_$year${month}_all-24h-$abr-{}.grib ens/ec-${bsf}_$year${month}_all-24h-$abr-{}.grib || echo "NOT remap sl - seasonal forecast input missing or already produced"
[ -s ens/ec-sf_$year${month}_pl-12h-$abr-50.grib ] && ! [ -s ens/ec-${bsf}_$year${month}_pl-12h-$abr-50.grib ] && \
 seq 0 50 | parallel cdo -s -b P8 -O --eccodes -remap,$era-$abr-grid,ec-sf-$era-$abr-weights.nc ens/ec-sf_$year${month}_pl-12h-$abr-50.grib ens/ec-${bsf}_$year${month}_pl-12h-$abr-{}.grib || echo "NOT remap pl - seasonal forecast input missing or already produced"

# BIAS ADJUSTMENS - single level data

# adjust unbound variables (2d,2t,msl,tcc,tclw,tcwv,u10,v10)
[ -s ens/ec-${bsf}_$year${month}_all-24h-$abr-50.grib ] && ! [ -s ens/ec-${bsf}_$year${month}_unbound-$abr-50.grib ] && \
 seq 0 50 | parallel cdo -s -b P8 -O --eccodes ymonadd \
    -selname,2d,2t,msl,tclw,tcwv,10u,10v ens/ec-${bsf}_$year${month}_all-24h-$abr-{}.grib \
    -selname,2d,2t,msl,tclw,tcwv,10u,10v $era/$era-ecsf_1995-2024_unbound-bias-$abr.grib \
    ens/ec-${bsf}_$year${month}_unbound-$abr-{}.grib || echo "NOT adj unbound - seasonal forecast input missing or already produced"

# calc wind (ws) + relative humidity (r) from unbound adjusted variables (2d,2t,10u,10v)
[ -s ens/ec-${bsf}_$year${month}_unbound-$abr-50.grib ] && ! [ -s ens/ec-${bsf}_$year${month}_bound-$abr-50.grib ] && \
    seq 0 50 | parallel -q cdo -s -b P8 -O --eccodes selname,ws,r \
        -aexpr,"ws=sqrt(10u^2+10v^2);r=100*exp((17.625*2d)/(243.04+2d)-(17.625*2t)/(243.04+2t));" \
        -selname,10u,10v,2d,2t ens/ec-${bsf}_$year${month}_unbound-$abr-{}.grib \
        ens/ec-${bsf}_$year${month}_bound-$abr-{}.grib || echo "NOT adj windspeed+relative humidity - seasonal forecast input missing or already produced"

# create disacc file from accumulated variables (tp,e,slhf,sshf,ro,str,strd,ssr,ssrd,sf,tsr,ttr,ewss,nsss)
[ -s ens/ec-${bsf}_$year${month}_all-24h-$abr-50.grib ] && ! [ -s ens/ec-${bsf}_$year${month}_disacc-all-$abr-50.grib ] && \
 seq 0 50 | parallel "cdo -s --eccodes -O mergetime -seltimestep,1 -selname,e,tp,slhf,sshf,ro,str,strd,ssr,ssrd,sf,tsr,ttr,ewss,nsss ens/ec-${bsf}_$year${month}_all-24h-$abr-{}.grib \
     -deltat -selname,e,tp,slhf,sshf,ro,str,strd,ssr,ssrd,sf,tsr,ttr,ewss,nsss ens/ec-${bsf}_$year${month}_all-24h-$abr-{}.grib ens/ec-${bsf}_$year${month}_disacc-all-$abr-{}.grib" || echo "NOT disacc - seasonal forecast input missing or already produced"

# adjust unbound disacc variables (slhf, sshf, str, strd, ewss, nsss)
[ -s ens/ec-${bsf}_$year${month}_disacc-all-$abr-50.grib ] && ! [ -s ens/ec-${bsf}_$year${month}_disacc-unbound-$abr-50.grib ] && \
 seq 0 50 | parallel "cdo -s --eccodes ymonmul -selname,sshf,slhf,str,strd,ewss,nsss ens/ec-${bsf}_$year${month}_disacc-all-$abr-{}.grib \
     -selname,sshf,slhf,str,strd,ewss,nsss $era/$era-ecsf_1995-2024_unbound-bias-$abr.grib \
     ens/ec-${bsf}_$year${month}_disacc-unbound-$abr-{}.grib" || echo "NOT adj unbound disacc - seasonal forecast input missing or already produced" 

# adjust mn2t24
[ -s ens/ec-${bsf}_$year${month}_all-24h-$abr-50.grib ] && ! [ -s ens/ec-${bsf}_$year${month}_mn2t24-unbound-24h-$abr-50.grib ] && \
 seq 0 50 | parallel cdo -s -b P8 -O --eccodes ymonadd \
    -selname,mn2t24 ens/ec-${bsf}_$year${month}_all-24h-$abr-{}.grib \
    -selname,mn2t24 $era/$era-ecsf_2000-2024_mn2t24_unbound-bias-$abr.grib \
    ens/ec-${bsf}_$year${month}_mn2t24-unbound-24h-$abr-{}.grib || echo "NOT adj mn2t24 - seasonal forecast input missing or already produced"

# adjust mx2t24
[ -s ens/ec-${bsf}_$year${month}_all-24h-$abr-50.grib ] && ! [ -s ens/ec-${bsf}_$year${month}_mx2t24-unbound-24h-$abr-50.grib ] && \
 seq 0 50 | parallel cdo -s -b P8 -O --eccodes ymonadd \
    -selname,mx2t24 ens/ec-${bsf}_$year${month}_all-24h-$abr-{}.grib \
    -selname,mx2t24 $era/$era-ecsf_2000-2024_mx2t24_unbound-bias-$abr.grib \
    ens/ec-${bsf}_$year${month}_mx2t24-unbound-24h-$abr-{}.grib || echo "NOT adj mx2t24 - seasonal forecast input missing or already produced"

# merge single level files to reduce number of files to work with
! [ -s ens/ec-${bsf}_$year${month}_bias_sl-all-$abr-50.grib ] && \
seq 0 50 | parallel cdo -s -b P8 -O --eccodes merge \
    -selname,e,tp,ssr,ssrd,ttr ens/ec-${bsf}_$year${month}_disacc-all-$abr-{}.grib \
    -selname,10fg,tcc ens/ec-${bsf}_${year}${month}_all-24h-eu-{}.grib \
    ens/ec-${bsf}_$year${month}_unbound-$abr-{}.grib \
    ens/ec-${bsf}_$year${month}_bound-$abr-{}.grib \
    ens/ec-${bsf}_$year${month}_disacc-unbound-$abr-{}.grib \
    ens/ec-${bsf}_$year${month}_mn2t24-unbound-24h-$abr-{}.grib \
    ens/ec-${bsf}_$year${month}_mx2t24-unbound-24h-$abr-{}.grib ens/ec-${bsf}_$year${month}_bias_sl-all-$abr-{}.grib || echo "NOT merging sl - input missing or already produced"

# fix grib coordinates for single level data
[ -s ens/ec-${bsf}_$year${month}_bias_sl-all-$abr-50.grib ] && ! [ -s ens/ec-${bsf}_$year${month}_bias_sl-all-$abr-50-fix.grib ] && \
seq 0 50 | parallel grib_set -r -s jScansPositively=0 ens/ec-${bsf}_$year${month}_bias_sl-all-$abr-{}.grib ens/ec-${bsf}_$year${month}_bias_sl-all-$abr-{}-fix.grib || echo "NOT fixing sl gribs attributes - already produced or no input"

# BIAS ADJUSTMENS - pressure level data

# adjust pressure level data
[ -s ens/ec-${bsf}_$year${month}_pl-12h-$abr-50.grib ] && ! [ -s ens/ec-${bsf}_$year${month}_pl-unbound-24h-$abr-50.grib ] && \
 seq 0 50 | parallel cdo -s --eccodes ymonadd \
    -selname,z,q,v,u,t -selhour,0 -sellevel,50000,70000,85000 ens/ec-${bsf}_$year${month}_pl-12h-$abr-{}.grib \
    -selname,z,q,v,u,t $era/$era-ecsf_1995-2024_pl_unbound-bias-$abr.grib \
    ens/ec-${bsf}_$year${month}_pl-unbound-24h-$abr-{}.grib || echo "NOT adj pl - seasonal forecast input missing or already produced"

# add K index to (non-adjusted) pressure level data - values too high from adjusted
[ -s ens/ec-${bsf}_$year${month}_pl-12h-$abr-50.grib ] && ! [ -s ens/ec-${bsf}_$year${month}_pl-pp-12h-$abr-50.grib ] && \
seq 0 50 | parallel -q cdo --eccodes -O -b P12 selhour,0 \
        -aexpr,'kx=sellevel(t,85000)-sellevel(t,50000)+sellevel(dpt,85000)-(sellevel(t,70000)-sellevel(dpt,70000));' \
        -aexpr,'dpt=log(vp/6.112)*243.5/(17.67-log(vp/6.112));' -aexpr,'ws=sqrt(u^2+v^2);' \
    -aexpr,'wdir=180+180/3.14159265*2*atan(v/(sqr(u^2+v^2)+u));' \
        -aexpr,'vp=clev(q)*q/(0.622+0.378*q);' ens/ec-${bsf}_$year${month}_pl-12h-$abr-{}.grib ens/ec-${bsf}_$year${month}_pl-pp-12h-$abr-{}.grib || \
 echo "NOT adding kx to pressure level - no input or already produced"

# merge
! [ -s ens/ec-${bsf}_$year${month}_bias_pl-all-$abr-50.grib ] && \
seq 0 50 | parallel cdo -s -b P8 -O --eccodes merge \
    -selname,kx ens/ec-${bsf}_$year${month}_pl-pp-12h-$abr-{}.grib \
    -sellevel,85000 ens/ec-${bsf}_$year${month}_pl-unbound-24h-$abr-{}.grib \
    ens/ec-${bsf}_$year${month}_bias_pl-all-$abr-{}.grib || echo "NOT merging pl - input missing or already produced"

# fix grib coordinates for pressure level data
[ -s ens/ec-${bsf}_$year${month}_bias_pl-all-$abr-50.grib ] && ! [ -s ens/ec-${bsf}_$year${month}_bias_pl-all-$abr-50-fix.grib ] && \
seq 0 50 | parallel grib_set -r -s jScansPositively=0 ens/ec-${bsf}_$year${month}_bias_pl-all-$abr-{}.grib ens/ec-${bsf}_$year${month}_bias_pl-all-$abr-{}-fix.grib || echo "NOT fixing unbound pl-pp gribs attributes - no input or already produced"

# xgboost for oceanids
cd /home/ubuntu/bin
parallel -j1 ./run-xgb-predict-oceanids.sh $year $month {\1} {\2} :::: harbors.txt :::: predictands.txt

#sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0