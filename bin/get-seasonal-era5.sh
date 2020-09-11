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

echo "y: $year m: $month ending $eyear-$emonth"
## Fetch seasonal data from CDS-API
[ -f ec-sf-$year$month-all-24h-euro.grib ] && echo "SF Data file already downloaded" ||cds-sf-all-24h.py $year $month

# ensure new eccodes and cdo
conda activate xr
## Make bias-adjustement
[ -f ens/ec-sf_$year${month}_all-24h-eu-6.grib ] && echo "Ensemble member files ready" || grib_copy ec-sf-$year$month-all-24h-euro.grib ens/ec-sf_$year${month}_all-24h-eu-[number].grib
seq 0 50 | parallel -j 16 --compress --tmpdir tmp/ cdo --eccodes aexprf,ec-sde.instr -ymonadd \
    -remapbil,era5-eu-grid -selvar,2d,2t,rsn,sd,stl1,swvl1,swvl2,swvl3,swvl4 ens/ec-sf_$year${month}_all-24h-eu-{}.grib \
    -selvar,2d,2t,rsn,sd,stl1,swvl1,swvl2,swvl3,swvl4 era5/era5-ecsf_2000-2019_unbound_bias.grib \
    ens/ec-b2sf_$year${month}_unbound-24h-eu-{}.grib 
seq 0 50 | parallel -j 16 --compress --tmpdir tmp/ -q cdo --eccodes ymonmul \
    -remapbil,era5-eu-grid -aexpr,'ws=sqrt(10u^2+10v^2);' -selvar,10u,10v ens/ec-sf_$year${month}_all-24h-eu-{}.grib \
    -aexpr,'10u=ws;10v=ws;' -selvar,ws era5/era5-ecsf_2000-2019_bound_bias+varc.grib \
    ens/ec-b2sf_$year${month}_bound-24h-eu-{}.grib
seq 0 50 | parallel -j 16 --compress --tmpdir tmp/ "cdo --eccodes mergetime -seltimestep,1 -selvar,e,tp ens/ec-sf_$year${month}_all-24h-eu-{}.grib \
     -sub -seltimestep,2/215 -selvar,e,tp ens/ec-sf_$year${month}_all-24h-eu-{}.grib \
      -seltimestep,1/214 -selvar,e,tp ens/ec-sf_$year${month}_all-24h-eu-{}.grib disacc2-tmp-{}.grib && \
    cdo --eccodes ymonmul -remapbil,era5-eu-grid disacc2-tmp-{}.grib\
     -selvar,e,tp era5/era5-ecsf_2000-2019_bound_bias+varc.grib \
     ens/ec-b2sf_$year${month}_disacc-24h-eu-{}.grib && \
    cdo --eccodes timcumsum ens/ec-b2sf_$year${month}_disacc-24h-eu-{}.grib ens/ec-b2sf_$year${month}_acc-24h-eu-{}.grib"
rm disacc2-tmp-*.grib
## Make stl2,3,4 from stl1
seq 0 50 |parallel -j 16 --compress --tmpdir tmp/ -q cdo --eccodes ymonadd \
    -aexpr,'stl2=stl1;stl3=stl1;stl4=stl1;' -remapbil,era5-eu-grid -selvar,stl1 ens/ec-sf_$year${month}_all-24h-eu-{}.grib \
    -selvar,stl1,stl2,stl3,stl4 era5/era5-stls-diff+bias-climate-eu.grib \
    ens/ec-b2sf_$year${month}_stl-24h-eu-{}.grib

## fix grib attributes
seq 0 50 | parallel -j 16 grib_set -r -s centre=98,setLocalDefinition=1,localDefinitionNumber=15,totalNumber=51,number={} ens/ec-b2sf_$year${month}_unbound-24h-eu-{}.grib \
    ens/ec-b2sf_$year${month}_unbound-24h-eu-{}-fixed.grib
seq 0 50 | parallel -j 16 grib_set -r -s centre=98,setLocalDefinition=1,localDefinitionNumber=15,totalNumber=51,number={} ens/ec-b2sf_$year${month}_bound-24h-eu-{}.grib \
    ens/ec-b2sf_$year${month}_bound-24h-eu-{}-fixed.grib
seq 0 50 | parallel -j 16 grib_set -r -s centre=98,setLocalDefinition=1,localDefinitionNumber=15,totalNumber=51,number={} ens/ec-b2sf_$year${month}_acc-24h-eu-{}.grib \
    ens/ec-b2sf_$year${month}_acc-24h-eu-{}-fixed.grib
seq 0 50 | parallel -j 16 grib_set -r -s centre=98,setLocalDefinition=1,localDefinitionNumber=15,totalNumber=51,number={} ens/ec-b2sf_$year${month}_stl-24h-eu-{}.grib \
    ens/ec-b2sf_$year${month}_stl-24h-eu-{}-fixed.grib

## join ensemble members and move to grib folder
grib_copy ens/ec-b2sf_$year${month}_unbound-24h-eu-*-fixed.grib grib/ECB2SF_$year${month}01T0000_unbound-24h-eu.grib &
grib_copy ens/ec-b2sf_$year${month}_bound-24h-eu-*-fixed.grib grib/ECB2SF_$year${month}01T0000_bound-24h-eu.grib &
grib_copy ens/ec-b2sf_$year${month}_acc-24h-eu-*-fixed.grib grib/ECB2SF_$year${month}01T0000_acc-24h-eu.grib &
grib_copy ens/ec-b2sf_$year${month}_stl-24h-eu-*-fixed.grib grib/ECB2SF_$year${month}01T0000_stl-24h-eu.grib &
wait
rm ens/ec-b2sf_$year${month}_*-24h-eu-*.grib
#grib_set -s edition=2 ec-sf-$year$month-all-24h.grib grib/EC-SF-${year}${month}01T0000-all-24h.grib2
cdo --eccodes -f nc2 merge grib/ECB2SF_$year${month}01T0000_unbound-24h-eu.grib grib/ECB2SF_$year${month}01T0000_bound-24h-eu.grib grib/ECB2SF_$year${month}01T0000_acc-24h-eu.grib -selvar,stl2,stl3,stl4 grib/ECB2SF_$year${month}01T0000_stl-24h-eu.grib ../bin/harvester_code_hops/data/ecmwf/domains/scandi/fcast_ens/ec-sf-$year$month-b2all-24h-eu.nc
#grib_set  -s jScansPositively=0,numberOfForecastsInEnsemble=51 -w jScansPositively=1,numberOfForecastsInEnsemble=0 EC-SF_$year${month}01T0000_all-24h-euro+y.grib grib/EC-SF_$year${month}01T0000_all-24h-euro.grib
#sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0
