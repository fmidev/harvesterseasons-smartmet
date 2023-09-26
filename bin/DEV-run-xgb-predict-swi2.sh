#!/bin/bash
#
# monthly script for XGBoost prediction for SWI2 
# 08/2023 testing with ens member 5

source ~/.smart
eval "$(conda shell.bash hook)"

conda activate xgb
cd /home/smartmet/data

year='2023'
month='09'
mon2=$(expr $month + 0)
mon1=$(expr $month - 1)
era='era5l'

# swvl2: ens/ec-sf_202309_swvls-24h-eu-5-fixLevs.grib remapped to era5l
#[ -f ens/ec-sf_$year${month}_swvls-24h-$abr-5-fixLevs.grib ] && ! [ -f ens/ec-sf_$era_$year${month}_swvls-24h-$abr-5-fixLevs.grib ] && \
    cdo -s -b P12 -O --eccodes remap,$era-$abr-grid,ec-sf-$era-$abr-weights.nc ens/ec-sf_$year${month}_swvls-24h-$abr-5-fixLevs.grib ens/ec-sf_era5l_$year${month}_swvls-24h-$abr-5-fixLevs.grib \
    || echo 'not remappig swvls - already done or no input file'

# u10,v10,d2m,t2m,rsn,sd,stl1 ens/ec-sf_202309_all-24h-eu-5.grib remapped to era5l
[ -f ens/ec-sf_202309_all-24h-eu-5.grib ] && ! [ -f ens/ec-sf_era5l_202309_sl00utc-24h-eu-5.grib ] && \
    cdo -s -b P12 -O --eccodes remap,$era-$abr-grid,ec-sf-$era-$abr-weights.nc -selname,10u,10v,2d,2t,rsn,sde,stl1 ens/ec-sf_202309_all+sde-24h-eu-5.grib ens/ec-sf_era5l_202309_sl00utc-24h-eu-5.grib \
    || echo 'not remappig 00utc - already done or no input file'


# tp,e,slhf,sshf,ro,str,strd,ssr,ssrd,sf ens/disacc-202309-5.grib remapped to era5l
[ -f ens/disacc-202309-5.grib ] && ! [ -f ens/disacc-era5l-202309-5.grib ] && \
    cdo -b P12 -O --eccodes remap,$era-$abr-grid,ec-sf-$era-$abr-weights.nc -shifttime,1day -selname,e,tp,slhf,sshf,ro,str,strd,ssr,ssrd,sf ens/disacc-202309-5.grib ens/disacc-era5l-202309-5.grib \
    || echo 'not remappig disacc - already done or no input file'

# rolling cumsums cdo 
[ -f ens/disacc-era5l-202309-5.grib ] && ! [ -f ens/ec-sf_runsums_202309-5.grib ] && \
    cdo -b P12 -O --eccodes runsum,15 -selname,e,tp,ro ens/disacc-era5l-202309-5.grib ens/ec-sf_runsums_202309-5.grib || echo 'not doing stuff'

# laihv lailv: shifttime ja karkausvuosi? 
! [ -f ens/ECC_${year}${month}01T000000_laihv-eu-day.grib ] && ! [ -f ens/ECC_${year}${month}01T000000_lailv-eu-day.grib ] && \
    diff=$(($year - 2020)) && \
    cdo -shifttime,${diff}years -shifttime,-12hour grib/ECC_20000101T000000_laihv-eu-day.grib ens/ECC_${year}${month}01T000000_laihv-eu-day.grib && \
    cdo -shifttime,${diff}years -shifttime,-12hour grib/ECC_20000101T000000_lailv-eu-day.grib ens/ECC_${year}${month}01T000000_lailv-eu-day.grib && \
    cdo -shifttime,${diff}years grib/SWIC_20000101T000000_2020_2015-2022_swis-ydaymean-eu-9km-fixed.grib ens/SWIC_${year}${month}01T000000_2020_2015-2022_swis-ydaymean-eu-9km-fixed.grib || echo 'not shifting'

# soilgrids?

# dtm-slope/aspect/height?

python3 /home/ubuntu/bin/DEV-xgb-predict-swi2-2.py ens/ec-sf_era5l_202309_swvls-24h-eu-5-fixLevs.grib ens/ec-sf_era5l_202309_sl00utc-24h-eu-5.grib ens/ec-sf_runsums_202309-5.grib ens/disacc-era5l-202309-5.grib ens/ECC_${year}${month}01T000000_laihv-eu-day.grib ens/ECC_${year}${month}01T000000_lailv-eu-day.grib ens/SWIC_${year}${month}01T000000_2020_2015-2022_swis-ydaymean-eu-9km-fixed.grib ens/ECXSF_swi2_out_DEV-5.nc

#echo 'netcdf to grib'
# netcdf to grib
#cdo -b 16 -f grb2 copy -setparam,41.228.192 -setmissval,-9.e38 ens/ECXBSF_swi2_out_DEV-5.nc ens/ECXBSF_swi2_out_DEV-5.grib #|| echo "NO input or already netcdf to grib1"

#echo 'grib fix'
# fix grib attributes
#grib_set -r -s centre=86,productDefinitionTemplateNumber=1,totalNumber=51,number={} ens/ECXBSF_swi2_out_DEV-5.grib \
#ens/ECXBSF_swi2_out_DEV-5-fixed.grib
# || echo "NOT fixing swi2 grib attributes - no input or already produced"

