#!/bin/bash
#
# monthly script for XGBoost prediction for SWI2 in ERA5-Land grid
# give year month as cmd

source ~/.smart
eval "$(conda shell.bash hook)"

conda activate xgb
TMPDIR=/home/smartmet/data/tmp
year=$1
month=$2

cd /home/smartmet/data

grid='era5l'
echo $year $month $grid

#echo 'remap swvls'
# swvl2: ens/ec-sf_${year}${month}_swvls-24h-eu-50-fixLevs.grib remapped to era5l
#[ -s ens/ec-sf_$year${month}_swvls-24h-$abr-50-fixLevs.grib ] && ! [ -s ens/ec-sf_${grid}_$year${month}_swvls-24h-$abr-50-fixLevs.grib ] && \
#seq 0 50 | parallel --tmpdir /home/ubuntu/data/tmp cdo -b P8 -O --eccodes remap,$grid-$abr-grid,ec-sf-$grid-$abr-weights.nc ens/ec-sf_$year${month}_swvls-24h-$abr-{}-fixLevs.grib ens/ec-sf_${grid}_$year${month}_swvls-24h-$abr-{}-fixLevs.grib || echo 'not remappig swvls - already done or no input file'

echo 'remap sl00'
# u10,v10,d2m,t2m,rsn,sd,stl1 ens/ec-sf_${year}${month}_all-24h-eu-50.grib remapped to era5l
#[ -s ens/ec-sf_${year}${month}_all+sde-24h-eu-50.grib ] && ! [ -s ens/ec-sf_${grid}_${year}${month}_sl00utc-24h-eu-50.grib ] && \
seq 0 50 | parallel --tmpdir /home/ubuntu/data/tmp grib_copy -w shortName=2t/2d/stl1/rsn/sde ens/ec-BSF_${year}${month}_unbound-24h-eu-{}-fixed.grib ens/ec-BSF_${year}${month}_snow-24h-eu-{}-fixed.grib  \
    ens/ec-sf_${grid}_${year}${month}_sl00utc-24h-eu-{}.grib || echo 'not remappig 00utc - already done or no input file'
#cdo -b P8 -O --eccodes merge -selname,2d,2t,stl1 ens/ec-BSF_${year}${month}_unbound-24h-eu-{}.grib -selname,rsn,sde ens/ec-BSF_${year}${month}_snow-24h-eu-{}.grib 

echo 'remap accumulated'
# tp,e,slhf,sshf,ro,str,strd,ssr,ssrd,sf ens/disacc_${year}${month}_50.grib remapped to era5l
#[ -s ens/disacc_${year}${month}_50.grib ] && ! [ -s ens/disacc_${grid}_${year}${month}_50.grib ] && \
 seq 0 50 | parallel --tmpdir /home/ubuntu/data/tmp cdo -b P8 -O --eccodes remap,$grid-$abr-grid,ec-sf-$grid-$abr-weights.nc -shifttime,1day \
 -selname,e,tp,slhf,sshf,ro,str,strd,ssr,ssrd,sf ens/disacc_${year}${month}_{}.grib ens/disacc_${grid}_${year}${month}_{}.grib \
#|| echo 'not remappig disacc - already done or no input files'
#[ -s ens/disacc_${grid}_${year}${month}_50.grib ] && ! [ -s ens/disacc_${grid}_${year}${month}_50-fixed.grib ] && \
seq 0 50 | parallel --tmpdir /home/ubuntu/data/tmp grib_set -s jScansPositively=0 ens/disacc_${grid}_${year}${month}_{}.grib ens/disacc_${grid}_${year}${month}_{}-fixed.grib \
#|| echo 'not fixing disacc - already done or no input files'

### without runsums results have no significant change so discarded (12/2024)
#echo 'runsums'
# rolling cumsums cdo 
#[ -s ens/disacc_${grid}_${year}${month}_50.grib ] && ! [ -s ens/ec-sf_runsums_${grid}_${year}${month}_50.grib ] && \
# seq 0 50 | parallel --tmpdir /home/ubuntu/data/tmp cdo -b P8 -O --eccodes runsum,15 -selname,e,tp,ro ens/disacc_${grid}_${year}${month}_{}.grib ens/ec-sf_runsums_${grid}_${year}${month}_{}.grib \
# || echo 'not doing runsums - already done or no input files'
#! [ -s ens/ec-sf_runsums_${grid}_${year}${month}_50-fixed.grib ] && \
# seq 0 50 | parallel --tmpdir /home/ubuntu/data/tmp grib_set -s jScansPositively=0 ens/ec-sf_runsums_${grid}_${year}${month}_{}.grib ens/ec-sf_runsums_${grid}_${year}${month}_{}-fixed.grib 

# laihv lailv
#! [ -s ens/ECC_${year}${month}01T000000_laihv-eu-day.grib ] && ! [ -s ens/ECC_${year}${month}01T000000_lailv-eu-day.grib ] && \
    diff=$(($year - 2020)) && \
    cdo -shifttime,${diff}years -shifttime,-12hour grib/ECC_20000101T000000_laihv-eu-day.grib ens/ECC_${year}${month}01T000000_laihv-eu-day.grib && \
    cdo -shifttime,${diff}years -shifttime,-12hour grib/ECC_20000101T000000_lailv-eu-day.grib ens/ECC_${year}${month}01T000000_lailv-eu-day.grib && \
    cdo -shifttime,${diff}years grib/SWIC_20000101T000000_2020_2015-2022_swis-ydaymean-eu-9km-fixed.grib ens/SWIC_${year}${month}01T000000_2020_2015-2022_swis-ydaymean-eu-9km-fixed.grib || echo 'not shifting'

echo 'start xgb predict'
# add runsums file here as input if needed
seq 0 50 | parallel --tmpdir /home/ubuntu/data/tmp -j3  python /home/ubuntu/bin/xgb-predict-swi2-${grid}.py ens/ec-BSF_${year}${month}_swvls-24h-eu-{}-fixed.grib ens/ec-sf_${grid}_${year}${month}_sl00utc-24h-eu-{}.grib  ens/disacc_${grid}_${year}${month}_{}-fixed.grib ens/ECC_${year}${month}01T000000_laihv-eu-day.grib ens/ECC_${year}${month}01T000000_lailv-eu-day.grib ens/SWIC_${year}${month}01T000000_2020_2015-2022_swis-ydaymean-eu-9km-fixed.grib ens/ECXSF_${year}${month}_swi2_${grid}_out-{}.nc

echo 'netcdf to grib'
# netcdf to grib
seq 0 50 | parallel --tmpdir /home/ubuntu/data/tmp cdo -b 10 -f grb2 copy -setparam,41.228.192 -setmissval,-9.e38 ens/ECXSF_${year}${month}_swi2_${grid}_out-{}.nc ens/ECXSF_${year}${month}_swi2_${grid}_out-{}.grib #|| echo "NO input or already netcdf to grib1"

echo 'grib fix'
# fix grib attributes
seq 0 50 | parallel --tmpdir /home/ubuntu/data/tmp grib_set -r -s edition=1,centre=98,setLocalDefinition=1,localDefinitionNumber=15,totalNumber=51,number={} ens/ECXSF_${year}${month}_swi2_${grid}_out-{}.grib \
ens/ECXSF_${year}${month}_swi2_${grid}_out-{}-fixed.grib
# || echo "NOT fixing swi2 grib attributes - no input or already produced"

echo 'join'
# join ensemble members and move to grib folder
grib_copy ens/ECXSF_${year}${month}_swi2_${grid}_out-*-fixed.grib grib/ECXSF_${year}${month}01T000000_swi2-24h-eu-${grid}.grib || echo "NOT joining pl-pp ensemble members - no input or already produced"
#wait 
