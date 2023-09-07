#!/bin/bash
#
# monthly script for XGBoost prediction for SWI2 

source ~/.smart
eval "$(conda shell.bash hook)"

conda activate xgb
cd /home/smartmet/data

year='2023'
month='08'
mon2=$(expr $month + 0)
mon1=$(expr $month - 1)
era='era5l'

echo 'remap swvls'
# swvl2: ens/ec-sf_202308_swvls-24h-eu-49-fixLevs.grib remapped to era5l
[ -f ens/ec-sf_$year${month}_swvls-24h-$abr-49-fixLevs.grib ] && ! [ -f ens/ec-sf_$era_$year${month}_swvls-24h-$abr-49-fixLevs.grib ] && \
seq 0 50 | parallel cdo -b P12 -O --eccodes remap,$era-$abr-grid,ec-sf-$era-$abr-weights.nc ens/ec-sf_$year${month}_swvls-24h-$abr-{}-fixLevs.grib ens/ec-sf_era5l_$year${month}_swvls-24h-$abr-{}-fixLevs.grib || echo 'not remappig swvls - already done or no input file'

echo 'remap sl00'
# u10,v10,d2m,t2m,rsn,sd,stl1 ens/ec-sf_202308_all-24h-eu-49.grib remapped to era5l
[ -f ens/ec-sf_202308_all-24h-eu-49.grib ] && ! [ -f ens/ec-sf_era5l_202308_sl00utc-24h-eu-49.grib ] && \
seq 0 50 | parallel cdo -b P12 -O --eccodes remap,$era-$abr-grid,ec-sf-$era-$abr-weights.nc -selname,10u,10v,2d,2t,rsn,sd,stl1 ens/ec-sf_202308_all-24h-eu-{}.grib ens/ec-sf_era5l_202308_sl00utc-24h-eu-{}.grib || echo 'not remappig 00utc - already done or no input file'

echo 'remap accumulated'
# tp,e,slhf,sshf,ro,str,strd,ssr,ssrd,sf ens/disacc-202308-49.grib remapped to era5l
[ -f ens/disacc-202308-49.grib ] && ! [ -f ens/disacc-era5l-202308-49.grib ] && \
seq 0 50 | parallel cdo -b P12 -O --eccodes remap,$era-$abr-grid,ec-sf-$era-$abr-weights.nc -selname,e,tp,slhf,sshf,ro,str,strd,ssr,ssrd,sf ens/disacc-202308-{}.grib ens/disacc-era5l-202308-{}.grib || echo 'not remappig disacc - already done or no input file'

echo 'runsums'
# rolling cumsums cdo 
[ -f ens/disacc-era5l-202308-49.grib ] && ! [ -f ens/ec-sf_runsums_202308-49.grib ] && \
seq 0 50 | parallel cdo -b P12 -O --eccodes shifttime,1day -runsum,15 -selname,e,tp,ro ens/disacc-era5l-202308-{}.grib ens/ec-sf_runsums_202308-{}.grib || echo 'not doing stuff'

#echo 'laihv lailv'
# laihv lailv: shifttime ja karkausvuosi? 
#! [ -f ECC_${year}0101T000000_laihv-eu-day.grib ] && ! [ -f ECC_${year}0101T000000_lailv-eu-day.grib ] && \
#diff=$(($year - 2020)) && \
#cdo -shifttime,${diff}years grib/ECC_20000101T000000_laihv-eu-day.grib ECC_${year}0101T000000_laihv-eu-day.grib && \
#cdo -shifttime,${diff}years grib/ECC_20000101T000000_lailv-eu-day.grib ECC_${year}0101T000000_lailv-eu-day.grib || echo 'not shifting'

# soilgrids?

echo 'start xgb predict'
seq 0 50 | parallel -j4 python /home/ubuntu/bin/xgb-predict-swi2-V2.py ens/ec-sf_era5l_202308_swvls-24h-eu-{}-fixLevs.grib ens/ec-sf_era5l_202308_sl00utc-24h-eu-{}.grib ens/ec-sf_runsums_202308-{}.grib ens/disacc-era5l-202308-{}.grib ens/ECXBSF_swi2_out_dev-{}.nc

echo 'netcdf to grib'
# netcdf to grib
seq 0 50 | parallel cdo -b 16 -f grb2 copy -setparam,41.228.192 -setmissval,-9.e38 ens/ECXBSF_swi2_out_dev-{}.nc ens/ECXBSF_swi2_out_dev-{}.grib #|| echo "NO input or already netcdf to grib1"

echo 'grib fix'
# fix grib attributes
seq 0 50 | parallel grib_set -r -s centre=86,productDefinitionTemplateNumber=1,totalNumber=51,number={} ens/ECXBSF_swi2_out_dev-{}.grib \
ens/ECXBSF_swi2_out_dev-{}-fixed.grib
# || echo "NOT fixing swi2 grib attributes - no input or already produced"

echo 'join'
# join ensemble members and move to grib folder
grib_copy ens/ECXBSF_swi2_out_dev-*-fixed.grib grib/ECXB2SF_20230801T000000_swi2-24h-eu-dev-V2-fixed.grib || echo "NOT joining pl-pp ensemble members - no input or already produced"
#wait 
