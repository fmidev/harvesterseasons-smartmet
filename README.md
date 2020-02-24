
# SmartMet-server for Harvester Sesaons service

Mainly for showing ERA5 Land grib datasets and HOPS hydrological forecasts from seasonal and weather forecast data.
This entails a mix of GRID and non-grid smartmet-server plugins to run. It is now being run on a WEkEO cloud server running Ubuntu.
... let's see how it works:

# Start all services (even with --detatch the build process will wait until finished)
docker-compose up --detatch

This will quickly add all components, but below are steps for all of the three Docker containers needed.

# Transfer files from C3S CDS with shell scripts
You will need grib_set and cdo, so install something like libeccodes-tools and cdo packages on Ubuntu and equivalents on other OSs.
under bin you have the get-seasonal.sh for now. Similar scripts for ERA5 and ERA5L will be added soon.

This should used to put data in a ~/data/grib directory, where the smartmet-server will look for new grib files read in.

# Build and run postgres-database

Setup database for geonames-engine because of who knows why

`docker-compose up --detatch --build fminames-db`

# Build and run Redis

Setup database for storing grib-file details

`docker-compose up --detatch --build redis_db`

# Build and run smartmet-server

`docker-compose up --build smartmet-server`

# Fire up all three services at once

This will:

* Start the Postgresql-database and create a db-directory to store all the data there.
* Start Redis for storing information about available grib data
* Start SmartMet Server after the Postgersql is ready

`docker-compose up --detatch`

# Read data to Redis to be used by SmartMet-server

Run a `filesys-to-smartmet`-script in the smartmet-server container... once Redis is ready. The location of filesys-to-smartmet.cfg depends on where the settings-files are located at. With `docker-compose.yaml` the settings are currently stored in `/home/smartmet/config`.

`docker exec --user smartmet smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0`

# HOPS forecasts and analysis as netCDF files as non-grid smartmet-server

The HOPS model produces netCDF as output that has to be turned into smartmet-server query data under the ~/data/hops directory structure.
To be available

# Using timeseries, WMS or WFS

The aim is to have timeseries and WMS layers for the http://harvesterseasons.com/ service and WFS downloads available for data sets that will be exported to
other service outlets of HOPS output.

Example:

`/timeseries?param=place,utctime,WindSpeedMS:ERA5:26:0:0:0&latlon=60.192059,24.945831&format=debug&source=grid&producer=ERA5&starttime=data&timesteps=5`
`/timeseries?producer=ERA5&param=WindSpeedMS&latlon=60.192059,24.94583&format=debug&source=grid&&starttime=2017-08-01T00:00:00Z`
`/wfs?request=getFeature&storedquery_id=windgustcoverage&starttime=2017-08-01T00:00:00Z&endtime=2017-08-01T00:00:00Z&source=grid&bbox=21,60,24,64&crs=EPSG:4326&limits=15,999,20,999,25,999,30–999`
`/wfs?request=getFeature&storedquery_id=pressurecoverage&starttime=2017-08-01T00:00:00Z&endtime=2017-08-01T00:00:00Z&source=grid&bbox=21,60,24,64&crs=EPSG:4326&limits=0,1000`

