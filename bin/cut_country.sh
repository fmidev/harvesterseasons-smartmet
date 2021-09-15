#!/bin/bash
# Cut and crop TWI files to country border
# Usage: give arguments Country name and twi file(s). Quote multiple files. Run in directory of the TWI files.
# 14.5.2021 Mikko Strahlendorff
cntr=$(echo $1 | tr "_" " ")
file=$1-twi
[ ! "$2" == "" ] && ifiles=$2 || ifiles=$file.tif
echo "$file will be cut according to $cntr"
db=/home/smartmet/data/gadm36_0.shp
layer=gadm36_0
gdalwarp -cutline $db -cl $layer -cwhere "name_0 = '$cntr'" -crop_to_cutline\
 -of COG -co COMPRESS=DEFLATE -co PREDICTOR=YES -co BIGTIFF=IF_SAFER\
 $ifiles $file-cut.tif
s3cmd -P -q put $file-cut.tif s3://copernicus/dtm/twi-dsm/