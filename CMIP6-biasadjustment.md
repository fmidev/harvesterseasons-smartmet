# CMIP6 data
All data is ingested from C3S CMIP5-projections monthlz mean datasets from https://cds-climate.copernicus.eu . Historical, ssp245 and ssp585 projections are pulled from 20+ models choosing mainly the models that ran on 100km resolution natively. As in some cases this did not lead to at least 10 ensemble members, also some lower resolution models are included. The area of interest is a grid from -33 W to 55 E and 28 S to 83 N.
ingestion script is cds-cmip6-monthly.py

Variables are 
- near_surface_air_temperature
- daily_maximum_near_surface_air_temperature
- daily_minimum_near_surface_air_temperature
- sea_level_pressure
- near_surface_wind_speed
- precipitation
- evaporation_including_sublimation_and_transpiration
- near_surface_relative_humidity or relative_humidity (at 1000 hPa; depending on what was available)
(as Taltech was also hoping for sealevel and temperature these are available for some models without bias-adjustment)
- sea_surface_height_above_geoid
- sea_surface_temperature

Models are 
- awi_cm_1_1_mr
- bcc_csm2_mr
- cams_csm1_0
- cesm2
- cesm2_waccm
- ciesm
- cmcc_esm2
- cnrm_cm6_1_hr
- e3sm_1_1
- ec_earth3_cc
- fgoals_f3_l
- fio_esm_2_0
- gfdl_esm4
- hadgem3_gc31_mm
- iitm_esm
- inm_cm5_0
- mpi_esm1_2_lr
- mri_esm2_0
- noresm2_mm

Data is bias-adjusted to allow some meaningful use with monthly health impact models. Adjustment is made with ERA5 reanalysis, downscaling the climate model to the ERA5 latlon grid at 0,25 degrees then correcting the bias with a simple addition of the mean monthly difference from 1995 to 2024 for the variables. The near surface air temperature bias is also applied to the daily minimum and maximum data as well as there is no daily min/maximum data in the monthly aggregations for ERA5. Relative humidity for ERA5 was calculated from 2m air and dew point temperatures with the commamd:
 cdo aexpr,'rh=100*exp((17.625*var168)/(243.04+var168))/exp((17.625*var167)/(243.04+var167))' input.grib output.grib

The whole process is captured in a bash script ba-cmip6-ensemble.sh, but below are simplified early versions of the processing required. In the end more nitty gritty details had to be ironed out.

command to build 1995-2024 comparison data sets:
 cdo --eccodes -b P16 -f grb setvar,r -mergetime hurs_Amon_CNRM-CM6-1-HR_historical_r1i1p1f2_gr_19950116-20141216.nc -selyear,2015/2024 hurs_Amon_CNRM-CM6-1-HR_ssp245_r1i1p1f2_gr_20150116-20991216.nc   CNRM-CM6-1-HR_19950101T000000_20241231T000000-relhum.grib

script to calculate bias:
 calc_bias_var.sh

command to apply bias adjustment to ssp245 and ssp585:
 parallel cdo --eccodes -b P16 -f grb2 monadd -remapdis,../eera5-eu-grid hur_Amon_{1}_{2}_*.nc -shifttime,-10y eera5-{1}-19950101T000000_1995-2025_r_bias_eu.grib CMIP6-{2}_20150101T000000_{1}_r-eu.grib :::: models-rh.lst ::: ssp245 ssp585