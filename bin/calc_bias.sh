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
unbound=2d,2t,stl1,swvl1,swvl2,swvl3,swvl4,rsn,sd

conda activate xr
# BIAS substraction method for unbounded variables
cdo --eccodes sub \
    -ymonmean -selvar,$unbound $obspath \
    -ymonmean -remapbil,${otags[0]}-eu-grid -selvar,$unbound $modpath \
    "${otags[0]}"-"${mtags[0]}$mtags[1]"_"${otags[1]}"_unbound_bias_"${mtags[-1]}" &
# division method for bounded variables
cdo --eccodes div \
    -ymonmean -expr,'ws=sqrt(10u^2+10v^2)' -selvar,10u,10v $obspath \
    -ymonmean -remapbil,${otags[0]}-eu-grid -chname,10si,ws -selvar,10si $modpath \
    "${otags[0]}"-"${mtags[0]}${mtags[1]}"_"${otags[1]}"_ws_bias_"${mtags[-1]}" &
# division method for tp- and erate variables
cdo --eccodes div \
    -ymonmean -selvar,tp $obspath \
    -ymonmean -remapbil,${otags[0]}-eu-grid -expr,'tp=tprate*3600*24' -selvar,tprate $modpath \
    "${otags[0]}"-"${mtags[0]}${mtags[1]}"_"${otags[1]}"_tp_bias_"${mtags[-1]}" &
cdo --eccodes div \
    -ymonmean -selvar,e $obspath \
    -ymonmean -remapbil,${otags[0]}-eu-grid -expr,'e=erate*3600*24' -selvar,erate $modpath \
    "${otags[0]}"-"${mtags[0]}${mtags[1]}"_"${otags[1]}"_e_bias_"${mtags[-1]}" &
# VARIANCE division also for unbounded variables
cdo --eccodes div  \
    -ymonvar1 -selvar,$unbound $obspath \
    -ymonvar1 -remapbil,${otags[0]}-eu-grid -selvar,$unbound $modpath \
    "${otags[0]}"-"${mtags[0]}${mtags[1]}"_"${otags[1]}"_unbound_varc_"${mtags[-1]}" &
# division method for bounded variables
cdo --eccodes div \
    -ymonvar1 -expr,'ws=sqrt(10u^2+10v^2)' -selvar,10u,10v $obspath \
    -ymonvar1 -remapbil,${otags[0]}-eu-grid -chname,10si,ws -selvar,10si $modpath \
    "${otags[0]}"-"${mtags[0]}${mtags[1]}"_"${otags[1]}"_ws_varc_"${mtags[-1]}" &
# division method for tp- and erate variables
cdo --eccodes div \
    -ymonvar1 -selvar,tp $obspath \
    -ymonvar1 -remapbil,${otags[0]}-eu-grid -expr,'tp=tprate*3600*24' -selvar,tprate $modpath \
    "${otags[0]}"-"${mtags[0]}${mtags[1]}"_"${otags[1]}"_tp_varc_"${mtags[-1]}" &
cdo --eccodes div \
    -ymonvar1 -selvar,e $obspath \
    -ymonvar1 -remapbil,${otags[0]}-eu-grid -expr,'e=erate*3600*24' -selvar,erate $modpath \
    "${otags[0]}"-"${mtags[0]}${mtags[1]}"_"${otags[1]}"_e_varc_"${mtags[-1]}" &
