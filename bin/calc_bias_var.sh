#!/bin/bash
# cmd line parameters are observation timeseries file and model timeseries file
# files are assumed to have same timesteps, run this in ~/data dir
eval "$(conda shell.bash hook)"
obspath=$1
modpath=$2
obsfile=${obspath##*/}
modfile=${modpath##*/}
otags=(${obsfile//_/ })
mtags=(${modfile//_/ })
unbound="$3"
evar="$4"
eevar="$5"

[[ $# -ge 4  ]] && evar=$4 || evar=$unbound
prefix="${otags[0]}"-"${mtags[0]}-${mtags[1]}"_"${otags[1]}"
ending="eu.grib"

echo ${prefix}_${unbound}_bias_"${otags[-1]}"
conda activate cdo
cd /home/ubuntu/data
# Step 1: Bias (mean difference)
cdo --eccodes -O -f grb2 -b P16 setparam,"$eevar" -setday,16 -settime,00:00:00 -sub \
    -ymonmean -selvar,$evar $obspath \
    -ymonmean -remapdis,${otags[0]}-eu-grid -selvar,$unbound $modpath \
    ${prefix}_${unbound}_bias_$ending &

# Step 2: Variance scaling factor (std ratio, NOT variance ratio!)
cdo --eccodes -O -f grb2 -b P16 setparam,"$eevar" -setday,16 -settime,00:00:00 -div  \
    -ymonstd1 -selvar,$evar $obspath \
    -ymonstd1 -remapdis,${otags[0]}-eu-grid -selvar,$unbound $modpath \
    ${prefix}_${unbound}_varc_$ending &

# Step 3: Apply correction: X_corrected = X_model × varc + bias
# (X_model - μ_model) × (σ_obs/σ_model) + μ_obs
# = X_model × (σ_obs/σ_model) - μ_model × (σ_obs/σ_model) + μ_obs
