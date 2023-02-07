#!/bin/bash
# cmd line parameters are observation timeseries file and model timeseries file
# files are assumed to have same timesteps, run this in ~/data dir
eval "$(conda shell.bash hook)"
obspath=$1
modpath=$2
obsfile=${obspath##*/}
modfile=${modpath##*/}
otags=(${obsfile//_/ })
mtags=(${modfile//-/ })
unbound="2d,2t,skt,rsn,sd,stl1,swvl1,swvl2,swvl3,swvl4"
prefix="${otags[0]}"-"${mtags[0]}${mtags[1]:0:2}"_"${otags[1]}"
ending="eu.grib"

echo ${prefix}_unbound_bias_"${otags[-1]}"
conda activate xr
# BIAS substraction method for unbounded variables
cdo --eccodes -O sub \
    -ymonmean -selvar,$unbound $obspath \
    -ymonmean -remapbil,${otags[0]}-eu-grid -selvar,$unbound $modpath \
    ${prefix}_unbound_bias_$ending &
# division method for bounded variables
cdo --eccodes -O div \
    -ymonmean -expr,'ws=sqrt(10u^2+10v^2)' -selvar,10u,10v $obspath \
    -ymonmean -remapbil,${otags[0]}-eu-grid -chname,10si,ws -selvar,10si $modpath \
    ${prefix}_ws_bias_$ending &
# division method for tp- and erate variables
cdo --eccodes -O div \
    -ymonmean -selvar,tp $obspath \
    -ymonmean -remapbil,${otags[0]}-eu-grid -expr,'tp=tprate*3600*24;tp=((tp<0.0001)?0:tp);' -selvar,tprate $modpath \
    ${prefix}_tp_bias_$ending &
cdo --eccodes -O div \
    -ymonmean -selvar,e $obspath \
    -ymonmean -remapbil,${otags[0]}-eu-grid -expr,'e=erate*3600*24;' -selvar,erate $modpath \
    ${prefix}_e_bias_$ending &
# VARIANCE division also for unbounded variables
cdo --eccodes -O div  \
    -ymonvar1 -selvar,$unbound $obspath \
    -ymonvar1 -remapbil,${otags[0]}-eu-grid -selvar,$unbound $modpath \
    ${prefix}_unbound_varc_$ending &
# division method for bounded variables
cdo --eccodes -O div \
    -ymonvar1 -expr,'ws=sqrt(10u^2+10v^2)' -selvar,10u,10v $obspath \
    -ymonvar1 -remapbil,${otags[0]}-eu-grid -chname,10si,ws -selvar,10si $modpath \
    ${prefix}_ws_varc_$ending &
# division method for tp- and erate variables
cdo --eccodes -O div \
    -ymonvar1 -selvar,tp $obspath \
    -ymonvar1 -remapbil,${otags[0]}-eu-grid -expr,'tp=tprate*3600*24;tp=((tp<0.0001)?0:tp);' -selvar,tprate $modpath \
    ${prefix}_tp_varc_$ending &
cdo --eccodes -O div \
    -ymonvar1 -selvar,e $obspath \
    -ymonvar1 -remapbil,${otags[0]}-eu-grid -expr,'e=erate*3600*24' -selvar,erate $modpath \
    ${prefix}_e_varc_$ending &
wait
cdo --eccodes -O merge ${prefix}_e_bias_$ending ${prefix}_tp_bias_$ending ${prefix}_ws_bias_$ending ${prefix}_bound_bias_$ending &
cdo --eccodes -O merge ${prefix}_e_varc_$ending ${prefix}_tp_varc_$ending ${prefix}_ws_varc_$ending ${prefix}_bound_varc_$ending &
wait
if [ ${otags[0]} -eq 'era5l' ] 
then
    cdo --eccodes -O setmiss era5l/era5l-"${mtags[0]}${mtags[1]:0:2}"_"${otags[1]}"_unbound_bias_$ending -remap,era5l-eu-grid,era5-era5l-eu-weights.nc \
     era5/era5-"${mtags[0]}${mtags[1]:0:2}"_"${otags[1]}"_unbound_bias_$ending era5l/era5l-"${mtags[0]}${mtags[1]:0:2}"_"${otags[1]}"_unbound_filled_bias_$ending
    cdo --eccodes -O setmiss era5l/era5l-"${mtags[0]}${mtags[1]:0:2}"_"${otags[1]}"_unbound_varc_$ending -remap,era5l-eu-grid,era5-era5l-eu-weights.nc \
     era5/era5-"${mtags[0]}${mtags[1]:0:2}"_"${otags[1]}"_unbound_varc_$ending era5l/era5l-"${mtags[0]}${mtags[1]:0:2}"_"${otags[1]}"_unbound_filled_varc_$ending
    cdo --eccodes -O setmiss era5l/era5l-"${mtags[0]}${mtags[1]:0:2}"_"${otags[1]}"_bound_bias_$ending -remap,era5l-eu-grid,era5-era5l-eu-weights.nc \
     era5/era5-"${mtags[0]}${mtags[1]:0:2}"_"${otags[1]}"_bound_bias_$ending era5l/era5l-"${mtags[0]}${mtags[1]:0:2}"_"${otags[1]}"_bound_filled_bias_$ending
    cdo --eccodes -O setmiss era5l/era5l-"${mtags[0]}${mtags[1]:0:2}"_"${otags[1]}"_bound_varc_$ending -remap,era5l-eu-grid,era5-era5l-eu-weights.nc \
     era5/era5-"${mtags[0]}${mtags[1]:0:2}"_"${otags[1]}"_bound_varc_$ending era5l/era5l-"${mtags[0]}${mtags[1]:0:2}"_"${otags[1]}"_bound_filled_varc_$ending
    cdo --eccodes -O mul ${prefix}_bound_filled_bias_$ending era5l/${prefix}_bound_filled_varc_$ending era5l/${prefix}_bound_bias+varc_$ending
    cdo --eccodes -O mul ${prefix}_unbound_filled_bias_$ending era5l/${prefix}_unbound_filled_varc_$ending era5l/${prefix}_unbound_bias+varc_$ending
    parallel mv {} {= s:_filled:: =} ::: ${prefix}_*_filled*
else
    cdo --eccodes -O mul ${prefix}_bound_bias_$ending ${prefix}_bound_varc_$ending ${prefix}_bound_bias+varc_$ending 
    cdo --eccodes -O mul ${prefix}_unbound_bias_$ending ${prefix}_unbound_varc_$ending ${prefix}_unbound_bias+varc_$ending 
    mv ${prefix}_*_$ending era5/
fi
