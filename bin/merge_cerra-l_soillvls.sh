#!/bin/bash
#
# CERRA has 14 soil layers compared to IFS models. 11 are needed to calculate the IFS equivalent levels
# - 0.01, 0.04, 0.1, 0.2, 0.4, 0.6, 0.8, 1, 1.5, 2, 3, 5, 8, and 12 m.
# this script merges CERRA-L levels 0,1,2 (-1cm,-4,-10)to SWVL1 or STL1 0-7cm 
# naming vsw as swvl, sot as stl, lqvm as liqvsm with according number
# give as argument a file 
eval "$(conda shell.bash hook)"
conda activate xgb

in=$1
out=${in:0:-5}
# 0,1,2
cdo -b P10 setname,swvl1 -divc,7 -add -sellevel,0 -selname,vsw $in -add -mulc,3 -sellevel,1 -selname,vsw $in \
 -divc,2 -sellevel,2 -selname,vsw $in $out-swvl1.grib &
#cdo -b P10 setname,stl1 -setlevel,0 -divc,7 -add -sellevel,0 -selname,sot $in -add -mulc,3 -sellevel,1 -selname,sot $in \
# -divc,2 -sellevel,2 -selname,sot $in $out-stl1.grib &
#cdo -b P10 setname,liqvsm -setlevel,0 -divc,7 -add -sellevel,0 -selname,liqvsm $in -add -mulc,3 -sellevel,1 -selname,liqvsm $in \
# -divc,2 -sellevel,2 -selname,liqvsm $in $out-liqvsm1.grib &
# 2,3,4 (-10,-20,-40cm) to SWVL2 7-28cm
cdo -b P10 setname,swvl2 -divc,21 -add -mulc,3 -sellevel,2 -selname,vsw $in -add -mulc,10 -sellevel,3 -selname,vsw $in \
 -mulc,8 -sellevel,4 -selname,vsw $in $out-swvl2.grib &
#cdo -b P10 setname,stl2 -setlevel,1 -divc,34 -add -mulc,3 -sellevel,2 -selname,sot $in -add -mulc,34 -divc,2.1 -sellevel,3 -selname,sot $in \
# -mulc,8 -sellevel,4 -selname,sot $in $out-stl2.grib &
#cdo -b P10 setname,liqvsm -setlevel,1 -divc,34 -add -mulc,3 -sellevel,2 -selname,liqvsm $in -add -mulc,34 -divc,2.1 -sellevel,3 -selname,liqvsm $in \
# -mulc,8 -sellevel,4 -selname,liqvsm $in $out-liqvsm2.grib &
# 4,5,6,7 (-40,-60,-80,-100cm) to SWVL3 28-100cm
cdo -b P10 setname,swvl3 -divc,72 -add -mulc,12 -sellevel,4 -selname,vsw $in -add -mulc,20 -sellevel,5 -selname,vsw $in \
 -add -mulc,20 -sellevel,6 -selname,vsw $in -mulc,20 -sellevel,7 -selname,vsw $in $out-swvl3.grib &
#cdo -b P10 setname,stl3 -setlevel,2 -divc,34 -add -mulc,3 -sellevel,2 -selname,sot $in -add -mulc,10 -sellevel,3 -selname,sot $in \
# -add -mulc,8 -sellevel,4 -selname,sot $in -mulc,8 -sellevel,4 -selname,sot $in $out-stl2.grib &
#cdo -b P10 setname,liqvsm -setlevel,2 -divc,34 -add -mulc,3 -sellevel,2 -selname,liqvsm $in -add -mulc,10 -sellevel,3 -selname,liqvsm $in \
# -add -mulc,8 -sellevel,4 -selname,liqvsm $in -mulc,8 -sellevel,4 -selname,liqvsm $in $out-liqvsm2.grib &
# 8,9,10 (-1.5,-2,-3m) to SWVL4 100-255cm
cdo -b P10 setname,swvl4 -divc,155 -add -mulc,50 -sellevel,2 -selname,vsw $in -add -mulc,50 -sellevel,3 -selname,vsw $in \
 -mulc,55 -sellevel,4 -selname,vsw $in $out-swvl4.grib &
