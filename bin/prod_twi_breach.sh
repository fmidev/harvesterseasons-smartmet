#!/bin/bash
# SAGA-GIS commands for TWI production based on https://doi.org/10.1016/j.scitotenv.2020.143785
# Kopecky M. 2021 - TWI calculation guidelines for best explanation for soil moisture. Input argument DEM dir
# Mikko Strahlendorff 8.5.2021
#
# v3: instead of filling sinks, breaching depressions is used to preserve more the terrain within
# this is a modification to Kopecky, who did not investigate this aspect to improve and 
# Mikko Strahlendorff 20.5.2021
dtm=${1}
# Burn streamnetwork into DEM using the DEMs auxilliary Water Body Mask product
[ ! -f $dtm-burn.tif ] && gdal_calc.py --quiet -A $dtm-dtm.tif -B $dtm-wbm.tif --outfile=$dtm-burn-tmp.tif --calc='A*(B<1)' --type Float32 --overwrite --NoDataValue=0 --co='COMPRESS=DEFLATE' --co='PREDICTOR=3' --co='BIGTIFF=IF_SAFER' --co='TILED=YES' &&\ 
 gdal_translate -of COG -co COMPRESS=DEFLATE -co BIGTIFF=IF_SAFER -co PREDICTOR=3 $dtm-burn-tmp.tif $dtm-burn.tif && rm $dtm-burn-tmp.tif
# Breach DTM depressions with Whitebox GAT method
[ ! -f $dtm-breach.tif ] && /usr/bin/saga_cmd ta_preprocessor 5 -DEM $dtm-burn.tif -NOSINKS $dtm-breach\
 && gdal_translate -of COG -co COMPRESS=DEFLATE -co BIGTIFF=IF_SAFER -co PREDICTOR=YES $dtm-breach.sdat $dtm-breach.tif\
 && rm $dtm-breach.[smp]*
# determine Channels and drainage basins. !not in use as DEM preprocess uses Copernicus DEM Water body mask
#[ ! -f $dtm-stream.tif ] && [ ! -f $dtm-flowdir.tif ] && /usr/bin/saga_cmd ta_channels 5 -DEM $dtm-breach.tif -DIRECTION $dtm-flowdir -BASIN $dtm-stream -SEGMENTS $dtm-channels -BASINS $dtm-basins\
# && parallel -j 2 s3cmd -P -q put $dtm-{}.* s3://copernicus/dtm/{}/ ::: basins channels\
#&& parallel -j 2 gdal_translate -of COG -co COMPRESS=DEFLATE -co BIGTIFF=IF_SAFER -co PREDICTOR=YES {} {.}.tif ::: $dtm-flowdir.sdat $dtm-stream.sdat\
#&& rm $dtm-stream.[smp]* $dtm-flowdir.[smp]*
# Calculate slope using third degree polinomial Haralick 1983  
[ ! -f $dtm-slope.tif ] && [ ! -f $dtm-aspect.tif ] && /usr/bin/saga_cmd ta_morphometry 0 -ELEVATION $dtm-breach.tif -SLOPE $dtm-slope -ASPECT $dtm-aspect -METHOD 7\
 && parallel -j 2 gdal_translate -of COG -co COMPRESS=DEFLATE -co BIGTIFF=IF_SAFER -co PREDICTOR=3 {} {.}.tif ::: $dtm-aspect.sdat $dtm-slope.sdat\
 && rm $dtm-slope.[smp]* $dtm-aspect.[smp]*
# Calculate catchments with FD8 multiple flow method Freeman 1991 and convergence 1.0 
[ ! -f $dtm-flow.tif ] && /usr/bin/saga_cmd ta_hydrology 0 -ELEVATION $dtm-breach.tif -FLOW $dtm-flow -CONVERGENCE 1.0\
 && gdal_translate -of COG -co COMPRESS=DEFLATE -co BIGTIFF=IF_SAFER -co PREDICTOR=3 $dtm-flow.sdat $dtm-flow.tif\
 && rm $dtm-flow.[smp]*
# Calculate specific catchment and flow width Quinn et al 1991
[ ! -f $dtm-flow-width.tif ] && [ ! -f $dtm-scarea.sdat ] && /usr/bin/saga_cmd ta_hydrology 19 -DEM $dtm-breach.tif -TCA $dtm-flow.tif -WIDTH $dtm-flow-width -SCA $dtm-scarea\
 && parallel -j 2 gdal_translate -of COG -co COMPRESS=DEFLATE -co BIGTIFF=IF_SAFER -co PREDICTOR=3 {} {.}.tif ::: $dtm-flow-width.sdat $dtm-scarea.sdat\
 && rm $dtm-scarea.[smp]* $dtm-flow-width.[smp]*
# Calculate TWI with Standard Beven & Kirkby 1979
[ ! -f $dtm-twi.sdat ] && /usr/bin/saga_cmd ta_hydrology 20 -SLOPE $dtm-slope.tif -AREA $dtm-scarea.tif -TWI $dtm-twi\
 && gdal_translate -q -of COG -co COMPRESS=DEFLATE -co BIGTIFF=IF_SAFER -co PREDICTOR=3 $dtm-twi.sdat $dtm-twi.tif\
 && rm $dtm-twi.[smp]*
# Translated TWI and contributing steps in cloud optimized tiff format are uploaded to cloud storage
