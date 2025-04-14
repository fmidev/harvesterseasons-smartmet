#!/bin/bash
#
# script for fetching ERA5 post-processed daily statistics data from cdsapi
# and setting it up in the smartmet-server
# given year, variable and statistic (daily_sum, daily_maximum, daily_minmum, daily_mean) as cmd
#
# 2025 Anni Kröger
#eval "$(conda shell.bash hook)"
eval "$(/home/ubuntu/mambaforge/bin/conda shell.bash hook)"

source ~/.smart

year=$1
var=$2
stat=$3

cd /home/smartmet/data

echo "fetch ERA5 daily stats for year: $year var: $var statistic: $stat"

[ -f ERA5D_${year}0101T000000_${year}1231T120000_${var}.nc ] || ../bin/cds-era5-dailystats.py $year $var $stat

# Variables daily_sum:
# GRIB2
# surface_latent_heat_flux surface_sensible_heat_flux surface_solar_radiation_downwards surface_thermal_radiation_downwards surface_net_thermal_radiation surface_net_solar_radiation  
# GRIB1
# toa_incident_solar_radiation top_net_solar_radiation top_net_thermal_radiation evaporation potential_evaporation runoff sub_surface_runoff surface_runoff eastward_turbulent_surface_stress northward_turbulent_surface_stress snowfall total_precipitation
# other stats (GRIB1): 
# 10m_wind_gust_since_previous_post_processing minimum_2m_temperature_since_previous_post_processing maximum_2m_temperature_since_previous_post_processing instantaneous_10m_wind_gust

# puuttuu
# runoff 2007 2013 2016 2019
# surface ro 2006 2007 2014 2015 2022 
# subsur ro 2007 2015 2016
# snowfall 2007

conda activate cdo

# GRIB2:
#cdo -s -b P8 -O --eccodes -f grb2 copy ERA5D_${year}0101T000000_${year}1231T120000_${var}.nc grib/ERA5D_20000101T000000_${year}_${var}.grib

# GRIB1:
cdo -s -b P8 -O --eccodes -f grb copy ERA5D_${year}0101T000000_${year}1231T120000_${var}.nc ERA5D_20000101T000000_${year}_${var}.grib 
grib_set -r -s jScansPositively=0 ERA5D_20000101T000000_${year}_${var}.grib grib/ERA5D_20000101T000000_${year}_${var}-fix.grib
rm ERA5D_20000101T000000_${year}_${var}.grib
###grib_set -r -s table2Version=128,indicatorOfParameter=228 ERA5D_20000101T000000_2000_total_precipitation-fix.grib ERA5D_20000101T000000_2000_total_precipitation-fix-fix.grib
###grib_set -r -s table2Version=128,indicatorOfParameter=49 grib/ERA5D_20000101T000000_${year}_10m_wind_gust_since_previous_post_processing-fix.grib grib/ERA5D_20000101T000000_${year}_10m_wind_gust_since_previous_post_processing-fix2.grib
###rm grib/ERA5D_20000101T000000_${year}_10m_wind_gust_since_previous_post_processing-fix.grib
#rm ERA5D_${year}0101T000000_${year}1231T120000_${var}.nc

#sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0
