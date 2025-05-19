#!/bin/bash
#
# Monthly script for fetching seasonal data from cdsapi, doing bias corrections,
# and setting up data in the Smartmet-server.
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
[ -s ec-sf-$year$month-all-24h-$abr.grib ] && echo "SF Data file alreakdy downloaded" || /home/smartmet/bin/cds-sf-all-24h.py $year $month $area $abr
[ -s ec-sf-$year$month-pl-12h-$abr.grib ] && echo "SF pressurelevel Data already downloaded" || /home/smartmet/bin/cds-sf-pl-12h.py $year $month $area $abr

# split sl/pl to ensemble members
[ -s ens/ec-sf_$year${month}_all-24h-$abr-50.grib ] && echo "Ensemble member sl files ready" || \
    grib_copy ec-sf-$year$month-all-24h-$abr.grib ens/ec-sf_$year${month}_all-24h-$abr-[number].grib
[ -s ens/ec-sf_$year${month}_pl-12h-$abr-50.grib ] && echo "Ensemble member pl files ready" || \
    grib_copy ec-sf-$year$month-pl-12h-$abr.grib ens/ec-sf_$year${month}_pl-12h-$abr-[number].grib

# BIAS ADJUSTMENS

# adjust unbound variables (2d,2t,msl,tcc,tclw,tcwv,u10,v10)
[ -s ens/ec-sf_$year${month}_all-24h-$abr-50.grib ] && ! [ -s ens/ec-${bsf}_$year${month}_unbound-24h-$abr-50.grib ] && \
 seq 0 50 | parallel cdo -s -b P8 -O --eccodes ymonadd \
    -remap,$era-$abr-grid,ec-sf-$era-$abr-weights.nc -selname,2d,2t,msl,tclw,tcwv,10u,10v ens/ec-sf_$year${month}_all-24h-$abr-{}.grib \
    -selname,2d,2t,msl,tclw,tcwv,10u,10v $era/$era-ecsf_1995-2024_unbound-bias-$abr.grib \
    ens/ec-${bsf}_$year${month}_unbound-24h-$abr-{}.grib || echo "NOT adj unbound - seasonal forecast input missing or already produced"

# calc wind (10fg) + relative humidity from unbound adjusted variables (2d,2t,10u,10v)
[ -s ens/ec-sf_$year${month}_unbound-24h-$abr-50.grib ] && ! [ -s ens/ec-${bsf}_$year${month}_bound-24h-$abr-50.grib ] && \
    seq 0 50 | parallel -q cdo -s -b P8 -O --eccodes selname,ws,rh\
        -aexpr,"ws=sqrt(10u^2+10v^2);rh=100*exp((17.625*2d)/(243.04+2d)-(17.625*2t)/(243.04+2t));" \
        -selname,10u,10v,2d,2t ens/ec-${bsf}_$year${month}_unbound-24h-$abr-{}.grib \
        ens/ec-${bsf}_$year${month}_bound-24h-$abr-{}.grib || echo "NOT adj windspeed+rh - seasonal forecast input missing or already produced"

# create disacc file from accumulated variables (tp,e,slhf,sshf,ro,str,strd,ssr,ssrd,sf,tsr,ttr,ewss,nsss)
[ -s ens/ec-sf_$year${month}_all-24h-$abr-50.grib ] && ! [ -s ens/ec-${bsf}_$year${month}_disacc-$abr-50.grib ] && \
 seq 0 50 | parallel "cdo -s --eccodes -O remap,$era-$abr-grid,ec-sf-$era-$abr-weights.nc -mergetime -seltimestep,1 -selname,e,tp,slhf,sshf,ro,str,strd,ssr,ssrd,sf,tsr,ttr,ewss,nsss ens/ec-sf_$year${month}_all-24h-$abr-{}.grib \
     -deltat -selname,e,tp,slhf,sshf,ro,str,strd,ssr,ssrd,sf,tsr,ttr,ewss,nsss ens/ec-sf_$year${month}_all-24h-$abr-{}.grib ens/ec-${bsf}_$year${month}_disacc-$abr-{}.grib" || echo "NOT disacc - seasonal forecast input missing or already produced"

# adjust unbound disacc variables (slhf, sshf, str, strd, ewss, nsss)
[ -s ens/ec-${bsf}_$year${month}_disacc-$abr-50.grib ] && ! [ -s ens/ec-${bsf}_$year${month}_disacc-24h-$abr-50.grib ] && \
 seq 0 50 | parallel "cdo -s --eccodes ymonmul -selname,sshf,slhf,str,strd,ewss,nsss ens/ec-${bsf}_$year${month}_disacc-$abr-{}.grib \
     -selname,sshf,slhf,str,strd,ewss,nsss $era/$era-ecsf_1995-2024_unbound-bias-$abr.grib \
     ens/ec-${bsf}_$year${month}_disacc-24h-$abr-{}.grib" || echo "NOT adj unbound disacc - seasonal forecast input missing or already produced" 

# adjust pressure level data
[ -s ens/ec-sf_$year${month}_pl-12h-$abr-50.grib ] && ! [ -s ens/ec-${bsf}_$year${month}_pl-unbound-24h-$abr-50.grib ] && \
 seq 0 50 | parallel cdo -s --eccodes ymonadd \
    -remap,$era-$abr-grid,ec-sf-$era-$abr-weights.nc -selname,z,q,v,u,t -selhour,0 -sellevel,50000,70000,85000 ens/ec-sf_$year${month}_pl-12h-$abr-{}.grib \
    -selname,z,q,v,u,t $era/$era-ecsf_1995-2024_pl_unbound-bias-$abr.grib \
    ens/ec-${bsf}_$year${month}_pl-unbound-24h-$abr-{}.grib || echo "NOT adj pl - seasonal forecast input missing or already produced"

# add K index to adjusted pressure level data
[ -s ens/ec-${bsf}_$year${month}_pl-unbound-24h-$abr-50.grib ] && ! [ -s ens/ec-${bsf}_$year${month}_pl-pp-unbound-24h-$abr-50.grib ] && \
seq 0 50 | parallel -q cdo --eccodes -O -b P12 \
        aexpr,'kx=sellevel(t,85000)-sellevel(t,50000)+sellevel(dpt,85000)-(sellevel(t,70000)-sellevel(dpt,70000));' \
        -aexpr,'dpt=log(vp/6.112)*243.5/(17.67-log(vp/6.112));' -aexpr,'ws=sqrt(u^2+v^2);' \
    -aexpr,'wdir=180+180/3.14159265*2*atan(v/(sqr(u^2+v^2)+u));' \
        -aexpr,'vp=clev(q)*q/(0.622+0.378*q);' ens/ec-${bsf}_$year${month}_pl-unbound-24h-$abr-{}.grib ens/ec-${bsf}_$year${month}_pl-pp-unbound-24h-$abr-{}.grib || \
 echo "NOT adding kx to ECSF pressure level - no input or already produced"

# adjust mn2t24
[ -s ens/ec-sf_$year${month}_all-24h-$abr-50.grib ] && ! [ -s ens/ec-${bsf}_$year${month}_mn2t24-unbound-24h-$abr-50.grib ] && \
 seq 0 50 | parallel cdo -s -b P8 -O --eccodes ymonadd \
    -remap,$era-$abr-grid,ec-sf-$era-$abr-weights.nc -selname,mn2t24 ens/ec-sf_$year${month}_all-24h-$abr-{}.grib \
    -selname,mn2t24 $era/$era-ecsf_2000-2024_mn2t24_unbound-bias-$abr.grib \
    ens/ec-${bsf}_$year${month}_mn2t24-unbound-24h-$abr-{}.grib || echo "NOT adj mn2t24 - seasonal forecast input missing or already produced"

# adjust mx2t24
[ -s ens/ec-sf_$year${month}_all-24h-$abr-50.grib ] && ! [ -s ens/ec-${bsf}_$year${month}_mx2t24-unbound-24h-$abr-50.grib ] && \
 seq 0 50 | parallel cdo -s -b P8 -O --eccodes ymonadd \
    -remap,$era-$abr-grid,ec-sf-$era-$abr-weights.nc -selname,mx2t24 ens/ec-sf_$year${month}_all-24h-$abr-{}.grib \
    -selname,mx2t24 $era/$era-ecsf_2000-2024_mx2t24_unbound-bias-$abr.grib \
    ens/ec-${bsf}_$year${month}_mx2t24-unbound-24h-$abr-{}.grib || echo "NOT adj mx2t24 - seasonal forecast input missing or already produced"

#[ -s  ] && ! [ -s ens/ec-${bsf}_$year${month}_acc-24h-$abr-50.grib ] && \
# seq 0 50 | parallel "cdo -s --eccodes ymonmul -selname,e,tp ens/disacc_$year${month}_{}.grib \
#     -selname,e,tp $era/$era-ecsf_2000-2019_bound_bias_$abr.grib \
#     ens/ec-${bsf}_$year${month}_disacc-24h-$abr-{}.grib && \
#    cdo -s --eccodes -b P8 timcumsum ens/ec-${bsf}_$year${month}_disacc-24h-$abr-{}.grib ens/ec-${bsf}_$year${month}_acc-24h-$abr-{}.grib" || echo "NOT adj acc - seasonal forecast input missing or already produced"
# adjust tp,e variables

# fix grib coordinates
# unbound
[ -s ens/ec-${bsf}_$year${month}_unbound-24h-$abr-50.grib ] && ! [ -s ens/ec-${bsf}_$year${month}_unbound-24h-$abr-50-fix.grib ] && \
seq 0 50 | parallel grib_set -r -s jScansPositively=0 ens/ec-${bsf}_$year${month}_unbound-24h-$abr-{}.grib ens/ec-${bsf}_$year${month}_unbound-24h-$abr-{}-fix.grib || echo "NOT fixing unbound gribs attributes - no input or already produced"
# bound
[ -s ens/ec-${bsf}_$year${month}_bound-24h-$abr-50.grib ] && ! [ -s ens/ec-${bsf}_$year${month}_bound-24h-$abr-50-fix.grib ] && \
seq 0 50 | parallel grib_set -r -s jScansPositively=0 ens/ec-${bsf}_$year${month}_bound-24h-$abr-{}.grib ens/ec-${bsf}_$year${month}_bound-24h-$abr-{}-fix.grib || echo "NOT fixing bound gribs attributes - no input or already produced"
# disacc
[ -s ens/ec-${bsf}_$year${month}_disacc-$abr-50.grib ] && ! [ -s ens/ec-${bsf}_$year${month}_disacc-$abr-50-fix.grib ] && \
seq 0 50 | parallel grib_set -r -s jScansPositively=0 ens/ec-${bsf}_$year${month}_disacc-$abr-{}.grib ens/ec-${bsf}_$year${month}_disacc-$abr-{}-fix.grib || echo "NOT fixing disacc gribs attributes - no input or already produced"
# unbound disacc
[ -s ens/ec-${bsf}_$year${month}_disacc-24h-$abr-50.grib ] && ! [ -s ens/ec-${bsf}_$year${month}_disacc-24h-$abr-50-fix.grib ] && \
seq 0 50 | parallel grib_set -r -s jScansPositively=0 ens/ec-${bsf}_$year${month}_disacc-24h-$abr-{}.grib ens/ec-${bsf}_$year${month}_disacc-24h-$abr-{}-fix.grib || echo "NOT fixing unbound disacc gribs attributes - no input or already produced"
# adjusted pressure level
[ -s ens/ec-${bsf}_$year${month}_pl-pp-unbound-24h-$abr-50.grib ] && ! [ -s ens/ec-${bsf}_$year${month}_pl-pp-unbound-24h-$abr-50-fix.grib ] && \
seq 0 50 | parallel grib_set -r -s jScansPositively=0 ens/ec-${bsf}_$year${month}_pl-pp-unbound-24h-$abr-{}.grib ens/ec-${bsf}_$year${month}_pl-pp-unbound-24h-$abr-{}-fix.grib || echo "NOT fixing unbound pl-pp gribs attributes - no input or already produced"
# mn2t24
[ -s ens/ec-${bsf}_$year${month}_mn2t24-unbound-24h-$abr-50.grib ] && ! [ -s ens/ec-${bsf}_$year${month}_mn2t24-unbound-24h-$abr-50-fix.grib ] && \
seq 0 50 | parallel grib_set -r -s jScansPositively=0 ens/ec-${bsf}_$year${month}_mn2t24-unbound-24h-$abr-{}.grib ens/ec-${bsf}_$year${month}_mn2t24-unbound-24h-$abr-{}-fix.grib || echo "NOT fixing unbound mn2t24 gribs attributes - no input or already produced"
# mx2t24
[ -s ens/ec-${bsf}_$year${month}_mx2t24-unbound-24h-$abr-50.grib ] && ! [ -s ens/ec-${bsf}_$year${month}_mx2t24-unbound-24h-$abr-50-fix.grib ] && \
seq 0 50 | parallel grib_set -r -s jScansPositively=0 ens/ec-${bsf}_$year${month}_mx2t24-unbound-24h-$abr-{}.grib ens/ec-${bsf}_$year${month}_mx2t24-unbound-24h-$abr-{}-fix.grib || echo "NOT fixing unbound mx2t24 gribs attributes - no input or already produced"

# xgboost for oceanids
cd /home/ubuntu/bin
parallel -j1 ./run-xgb-predict-era5-oceanids.sh $year $month {\1} {\2} :::: harbors.txt :::: predictands.txt

#echo 'stop'

## fix grib attributes
#[ -s ens/ec-${bsf}_$year${month}_unbound-24h-$abr-50.grib ] && ! [ -s ens/ec-${bsf}_$year${month}_unbound-24h-$abr-50-fixed.grib ] && \
# seq 0 50 | parallel grib_set -r -s centre=98,setLocalDefinition=1,localDefinitionNumber=15,jScansPositively=0,totalNumber=51,number={} ens/ec-${bsf}_$year${month}_unbound-24h-$abr-{}.grib \
#    ens/ec-${bsf}_$year${month}_unbound-24h-$abr-{}-fixed.grib || echo "NOT fixing unbound gribs attributes - no input or already produced"
#[ -s ens/ec-${bsf}_$year${month}_snow-24h-$abr-50.grib ] && ! [ -s ens/ec-${bsf}_$year${month}_snow-24h-$abr-50-fixed.grib ] && \
# seq 0 50 | parallel grib_set -r -s centre=98,setLocalDefinition=1,localDefinitionNumber=15,jScansPositively=0,totalNumber=51,number={} ens/ec-${bsf}_$year${month}_snow-24h-$abr-{}.grib \
#    ens/ec-${bsf}_$year${month}_snow-24h-$abr-{}-fixed.grib || echo "NOT fixing snow gribs attributes - no input or already produced"
#[ -s ens/ec-${bsf}_$year${month}_bound-24h-$abr-50.grib ] && ! [ -s ens/ec-${bsf}_$year${month}_bound-24h-$abr-50-fixed.grib ] && \
# seq 0 50 | parallel grib_set -r -s centre=98,setLocalDefinition=1,localDefinitionNumber=15,jScansPositively=0,totalNumber=51,number={} ens/ec-${bsf}_$year${month}_bound-24h-$abr-{}.grib \
#    ens/ec-${bsf}_$year${month}_bound-24h-$abr-{}-fixed.grib || echo "NOT fixing bound gribs attributes - no input or already produced"
#[ -s ens/ec-${bsf}_$year${month}_acc-24h-$abr-50.grib ] && ! [ -s ens/ec-${bsf}_$year${month}_acc-24h-$abr-50-fixed.grib ] && \
# seq 0 50 | parallel grib_set -r -s centre=98,setLocalDefinition=1,localDefinitionNumber=15,jScansPositively=0,totalNumber=51,number={} ens/ec-${bsf}_$year${month}_acc-24h-$abr-{}.grib \
#    ens/ec-${bsf}_$year${month}_acc-24h-$abr-{}-fixed.grib || echo "NOT fixing acc gribs attributes - no input or already produced"

## join ensemble members and move to grib folder
#[ -s ens/ec-${bsf}_$year${month}_unbound-24h-$abr-50-fixed.grib ] && ! [ -s grib/EC${bsf}_$year${month}01T000000_unbound-24h-$abr.grib ] &&\
# grib_copy ens/ec-${bsf}_$year${month}_unbound-24h-$abr-*-fixed.grib grib/EC${bsf}_$year${month}01T000000_unbound-24h-$abr.grib &
#[ -s ens/ec-${bsf}_$year${month}_snow-24h-$abr-50-fixed.grib ] && ! [ -s grib/EC${bsf}_$year${month}01T000000_snow-24h-$abr.grib ] &&\
# grib_copy ens/ec-${bsf}_$year${month}_snow-24h-$abr-*-fixed.grib grib/EC${bsf}_$year${month}01T000000_snow-24h-$abr.grib &
#[ -s ens/ec-${bsf}_$year${month}_bound-24h-$abr-50-fixed.grib ] && ! [ -s grib/EC${bsf}_$year${month}01T000000_bound-24h-$abr.grib ] &&\
# grib_copy ens/ec-${bsf}_$year${month}_bound-24h-$abr-*-fixed.grib grib/EC${bsf}_$year${month}01T000000_bound-24h-$abr.grib &
#[ -s ens/ec-${bsf}_$year${month}_acc-24h-$abr-50-fixed.grib ] && ! [ -s grib/EC${bsf}_$year${month}01T000000_acc-24h-$abr.grib ] &&\
# grib_copy ens/ec-${bsf}_$year${month}_acc-24h-$abr-*-fixed.grib grib/EC${bsf}_$year${month}01T000000_acc-24h-$abr.grib &
wait 

# fix grib attributes for ECSF
#[ -s ens/ec-sf_$year${month}_all+sde-24h-$abr-50.grib ] && ! [ -s ens/ECSF_$year${month}01T000000_all-24h-$abr-50.grib ] && \
# seq 0 50 | parallel grib_set -r -s centre=98,setLocalDefinition=1,localDefinitionNumber=15,totalNumber=51,number={} ens/ec-sf_$year${month}_all+sde-24h-$abr-{}.grib \
#    ens/ECSF_$year${month}01T000000_all-24h-$abr-{}.grib || echo "NOT fixing ecsf swvls gribs attributes - no input or already produced"
# join ensemble members and move to grib folder 
#[ -s ens/ECSF_$year${month}01T000000_all-24h-$abr-50.grib ] && ! [ -s grib/ECSF_$year${month}01T000000_all-24h-$abr.grib ] &&\
#grib_copy ens/ECSF_$year${month}01T000000_all-24h-$abr-*.grib grib/ECSF_$year${month}01T000000_all-24h-$abr.grib || echo "NOT joining ensemble members ecsf - no input or already produced"

## Post-process pressure level data to add K-index 
## calculate variables vapour pressures, dew point temps, k-index and add them to the data set
#[ -s ens/ec-sf_$year${month}_pl-12h-$abr-50.grib ] && ! [ -s ens/ec-sf_$year${month}_pl-pp-12h-$abr-50.grib ] && \
#seq 0 50 | parallel -q cdo --eccodes -O -b P12 \
#        aexpr,'kx=sellevel(t,85000)-sellevel(t,50000)+sellevel(dpt,85000)-(sellevel(t,70000)-sellevel(dpt,70000));' \
#        -aexpr,'dpt=log(vp/6.112)*243.5/(17.67-log(vp/6.112));' -aexpr,'ws=sqrt(u^2+v^2);' \
#    -aexpr,'wdir=180+180/3.14159265*2*atan(v/(sqr(u^2+v^2)+u));' \
#        -aexpr,'vp=clev(q)*q/(0.622+0.378*q);' ens/ec-sf_$year${month}_pl-12h-$abr-{}.grib ens/ec-sf_$year${month}_pl-pp-12h-$abr-{}.grib || \
# echo "NOT adding kx to ECSF pressure level - no input or already produced"

# fix grib attributes for pl-pp
#[ -s ens/ec-sf_$year${month}_pl-pp-12h-$abr-50.grib ] && ! [ -s ens/ec-sf_$year${month}_pl-pp-12h-$abr-50-fixed.grib ] && \
#seq 0 50 | parallel grib_set -r -s centre=98,setLocalDefinition=1,localDefinitionNumber=15,jScansPositively=0,totalNumber=51,number={} ens/ec-sf_$year${month}_pl-pp-12h-$abr-{}.grib \
#ens/ec-sf_$year${month}_pl-pp-12h-$abr-{}-fixed.grib || echo "NOT fixing pl-pp grib attributes - no input or already produced"

## join pl-pp and tp ensemble members and move to grib folder
#[ -s ens/ec-sf_$year${month}_pl-pp-12h-$abr-50-fixed.grib ] && ! [ -s grib/ECSF_$year${month}01T000000_pl-pp-12h-$abr.grib ] && \
#grib_copy ens/ec-sf_$year${month}_pl-pp-12h-$abr-*-fixed.grib grib/ECSF_$year${month}01T000000_pl-pp-12h-$abr.grib || echo "NOT joining pl-pp ensemble members - no input or already produced"
#wait 

# run XGBoost model to produce harbor forecasts
#! [ -s  ]

# run XGBoost model to produce precipitation forecasts
#! [ -s grib/ECXSF_$year${month}01T000000_tp-acc-$abr.grib ] && echo "start XGBoost predict for precipitation" && run-xgb-predict-prec.sh $year $month

#sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0