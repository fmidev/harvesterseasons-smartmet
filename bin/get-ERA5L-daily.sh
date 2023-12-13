#!/bin/bash
#
# monthly script for fetching ERA5 Land reanalysis data from cdsapi
# and setting it up in the smartmet-server
#
eval "$(conda shell.bash hook)"
if [ $# -ne 0 ]
then
    year=$1
    month=$2
    day=$3
    ymond=$year$month$day
    ymond1=$(date -d $ymond '+%Y%m%d')
    ymond2="$(date -d "$ymond1 - 1 days" +%Y%m%d)"
    yday=$(date -d $ymond2 '+%d')
    ymonth=$(date -d $ymond2 '+%m')
    yyear=$(date -d $ymond2 '+%Y')
    echo $yday
else
    year=$(date -d '6 days ago' +%Y)
    month=$(date -d '6 days ago' +%m)
    day=$(date -d '6 days ago' +%d)
    yyear=$(date -d '7 days ago' +%Y)
    ymonth=$(date -d '7 days ago' +%m)
    yday=$(date -d '7 days ago' +%d)    
    ymond1=$year$month$day
    ymond2=$yyear$ymonth$yday

fi

source ~/.smart 
cd /home/smartmet/data
echo "fetch ERA5 for y: $year m: $month d: $day"
[ -f ERA5L_$year$month${day}T000000_sfc-1h.grib ] || ../bin/cds-era5l.py $year $month $day $abr $area
conda activate cdo
# accumulated at 00UTC
cdo -b P8 -O --eccodes shifttime,-1day -selhour,0 -selname,e,tp,slhf,sshf,ro,str,strd,ssr,ssrd,sf ERA5L_${ymond1}T000000_sfc-1h.grib ERA5L_20000101T000000_${ymond2}T000000_accumulated.grib

# daily means for instantaneous
cdo -b P8 -O --eccodes daymean -selname,10u,10v,2d,2t,lai_hv,lai_lv,src,skt,asn,rsn,sd,stl1,stl2,stl3,stl4,sp,tsn,swvl1,swvl2,swvl3,swvl4 grib/ERA5L_20000101T000000_${ymond2}T000000_base+soil.grib ERA5LD_20000101T000000_${ymond2}T000000_dailymeans.grib

# append to monthly files - with parallel run use -j1 
if [ $yday -eq 01 ]
then
    mv ERA5L_20000101T000000_${ymond2}T000000_accumulated.grib grib/ERA5L_20000101T000000_${ymond2}T000000_accumulated.grib
    mv ERA5LD_20000101T000000_${ymond2}T000000_dailymeans.grib grib/ERA5LD_20000101T000000_${ymond2}T000000_dailymeans.grib
else
    export SKIP_SAME_TIME=1
    cdo -b P8 -O --eccodes mergetime grib/ERA5L_20000101T000000_${yyear}${ymonth}01T000000_accumulated.grib ERA5L_20000101T000000_${ymond2}T000000_accumulated.grib grib/out1.grib
    mv grib/out1.grib grib/ERA5L_20000101T000000_${yyear}${ymonth}01T000000_accumulated.grib
    rm ERA5L_20000101T000000_${ymond2}T000000_accumulated.grib
    cdo -b P8 -O --eccodes mergetime grib/ERA5LD_20000101T000000_${yyear}${ymonth}01T000000_dailymeans.grib ERA5LD_20000101T000000_${ymond2}T000000_dailymeans.grib grib/out2.grib
    mv grib/out2.grib grib/ERA5LD_20000101T000000_${yyear}${ymonth}01T000000_dailymeans.grib
    rm ERA5LD_20000101T000000_${ymond2}T000000_dailymeans.grib
fi

# daily hourly data
mv ERA5L_$year$month${day}T000000_sfc-1h.grib grib/ERA5L_20000101T000000_${ymond1}T000000_base+soil.grib


cdo -f grb2 --eccodes setparam,11.1.0 -selname,sde -aexprf,ec-sde.instr grib/ERA5L_20000101T000000_$year$month${day}T000000_base+soil.grib grib/ERA5L_${year}0101T000000_$year$month${day}T000000_sde.grib
sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0
