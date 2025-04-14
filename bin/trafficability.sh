#!/bin/bash
eval "$(conda shell.bash hook)"
conda activate xgb
set -e
date=$1
cd /home/smartmet/data
# Input file containing ensemble data
input="grib/ECENS_${date}T000000_era5l_sfc-all+sde-nd-6h.grib"
inputswi="grib/ECENS_${date}T000000_era5l_swi-nd-6h.grib"

# Temporary files
summer="summer.nc"
winter="winter.nc"
merged="merged.nc"
final="final.nc"

echo "Processing summer condition..."
# Create binary field: 1 if soil_swci < 69, compute ensemble mean, then classify
cdo -s --eccodes -f nc4c expr,'summer=(sw_bin>=0.9)?2:((sw_bin<=0.1)?0:1)' -ensmean -selname,sw_bin\
 -expr,'sw_bin=(swvl2<0.4)?1:0' -selname,swvl2 "$input" "$summer"
# -aexpr,'sw_bin=(swi<69)?1:0' "$inputswi" "$summer"

echo "Processing winter condition..."
# Create binary fields for soil temperature and snow depth, combine with OR, compute ensemble mean, then classify
cdo -s --eccodes -f nc4c expr,'winter=(win_bin>=0.9)?2:((win_bin<=0.1)?0:1)' -ensmean -selname,win_bin\
 -expr,'temp_bin=(stl2<-0.1)?1:0;snow_bin=(sde>0.4)?1:0;win_bin=max(temp_bin,snow_bin)'\
 -selname,sde,stl2 "$input" "$winter"

echo "Combining summer and winter indices with max operation..."
# Merge summer and winter files and compute final index as max(summer, winter)
cdo expr,'traf=max(summer,winter)' [ -merge "$summer" "$winter" ] "$final"

echo "Processing complete. Final combined index is saved in: $final"
