#!/bin/bash
#
# monthly script for XGBoost prediction for SWI2 
# 08/2023 testing with ens member 5
# notes: very slow remapping even one ens member

source ~/.smart
eval "$(conda shell.bash hook)"

conda activate xgb
cd /home/smartmet/data

year='2023'
month='09'
grid='swi'

# swvl2: ens/ec-sf_${year}${month}_swvls-24h-eu-5-fixLevs.grib remapped to swi ~26min
# sellevel pudottaa aika-askelia jostain syystä
echo 'remap swvl'
[ -f ens/ec-sf_$year${month}_swvls-24h-$abr-5-fixLevs.grib ] && ! [ -f ens/ec-sf_${grid}_$year${month}_swvls-24h-$abr-5-fixLevs.grib ] && \
    cdo -s -b P12 -O --eccodes remap,$grid-$abr-grid,ec-sf-$grid-$abr-weights.nc ens/ec-sf_$year${month}_swvls-24h-$abr-5-fixLevs.grib ens/ec-sf_${grid}_$year${month}_swvls-24h-$abr-5-fixLevs.grib \
    || echo 'not remappig swvls - already done or no input file'

echo 'remap 00utc'
# u10,v10,d2m,t2m,rsn,sd,stl1 ens/ec-sf_${year}${month}_all-24h-eu-5.grib remapped to swi
[ -f ens/ec-sf_${year}${month}_all-24h-eu-5.grib ] && ! [ -f ens/ec-sf_${grid}_${year}${month}_sl00utc-24h-eu-5.grib ] && \
    cdo -s -b P12 -O --eccodes remap,$grid-$abr-grid,ec-sf-$grid-$abr-weights.nc -selname,10u,10v,2d,2t,rsn,sde,stl1 ens/ec-sf_${year}${month}_all+sde-24h-eu-5.grib ens/ec-sf_${grid}_${year}${month}_sl00utc-24h-eu-5.grib \
    || echo 'not remappig 00utc - already done or no input file'

echo 'remap disacc'
# tp,e,slhf,sshf,ro,str,strd,ssr,ssrd,sf ens/disacc-${year}${month}-5.grib remapped to swi
[ -f ens/disacc-${year}${month}-5.grib ] && ! [ -f ens/disacc_${grid}_${year}${month}-5.grib ] && \
    cdo -b P12 -O --eccodes remap,$grid-$abr-grid,ec-sf-$grid-$abr-weights.nc -shifttime,1day -selname,e,tp,slhf,sshf,ro,str,strd,ssr,ssrd,sf ens/disacc-${year}${month}-5.grib ens/disacc_${grid}_${year}${month}-5.grib \
    || echo 'not remappig disacc - already done or no input file'

echo 'rolling sums'
# rolling cumsums cdo 
[ -f ens/disacc_${grid}_${year}${month}-5.grib ] && ! [ -f ens/ec-sf_runsums_${grid}_${year}${month}-5.grib ] && \
    cdo -b P12 -O --eccodes runsum,15 -selname,e,tp,ro ens/disacc_${grid}_${year}${month}-5.grib ens/ec-sf_runsums_${grid}_${year}${month}-5.grib || echo 'not doing stuff'

echo 'laihv jne'
# laihv lailv swi2clim
# 
! [ -f ens/ECC_${year}${month}01T000000_2020-21_laihv-eu-swi-day.grib ] && ! [ -f ens/ECC_${year}${month}01T000000_2020-21_laihv-eu-swi-day.grib ] && \
    diff=$(($year - 2020)) && \
    cdo -shifttime,${diff}years grib/ECC_20000101T000000_2020-21_laihv-eu-swi-day.grib ens/ECC_${year}${month}01T000000_2020-21_laihv-eu-swi-day.grib && \
    cdo -shifttime,${diff}years grib//ECC_20000101T000000_2020-21_lailv-eu-swi-day.grib ens/ECC_${year}${month}01T000000_2020-21_lailv-eu-swi-day.grib && \
    cdo -shifttime,${diff}years grib/SWIC_20000101T000000_2020_2015-2022_swis-ydaymean.grib ens/SWIC_${year}${month}01T000000_2020_2015-2022_swis-ydaymean.grib || echo 'not shifting'

echo 'start xgb'
python3 /home/ubuntu/bin/DEV-xgb-predict-swi2-swigrid.py ens/ec-sf_${grid}_${year}${month}_swvls-24h-eu-5-fixLevs.grib ens/ec-sf_${grid}_${year}${month}_sl00utc-24h-eu-5.grib ens/ec-sf_runsums_${grid}_${year}${month}-5.grib ens/disacc_${grid}_${year}${month}-5.grib ens/ECC_${year}${month}01T000000_2020-21_laihv-eu-swi-day.grib ens/ECC_${year}${month}01T000000_2020-21_lailv-eu-swi-day.grib ens/SWIC_${year}${month}01T000000_2020_2015-2022_swis-ydaymean.grib ens/ECXBSF_swi2_${grid}_out_DEV-5.nc

#echo 'netcdf to grib'
# netcdf to grib
#cdo -b 16 -f grb2 copy -setparam,41.228.192 -setmissval,-9.e38 ens/ECXBSF_swi2_${grid}_out_DEV-5.nc ens/ECXBSF_swi2_${grid}_out_DEV-5.grib #|| echo "NO input or already netcdf to grib1"

#echo 'grib fix'
# fix grib attributes
#grib_set -r -s centre=86,productDefinitionTemplateNumber=1,totalNumber=51,number={} ens/ECXBSF_swi2_${grid}_out_DEV-5.grib \
#ens/ECXBSF_swi2_${grid}_out_DEV-5-fixed.grib
# || echo "NOT fixing swi2 grib attributes - no input or already produced"

