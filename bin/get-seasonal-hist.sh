#!/bin/bash
#
# fetch seasonal forecast data from CDS for past months and years

source ~/.smart

#eval "$(conda shell.bash hook)"
eval "$(/home/ubuntu/mambaforge/bin/conda shell.bash hook)"
cd /home/smartmet/data

year=$1
month=$2

eyear=$(date -d "$year${month}01 7 months" +%Y)
emonth=$(date -d "$year${month}01 7 months" +%m)

echo "y: $year m: $month ending $eyear-$emonth area: $area abr: $abr"

## Fetch seasonal data from CDS-API
[ -s ec-sf-$year$month-all-24h-$abr.grib ] && echo "SF Data file already downloaded" || /home/smartmet/bin/cds-sf-all-24h.py $year $month $area $abr
[ -s ec-sf-$year$month-pl-12h-$abr.grib ] && echo "SF pressurelevel Data already downloaded" || /home/smartmet/bin/cds-sf-pl-12h.py $year $month $area $abr
[ -s ec-sf-$year$month-vsw-24h-$abr.grib ] && echo "SF SoilLevel Data already downloaded" || /home/smartmet/bin/cds-sf-vsw-24h.py $year $month $area $abr

# ensemble members
[ -s ens/ec-sf_$year${month}_all-24h-$abr-50.grib ] && echo "Ensemble member sl files ready" || \
    grib_copy ec-sf-$year$month-all-24h-$abr.grib ens/ec-sf_$year${month}_all-24h-$abr-[number].grib
[ -s ens/ec-sf_$year${month}_swvls-24h-$abr-50.grib ] && echo "Ensemble member swvl files ready"  || \
    grib_copy ec-sf-$year${month}-vsw-24h-$abr.grib ens/ec-sf_$year${month}_swvls-24h-$abr-[number].grib

# swvls levels
[ -s ens/ec-sf_$year${month}_swvls-24h-$abr-50-lvl-3.grib ] && echo "Levels swvls files ready" || \
seq 0 50 | parallel grib_copy ens/ec-sf_$year${month}_swvls-24h-$abr-{}.grib ens/ec-sf_$year${month}_swvls-24h-$abr-{}-lvl-[level].grib
# fix levels
[ -s ens/ec-sf_$year${month}_swvls-24h-$abr-50-lvl-3-fix.grib ] && echo "Levels swvls fixed already" || \
seq 0 50 | parallel "grib_set -s levelType=106,level:d=0,topLevel:d=0.0,bottomLevel:d=0.07 ens/ec-sf_$year${month}_swvls-24h-$abr-{}-lvl-1.grib ens/ec-sf_$year${month}_swvls-24h-$abr-{}-lvl-0-fix.grib &&
grib_set -s levelType=106,level:d=1,topLevel:d=0.07,bottomLevel:d=0.28 ens/ec-sf_$year${month}_swvls-24h-$abr-{}-lvl-2.grib ens/ec-sf_$year${month}_swvls-24h-$abr-{}-lvl-1-fix.grib &&
grib_set -s levelType=106,level:d=2,topLevel:d=0.28,bottomLevel:d=1.0 ens/ec-sf_$year${month}_swvls-24h-$abr-{}-lvl-3.grib ens/ec-sf_$year${month}_swvls-24h-$abr-{}-lvl-2-fix.grib &&
grib_set -s levelType=106,level:d=3,topLevel:d=1.0,bottomLevel:d=2.54 ens/ec-sf_$year${month}_swvls-24h-$abr-{}-lvl-4.grib ens/ec-sf_$year${month}_swvls-24h-$abr-{}-lvl-3-fix.grib"
# merge levels 
[ -s ens/ec-sf_$year${month}_swvls-24h-$abr-50-fixLevs.grib ] && echo "Already merged swvls levels" || \
 seq 0 50 | parallel cdo --eccodes merge ens/ec-sf_$year${month}_swvls-24h-$abr-{}-lvl-0-fix.grib ens/ec-sf_$year${month}_swvls-24h-$abr-{}-lvl-1-fix.grib ens/ec-sf_$year${month}_swvls-24h-$abr-{}-lvl-2-fix.grib ens/ec-sf_$year${month}_swvls-24h-$abr-{}-lvl-3-fix.grib ens/ec-sf_$year${month}_swvls-24h-$abr-{}-fixLevs.grib

# add snow depth to ECSF
[ -s ens/ec-sf_$year${month}_all-24h-$abr-50.grib ] && [ ! -s ens/ec-sf_$year${month}_all+sde-24h-$abr-50.grib ] &&\
 seq 0 50 | parallel cdo -s --eccodes -O aexprf,ec-sde.instr ens/ec-sf_$year${month}_all-24h-$abr-{}.grib ens/ec-sf_$year${month}_all+sde-24h-$abr-{}.grib ||\
 echo "NOT adding ECSF snow - no input or already produced"
# fix grib attributes for ECSF
[ -s ens/ec-sf_$year${month}_all+sde-24h-$abr-50.grib ] && [ ! -s ens/ECSF_$year${month}01T000000_all-24h-$abr-50.grib ] && \
 seq 0 50 | parallel grib_set -r -s centre=98,setLocalDefinition=1,localDefinitionNumber=15,totalNumber=51,number={} ens/ec-sf_$year${month}_all+sde-24h-$abr-{}.grib \
    ens/ECSF_$year${month}01T000000_all-24h-$abr-{}.grib || echo "NOT fixing ecsf swvls gribs attributes - no input or already produced"
# join ensemble members and move to grib folder 
[ -s ens/ECSF_$year${month}01T000000_all-24h-$abr-50.grib ] && [ ! -s grib/ECSF_$year${month}01T000000_all-24h-$abr.grib ] &&\
grib_copy ens/ECSF_$year${month}01T000000_all-24h-$abr-*.grib grib/ECSF_$year${month}01T000000_all-24h-$abr.grib || echo "NOT joining ensemble members ecsf - no input or already produced"

# ECSF-SWVLs
# fix grib attributes
[ -s ens/ECSF_$year${month}01T000000_swvls-24h-$abr-{}-fixed.grib ] && echo "NOT fixing ecsf swvl gribs attributes - no input or already produced" || \
seq 0 50 | parallel grib_set -r -s centre=98,setLocalDefinition=1,localDefinitionNumber=15,totalNumber=51,number={} ens/ec-sf_$year${month}_swvls-24h-$abr-{}-fixLevs.grib \
ens/ECSF_$year${month}01T000000_swvls-24h-$abr-{}-fixed.grib
# join ensemble members and move to grib file
[ -s grib/ECSF_$year${month}01T000000_swvls-24h-$abr.grib ] && echo "NOT joining ensemlbe members ecsf swvls - no input or already produced" || \
grib_copy ens/ECSF_$year${month}01T000000_swvls-24h-$abr-*-fixed.grib grib/ECSF_$year${month}01T000000_swvls-24h-$abr.grib

## Split pl to ensemble members 
[ -s ens/ec-sf_$year${month}_pl-12h-$abr-50.grib ] && echo "Ensemble member pl files ready" || grib_copy ec-sf-$year${month}-pl-12h-$abr.grib ens/ec-sf_$year${month}_pl-12h-$abr-[number].grib

## Post-process pressure level data to add K-index 
## calculate variables vapour pressures, dew point temps, k-index and add them to the data set
[ -s ens/ec-sf_$year${month}_pl-12h-$abr-50.grib ] && ! [ -s ens/ec-sf_$year${month}_pl-pp-12h-$abr-50.grib ] && \
seq 0 50 | parallel -q cdo --eccodes -O -b P12 \
        aexpr,'kx=sellevel(t,85000)-sellevel(t,50000)+sellevel(dpt,85000)-(sellevel(t,70000)-sellevel(dpt,70000));' \
        -aexpr,'dpt=log(vp/6.112)*243.5/(17.67-log(vp/6.112));' -aexpr,'ws=sqrt(u^2+v^2);' \
    -aexpr,'wdir=180+180/3.14159265*2*atan(v/(sqr(u^2+v^2)+u));' \
        -aexpr,'vp=clev(q)*q/(0.622+0.378*q);' ens/ec-sf_$year${month}_pl-12h-$abr-{}.grib ens/ec-sf_$year${month}_pl-pp-12h-$abr-{}.grib || \
 echo "NOT adding kx to ECSF pressure level - no input or already produced"

# fix grib attributes for pl-pp
[ -s ens/ec-sf_$year${month}_pl-pp-12h-$abr-50.grib ] && ! [ -s ens/ec-sf_$year${month}_pl-pp-12h-$abr-50-fixed.grib ] && \
seq 0 50 | parallel grib_set -r -s centre=98,setLocalDefinition=1,localDefinitionNumber=15,jScansPositively=0,totalNumber=51,number={} ens/ec-sf_$year${month}_pl-pp-12h-$abr-{}.grib \
ens/ec-sf_$year${month}_pl-pp-12h-$abr-{}-fixed.grib || echo "NOT fixing pl-pp grib attributes - no input or already produced"

## join pl-pp and tp ensemble members and move to grib folder
[ -s ens/ec-sf_$year${month}_pl-pp-12h-$abr-50-fixed.grib ] && ! [ -s grib/ECSF_$year${month}01T000000_pl-pp-12h-$abr.grib ] && \
grib_copy ens/ec-sf_$year${month}_pl-pp-12h-$abr-*-fixed.grib grib/ECSF_$year${month}01T000000_pl-pp-12h-$abr.grib || echo "NOT joining pl-pp ensemble members - no input or already produced"
wait 

#make space
rm ens/ec-sf_$year${month}*.grib

#sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0