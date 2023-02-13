#!/bin/bash
#
# For renaming files in s3://ecache/ with better generation dates/end dates
# f.ex. gnu parallel run: parallel ./change-ecache-date.sh {\1} {\2} ::: `seq firstyear lastyear` ::: `seq -q firstmonth lastmonth` 

year=$1
month=$2

edate=$(date -d "$year${month}01 215 days" +%Y%m%d)
rclone moveto s3://ecache/sf/ECSF_20000101T000000_$year${month}01T000000_all_24h_euro.grib s3://ecache/sf/ECSF_$year${month}01T000000_${edate}01T000000_all_24h_euro.grib
#rclone moveto ECSF_20000101T000000_$year${month}T000000_all_24h_euro.grib ECSF_$year${month}01T000000_${edate}01T000000_all_24h_euro.grib
#rclone moveto ECSF_20000101T000000_$year${month}01T000000_pl_12h_euro.grib ECSF_$year${month}01T000000_${edate}01T000000_pl_12h_euro.grib