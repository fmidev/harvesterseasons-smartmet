#!/bin/env bash
# get NASA NEXX GDDP
# syntax: get-nex-gddp.sh <date>
#conda activate pandas
yr=$1
doy=$(date -d "$yr-12-30" +%j)
mdl=$2
scn=$3

cd /home/ubuntu/data/
cdo -O -a -s -f grb1 -b P12 copy -setgrid,era5-eu-grid -setname,avg_2r \
 https://ds.nccs.nasa.gov/thredds/dodsC/AMES/NEX/GDDP-CMIP6/$mdl/$scn/r1i1p1f1/hurs/hurs_day_${mdl}_${scn}_r1i1p1f1_gn_${yr}_v1.1.nc?time[0:1:$doy],lat[0:1:599],lon[0:1:1439],hurs[0:1:$doy][339:1:539][599:1:919]\
 cmip6/CMIP6_${yr}0101120000_$mdl-$scn-rh-eu.grib
cdo -O -a -s -f grb1 -b P12 copy -setgrid,era5-eu-grid -setname,mx2t24 \
 https://ds.nccs.nasa.gov/thredds/dodsC/AMES/NEX/GDDP-CMIP6/$mdl/$scn/r1i1p1f1/tasmax/tasmax_day_${mdl}_${scn}_r1i1p1f1_gn_${yr}.nc?time[0:1:$doy],lat[0:1:599],lon[0:1:1439],tasmax[0:1:$doy][339:1:539][599:1:919]\
 cmip6/CMIP6_${yr}0101120000_$mdl-$scn-t2mx24-eu.grib
cdo -O -a -s -f grb1 -b P12 copy -setgrid,era5-eu-grid -setname,mx2t24 \
 https://ds.nccs.nasa.gov/thredds/dodsC/AMES/NEX/GDDP-CMIP6/$mdl/$scn/r1i1p1f1/tasmin/tasmin_day_${mdl}_${scn}_r1i1p1f1_gn_${yr}.nc?time[0:1:$doy],lat[0:1:599],lon[0:1:1439],tasmin[0:1:$doy][339:1:539][599:1:919]\
 cmip6/CMIP6_${yr}0101120000_$mdl-$scn-t2mn24-eu.grib
cdo -O -a -s -f grb1 -b P12 copy -setgrid,era5-eu-grid -setname,mean2t24 \
 https://ds.nccs.nasa.gov/thredds/dodsC/AMES/NEX/GDDP-CMIP6/$mdl/$scn/r1i1p1f1/tas/tas_day_${mdl}_${scn}_r1i1p1f1_gn_${yr}.nc?time[0:1:$doy],lat[0:1:599],lon[0:1:1439],tas[0:1:$doy][339:1:539][599:1:919]\
 cmip6/CMIP6_${yr}0101120000_$mdl-$scn-t2mn24-eu.grib
cdo -O -a -s -f grb1 -b P12 copy -setgrid,era5-eu-grid -setname,10si \
 https://ds.nccs.nasa.gov/thredds/dodsC/AMES/NEX/GDDP-CMIP6/$mdl/$scn/r1i1p1f1/sfcWind/sfcWind_day_${mdl}_${scn}_r1i1p1f1_gn_${yr}.nc?time[0:1:$doy],lat[0:1:599],lon[0:1:1439],sfcWind[0:1:$doy][339:1:539][599:1:919]\
 cmip6/CMIP6_${yr}0101120000_$mdl-$scn-ws-eu.grib
cdo -O -a -s -f grb1 -b P12 copy -setgrid,era5-eu-grid -setname,tp \
 https://ds.nccs.nasa.gov/thredds/dodsC/AMES/NEX/GDDP-CMIP6/$mdl/$scn/r1i1p1f1/pr/pr_day_${mdl}_${scn}_r1i1p1f1_gn_${yr}_v1.1.nc?time[0:1:$doy],lat[0:1:599],lon[0:1:1439],pr[0:1:$doy][339:1:539][599:1:919]\
 cmip6/CMIP6_${yr}0101120000_$mdl-$scn-tp-eu.grib
cdo -O -a -s -f grb1 -b P12 copy -setgrid,era5-eu-grid -setname,msdtrf \
 https://ds.nccs.nasa.gov/thredds/dodsC/AMES/NEX/GDDP-CMIP6/$mdl/$scn/r1i1p1f1/rkds/rlds_day_${mdl}_${scn}_r1i1p1f1_gn_${yr}.nc?time[0:1:$doy],lat[0:1:599],lon[0:1:1439],rlds[0:1:$doy][339:1:539][599:1:919]\
 cmip6/CMIP6_${yr}0101120000_$mdl-$scn-rlds-eu.grib
cdo -O -a -s -f grb1 -b P12 copy -setgrid,era5-eu-grid -setname,msdsrf \
 https://ds.nccs.nasa.gov/thredds/dodsC/AMES/NEX/GDDP-CMIP6/$mdl/$scn/r1i1p1f1/rsds/rsds_day_${mdl}_${scn}_r1i1p1f1_gn_${yr}.nc?time[0:1:$doy],lat[0:1:599],lon[0:1:1439],rsds[0:1:$doy][339:1:539][599:1:919]\
 cmip6/CMIP6_${yr}0101120000_$mdl-$scn-rsds-eu.grib
