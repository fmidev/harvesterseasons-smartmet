#!/bin/bash
#
# script for fetching ERA5-Land post-processed daily statistics data from cdsapi
# and setting it up in the smartmet-server
# given year, variable and statistic (daily_sum, daily_maximum, daily_minmum, daily_mean) as cmd
#
# 2025 Anni Kröger
#eval "$(conda shell.bash hook)"
eval "$(/home/ubuntu/mambaforge/bin/conda shell.bash hook)"

source ~/.smart

year=$1
var=$2
stat=$3

cd /home/smartmet/data

echo "fetch ERA5-Land daily stats for year: $year var: $var statistic: $stat"

[ -f ERA5D_${year}0101T000000_${year}1231T120000_${var}.nc ] || ../bin/cds-era5l-dailystats.py $year $var $stat
