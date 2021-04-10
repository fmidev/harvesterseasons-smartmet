#!/bin/bash
eval "$(conda shell.bash hook)"
conda activate xr
if [ $# -ne 0 ]
then
    date=$1
    ydate=$(date -d "$date 1 day ago" +%Y%m%d)
else
    date=$(date +%Y%m%d)
    ydate=$(date -d '1 day ago' +%Y%m%d)
fi
#fmiapi=710d743a-7a54-4b40-bf28-89c8b8cf33ed for Metsäteho
fmiapi=edfa704e-69a2-45e2-89bf-d173d79b6b76 
# for HarvesterSesaons
timestep=1440
# predictions 
wget -O /home/smartmet/data/fmi-smartmet-$date-e+fire.grib "http://data.fmi.fi/fmi-apikey/$fmiapi/download?param=Evaporation,ForestGroundHumidity,ForestFireWarning&timestep=$timestep&starttime=${date}T000000&format=grib2&producer=metsapalomalli"
#wget -O /home/smartmet/data/fmi-smartmet-$date-t+rr.grib "http://data.fmi.fi/fmi-apikey/$fmiapi/download?param=Temperature,Precipitation1h&timestep=60&starttime=${date}T000000&format=grib1&producer=pal_skandinavia"
wget -O /home/smartmet/data/fmi-smartmet-$date-24h.grib "http://data.fmi.fi/fmi-apikey/$fmiapi/download?param=MinimumTemperature24h,MaximumTemperature24h,DailyMeanTemperature,Precipitation24h&timestep=$timestep&starttime=${date}T000000&format=grib2&producer=daily00"
# SWVL2 calculation only for summer season
wget -O /home/smartmet/data/fmi-smartmet-$date-swvl2.grib "http://data.fmi.fi/fmi-apikey/$fmiapi/download?param=VolumetricSoilWaterLayer28&timestep=720&starttime=${date}T000000&format=grib2&producer=fmi_soil_water&projection=epsg:4326"
wget -O /home/smartmet/data/fmi-smartmet-$date-TG.grib "http://data.fmi.fi/fmi-apikey/$fmiapi/download?param=GroundTemperature&timestep=$timestep&starttime=${date}T000000&format=grib2&producer=pal_skandinavia_frost"
#wget -O /home/smartmet/data/fmi-smartmet-$date-rr6h.grib "http://data.fmi.fi/fmi-apikey/$fmiapi/download?param=Precipitation6h&timestep=360&starttime=${date}T000000&format=grib1&producer=pal_skandinavia_precipitation6h"
wget -O /home/smartmet/data/fmi-smartmet-$date-snowacc.grib "http://data.fmi.fi/fmi-apikey/$fmiapi/download?param=WaterAccumulation,SnowAccumulation,SnowWaterRatio&timestep=720&starttime=${date}T000000&format=grib2&producer=snow_accumulation"
# observations
# SWVL2 calculation only for summer season
wget -O /home/smartmet/data/fmi-smartmet-$ydate-swvl2-cum.grib "http://data.fmi.fi/fmi-apikey/$fmiapi/download?param=VolumetricSoilWaterLayer28&timestep=1440&starttime=${ydate:0:4}0401T090000&format=grib2&producer=fmi_soil_cumulative&projection=epsg:4326"
wget -O /home/smartmet/data/fmi-smartmet-$ydate-synop-krg.grib "http://data.fmi.fi/fmi-apikey/$fmiapi/download?param=Temperature,Evaporation,WindSpeedMS&timestep=data&starttime=${ydate}T000000&format=grib1&producer=kriging_suomi_synop&projection=epsg:4326"
wget -O /home/smartmet/data/fmi-smartmet-$ydate-sd-krg.grib "http://data.fmi.fi/fmi-apikey/$fmiapi/download?param=WaterEquivalentOfSnow&timestep=data&starttime=${ydate}T000000&format=grib1&producer=kriging_suomi_snow&projection=epsg:4326"
wget -O /home/smartmet/data/fmi-smartmet-$ydate-tg-krg.grib "http://data.fmi.fi/fmi-apikey/$fmiapi/download?param=GroundTemperature&timestep=data&starttime=${ydate}T000000&format=grib2&producer=roadkriging_suomi&projection=epsg:4326"
cd /home/smartmet/data
conda activate xr
grib_copy fmi-smartmet-$date-*.grib grib/SMARTMET_${date:0:4}0101T000000_${date}T0000_[shortName].grib
mv fmi-smartmet-$ydate-swvl2-cum.grib grib/SMARTOBS_${date:0:4}0101T000000_${date}T0900_swvl2.grib
rm grib/SMARTOBS_${ydate:0:4}0101T000000_${ydate}T090000_swvl2.grib
grib_copy fmi-smartmet-$ydate-synop-krg.grib grib/SMARTOBS_${ydate:0:4}0101T000000_${ydate}T0000_[shortName].grib
# calculate snow depth forecast from snow fall accumulation data
# need snow state: ERA5 (5 days old) will be accumulated by the forecast from same day in past with ERA5 analysis
edate=$(date -d "$ydate 5 days ago" +%Y%m%d)
cdo --eccodes -O chparam,144.173.192,11.1.0 -mulc,0.001 -add grib/SMARTMET_${edate:0:4}0101T000000_${edate}T0000_sfara.grib \
    -remapbil,smartmet-sk-grid -selname,sd -seltimestep,1 grib/ERA5_${edate:0:4}0101T000000_${edate}T0000_base+soil.grib sde-state.grib
# add new forecast to sde-state
cdo --eccodes chparam,144.173.192,11.1.0 -add -mulc,0.001 grib/SMARTMET_${date:0:4}0101T000000_${date}T0000_sfara.grib \
    -seltimestep,8 sde-state.grib grib/SMARTMET_${date:0:4}0101T000000_${date}T0000_sde.grib
# calculate snow depth obs from swe kriging data
cdo --eccodes chparam,141.228,141.128 -mulc,0.01 fmi-smartmet-$ydate-sd-krg.grib grib/SMARTOBS_${date:0:4}0101T000000_${date}T0000_sde.grib
mv fmi-smartmet-* smartmet/
sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0