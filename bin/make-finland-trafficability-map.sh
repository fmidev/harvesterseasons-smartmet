#!/usr/bin/env bash
# Script to generate a trafficability map for Finland from EC-ENS output
# Usage: make-finland-trafficability-map.sh YYYY-MM-DD [offset_day 0-14] [output-dir]
eval "$(conda shell.bash hook)"

conda activate xgb
# Input arguments
if [ $# -lt 1 ]; then
    echo "Usage: $0 YYYY-MM-DD [offset_day: 0-14] [output-dir]"
    exit 1
fi
DATE="$1"
offset_day="${2:-0}"
outdir="${3:-maps}"
# Validate offset day
if [[ $offset_day -lt 0 || $offset_day -gt 14 ]]; then
    echo "Error: offset_day must be between 0 and 14"
    exit 1
fi

cd /home/smartmet/data

# Prepare directories
mkdir -p "$outdir"

# Identify input GRIB file
grib_file="grib/ECXENS_${DATE//-/}T000000_swi2-era5l-nd.grib"
if [ ! -s "$grib_file" ]; then
    echo "Error: EC-ENS GRIB file not found: $grib_file"
    exit 1
fi

tif_original="/vsicurl/https://pta.data.lit.fmi.fi/geo/harvestability/KKL_SMK_Suomi_2021_06_01.tif"

# Calculate actual forecast date
forecast_date=$(date -d "$DATE + $offset_day days" +%Y-%m-%d)

# File names for this forecast
swi2_p90="$outdir/swi2_p90_${forecast_date}_${DATE}.grib"
swi2_p10="$outdir/swi2_p10_${forecast_date}_${DATE}.grib"
tif_modified_t="$outdir/trafficability_modified_${forecast_date}_${DATE}.tif"
cog_out_t="$outdir/trafficability_finland_${forecast_date}_${DATE}.tif"

# Check if final output already exists
if [ -s "$cog_out_t" ]; then
    echo "Trafficability map already exists, skipping: $cog_out_t"
    exit 0
fi

# Set GDAL configuration to handle large files
export GDAL_CACHEMAX=1024
export CHECK_DISK_FREE_SPACE=FALSE

echo "1) Extract ensemble members for the specific forecast day and compute 90th and 10th percentiles"
[ -s ${swi2_p90} ] && echo "EC-ENS P90 file already processed" || cdo --eccodes -b P8 \
 -s -f grb seldate,${forecast_date}T00:00:00 \
 -sellonlatbox,18.5,33,59.5,69.2 -enspctl,90 $grib_file $swi2_p90
[ -s ${swi2_p10} ] && echo "EC-ENS P10 file already processed" || cdo --eccodes -b P8 \
 -s -f grb seldate,${forecast_date}T00:00:00 \
 -sellonlatbox,18.5,33,59.5,69.2 -enspctl,10 $grib_file $swi2_p10

echo "2) Resample SWI2 p90+p10 to match trafficability map resolution and extent"
[ -s ${swi2_p90:0:-5}.tif ] && echo "P90 file already warped" || \
 gdalwarp -overwrite -t_srs '+proj=utm +zone=35 +ellps=GRS80 +towgs84=0,0,0,-0,-0,-0,0 +units=m +no_defs +type=crs' -ot byte \
 -te 164000 6617999.999 734000 7692000 -ts 35625 67125 -q \
 -co COMPRESS=DEFLATE -co PREDICTOR=2 -co TILED=YES -co BIGTIFF=YES \
 "$swi2_p90" "${swi2_p90:0:-5}.tif"
[ -s ${swi2_p10:0:-5}.tif ] && echo "P10 file already warped" || \
 gdalwarp -overwrite -t_srs '+proj=utm +zone=35 +ellps=GRS80 +towgs84=0,0,0,-0,-0,-0,0 +units=m +no_defs +type=crs' -ot byte \
 -te 164000 6617999.999 734000 7692000 -ts 35625 67125 -q \
 -co COMPRESS=DEFLATE -co PREDICTOR=2 -co TILED=YES -co BIGTIFF=YES \
 "$swi2_p10" "${swi2_p10:0:-5}.tif"

echo "3) Create modified trafficability map using gdal_calc"
[ -s ${tif_modified_t} ] && echo "Calculation already processed" || \
gdal_calc.py --overwrite -A "$tif_original" -B "${swi2_p90:0:-5}.tif" -C "${swi2_p10:0:-5}.tif" \
 --outfile="$tif_modified_t" --NoDataValue=0 --color-table="maps/trafficability_colormap.txt" --quiet \
 --calc="numpy.where((B>=65) & ((A==3) | (A==5)), 6, numpy.where((C<65) & ((A>=2) & (A<=5)), 1, A))"

[ -s ${cog_out_t} ] && echo "COG-out file already processed" || \
gdal_translate -of COG -co COMPRESS=DEFLATE -co PREDICTOR=2 -a_srs epsg:3067 -q \
 -co BIGTIFF=YES "$tif_modified_t" "${cog_out_t}"
# ...existing gdal_calc.py call (no --color-table)...
python3 - << 'EOF'
from osgeo import gdal
ds = gdal.Open("${cog_out_t}", gdal.GA_Update)
ct = gdal.ColorTable()
with open("maps/trafficability_colormap.txt") as f:
    for line in f:
        idx, r, g, b, a = map(int, line.split())
        ct.SetColorEntry(idx, (r, g, b, a))
ds.GetRasterBand(1).SetColorTable(ct)
ds = None
EOF

s3cmd put -Pq "${cog_out_t}" s3://wetterra/sten/ && echo "6) ${cog_out_t} uploaded to S3"

#rm -f "${swi2_p90:0:-5}.tif" "$tif_modified_t"
