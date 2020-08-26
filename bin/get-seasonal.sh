#!/bin/bash
#
# monthly script for fetching seasonal data from cdsapi, doing bias corrections and
# and setting up data in the smartmet-server
#
# 14.1.2020 Mikko Strahlendorff
eval "$(conda shell.bash hook)"
if [ $# -ne 0 ]
then
    year=$1
    month=$2
else
    year=$(date +%Y)
    month=$(date +%m)
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

echo "y: $year m: $month ending $eyear-$emonth $mon1,$mon2,$mon3,$mon4,$mon5,$mon6,$mon7,$mon8"
## Fetch seasonal data from CDS-API
[ -f ec-sf-$year$month-all-24h-euro.grib ] && echo "SF Data file already downloaded" ||cds-sf-all-24h.py $year $month

# ensure new eccodes and cdo
conda activate xr
## Make bias-adjustement
[ -f ens/ec-sf_$year${month}_all-24h-eu-6.grib ] && echo "Ensemble member files ready" || grib_copy ec-sf-$year$month-all-24h-euro.grib ens/ec-sf_$year${month}_all-24h-eu-[number].grib
seq 0 50 | parallel -j 16 --compress --tmpdir tmp/ cdo --eccodes ymonadd \
    -remapbil,era5l-eu-grid -selvar,2d,2t,rsn,stl1,swvl1,swvl2,swvl3,swvl4 ens/ec-sf_$year${month}_all-24h-eu-{}.grib \
    -selmonth,$mon1,$mon2,$mon3,$mon4,$mon5,$mon6,$mon7,$mon8 -selvar,2d,2t,rsn,stl1,swvl1,swvl2,swvl3,swvl4 era5l/era5l-ecsf_2000-2019_unbound_bias.grib \
    ens/ec-bsf_$year${month}_unbound-24h-eu-{}.grib
seq 0 50 | parallel -j 16 --compress --tmpdir tmp/ -q cdo --eccodes ymonmul \
    -remapbil,era5l-eu-grid -selvar,e,tp,sd,10u,10v ens/ec-sf_$year${month}_all-24h-eu-{}.grib \
    -selmonth,$mon1,$mon2,$mon3,$mon4,$mon5,$mon6,$mon7,$mon8 -selvar,e,tp,sd era5l/era5l-ecsf_2000-2019_bound_bias.grib \
    ens/ec-bsf_$year${month}_bound-24h-eu-{}.grib
## Make stl2,3,4 from stl1
seq 0 50 |parallel -j 16 --compress --tmpdir tmp/ -q cdo --eccodes ymonadd \
    -aexpr,'stl2=stl1;stl3=stl1;stl4=stl1;' -remapbil,era5l-eu-grid -selvar,stl1 ens/ec-sf_$year${month}_all-24h-eu-{}.grib \
    -selvar,stl1,stl2,stl3,stl4 era5l/era5l-stls-diff+bias-climate-eu.grib \
    ens/ec-bsf_$year${month}_stl-24h-eu-{}.grib

## fix grib attributes
seq 0 50 | parallel -j 16 grib_set -r -s centre=98,setLocalDefinition=1,localDefinitionNumber=15,totalNumber=51,number={} ens/ec-bsf_$year${month}_unbound-24h-eu-{}.grib \
    ens/ec-bsf_$year${month}_unbound-24h-eu-{}-fixed.grib
seq 0 50 | parallel -j 16 grib_set -r -s centre=98,setLocalDefinition=1,localDefinitionNumber=15,totalNumber=51,number={} ens/ec-bsf_$year${month}_bound-24h-eu-{}.grib \
    ens/ec-bsf_$year${month}_bound-24h-eu-{}-fixed.grib
seq 0 50 | parallel -j 16 grib_set -r -s centre=98,setLocalDefinition=1,localDefinitionNumber=15,totalNumber=51,number={} ens/ec-bsf_$year${month}_stl-24h-eu-{}.grib \
    ens/ec-bsf_$year${month}_stl-24h-eu-{}-fixed.grib

## join ensemble members and move to grib folder
grib_copy ens/ec-bsf_$year${month}_unbound-24h-eu-*-fixed.grib grib/ECBSF_$year${month}01T0000_unbound-24h-eu.grib
grib_copy ens/ec-bsf_$year${month}_bound-24h-eu-*-fixed.grib grib/ECBSF_$year${month}01T0000_bound-24h-eu.grib
grib_copy ens/ec-bsf_$year${month}_stl-24h-eu-*-fixed.grib grib/ECBSF_$year${month}01T0000_stl-24h-eu.grib

#grib_set -s edition=2 ec-sf-$year$month-all-24h.grib grib/EC-SF-${year}${month}01T0000-all-24h.grib2
cdo -f nc4 copy grib/ECBSF_$year${month}01T0000_unbound-24h-eu.grib grib/ECBSF_$year${month}01T0000_bound-24h-eu.grib grib/ECBSF_$year${month}01T0000_stl-24h-eu.grib ../bin/harvester_code_hops/data/ecmwf/domains/scandi/fcast_ens/ec-sf-$year$month-ball-24h-eu.nc
#grib_set  -s jScansPositively=0,numberOfForecastsInEnsemble=51 -w jScansPositively=1,numberOfForecastsInEnsemble=0 EC-SF_$year${month}01T0000_all-24h-euro+y.grib grib/EC-SF_$year${month}01T0000_all-24h-euro.grib
sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0
