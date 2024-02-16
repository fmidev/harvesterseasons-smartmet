#!/bin/bash
# Find Copernicus DSM TIF DEM and AUXFILES in distributed TAR files and produce dtm subtracting forest canopy height from DSM
# Combine for dem and metadata the countries tiles into variable wide VRT and translate to a unified COG 
# For directories including distant territories/islands, these have been separated
# into own VRT/COGs with "grep -P DSM_10_..." on the full directory lst files
# Usage:
# Give as argument the country directory name + /, for areas north of 52N second argument: full path to GeoTiff with Forest Canopy Height
# Running from the parent directory
#
# Mikko Strahlendorff 7.5.2021 (updated to use aux_lists 25.5.)
out=${1:0:-1}
[ ! "$2" == "" ] && fch=$2 || fch=/vsicurl/https://copernicus.data.lit.fmi.fi/dtm/fch/GEDI_FCH_2019.tif
cd $1
[ ! -f $out.lst ] && parallel gdalinfo /vsitar/{} ::: DEM1_SAR_DGE_30_*.tar | grep _DEM.tif | sed 's/^[[:space:]]*//' 1>$out.lst 2>/dev/null 
aux-lists.sh $out
#[ ! -f $out-wbm.lst ] && parallel gdalinfo /vsitar/{} ::: DEM1_SAR_DGE_30_* | grep _WBM.tif | sed 's/^[[:space:]]*//' 1>$out-wbm.lst 2>/dev/null 
#[ ! -f $out-flm.lst ] && parallel gdalinfo /vsitar/{} ::: DEM1_SAR_DGE_30_* | grep _FLM.tif | sed 's/^[[:space:]]*//' 1>$out-flm.lst 2>/dev/null 
#[ ! -f $out-edm.lst ] && parallel gdalinfo /vsitar/{} ::: DEM1_SAR_DGE_30_* | grep _EDM.tif | sed 's/^[[:space:]]*//' 1>$out-edm.lst 2>/dev/null 
#[ ! -f $out-hem.lst ] && parallel gdalinfo /vsitar/{} ::: DEM1_SAR_DGE_30_* | grep _HEM.tif | sed 's/^[[:space:]]*//' 1>$out-hem.lst 2>/dev/null 
[ ! -f $out-wbm.vrt ] && parallel gdalbuildvrt -q -overwrite -input_file_list {}.lst {}.vrt ::: $out $out-wbm $out-flm $out-edm $out-hem
[ ! -f ../$out.tif ] && parallel gdal_translate -q -of COG -co COMPRESS=DEFLATE -co PREDICTOR=3 -co BIGTIFF=IF_SAFER {}.vrt ../{}.tif ::: $out $out-hem
[ ! -f ../$out-wbm.tif ] && parallel gdal_translate -q -of COG -co COMPRESS=DEFLATE -co PREDICTOR=2 -co BIGTIFF=IF_SAFER {}.vrt ../{}.tif ::: $out-wbm $out-flm $out-edm
cd ..
[ ! -f $out-dtm.tif ] && gdal_calc.py --quiet -A "$out.tif" -B $fch --outfile="$out-tmp.tif" --extent=intersect --calc='(A-1.0*B)*(A>0)*(B<100)' --type Float32 --NoDataValue=0 --co='COMPRESS=DEFLATE' --co='PREDICTOR=3' --co='BIGTIFF=IF_SAFER' --co='TILED=YES' --overwrite\
 && gdal_translate -q -of COG -co COMPRESS=DEFLATE -co PREDICTOR=3 -co BIGTIFF=IF_SAFER $out-tmp.tif $out-dtm.tif && rm $out-tmp.tif
s3cmd -P -q sync $out-dtm.tif s3://copernicus/dtm/ &
s3cmd -P -q sync $out-wbm.tif s3://copernicus/dtm/wbm/ &
s3cmd -P -q sync $out-flm.tif s3://copernicus/dtm/flm/ &
s3cmd -P -q sync $out-edm.tif s3://copernicus/dtm/edm/ &
s3cmd -P -q sync $out-hem.tif s3://copernicus/dtm/hem/ && rm $out-hem.tif &
s3cmd -P -q sync $out.tif s3://copernicus/dsm/
