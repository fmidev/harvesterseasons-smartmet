#!/bin/bash
#
# monthly script for fetching seasonal data from cdsapi, doing bias corrections and
# and setting up data in the smartmet-server, bias adjustment can be done based on ERA5 Land (default) or ERA5
# add era5 as a third attribute on the command line for this and you have to define year and month for this case
#
# 14.9.2020 Mikko Strahlendorff
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

# ensure new eccodes and cdo
conda activate xr
[ -f ens/ec-sf_$year${month}_all-24h-eu-50.grib ] && echo "Ensemble member files ready" || grib_copy ec-sf-$year$month-all-24h-euro.grib ens/ec-sf_$year${month}_all-24h-eu-[number].grib
## Make bias-adjustement
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
     -deltat -selname,e,tp ens/ec-sf_$year${month}_all-24h-eu-{}.grib disacc-tmp-{}.grib && \
    cdo -s --eccodes ymonmul -remap,$era-eu-grid,ec-sf-$era-eu-weights.nc disacc-tmp-{}.grib \
     -selname,e,tp $era/$era-ecsf_2000-2019_bound_bias_eu.grib \
     ens/ec-${bsf}_$year${month}_disacc-24h-eu-{}.grib && \
    cdo -s --eccodes -b P8 timcumsum ens/ec-${bsf}_$year${month}_disacc-24h-eu-{}.grib ens/ec-${bsf}_$year${month}_acc-24h-eu-{}.grib" \
    && rm disacc-tmp-*.grib || echo "NOT adj acc - seasonal forecast input missing or already produced"

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
rm ens/ec-${bsf}_$year${month}_*-24h-eu-*.grib
# add snow depth to ECSF
[ -f ec-sf-$year$month-all-24h-euro.grib ] && [ ! -f grib/ECSF_$year${month}01T000000_all-24h-euro.grib ] &&\
 cdo -s --eccodes -O aexprf,ec-sde.instr ec-sf-$year$month-all-24h-euro.grib grib/ECSF_$year${month}01T000000_all-24h-euro.grib ||\
 echo "NOT adding ECSF snow - no input or already produced"

# produce forcing file for HOPS
# mod. M.Kosmale 18.03.2021: called now independently from cron (v3)
#/home/smartmet/harvesterseasons-hops2smartmet/get-seasonal_hops.sh $year $month

#sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0