#!/bin/bash
date=$(date +%Y%m%d)
ydate=$(date -d '1 day ago' +%Y%m%d)
#fmiapi=710d743a-7a54-4b40-bf28-89c8b8cf33ed Metsäteho
fmiapi=edfa704e-69a2-45e2-89bf-d173d79b6b76 #HarvesterSesaons
timestep=1440
wget -O ~/data/fmi-smartmet-$date-e+fire.grib "http://data.fmi.fi/fmi-apikey/$fmiapi/download?param=Evaporation,ForestGroundHumidity,ForestFireWarning&timestep=$timestep&format=grib2&producer=metsapalomalli&projection=epsg:4326"
#wget -O ~/data/fmi-smartmet-$date-t+rr.grib "http://data.fmi.fi/fmi-apikey/$fmiapi/download?param=Temperature,Precipitation1h&timestep=60&format=grib1&producer=pal_skandinavia"
wget -O ~/data/fmi-smartmet-$date-24h.grib "http://data.fmi.fi/fmi-apikey/$fmiapi/download?param=MinimumTemperature24h,MaximumTemperature24h,DailyMeanTemperature,Precipitation24h&timestep=$timestep&format=grib2&producer=daily00&projection=stereographic"
wget -O ~/data/fmi-smartmet-$date-swvl2.grib "http://data.fmi.fi/fmi-apikey/$fmiapi/download?param=VolumetricSoilWaterLayer28&timestep=720&format=grib2&producer=fmi_soil_water&projection=epsg:4326"
wget -O ~/data/fmi-smartmet-$date-TG.grib "http://data.fmi.fi/fmi-apikey/$fmiapi/download?param=GroundTemperature&timestep=$timestep&format=grib2&producer=pal_skandinavia_frost&projection=stereographic"
#wget -O ~/data/fmi-smartmet-$date-rr6h.grib "http://data.fmi.fi/fmi-apikey/$fmiapi/download?param=Precipitation6h&timestep=360&format=grib1&producer=pal_skandinavia_precipitation6h"
cd ~/data
grib_copy fmi-smartmet-$date-*.grib grib/SMARTMET_${date}T0000_[shortName].grib
sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0
sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0
