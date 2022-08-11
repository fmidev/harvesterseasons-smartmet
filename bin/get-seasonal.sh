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

eval "$(conda shell.bash hook)"
if [ $# -ne 0 ]
then
    year=$1
    month=$2
    if [ $3 == 'era5' ] 
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
    rm ens/ec-${bsf}_$oldyear${oldmonth}_*-24h-eu-*.grib
    rm ens/ec-*_$oldyear${oldmonth}_pl-12h-euro-*.grib
    rm ens/ec-*_$oldyear${oldmonth}_pl-pp-12h-euro-*.grib
    rm ens/ec-${bsf}_$oldyear${oldmonth}_tp-euro-*.nc
    rm ens/disacc-$oldyear${oldmonth}-*.grib 
    rm era5-orography-$oldyear${oldmonth}-euro.grib 
    rm ens/ECX${bsf}_$oldyear${oldmonth}_tp-euro-*
    rm ens/ec-sf-${era}_$oldyear${oldmonth}_disacc-euro-*.grib
    rm ens/ec-sf_$oldyear${oldmonth}_all+sde-24h-eu-*
    rm ens/ECSF_$oldyear${oldmonth}01T000000_all-24h-eu-*
fi
cd /home/smartmet/data

eyear=$(date -d "$year${month}01 7 months" +%Y)
emonth=$(date -d "$year${month}01 7 months" +%m)

mon1=$(echo "$month" |bc)
mon2=$(date -d "$year${month}01 1 months" +%m |bc)
mon3=$(date -d "$year${month}01 2 months" +%m |bc)
mon4=$(date -d "$year${month}01 3 months" +%m |bc)
mon5=$(date -d "$year${month}01 4 months" +%m |bc)
mon6=$(date -d "$year${month}01 5 months" +%m |bc)
mon7=$(date -d "$year${month}01 6 months" +%m |bc)
mon8=$(date -d "$year${month}01 7 months" +%m |bc)

echo "$bsf $era y: $year m: $month ending $eyear-$emonth $mon1,$mon2,$mon3,$mon4,$mon5,$mon6,$mon7,$mon8"

## Fetch seasonal data from CDS-API
[ -f ec-sf-$year$month-all-24h-euro.grib ] && echo "SF Data file already downloaded" || /home/smartmet/bin/cds-sf-all-24h.py $year $month
[ -f ec-sf-$year$month-pl-12h-euro.grib ] && echo "SF pressurelevel Data file already downloaded" || /home/smartmet/bin/cds-sf-pl-12h.py $year $month

# ensure new eccodes and cdo
conda activate xr
[ -f ens/ec-sf_$year${month}_all-24h-eu-50.grib ] && echo "Ensemble member sl files ready" || grib_copy ec-sf-$year$month-all-24h-euro.grib ens/ec-sf_$year${month}_all-24h-eu-[number].grib
## Make bias-adjustements for single level parameters
### adjust unbound variables
[ -f ens/ec-sf_$year${month}_all-24h-eu-50.grib ] && ! [ -f ens/ec-${bsf}_$year${month}_unbound-24h-eu-50.grib ] && \
 seq 0 50 | parallel cdo -s -b P8 -O --eccodes ymonadd \
    -remap,$era-eu-grid,ec-sf-$era-eu-weights.nc -selname,2d,2t,stl1,swvl1,swvl2 ens/ec-sf_$year${month}_all-24h-eu-{}.grib \
    -selname,2d,2t,stl1,swvl1,swvl2 $era/$era-ecsf_2000-2019_unbound_bias_eu.grib \
    ens/ec-${bsf}_$year${month}_unbound-24h-eu-{}.grib || echo "NOT adj unbound - seasonal forecast input missing or already produced"
### adjust snow variables
[ -f ens/ec-sf_$year${month}_all-24h-eu-50.grib ] && ! [ -f ens/ec-${bsf}_$year${month}_snow-24h-eu-50.grib ] && \
 seq 0 50 | parallel cdo -s -O -b P12 --eccodes setmisstoc,0.0 -aexprf,ec-sde.instr -ymonadd \
    -remap,$era-eu-grid,ec-sf-$era-eu-weights.nc -selname,rsn,sd ens/ec-sf_$year${month}_all-24h-eu-{}.grib \
    -selname,rsn,sd $era/$era-ecsf_2000-2019_unbound_bias_eu.grib \
    ens/ec-${bsf}_$year${month}_snow-24h-eu-{}.grib || echo "NOT adj snow - seasonal forecast input missing or already produced"
### adjust wind
[ -f ens/ec-sf_$year${month}_all-24h-eu-50.grib ] && ! [ -f ens/ec-${bsf}_$year${month}_bound-24h-eu-50.grib ] && \
 seq 0 50 | parallel -q cdo -s -b P8 -O --eccodes ymonmul \
    -remap,$era-eu-grid,ec-sf-$era-eu-weights.nc -aexpr,'ws=sqrt(10u^2+10v^2);' -selname,10u,10v ens/ec-sf_$year${month}_all-24h-eu-{}.grib \
    -aexpr,'10u=ws;10v=ws;' -selname,ws $era/$era-ecsf_2000-2019_bound_bias_eu.grib \
    ens/ec-${bsf}_$year${month}_bound-24h-eu-{}.grib || echo "NOT adj wind - seasonal forecast input missing or already produced"
### adjust evaporation and total precip or other accumulating variables
### due to a clearly too strong variance term in tp adjustment is only done with bias for now
[ -f ens/ec-sf_$year${month}_all-24h-eu-50.grib ] && ! [ -f ens/ec-${bsf}_$year${month}_acc-24h-eu-50.grib ] && \
 seq 0 50 | parallel "cdo -s --eccodes -O mergetime -seltimestep,1 -selname,e,tp ens/ec-sf_$year${month}_all-24h-eu-{}.grib \
     -deltat -selname,e,tp ens/ec-sf_$year${month}_all-24h-eu-{}.grib ens/disacc-$year${month}-{}.grib && \
    cdo -s --eccodes ymonmul -remap,$era-eu-grid,ec-sf-$era-eu-weights.nc ens/disacc-$year${month}-{}.grib \
     -selname,e,tp $era/$era-ecsf_2000-2019_bound_bias_eu.grib \
     ens/ec-${bsf}_$year${month}_disacc-24h-eu-{}.grib && \
    cdo -s --eccodes -b P8 timcumsum ens/ec-${bsf}_$year${month}_disacc-24h-eu-{}.grib ens/ec-${bsf}_$year${month}_acc-24h-eu-{}.grib" || echo "NOT adj acc - seasonal forecast input missing or already produced"

## Make stl2,3,4 from stl1
[ -f ens/ec-sf_$year${month}_all-24h-eu-50.grib ] && ! [ -f ens/ec-${bsf}_$year${month}_stl-24h-eu-50.grib ] && \
 seq 0 50 |parallel -q cdo -s --eccodes -O -b P8 ymonadd -aexpr,'stl2=stl1;stl3=stl1;stl4=stl1;' -remap,$era-eu-grid,ec-sf-$era-eu-weights.nc -selname,stl1 ens/ec-sf_$year${month}_all-24h-eu-{}.grib \
    -selname,stl1,stl2,stl3,stl4 $era/$era-stls-diff+bias-climate-eu.grib ens/ec-${bsf}_$year${month}_stl-24h-eu-{}.grib \
    || echo "NOT making stl levels 2,3,4 - seasonal forecast input missing or already produced"
# cdo -s correcting levels for stl2,3,4 segfaults with the below operator:
# changemulti,\'$'(170;*;7|170;*;28);(183;*;7|183;*;100);(236;*;7|236;*;289);'\'

## fix grib attributes
[ -f ens/ec-${bsf}_$year${month}_unbound-24h-eu-50.grib ] && [ ! -f ens/ec-${bsf}_$year${month}_unbound-24h-eu-50-fixed.grib ] && \
 seq 0 50 | parallel grib_set -r -s centre=98,setLocalDefinition=1,localDefinitionNumber=15,totalNumber=51,number={} ens/ec-${bsf}_$year${month}_unbound-24h-eu-{}.grib \
    ens/ec-${bsf}_$year${month}_unbound-24h-eu-{}-fixed.grib || echo "NOT fixing unbound gribs attributes - no input or already produced"
[ -f ens/ec-${bsf}_$year${month}_snow-24h-eu-50.grib ] && [ ! -f ens/ec-${bsf}_$year${month}_snow-24h-eu-50-fixed.grib ] && \
 seq 0 50 | parallel grib_set -r -s centre=98,setLocalDefinition=1,localDefinitionNumber=15,totalNumber=51,number={} ens/ec-${bsf}_$year${month}_snow-24h-eu-{}.grib \
    ens/ec-${bsf}_$year${month}_snow-24h-eu-{}-fixed.grib || echo "NOT fixing snow gribs attributes - no input or already produced"
[ -f ens/ec-${bsf}_$year${month}_bound-24h-eu-50.grib ] && [ ! -f ens/ec-${bsf}_$year${month}_bound-24h-eu-50-fixed.grib ] && \
 seq 0 50 | parallel grib_set -r -s centre=98,setLocalDefinition=1,localDefinitionNumber=15,totalNumber=51,number={} ens/ec-${bsf}_$year${month}_bound-24h-eu-{}.grib \
    ens/ec-${bsf}_$year${month}_bound-24h-eu-{}-fixed.grib || echo "NOT fixing bound gribs attributes - no input or already produced"
[ -f ens/ec-${bsf}_$year${month}_acc-24h-eu-50.grib ] && [ ! -f ens/ec-${bsf}_$year${month}_acc-24h-eu-50-fixed.grib ] && \
 seq 0 50 | parallel grib_set -r -s centre=98,setLocalDefinition=1,localDefinitionNumber=15,totalNumber=51,number={} ens/ec-${bsf}_$year${month}_acc-24h-eu-{}.grib \
    ens/ec-${bsf}_$year${month}_acc-24h-eu-{}-fixed.grib || echo "NOT fixing acc gribs attributes - no input or already produced"
[ -f ens/ec-${bsf}_$year${month}_stl-24h-eu-50.grib ] && [ ! -f ens/ec-${bsf}_$year${month}_stl-24h-eu-50-fixed.grib ] && \
 seq 0 50 | parallel grib_set -r -s centre=98,setLocalDefinition=1,localDefinitionNumber=15,totalNumber=51,number={} ens/ec-${bsf}_$year${month}_stl-24h-eu-{}.grib \
    ens/ec-${bsf}_$year${month}_stl-24h-eu-{}-fixed.grib || echo "NOT fixing stl gribs attributes - no input or already produced"

## join ensemble members and move to grib folder
[ -f ens/ec-${bsf}_$year${month}_unbound-24h-eu-50-fixed.grib ] && [ ! -f grib/EC${bsf}_$year${month}01T000000_unbound-24h-eu.grib ] &&\
 grib_copy ens/ec-${bsf}_$year${month}_unbound-24h-eu-*-fixed.grib grib/EC${bsf}_$year${month}01T000000_unbound-24h-eu.grib &
[ -f ens/ec-${bsf}_$year${month}_snow-24h-eu-50-fixed.grib ] && [ ! -f grib/EC${bsf}_$year${month}01T000000_snow-24h-eu.grib ] &&\
 grib_copy ens/ec-${bsf}_$year${month}_snow-24h-eu-*-fixed.grib grib/EC${bsf}_$year${month}01T000000_snow-24h-eu.grib &
[ -f ens/ec-${bsf}_$year${month}_bound-24h-eu-50-fixed.grib ] && [ ! -f grib/EC${bsf}_$year${month}01T000000_bound-24h-eu.grib ] &&\
 grib_copy ens/ec-${bsf}_$year${month}_bound-24h-eu-*-fixed.grib grib/EC${bsf}_$year${month}01T000000_bound-24h-eu.grib &
[ -f ens/ec-${bsf}_$year${month}_acc-24h-eu-50-fixed.grib ] && [ ! -f grib/EC${bsf}_$year${month}01T000000_acc-24h-eu.grib ] &&\
 grib_copy ens/ec-${bsf}_$year${month}_acc-24h-eu-*-fixed.grib grib/EC${bsf}_$year${month}01T000000_acc-24h-eu.grib &
[ -f ens/ec-${bsf}_$year${month}_stl-24h-eu-50-fixed.grib ] && [ ! -f grib/EC${bsf}_$year${month}01T000000_stl-24h-eu.grib ] &&\
 grib_copy ens/ec-${bsf}_$year${month}_stl-24h-eu-*-fixed.grib grib/EC${bsf}_$year${month}01T000000_stl-24h-eu.grib &
wait 

# add snow depth to ECSF
[ -f ens/ec-sf_$year${month}_all-24h-eu-50.grib ] && [ ! -f ens/ec-sf_$year${month}_all+sde-24h-eu-50.grib ] &&\
 seq 0 50 | parallel cdo -s --eccodes -O aexprf,ec-sde.instr ens/ec-sf_$year${month}_all-24h-eu-{}.grib ens/ec-sf_$year${month}_all+sde-24h-eu-{}.grib ||\
 echo "NOT adding ECSF snow - no input or already produced"
# fix grib attributes for ECSF
[ -f ens/ec-sf_$year${month}_all+sde-24h-eu-50.grib ] && [ ! -f ens/ECSF_$year${month}01T000000_all-24h-eu-50.grib ] && \
 seq 0 50 | parallel grib_set -r -s centre=98,setLocalDefinition=1,localDefinitionNumber=15,totalNumber=51,number={} ens/ec-sf_$year${month}_all+sde-24h-eu-{}.grib \
    ens/ECSF_$year${month}01T000000_all-24h-eu-{}.grib || echo "NOT fixing sde gribs attributes - no input or already produced"
# join ensemble members and move to grib folder 
[ -f ens/ECSF_$year${month}01T000000_all-24h-eu-50.grib ] && [ ! -f grib/ECSF_$year${month}01T000000_all-24h-eu.grib ] &&\
grib_copy ens/ECSF_$year${month}01T000000_all-24h-eu-*.grib grib/ECSF_$year${month}01T000000_all-24h-eu.grib || echo "NOT joining ensemble members with sde - no input or already produced"

#### Gradient boosting bias adjustment for tp 
## onko era5land orography tiedostoa eli sdor anor slor edes olemassa cds? 
era='era5'
bsf='B2SF'
## Split pl to ensemble members 
[ -f ens/ec-sf_$year${month}_pl-12h-euro-50.grib ] && echo "Ensemble member pl files ready" || grib_copy ec-sf-$year${month}-pl-12h-euro.grib ens/ec-sf_$year${month}_pl-12h-euro-[number].grib

## Post-process pressure level data to add K-index 
## calculate variables vapour pressures, dew point temps, k-index and add them to the data set
[ -f ens/ec-sf_$year${month}_pl-12h-euro-50.grib ] && ! [ -f ens/ec-sf_$year${month}_pl-pp-12h-euro-50.grib ] && \
seq 0 50 | parallel -q cdo --eccodes -O -b P12 \
        aexpr,'kx=sellevel(t,85000)-sellevel(t,50000)+sellevel(dpt,85000)-(sellevel(t,70000)-sellevel(dpt,70000));' \
        -aexpr,'dpt=log(vp/6.112)*243.5/(17.67-log(vp/6.112));' -aexpr,'ws=sqrt(u^2+v^2);' \
    -aexpr,'wdir=180+180/3.14159265*2*atan(v/(sqr(u^2+v^2)+u));' \
        -aexpr,'vp=clev(q)*q/(0.622+0.378*q);' ens/ec-sf_$year${month}_pl-12h-euro-{}.grib ens/ec-sf_$year${month}_pl-pp-12h-euro-{}.grib || \
 echo "NOT adding kx to ECSF pressure level - no input or already produced"

## remap to era5(/era5l) 
[ -f ens/ec-sf_$year${month}_pl-pp-12h-euro-50.grib ] && ! [ -f ens/ec-sf-${era}_$year${month}_pl-pp-12h-euro-50.grib ] && \
seq 0 50 | parallel cdo --eccodes -O -b P12 \
    remap,$era-eu-grid,ec-sf-$era-eu-weights.nc -sellevel,85000,70000,50000 -selname,t,q,z,u,v,kx ens/ec-sf_$year${month}_pl-pp-12h-euro-{}.grib \
    ens/ec-sf-${era}_$year${month}_pl-pp-12h-euro-{}.grib || echo "NOT remap pl - no input or already produced"
[ -f ens/ec-sf_$year${month}_all-24h-eu-50.grib ] && ! [ -f ens/ec-sf-${era}_$year${month}_all-24h-eu-50.grib ] && \
seq 0 50 | parallel cdo --eccodes -O -b P12 \
    remap,$era-eu-grid,ec-sf-$era-eu-weights.nc -selname,10u,10v,2d,2t,msl,tp,tsr ens/ec-sf_$year${month}_all-24h-eu-{}.grib \
    ens/ec-sf-${era}_$year${month}_all-24h-eu-{}.grib || echo "NOT remap sl - no input or already produced"
[ -f ens/disacc-$year${month}-50.grib ] && ! [ -f ens/ec-sf-${era}_$year${month}_disacc-euro-50.grib ] && \
seq 0 50 | parallel cdo --eccodes -O -b P12 \
    remap,$era-eu-grid,ec-sf-$era-eu-weights.nc -mulc,1000 ens/disacc-$year${month}-{}.grib \
    ens/ec-sf-${era}_$year${month}_disacc-euro-{}.grib || echo "NOT remap disacc - no input or already produced"

## (change dates in era5-orography-XGB-202105-euro.grib to match fetched data)
#diff=$(( ($year - 2021) * 12 + (10#$month - 10#5) ))
#[ -f $era-orography-XGB-202105-euro.grib ] && ! [ -f $era-orography-$year${month}-euro.grib ] && \
#cdo shifttime,${diff}months $era-orography-XGB-202105-euro.grib $era-orography-$year${month}-euro.grib  || echo "NOT current date era5 orography - no input or already produced" 

## run grb-predict.py 
## remove print commands from python script when tuotantoajo :D 
#conda activate xgb
#[ -f ens/ec-sf-${era}_$year${month}_pl-pp-12h-euro-50.grib ] && [ -f ens/ec-sf-${era}_$year${month}_all-24h-eu-50.grib ] && [ -f $era-orography-$year${month}-euro.grib ] && [ -f ens/ec-sf-${era}_$year${month}_disacc-euro-50.grib ] && ! [ -f ens/ECX${bsf}_$year${month}_tp-euro-50.nc ] && \
#seq 0 50 | parallel -j 8 python3 /home/smartmet/mlbias/grb-predict.py ens/ec-sf-${era}_$year${month}_disacc-euro-{}.grib ens/ec-sf-${era}_$year${month}_pl-pp-12h-euro-{}.grib ens/ec-sf-${era}_$year${month}_all-24h-eu-{}.grib $era-orography-$year${month}-euro.grib ens/ECX${bsf}_$year${month}_tp-euro-{}.nc || echo "NO input or already produced GB files"
#conda activate xr

## netcdf to grib (16bit grib and missing values set to -9.e38 ?)
## TP ON NYT MM YKSIKÖISSÄ VAIKKA GRIB YKSIKÖT METRI, MUUTA
[ -f ens/ECX${bsf}_$year${month}_tp-euro-50.nc ] && ! [ -f ens/ECX${bsf}_$year${month}_tp-euro-50.grib ] && \
seq 0 50 | parallel cdo -b 16 -f grb copy -setparam,128.228 -setmissval,-9.e38 ens/ECX${bsf}_$year${month}_tp-euro-{}.nc ens/ECX${bsf}_$year${month}_tp-euro-{}.grib ||echo "NO input or already netcdf to grib1"

## fix grib attributes for tp and pl-pp 
[ -f ens/ECX${bsf}_$year${month}_tp-euro-50.grib ] && ! [ -f ens/ECX${bsf}_$year${month}_tp-euro-50-fixed.grib ] && \
seq 0 50 | parallel grib_set -r -s table2Version=128,indicatorOfParameter=228,centre=98,setLocalDefinition=1,localDefinitionNumber=15,totalNumber=51,number={} ens/ECX${bsf}_$year${month}_tp-euro-{}.grib \
ens/ECX${bsf}_$year${month}_tp-euro-{}-fixed.grib || echo "NOT fixing tp grib attributes - no input or already produced"
[ -f ens/ec-sf_$year${month}_pl-pp-12h-euro-50.grib ] && ! [ -f ens/ec-sf_$year${month}_pl-pp-12h-euro-50-fixed.grib ] && \
seq 0 50 | parallel grib_set -r -s centre=98,setLocalDefinition=1,localDefinitionNumber=15,totalNumber=51,number={} ens/ec-sf_$year${month}_pl-pp-12h-euro-{}.grib \
ens/ec-sf_$year${month}_pl-pp-12h-euro-{}-fixed.grib || echo "NOT fixing pl-pp grib attributes - no input or already produced"

## join pl-pp and tp ensemble members and move to grib folder
[ -f ens/ECX${bsf}_$year${month}_tp-euro-50-fixed.grib  ] && ! [ -f grib/ECX${bsf}_$year${month}01T000000_tp-euro.grib  ] && \
grib_copy ens/ECX${bsf}_$year${month}_tp-euro-*-fixed.grib grib/ECX${bsf}_$year${month}01T000000_tp-euro.grib || echo "NOT joining tp ensemble members - no input or already produced"
[ -f ens/ec-sf_$year${month}_pl-pp-12h-euro-50-fixed.grib ] && ! [ -f grib/ECSF_$year${month}01T000000_pl-pp-12h-euro.grib ] && \
grib_copy ens/ec-sf_$year${month}_pl-pp-12h-euro-*-fixed.grib grib/ECSF_$year${month}01T000000_pl-pp-12h-euro.grib || echo "NOT joining pl-pp ensemble members - no input or already produced"
wait 

# produce forcing file for HOPS
# mod. M.Kosmale 18.03.2021: called now independently from cron (v3)
#/home/smartmet/harvesterseasons-hops2smartmet/get-seasonal_hops.sh $year $month

#sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0
