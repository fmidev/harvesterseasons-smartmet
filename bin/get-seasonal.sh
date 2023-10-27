#!/bin/bash
#
# monthly script for fetching seasonal data from cdsapi, doing bias corrections and
# and setting up data in the smartmet-server, bias adjustment can be done based on ERA5 Land (default) or ERA5
# add era5 as a third attribute on the command line for this and you have to define year and month for this case
#
# 14.9.2020 Mikko Strahlendorff
# add fetching and postprocessing pressurelevel data 850,700,500 hPa
# 5.3.2022 Mikko Strahlendorff/Anni Kröger
# add gradient boosting bias adjustment 7/2022 -> 
# 22.2.2023 add 'source ~/.smart' for area/abr etc information 

source ~/.smart

eval "$(conda shell.bash hook)"
if [ $# -ne 0 ]
then
    year=$1
    month=$2
    if [[ $3 == 'era5' ]] 
        then bsf='B2SF'; era='era5'; 
        else bsf='BSF'; era='era5l'; 
    fi
else
    year=$(date +%Y)
    month=$(date +%m)
    bsf='BSF'; era='era5l';
    
    ## remove previous month files
    oldmonth=$(date -d '1 month ago' +%m)
    oldyear=$(date -d '1 month ago' +%Y)
    rm ens/*_$oldyear${oldmonth}_*.grib
fi
cd /home/smartmet/data

eyear=$(date -d "$year${month}01 7 months" +%Y)
emonth=$(date -d "$year${month}01 7 months" +%m)

echo "$bsf $era y: $year m: $month ending $eyear-$emonth area: $area abr: $abr"

## Fetch seasonal data from CDS-API
[ -f ec-sf-$year$month-all-24h-$abr.grib ] && echo "SF Data file already downloaded" || /home/smartmet/bin/cds-sf-all-24h.py $year $month $area $abr
[ -f ec-sf-$year$month-pl-12h-$abr.grib ] && echo "SF pressurelevel Data already downloaded" || /home/smartmet/bin/cds-sf-pl-12h.py $year $month $area $abr
[ -f ecsf_$year-$month-01_$abr-swvls.grib ] && echo "SF SoilLevel Data already downloaded" || sed s:2023-01-01:$year-$month-01:g ../mars/seas-swvl.mars | /home/smartmet/bin/mars

# ensure new eccodes and cdo
#conda activate xr
# ensemble members
[ -f ens/ec-sf_$year${month}_all-24h-$abr-50.grib ] && echo "Ensemble member sl files ready" || \
    grib_copy ec-sf-$year$month-all-24h-$abr.grib ens/ec-sf_$year${month}_all-24h-$abr-[number].grib
[ -f ens/ec-sf_$year${month}_swvls-24h-$abr-50.grib ] && echo "Ensemble member swvl files ready"  || \
    grib_copy ecsf_$year-$month-01_$abr-swvls.grib ens/ec-sf_$year${month}_swvls-24h-$abr-[number].grib
# swvls levels
[ -f ens/ec-sf_$year${month}_swvls-24h-$abr-50-lvl-3.grib ] && echo "Levels swvls files ready" || \
seq 0 50 | parallel grib_copy ens/ec-sf_$year${month}_swvls-24h-$abr-{}.grib ens/ec-sf_$year${month}_swvls-24h-$abr-{}-lvl-[level].grib
# fix levels
[ -f ens/ec-sf_$year${month}_swvls-24h-$abr-50-lvl-3-fix.grib ] && echo "Levels swvls fixed already" || \
seq 0 50 | parallel "grib_set -s levelType=106,level:d=0,topLevel:d=0.0,bottomLevel:d=0.07 ens/ec-sf_$year${month}_swvls-24h-$abr-{}-lvl-0.grib ens/ec-sf_$year${month}_swvls-24h-$abr-{}-lvl-0-fix.grib &&
grib_set -s levelType=106,level:d=1,topLevel:d=0.07,bottomLevel:d=0.28 ens/ec-sf_$year${month}_swvls-24h-$abr-{}-lvl-1.grib ens/ec-sf_$year${month}_swvls-24h-$abr-{}-lvl-1-fix.grib &&
grib_set -s levelType=106,level:d=2,topLevel:d=0.28,bottomLevel:d=1.0 ens/ec-sf_$year${month}_swvls-24h-$abr-{}-lvl-2.grib ens/ec-sf_$year${month}_swvls-24h-$abr-{}-lvl-2-fix.grib &&
grib_set -s levelType=106,level:d=3,topLevel:d=1.0,bottomLevel:d=2.54 ens/ec-sf_$year${month}_swvls-24h-$abr-{}-lvl-3.grib ens/ec-sf_$year${month}_swvls-24h-$abr-{}-lvl-3-fix.grib"
# merge levels 
[ -f ens/ec-sf_$year${month}_swvls-24h-$abr-50-fixLevs.grib ] && echo "Already merged swvls levels" || \
 seq 0 50 | parallel cdo --eccodes merge ens/ec-sf_$year${month}_swvls-24h-$abr-{}-lvl-0-fix.grib ens/ec-sf_$year${month}_swvls-24h-$abr-{}-lvl-1-fix.grib ens/ec-sf_$year${month}_swvls-24h-$abr-{}-lvl-2-fix.grib ens/ec-sf_$year${month}_swvls-24h-$abr-{}-lvl-3-fix.grib ens/ec-sf_$year${month}_swvls-24h-$abr-{}-fixLevs.grib
## Make bias-adjustements for single level parameters
### adjust swvl1/2 from mars file
[ -f ens/ec-sf_$year${month}_swvls-24h-$abr-50-fixLevs.grib ] && ! [ -f ens/ec-${bsf}_$year${month}_swvls-24h-$abr-50.grib ] && \
 seq 0 50 | parallel cdo -s -b P8 -O --eccodes ymonadd \
 -remap,$era-$abr-grid,ec-sf-$era-$abr-weights.nc ens/ec-sf_$year${month}_swvls-24h-$abr-{}-fixLevs.grib \
 era5l/era5l-ecsf_2000-2019_swvls_unbound_bias_eu_vsws_fixed.grib \
 ens/ec-${bsf}_$year${month}_swvls-24h-$abr-{}.grib || echo "NOT adj swvls - seasonal forecast input missing or already produced"
 ### adjust unbound variables (removed swvl1/2 in Nov 2022 as not anymore available from CDS)
[ -f ens/ec-sf_$year${month}_all-24h-$abr-50.grib ] && ! [ -f ens/ec-${bsf}_$year${month}_unbound-24h-$abr-50.grib ] && \
 seq 0 50 | parallel cdo -s -b P8 -O --eccodes ymonadd \
    -remap,$era-$abr-grid,ec-sf-$era-$abr-weights.nc -selname,2d,2t,stl1 ens/ec-sf_$year${month}_all-24h-$abr-{}.grib \
    -selname,2d,2t,stl1 $era/$era-ecsf_2000-2019_unbound_bias_$abr.grib \
    ens/ec-${bsf}_$year${month}_unbound-24h-$abr-{}.grib || echo "NOT adj unbound - seasonal forecast input missing or already produced"
### adjust snow variables
[ -f ens/ec-sf_$year${month}_all-24h-$abr-50.grib ] && ! [ -f ens/ec-${bsf}_$year${month}_snow-24h-$abr-50.grib ] && \
 seq 0 50 | parallel cdo -s -O -b P12 --eccodes setmisstoc,0.0 -aexprf,ec-sde.instr -ymonadd \
    -remap,$era-$abr-grid,ec-sf-$era-$abr-weights.nc -selname,rsn,sd ens/ec-sf_$year${month}_all-24h-$abr-{}.grib \
    -selname,rsn,sd $era/$era-ecsf_2000-2019_unbound_bias_$abr.grib \
    ens/ec-${bsf}_$year${month}_snow-24h-$abr-{}.grib || echo "NOT adj snow - seasonal forecast input missing or already produced"
### adjust wind
[ -f ens/ec-sf_$year${month}_all-24h-$abr-50.grib ] && ! [ -f ens/ec-${bsf}_$year${month}_bound-24h-$abr-50.grib ] && \
 seq 0 50 | parallel -q cdo -s -b P8 -O --eccodes ymonmul \
    -remap,$era-$abr-grid,ec-sf-$era-$abr-weights.nc -aexpr,'ws=sqrt(10u^2+10v^2);' -selname,10u,10v ens/ec-sf_$year${month}_all-24h-$abr-{}.grib \
    -aexpr,'10u=ws;10v=ws;' -selname,ws $era/$era-ecsf_2000-2019_bound_bias_$abr.grib \
    ens/ec-${bsf}_$year${month}_bound-24h-$abr-{}.grib || echo "NOT adj wind - seasonal forecast input missing or already produced"
### adjust evaporation and total precip or other accumulating variables
### due to a clearly too strong variance term in tp adjustment is only done with bias for now
### disacc tp,e,slhf,sshf,ro,str,strd,ssr,ssrd,sf,tsr,ttr
[ -f ens/ec-sf_$year${month}_all-24h-$abr-50.grib ] && ! [ -f ens/ec-${bsf}_$year${month}_acc-24h-$abr-50.grib ] && \
 seq 0 50 | parallel "cdo -s --eccodes -O mergetime -seltimestep,1 -selname,e,tp,slhf,sshf,ro,str,strd,ssr,ssrd,sf,tsr,ttr ens/ec-sf_$year${month}_all-24h-$abr-{}.grib \
     -deltat -selname,e,tp,slhf,sshf,ro,str,strd,ssr,ssrd,sf,tsr,ttr ens/ec-sf_$year${month}_all-24h-$abr-{}.grib ens/disacc-$year${month}-{}.grib && \
    cdo -s --eccodes ymonmul -remap,$era-$abr-grid,ec-sf-$era-$abr-weights.nc -selname,e,tp ens/disacc-$year${month}-{}.grib \
     -selname,e,tp $era/$era-ecsf_2000-2019_bound_bias_$abr.grib \
     ens/ec-${bsf}_$year${month}_disacc-24h-$abr-{}.grib && \
    cdo -s --eccodes -b P8 timcumsum ens/ec-${bsf}_$year${month}_disacc-24h-$abr-{}.grib ens/ec-${bsf}_$year${month}_acc-24h-$abr-{}.grib" || echo "NOT adj acc - seasonal forecast input missing or already produced"

## Make stl2,3,4 from stl1
[ -f ens/ec-sf_$year${month}_all-24h-$abr-50.grib ] && ! [ -f ens/ec-${bsf}_$year${month}_stl-24h-$abr-50.grib ] && \
 seq 0 50 |parallel -q cdo -s --eccodes -O -b P8 ymonadd -aexpr,'stl2=stl1;stl3=stl1;stl4=stl1;' -remap,$era-$abr-grid,ec-sf-$era-$abr-weights.nc -selname,stl1 ens/ec-sf_$year${month}_all-24h-$abr-{}.grib \
    -selname,stl1,stl2,stl3,stl4 $era/$era-stls-diff+bias-climate-$abr.grib ens/ec-${bsf}_$year${month}_stl-24h-$abr-{}.grib \
    || echo "NOT making stl levels 2,3,4 - seasonal forecast input missing or already produced"
# cdo -s correcting levels for stl2,3,4 segfaults with the below operator:
# changemulti,\'$'(170;*;7|170;*;28);(183;*;7|183;*;100);(236;*;7|236;*;289);'\'

## fix grib attributes
[ -f ens/ec-${bsf}_$year${month}_swvls-24h-$abr-50.grib ] && [ ! -f ens/ec-${bsf}_$year${month}_swvls-24h-$abr-50-fixed.grib ] && \
 seq 0 50 | parallel grib_set -r -s centre=98,setLocalDefinition=1,localDefinitionNumber=15,jScansPositively=0,totalNumber=51,number={} ens/ec-${bsf}_$year${month}_swvls-24h-$abr-{}.grib \
    ens/ec-${bsf}_$year${month}_swvls-24h-$abr-{}-fixed.grib || echo "NOT fixing swvls gribs attributes - no input or already produced"
[ -f ens/ec-${bsf}_$year${month}_unbound-24h-$abr-50.grib ] && [ ! -f ens/ec-${bsf}_$year${month}_unbound-24h-$abr-50-fixed.grib ] && \
 seq 0 50 | parallel grib_set -r -s centre=98,setLocalDefinition=1,localDefinitionNumber=15,jScansPositively=0,totalNumber=51,number={} ens/ec-${bsf}_$year${month}_unbound-24h-$abr-{}.grib \
    ens/ec-${bsf}_$year${month}_unbound-24h-$abr-{}-fixed.grib || echo "NOT fixing unbound gribs attributes - no input or already produced"
[ -f ens/ec-${bsf}_$year${month}_snow-24h-$abr-50.grib ] && [ ! -f ens/ec-${bsf}_$year${month}_snow-24h-$abr-50-fixed.grib ] && \
 seq 0 50 | parallel grib_set -r -s centre=98,setLocalDefinition=1,localDefinitionNumber=15,jScansPositively=0,totalNumber=51,number={} ens/ec-${bsf}_$year${month}_snow-24h-$abr-{}.grib \
    ens/ec-${bsf}_$year${month}_snow-24h-$abr-{}-fixed.grib || echo "NOT fixing snow gribs attributes - no input or already produced"
[ -f ens/ec-${bsf}_$year${month}_bound-24h-$abr-50.grib ] && [ ! -f ens/ec-${bsf}_$year${month}_bound-24h-$abr-50-fixed.grib ] && \
 seq 0 50 | parallel grib_set -r -s centre=98,setLocalDefinition=1,localDefinitionNumber=15,jScansPositively=0,totalNumber=51,number={} ens/ec-${bsf}_$year${month}_bound-24h-$abr-{}.grib \
    ens/ec-${bsf}_$year${month}_bound-24h-$abr-{}-fixed.grib || echo "NOT fixing bound gribs attributes - no input or already produced"
[ -f ens/ec-${bsf}_$year${month}_acc-24h-$abr-50.grib ] && [ ! -f ens/ec-${bsf}_$year${month}_acc-24h-$abr-50-fixed.grib ] && \
 seq 0 50 | parallel grib_set -r -s centre=98,setLocalDefinition=1,localDefinitionNumber=15,jScansPositively=0,totalNumber=51,number={} ens/ec-${bsf}_$year${month}_acc-24h-$abr-{}.grib \
    ens/ec-${bsf}_$year${month}_acc-24h-$abr-{}-fixed.grib || echo "NOT fixing acc gribs attributes - no input or already produced"
[ -f ens/ec-${bsf}_$year${month}_stl-24h-$abr-50.grib ] && [ ! -f ens/ec-${bsf}_$year${month}_stl-24h-$abr-50-fixed.grib ] && \
 seq 0 50 | parallel grib_set -r -s centre=98,setLocalDefinition=1,localDefinitionNumber=15,jScansPositively=0,totalNumber=51,number={} ens/ec-${bsf}_$year${month}_stl-24h-$abr-{}.grib \
    ens/ec-${bsf}_$year${month}_stl-24h-$abr-{}-fixed.grib || echo "NOT fixing stl gribs attributes - no input or already produced"

## join ensemble members and move to grib folder
[ -f ens/ec-${bsf}_$year${month}_swvls-24h-$abr-50-fixed.grib ] && [ ! -f grib/EC${bsf}_$year${month}01T000000_swvls-24h-$abr.grib ] &&\
 grib_copy ens/ec-${bsf}_$year${month}_swvls-24h-$abr-*-fixed.grib grib/EC${bsf}_$year${month}01T000000_swvls-24h-$abr.grib &
[ -f ens/ec-${bsf}_$year${month}_unbound-24h-$abr-50-fixed.grib ] && [ ! -f grib/EC${bsf}_$year${month}01T000000_unbound-24h-$abr.grib ] &&\
 grib_copy ens/ec-${bsf}_$year${month}_unbound-24h-$abr-*-fixed.grib grib/EC${bsf}_$year${month}01T000000_unbound-24h-$abr.grib &
[ -f ens/ec-${bsf}_$year${month}_snow-24h-$abr-50-fixed.grib ] && [ ! -f grib/EC${bsf}_$year${month}01T000000_snow-24h-$abr.grib ] &&\
 grib_copy ens/ec-${bsf}_$year${month}_snow-24h-$abr-*-fixed.grib grib/EC${bsf}_$year${month}01T000000_snow-24h-$abr.grib &
[ -f ens/ec-${bsf}_$year${month}_bound-24h-$abr-50-fixed.grib ] && [ ! -f grib/EC${bsf}_$year${month}01T000000_bound-24h-$abr.grib ] &&\
 grib_copy ens/ec-${bsf}_$year${month}_bound-24h-$abr-*-fixed.grib grib/EC${bsf}_$year${month}01T000000_bound-24h-$abr.grib &
[ -f ens/ec-${bsf}_$year${month}_acc-24h-$abr-50-fixed.grib ] && [ ! -f grib/EC${bsf}_$year${month}01T000000_acc-24h-$abr.grib ] &&\
 grib_copy ens/ec-${bsf}_$year${month}_acc-24h-$abr-*-fixed.grib grib/EC${bsf}_$year${month}01T000000_acc-24h-$abr.grib &
[ -f ens/ec-${bsf}_$year${month}_stl-24h-$abr-50-fixed.grib ] && [ ! -f grib/EC${bsf}_$year${month}01T000000_stl-24h-$abr.grib ] &&\
 grib_copy ens/ec-${bsf}_$year${month}_stl-24h-$abr-*-fixed.grib grib/EC${bsf}_$year${month}01T000000_stl-24h-$abr.grib &
wait 

# add snow depth to ECSF
[ -f ens/ec-sf_$year${month}_all-24h-$abr-50.grib ] && [ ! -f ens/ec-sf_$year${month}_all+sde-24h-$abr-50.grib ] &&\
 seq 0 50 | parallel cdo -s --eccodes -O aexprf,ec-sde.instr ens/ec-sf_$year${month}_all-24h-$abr-{}.grib ens/ec-sf_$year${month}_all+sde-24h-$abr-{}.grib ||\
 echo "NOT adding ECSF snow - no input or already produced"
# fix grib attributes for ECSF
[ -f ens/ec-sf_$year${month}_all+sde-24h-$abr-50.grib ] && [ ! -f ens/ECSF_$year${month}01T000000_all-24h-$abr-50.grib ] && \
 seq 0 50 | parallel grib_set -r -s centre=98,setLocalDefinition=1,localDefinitionNumber=15,totalNumber=51,number={} ens/ec-sf_$year${month}_all+sde-24h-$abr-{}.grib \
    ens/ECSF_$year${month}01T000000_all-24h-$abr-{}.grib || echo "NOT fixing ecsf swvls gribs attributes - no input or already produced"
# join ensemble members and move to grib folder 
[ -f ens/ECSF_$year${month}01T000000_all-24h-$abr-50.grib ] && [ ! -f grib/ECSF_$year${month}01T000000_all-24h-$abr.grib ] &&\
grib_copy ens/ECSF_$year${month}01T000000_all-24h-$abr-*.grib grib/ECSF_$year${month}01T000000_all-24h-$abr.grib || echo "NOT joining ensemble members ecsf - no input or already produced"

# ECSF-SWVLs
# fix grib attributes
[ -f ens/ECSF_$year${month}01T000000_swvls-24h-$abr-{}-fixed.grib ] && echo "NOT fixing ecsf swvl gribs attributes - no input or already produced" || \
seq 0 50 | parallel grib_set -r -s centre=98,setLocalDefinition=1,localDefinitionNumber=15,totalNumber=51,number={} ens/ec-sf_$year${month}_swvls-24h-$abr-{}-fixLevs.grib \
ens/ECSF_$year${month}01T000000_swvls-24h-$abr-{}-fixed.grib
# join ensemble members and move to grib file
[ -f grib/ECSF_$year${month}01T000000_swvls-24h-$abr.grib ] && echo "NOT joining ensemlbe members ecsf swvls - no input or already produced" || \
grib_copy ens/ECSF_$year${month}01T000000_swvls-24h-$abr-*-fixed.grib grib/ECSF_$year${month}01T000000_swvls-24h-$abr.grib

## Split pl to ensemble members 
[ -f ens/ec-sf_$year${month}_pl-12h-$abr-50.grib ] && echo "Ensemble member pl files ready" || grib_copy ec-sf-$year${month}-pl-12h-$abr.grib ens/ec-sf_$year${month}_pl-12h-$abr-[number].grib

## Post-process pressure level data to add K-index 
## calculate variables vapour pressures, dew point temps, k-index and add them to the data set
[ -f ens/ec-sf_$year${month}_pl-12h-$abr-50.grib ] && ! [ -f ens/ec-sf_$year${month}_pl-pp-12h-$abr-50.grib ] && \
seq 0 50 | parallel -q cdo --eccodes -O -b P12 \
        aexpr,'kx=sellevel(t,85000)-sellevel(t,50000)+sellevel(dpt,85000)-(sellevel(t,70000)-sellevel(dpt,70000));' \
        -aexpr,'dpt=log(vp/6.112)*243.5/(17.67-log(vp/6.112));' -aexpr,'ws=sqrt(u^2+v^2);' \
    -aexpr,'wdir=180+180/3.14159265*2*atan(v/(sqr(u^2+v^2)+u));' \
        -aexpr,'vp=clev(q)*q/(0.622+0.378*q);' ens/ec-sf_$year${month}_pl-12h-$abr-{}.grib ens/ec-sf_$year${month}_pl-pp-12h-$abr-{}.grib || \
 echo "NOT adding kx to ECSF pressure level - no input or already produced"

echo "start XGBoost predict for precipitation" # tmp echo 
run-xgb-predict-prec.sh $year $month

[ -f ens/ec-sf_$year${month}_pl-pp-12h-$abr-50.grib ] && ! [ -f ens/ec-sf_$year${month}_pl-pp-12h-$abr-50-fixed.grib ] && \
seq 0 50 | parallel grib_set -r -s centre=98,setLocalDefinition=1,localDefinitionNumber=15,jScansPositively=0,totalNumber=51,number={} ens/ec-sf_$year${month}_pl-pp-12h-$abr-{}.grib \
ens/ec-sf_$year${month}_pl-pp-12h-$abr-{}-fixed.grib || echo "NOT fixing pl-pp grib attributes - no input or already produced"

## join pl-pp and tp ensemble members and move to grib folder
[ -f ens/ec-sf_$year${month}_pl-pp-12h-$abr-50-fixed.grib ] && ! [ -f grib/ECSF_$year${month}01T000000_pl-pp-12h-$abr.grib ] && \
grib_copy ens/ec-sf_$year${month}_pl-pp-12h-$abr-*-fixed.grib grib/ECSF_$year${month}01T000000_pl-pp-12h-$abr.grib || echo "NOT joining pl-pp ensemble members - no input or already produced"
wait 

# run xgboost model to produce swi2 forecasts
echo 'start XGBoost predict for SWI2'
run-xgb-predict-swi2.sh $year $month
# produce forcing file for HOPS
# mod. M.Kosmale 18.03.2021: called now independently from cron (v3)
#/home/smartmet/harvesterseasons-hops2smartmet/get-seasonal_hops.sh $year $month

#sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0
