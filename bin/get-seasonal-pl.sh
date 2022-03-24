#!/bin/bash
#
# monthly script for fetching seasonal pressure level data from cdsapi, move to s3

year=$1
mon=$2
eval "$(conda shell.bash hook)"

conda activate xr

cd /home/smartmet/data

! [ -f ec-sf-$year$mon-pl-12h-euro.grib ] && python3 /home/smartmet/bin/cds-sf-pl-12h.py $year $mon
! [ -f ec-sf-$year$mon-all-24h-euro.grib ] && python3 /home/smartmet/bin/cds-sf-all-24h.py $year $mon \
 && s3cmd -Pq put --continue-put ec-sf-$year$mon-pl-12h-euro.grib ec-sf-$year$mon-all-24h-euro.grib s3://ecache/sf/ \
 || echo "SF Data file already downloaded"
# && rm ec-sf-$year$mon-pl-12h-euro.grib 

