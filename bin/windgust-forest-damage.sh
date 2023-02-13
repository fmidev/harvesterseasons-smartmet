#!/bin/bash
# use the gdal conda environment
eval "$(conda shell.bash hook)"
conda activate gdal
if [ $# -ne 0 ]
then
    yday=$1
else
    yday=$(date -d yesterday +%Y-%m-%d)
fi

cd /home/smartmet/data/gdalcubes
# execute the Rscript in the gdalcubes docker image for wg kriging, then make a COG and put to ceph
sudo docker exec -u rstudio busy_matsumoto Rscript /home/rstudio/wg_interpolation_new_code.R -s $yday \
 && gdal_calc.py --calc="2*logical_and(A>=17,A<28)+3*(A>=28)" -A Tuuli_${yday}_WG_KED.tif --outfile=Tuuli_${yday}_WG_KED_CLASSIFIED.tif \
--type Byte --NoDataValue=0 --co='COMPRESS=DEFLATE' --co='PREDICTOR=2' --co='BIGTIFF=IF_SAFER' --co='TILED=YES' \
 && gdal_polygonize.py -b 1 Tuuli_${yday}_WG_KED_CLASSIFIED.tif Tuuli_${yday}_WG_KED.geojson \
 && gdal_translate -q -of COG -co COMPRESS=DEFLATE -co PREDICTOR=3 Tuuli_${yday}_WG_KED.tif ../forest/Tuuli_${yday}_WG_KED.tif \
 && s3cmd -Pq put Tuuli_${yday}_obs_wg.csv ../forest/Tuuli_${yday}_WG_KED.tif Tuuli_${yday}_WG_KED.geojson Tuuli_${yday}_WG_KED_CLASSIFIED.tif s3://pta/met/wgfd/ \
 && rm ../forest/Tuuli_${yday}_WG_KED.tif
