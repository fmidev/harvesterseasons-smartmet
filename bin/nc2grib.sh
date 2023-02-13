#!/bin/bash


## netcdf to grib (16bit grib and missing values set to -9.e38 ?)
## TP ON NYT MM YKSIKÖISSÄ VAIKKA GRIB YKSIKÖT METRI, MUUTA
# -f ens/ECX${bsf}_$year${month}_tp-euro-50.nc ] && ! [ -f ens/ECX${bsf}_$year${month}_tp-euro-50.grib ] && \
#seq 0 50 | parallel cdo -b 16 -f grb copy -setparam,128.228 -divc,1000 ens/ECX${bsf}_$year${month}_tp-euro-{}.nc ens/ECX${bsf}_$year${month}_tp-euro-{}.grib ||echo "NO input or already netcdf to grib1"


cdo -b 16 -f grb copy -setparam,128.228 -divc,1000  rr_ens_mean_0.1deg_reg_1995-2010_v25.0e.nc rr_ens_mean_0.1deg_reg_1995-2010_v25.0e.grib
grib_set -r -s table2Version=128,indicatorOfParameter=228 rr_ens_mean_0.1deg_reg_1995-2010_v25.0e.grib EOBS_19950101T000000_20101231T000000_rr_24h_v25.0e.grib
#grib_set -r -s table2Version=128,indicatorOfParameter=228,centre=98,setLocalDefinition=1,localDefinitionNumber=15 
