#!/bin/bash
#
# monthly script for fetching ERA5 Land reanalysis daily (ERA5L) and daily statistics (ERA5LD) data from cdsapi
# and setting it up in the smartmet-server
#
#eval "$(conda shell.bash hook)"
eval "$(/home/ubuntu/mambaforge/bin/conda shell.bash hook)"

if [ $# -ne 0 ]
then
    year=$1
    month=$2
    day=$3
    input_date=$(printf "%04d-%02d-%02d" "$year" "$month" "$day")
    previous_day=$(date -d "$input_date -1 day" +"%Y%m%d")
else
    year=$(date -d '6 days ago' +%Y)
    month=$(date -d '6 days ago' +%m)
    day=$(date -d '6 days ago' +%d)
    previous_day=$(date -d '7 days ago' +%Y%m%d)
fi

source ~/.smart

cd /home/smartmet/data

# ERA5-Land 3-hourly
[ -s grib/ERA5L_20000101T000000_${year}${month}${day}T000000_sfc-3h-$abr.grib ] && echo "Already downloaded ERA5L for $day-$month-$year" || ../bin/cds-era5l-3h.py $year $month $day #$abr $area # area not working anymore in cdsapi as intended
[ -s ERA5L_${year}${month}${day}T000000_sfc-3h.grib ] && ! [ -s grib/ERA5L_20000101T000000_${year}${month}${day}T000000_sfc-3h-$abr.grib ] && mv ERA5L_${year}${month}${day}T000000_sfc-3h.grib grib/ERA5L_20000101T000000_${year}${month}${day}T000000_sfc-3h-$abr.grib
# add sde to ERA5-Land 3-hourly
! [ -s grib/ERA5L_20000101T000000_${year}${month}${day}T000000_sde-3h-$abr.grib ] && [ -s grib/ERA5L_20000101T000000_${year}${month}${day}T000000_sfc-3h-$abr.grib ] && cdo -f grb2 --eccodes setparam,11.1.0 -selname,sde -aexprf,ec-sde.instr grib/ERA5L_20000101T000000_${year}${month}${day}T000000_sfc-3h-$abr.grib grib/ERA5L_20000101T000000_${year}${month}${day}T000000_sde-3h-$abr.grib

# ERA5-Land hourly to create 24h accumulated data
[ -s grib/ERA5LD_20000101T000000_${year}${month}${day}T000000_24h-acc-$abr.grib ] && echo "Already downloaded ERA5L 1-hourly for $day-$month-$year" || ../bin/cds-era5l-1h.py $year $month $day #$abr $area # area not working anymore in cdsapi as intended
[ -s ERA5L_${year}${month}${day}T000000_sfc-1h.grib ] && ! [ -s grib/ERA5LD_20000101T000000_${year}${month}${day}T000000_24h-acc-$abr.grib ] && cdo -b P8 -O --eccodes shifttime,-11hours -shifttime,-30minutes -daysum ERA5L_${year}${month}${day}T000000_sfc-1h.grib grib/ERA5LD_20000101T000000_${year}${month}${day}T000000_24h-acc-$abr.grib && rm ERA5L_${year}${month}${day}T000000_sfc-1h.grib || echo "Already accumulated ERA5L for $day-$month-$year"

# ERA5-Land daily statistics
# daily means
# unzip and grib_copy 
#[ -s grib/ERA5LD_20000101T000000_${year}${month}${day}T000000_dailymeans-$abr.grib ] && echo "Already downloaded ERA5LD daily means for $day-$month-$year" || python ../bin/cds-era5l-dailymeans.py $year $month $day #$abr $area # area not working anymore in cdsapi as intended
#[ -s ERA5LD_{year}{month}{day}T000000_dailymeans.grib ] && ! [ -s grib/ERA5LD_20000101T000000_${year}${month}${day}T000000_dailymeans-$abr.grib ] && mv ERA5LD_${year}${month}${day}T000000_dailymeans.grib grib/ERA5LD_20000101T000000_${year}${month}${day}T000000_dailymeans-$abr.grib 

#sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0

#conda activate cdo
# accumulated at 00UTC
#cdo -b P8 -O --eccodes shifttime,-1day -selhour,0 -selname,e,tp,slhf,sshf,ro,str,strd,ssr,ssrd,sf ERA5L_${ymond1}T000000_sfc-1h.grib ERA5LD_20000101T000000_${ymond2}T000000_accumulated.grib
# daily means for instantaneous ERA5L_20000101T000000_
#cdo -b P8 -O --eccodes daymean -selname,10u,10v,2d,2t,lai_hv,lai_lv,src,skt,asn,rsn,sd,stl1,stl2,stl3,stl4,sp,tsn,swvl1,swvl2,swvl3,swvl4 ERA5L_${ymond1}T000000_sfc-1h.grib ERA5LD_20000101T000000_${ymond1}T000000_dailymeans.grib

# append to monthly files - with parallel run use -j1
#if [ $yday -eq 01 ]
#then
#    mv ERA5LD_20000101T000000_${ymond2}T000000_accumulated.grib grib/ERA5LD_20000101T000000_${ymond2}T000000_accumulated.grib
#    mv ERA5LD_20000101T000000_${ymond1}T000000_dailymeans.grib grib/ERA5LD_20000101T000000_${ymond2}T000000_dailymeans.grib
#else
#    export SKIP_SAME_TIME=1
#    cdo -b P8 -O --eccodes mergetime grib/ERA5LD_20000101T000000_${yyear}${ymonth}01T000000_accumulated.grib ERA5LD_20000101T000000_${ymond2}T000000_accumulated.grib out1-$ymond1.grib && \
#    mv out1-$ymond1.grib grib/ERA5LD_20000101T000000_${yyear}${ymonth}01T000000_accumulated.grib &&\
#    rm ERA5LD_20000101T000000_${ymond2}T000000_accumulated.grib
#    cdo -b P8 -O --eccodes mergetime grib/ERA5LD_20000101T000000_${yyear}${ymonth}01T000000_dailymeans.grib ERA5LD_20000101T000000_${ymond1}T000000_dailymeans.grib out2-$ymond1.grib && \
#    mv out2-$ymond1.grib grib/ERA5LD_20000101T000000_${yyear}${ymonth}01T000000_dailymeans.grib &&\
#    rm ERA5LD_20000101T000000_${ymond1}T000000_dailymeans.grib
#fi

# daily hourly data
#mv ERA5L_${ymond1}T000000_sfc-1h.grib grib/ERA5L_20000101T000000_$year$month${day}T000000_base+soil.grib
#cdo -f grb2 --eccodes setparam,11.1.0 -selname,sde -aexprf,ec-sde.instr grib/ERA5L_20000101T000000_$year$month${day}T000000_base+soil.grib grib/ERA5L_20000101T000000_$year$month${day}T000000_sde.grib
#sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0

# Check if any of the generated files are 0KB
#for file in grib/ERA5L_20000101T000000_$year$month${day}T000000_base+soil.grib \
#           grib/ERA5LD_20000101T000000_${ymond2}T000000_accumulated.grib \
#           grib/ERA5LD_20000101T000000_${ymond1}T000000_dailymeans.grib \
#           grib/ERA5L_20000101T000000_$year$month${day}T000000_sde.grib
#do
#    # check if file is empty
#    if [ -f "$file" ] && [ ! -s "$file" ] 
#    then
#        # print file that is empty
##        echo "Error: $file is 0KB"
#	echo "Removing $file"
#	rm "$file"
#        exit 1
#    else
#        # print file that is not empty
#        echo "$file is not 0KB"
#        
#    fi
#done

#echo "Done"
