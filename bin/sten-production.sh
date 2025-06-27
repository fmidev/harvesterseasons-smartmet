#!/bin/bash
# This script is used to run a Python script for Stora-Enso trafficability map generation
eval "$(/home/smartmet/mambaforge/bin/conda shell.bash hook)"
conda activate xgb
if [[ $# -gt 0 ]]; then
    date=`date -d $1 +%Y-%m-%d`
else 
    date=$(date +%Y-%m-%d)
fi
sdate=$(date -d "$date" +%Y%m%d)
cd /home/smartmet/data
parallel -j 3 /home/ubuntu/mambaforge/envs/xgb/bin/python /home/ubuntu/bin/make_finland_trafficability_map.py $date ::: 1 7 14
cd /home/smartmet/data/maps
parallel -j 3 gdal_translate -q -of COG -co COMPRESS=DEFLATE -co PREDICTOR=2 -co BIGTIFF=IF_SAFER -co NUM_THREADS=ALL_CPUS {} {.}-cog.tif ::: trafficability_modified_*_${sdate}.tif
parallel mv {.}-cog.tif {} ::: trafficability_modified_*_${sdate}.tif
parallel gdalinfo -stats -hist {} ::: trafficability_modified_*_${sdate}.tif
parallel s3cmd put -Pq {} s3://wetterra/sten/ ::: trafficability_modified_*_${sdate}.tif*
ls -1 trafficability_modified_*_${sdate}.tif | sed 's;tr;https://wetterra.data.lit.fmi.fi/sten/tr;' >> MANIFEST
s3cmd put -Pq MANIFEST s3://wetterra/sten/