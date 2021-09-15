#!/bin/bash
# SAGA-GIS commands for TWI production based on https://doi.org/10.1016/j.scitotenv.2020.143785
# Kopecky M. 2021 - TWI calculation guidelines for best explanation for soil moisture. Input argument DEM dir
# Mikko Strahlendorff 8.5.2021
#
# v2: updated to use DGED float32 TIF version for more precision and water masks retrieved from DEM auxilliary files
# Mikko Strahlendorff 17.5.2021
dtm=${1}
[ ! "$2" == "" ] && dtm_in=$2 || dtm_in=$dtm-dtm.tif
# Burn streamnetwork into DEM using the DEMs auxilliary Water Body Mask product
[ ! -f $dtm-burn.tif ] && gdal_calc.py --quiet -A "$dtm_in" -B "$dtm-wbm.tif" --outfile="$dtm-burn-tmp.tif" --calc='A*(B<1)' --type Float32 --overwrite --NoDataValue=0 --co='COMPRESS=DEFLATE' --co='PREDICTOR=3' --co='BIGTIFF=IF_SAFER' --co='TILED=YES'\
 && gdal_translate -of COG -co COMPRESS=DEFLATE -co BIGTIFF=IF_SAFER -co PREDICTOR=3 $dtm-burn-tmp.tif $dtm-burn.tif && rm $dtm-burn-tmp.tif \
 && s3cmd -P -q sync $dtm-dtm.tif s3://copernicus/dtm/ && rm $dtm-dtm.tif
# Fill DTM depressions with Wang 2006 XXL method and 0.01 minimum slope
[ ! -f $dtm-filled.tif ] && /usr/bin/saga_cmd ta_preprocessor 5 -ELEV $dtm-burn.tif -FILLED $dtm-filled -MINSLOPE 0.01\
 && gdal_translate -of COG -co COMPRESS=DEFLATE -co BIGTIFF=IF_SAFER -co PREDICTOR=YES $dtm-filled.sdat $dtm-filled.tif\
 && rm $dtm-filled.[smp]*\
 && s3cmd -P -q sync $dtm-burn.tif s3://copernicus/dtm/stream-burn/ && rm $dtm-burn.tif
# determine Channels and drainage basins. !not in use as DEM preprocess uses Copernicus DEM Water body mask
#[ ! -f $dtm-stream.tif ] && [ ! -f $dtm-flowdir.tif ] && /usr/bin/saga_cmd ta_channels 5 -DEM $dtm-filled.tif -DIRECTION $dtm-flowdir -BASIN $dtm-stream -SEGMENTS $dtm-channels -BASINS $dtm-basins\
# && parallel -j 2 s3cmd -P -q put $dtm-{}.* s3://copernicus/dtm/{}/ ::: basins channels\
#&& parallel -j 2 gdal_translate -of COG -co COMPRESS=DEFLATE -co BIGTIFF=IF_SAFER -co PREDICTOR=YES {} {.}.tif ::: $dtm-flowdir.sdat $dtm-stream.sdat\
#&& rm $dtm-stream.[smp]* $dtm-flowdir.[smp]*
# Calculate slope using third degree polinomial Haralick 1983  
[ ! -f $dtm-slope.tif ] && /usr/bin/saga_cmd ta_morphometry 0 -ELEVATION $dtm-filled.tif -SLOPE $dtm-slope -ASPECT $dtm-aspect -METHOD 7\
 && parallel -j 2 gdal_translate -of COG -co COMPRESS=DEFLATE -co BIGTIFF=IF_SAFER -co PREDICTOR=3 {} {.}.tif ::: $dtm-slope.sdat $dtm-aspect.sdat\
 && rm $dtm-slope.[smp]* $dtm-aspect.[smp]* \
 && s3cmd -P -q sync $dtm-aspect.tif s3://copernicus/dtm/aspect/ && rm $dtm-aspect.tif
# Calculate catchments with FD8 multiple flow method Freeman 1991 and convergence 1.0 
[ ! -f $dtm-flow.tif ] && /usr/bin/saga_cmd ta_hydrology 0 -ELEVATION $dtm-filled.tif -FLOW $dtm-flow -CONVERGENCE 1.0\
 && gdal_translate -of COG -co COMPRESS=DEFLATE -co BIGTIFF=IF_SAFER -co PREDICTOR=3 $dtm-flow.sdat $dtm-flow.tif\
 && rm $dtm-flow.[smp]*
# Calculate specific catchment and flow width Quinn et al 1991
[ ! -f $dtm-scarea.tif ] && /usr/bin/saga_cmd ta_hydrology 19 -DEM $dtm-filled.tif -TCA $dtm-flow.tif -WIDTH $dtm-flow-width -SCA $dtm-scarea\
 && parallel -j 2 gdal_translate -of COG -co COMPRESS=DEFLATE -co BIGTIFF=IF_SAFER -co PREDICTOR=3 {} {.}.tif ::: $dtm-scarea.sdat $dtm-flow-width.sdat\
 && rm $dtm-scarea.[smp]* $dtm-flow-width.[smp]*\
 && s3cmd -P -q sync $dtm-flow-width.tif s3://copernicus/dtm/flow-width/ && rm $dtm-flow-width.tif
# Calculate TWI with Standard Beven & Kirkby 1979
[ ! -f $dtm-twi.tif ] && /usr/bin/saga_cmd ta_hydrology 20 -SLOPE $dtm-slope.tif -AREA $dtm-scarea.tif -TWI $dtm-twi\
 && gdal_translate -q -of COG -co COMPRESS=DEFLATE -co BIGTIFF=IF_SAFER -co PREDICTOR=3 $dtm-twi.sdat $dtm-twi.tif\
 && rm $dtm-twi.[smp]*
# Translated TWI and contributing steps in cloud optimized tiff format are uploaded to cloud storage
[ -f $dtm-twi.tif ] && upload.sh $dtm