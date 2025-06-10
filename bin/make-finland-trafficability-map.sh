#!/usr/bin/env bash
# Script to generate a trafficability map for Finland from EC-ENS output
# Usage: make-finland-trafficability-map.sh YYYY-MM-DD [era] [output-dir]
eval "$(conda shell.bash hook)"

conda activate xgb
# Input arguments
if [ $# -lt 1 ]; then
    echo "Usage: $0 YYYY-MM-DD [era: era5l|era5] [output-dir]"
    exit 1
fi
DATE="$1"
era="${2:-era5l}"
outdir="${3:-maps}"
cd /home/smartmet

# Prepare directories
grib_dir="data/grib"
mkdir -p "$outdir"

# Identify input GRIB file
grib_file="$grib_dir/ECXENS_${DATE//-/}T000000_${era}_swi2-era5l-nd.grib"
if [ ! -s "$grib_file" ]; then
    echo "Error: EC-ENS GRIB file not found: $grib_file"
    exit 1
fi

# Temporary files
mean_nc="$outdir/trafficability_mean_${DATE}.nc"
tif_all="$outdir/trafficability_mean_${DATE}.tif"
tif_fin="/vsicurl/https://pta.data.lit.fmi.fi/geo/harvestability/KKL_SMK_Suomi_2021_06_01.tif"
png_out="$outdir/trafficability_finland_${DATE}.png"
colormap="${outdir}/trafficability_colormap.txt"

# 1) Compute ensemble 90th percentile
cdo enspctl,90 "$grib_file" "$mean_nc"

# 2) Convert to GeoTIFF
#cdo -f gdal copy "$mean_nc" "$tif_all"

# 3) Clip to Finland bounding box (lon_min,lat_min,lon_max,lat_max)
# Approx Finland: 19.0 59.8 31.5 70.1
gdalwarp -overwrite -t_srs EPSG:4326 -te 19.0 59.8 31.5 70.1 "$mean_nc" "$tif_fin"

# 4) Create a simple colormap for trafficability
cat > "$colormap" << EOF
0.00  #ffffff
0.25  #a1dab4
0.50  #41b6c4
0.75  #2c7fb8
1.00  #253494
EOF

# 5) Generate colored PNG
gdaldem color-relief "$tif_fin" "$colormap" "$png_out" -alpha

# Cleanup intermediate files
rm -f "$mean_nc" "$tif_all" "$colormap"

echo "Trafficability map generated: $png_out"
