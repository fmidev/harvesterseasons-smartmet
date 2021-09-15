#!/bin/bash
# rerun Specific Catchment Area and calculate TWI
dtm=${1:0:-4}
#cd ${dtm}_
/usr/bin/saga_cmd ta_hydrology 19 -DEM $dtm-filled.sdat -WIDTH $dtm-flow-width -TCA $dtm-flow.sdat -SCA $dtm-scarea
#saga_cmd ta_hydrology 19 -DEM $dtm.tif -WIDTH $dtm-flow-width -SCA $dtm-scarea
# Calculate TWI
/usr/bin/saga_cmd ta_hydrology 20 -SLOPE $dtm-slope.sdat -AREA $dtm-scarea.sdat -TWI $dtm-twi
#saga_cmd ta_hydrology 20 -SLOPE $dtm-slope.sdat -AREA $dtm-flow.sdat -TWI $dtm-twi
# Translate TWI to cloud optimized tiff
gdal_translate -of COG -co COMPRESS=DEFLATE -co BIGTIFF=IF_SAFER -co PREDICTOR=3 $dtm-twi.sdat $dtm-twi.tif