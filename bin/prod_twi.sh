#!/bin/bash
# SAGA-GIS commands for TWI production based on https://doi.org/10.1016/j.scitotenv.2020.143785
# Kopecky M. 2021 - TWI calculation guidelines for best explanation for soil moisture
# Mikko Strahlendorff 8.5.2021
#
# v2: It seems this guideline missed the burn stream network into DEM, so I added two steps to calculate
# channels and drainage basins and burning these in to the filled sinks DEM
# Mikko Strahlendorff 17.5.2021
dtm=${1:0:-4}
# Set oceans to no_data (oceans are all elevation 0m) will also let fill sinks fill all missing -32767 values
[ ! -f $dtm-oceanfree.tif ] && gdal_calc.py -A $dtm.tif --co COMPRESS=DEFLATE --co PREDICTOR=2 --calc="A*(A>0)" --NoDataValue=-32767 --quiet --outfile=$dtm-oceanfree.tif
# Fill DTM depressions with Wang 2006 XXL method and 0.01 minimum slope
[ ! -f $dtm-filled.tif ] && /usr/bin/saga_cmd ta_preprocessor 5 -ELEV $dtm-oceanfree.tif -FILLED $dtm-filled -MINSLOPE 0.01\
 && gdal_translate -of COG -co COMPRESS=DEFLATE -co BIGTIFF=IF_SAFER -co PREDICTOR=YES $dtm-filled.sdat $dtm-filled.tif\
scp && rm $dtm-filled.[smp]*
# determine Channels and drainage basins. !not in use as DEM preprocess uses Copernicus DEM Water body mask ! Here calculated from DEM
[ ! -f $dtm-stream.tif ] && [ ! -f $dtm-flowdir.tif ] && /usr/bin/saga_cmd ta_channels 5 -DEM $dtm-filled.tif -DIRECTION $dtm-flowdir -BASIN $dtm-stream -SEGMENTS $dtm-channels -BASINS $dtm-basins\
 && parallel -j 2 s3cmd -P -q put $dtm-{}.* s3://copernicus/dtm/{}/ ::: basins channels\
 && parallel -j 2 gdal_translate -of COG -co COMPRESS=DEFLATE -co BIGTIFF=IF_SAFER -co PREDICTOR=YES {} {.}.tif ::: $dtm-flowdir.sdat $dtm-stream.sdat\
 && rm $dtm-stream.[smp]* $dtm-flowdir.[smp]*
# Burn streamnetwork into DEM !not in use in v2! as Water Body Mask burned in preprocess already
[ ! -f $dtm-burn.tif ] && /usr/bin/saga_cmd ta_preprocessor 6 -DEM $dtm-filled.tif -BURN $dtm-burn -STREAM $dtm-stream.tif -FLOWDIR $dtm-flowdir.tif\
 && gdal_translate -of COG -co COMPRESS=DEFLATE -co BIGTIFF=IF_SAFER -co PREDICTOR=YES $dtm-burn.sdat $dtm-burn.tif\
 && rm $dtm-burn.[smp]*
# Calculate catchments with FD8 multiple flow method Freeman 1991 and convergence 1.0 
[ ! -f $dtm-flow.tif ] && /usr/bin/saga_cmd ta_hydrology 0 -ELEVATION $dtm-burn.tif -FLOW $dtm-flow -CONVERGENCE 1.0\
 && gdal_translate -of COG -co COMPRESS=DEFLATE -co BIGTIFF=IF_SAFER -co PREDICTOR=YES $dtm-flow.sdat $dtm-flow.tif\
 && rm $dtm-flow.[smp]*
# Calculate slope using third degree polinomial Haralick 1983 ! calculated from unfilled DTM, original is stream corrected 
[ ! -f $dtm-slope.tif ] && [ ! -f $dtm-aspect.tif ] && /usr/bin/saga_cmd ta_morphometry 0 -ELEVATION $dtm-filled.tif -SLOPE $dtm-slope -ASPECT $dtm-aspect -METHOD 7\
 && parallel -j 2 gdal_translate -of COG -co COMPRESS=DEFLATE -co BIGTIFF=IF_SAFER -co PREDICTOR=YES {} {.}.tif ::: $dtm-aspect.sdat $dtm-slope.sdat\
 && rm $dtm-slope.[smp]* $dtm-aspect.[smp]*
# Calculate specific catchment and flow width Quinn et al 1991
[ ! -f $dtm-flow-width.tif ] && [ ! -f $dtm-scarea.sdat ] && /usr/bin/saga_cmd ta_hydrology 19 -DEM $dtm-burn.tif -TCA $dtm-flow.tif -WIDTH $dtm-flow-width -SCA $dtm-scarea \
 && parallel -j 2 gdal_translate -of COG -co COMPRESS=DEFLATE -co BIGTIFF=IF_SAFER -co PREDICTOR=YES {} {.}.tif ::: $dtm-flow-width.sdat $dtm-scarea.sdat\
 && rm $dtm-scarea.[smp]* $dtm-flow-width.[smp]*
# Calculate TWI with Standard Beven & Kirkby 1979
[ ! -f $dtm-twi.sdat ] && /usr/bin/saga_cmd ta_hydrology 20 -SLOPE $dtm-slope.tif -AREA $dtm-scarea.tif -TWI $dtm-twi\
 && gdal_translate -of COG -co COMPRESS=DEFLATE -co BIGTIFF=IF_SAFER -co PREDICTOR=YES $dtm-twi.sdat $dtm-twi.tif\
 && rm $dtm-twi.[smp]*
# Translate TWI and contributing steps to cloud optimized tiff
upload.sh $dtm