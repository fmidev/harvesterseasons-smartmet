#!/usr/bin/env bash
# This script fetches single level 15-days EC-ENS data from MARS archive,
# adds sde from snow variables, and performs XGBoost downscaling to get SWI2 forecasts
# for Nordic domain (72/3/52/33).
# Forecasts for SWI2, SDE and STL2 for Harvester Seasons. 
# Default date is yesterday, give year month day as cmd for other dates.
# Default grid is ERA5-Land, give era5 as 4th cmd for ERA5 grid.
# (AK 2025)
eval "$(/home/ubuntu/mambaforge/bin/conda shell.bash hook)"
conda activate xgb

if [ $# -ne 0 ]
then
    year=$1
    month=$2
    day=$3
    if [[ $4 == 'era5' ]] 
        then bsf='B2SF'; era='era5'; GRID=0.25/0.25;
        else bsf='BSF'; era='era5l'; GRID=0.1/0.1;
    fi
else
    year=$(date +%Y)
    month=$(date +%m)
    day=$(date +%d)
    bsf='BSF'; era='era5l'; GRID=0.1/0.1;
fi

DATE="${year}-${month}-${day}"
echo $DATE $GRID $bsf $era

# MARS parameters for surface and pressure levels
MARS_DIR="/home/ubuntu/harvesterseasons-smartmet/mars"

# MARS requests
process_param() {
    DATE=$1
    MARS_DIR=$2
    GRID=$3
    era=$4

    REQ_TEMP_0="ec-ens_sfc_req_temp_0.mars"
    REQ_TEMP_1TO50="ec-ens_sfc_req_temp_1to50.mars"
    
    TARGET_0="ec-ens_${DATE}_${era}_sfc-nd-0.grib"
    TARGET_1TO50="ec-ens_${DATE}_${era}_sfc-nd-1to50.grib"

    REQUEST_FILE_0="${MARS_DIR}/ec-ens_req_${DATE}_0.mars"
    REQUEST_FILE_1TO50="${MARS_DIR}/ec-ens_req_${DATE}_1to50.mars"
    
    # request control 0
    sed -e "s#DATE_CMD#$DATE#g" \
        -e "s#GRID_CMD#$GRID#g" \
        -e "s#TARGET_CMD#$TARGET_0#g" \
        "${MARS_DIR}/${REQ_TEMP_0}" > "$REQUEST_FILE_0"

    # request members 1 to 50    
    sed -e "s#DATE_CMD#$DATE#g" \
        -e "s#GRID_CMD#$GRID#g" \
        -e "s#TARGET_CMD#$TARGET_1TO50#g" \
        "${MARS_DIR}/${REQ_TEMP_1TO50}" > "$REQUEST_FILE_1TO50"

    # download control 0
    [ -s ec-ens/${TARGET_0} ] && echo "EC-ENS control file already downloaded" || cat $REQUEST_FILE_0 | mars
    
    # download members 1 to 50
    [ -s ec-ens/${TARGET_1TO50} ] && echo "EC-ENS members 1 to 50 file already downloaded" || cat $REQUEST_FILE_1TO50 | mars

    [ -s ec-ens/${TARGET_0} ] && [ -s ec-ens/${TARGET_1TO50} ] && echo "EC-ENS ready" || mv $TARGET_0 $TARGET_1TO50 ec-ens/

    rm $REQUEST_FILE_0 $REQUEST_FILE_1TO50
}

export -f process_param

cd /home/ubuntu/data

# Fetch data from MARS
[ ! -s ec-ens/ec-ens_${DATE}_${era}_sfc-nd-0.grib ] && [ ! -s ec-ens/ec-ens_${DATE}_${era}_sfc-nd-1to50.grib ] && \
    echo "Downloading EC-ENS data for ${DATE}..." && \
    process_param $DATE $MARS_DIR $GRID $era || echo "EC-ENS data already downloaded for ${DATE}"

# sfc to ensemble members 1-50 and copy control 0 to ensmems/ too
[ ! -s ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-nd-50.grib ] && grib_copy ec-ens/ec-ens_${DATE}_${era}_sfc-nd-1to50.grib ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-nd-[number].grib || echo "Already sfc to members"
[ ! -s ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-nd-0.grib ] && cp ec-ens/ec-ens_${DATE}_${era}_sfc-nd-0.grib ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-nd-0.grib || echo "Already sfc control to members"

## create disaccumulated variables
[ -s ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-nd-50.grib ] && ! [ -s ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-disacc-nd-50.grib ] && \
 seq 0 50 | parallel "cdo -s --eccodes -O mergetime -seltimestep,1 -selname,e,tp,slhf,sshf,ro,str,strd,ssr,ssrd,sf ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-nd-{}.grib \
     -deltat -selname,e,tp,slhf,sshf,ro,str,strd,ssr,ssrd,sf ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-nd-{}.grib ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-disacc-nd-{}.grib"

# single level data
# add snow depth to ec-ens
[ -s ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-nd-50.grib ] && [ ! -s ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc+sde-nd-50.grib ] && \
    seq 0 50 | parallel cdo -s --eccodes -O aexprf,ec-sde.instr ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-nd-{}.grib ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc+sde-nd-{}.grib || \
    echo "NOT adding snow - no input or already produced"
# fix grib attributes for ECENS
[ -s ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc+sde-nd-50.grib ] && [ ! -s ec-ens/ensmems/ECENS_${year}${month}${day}T000000_${era}_sfc+sde-nd-50.grib ] && \
 seq 0 50 | parallel grib_set -r -s centre=98,setLocalDefinition=1,localDefinitionNumber=15,totalNumber=51,number={} ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc+sde-nd-{}.grib \
    ec-ens/ensmems/ECENS_${year}${month}${day}T000000_${era}_sfc+sde-nd-{}.grib || echo "NOT fixing ECENS all+sde gribs attributes - no input or already produced"
# join ensemble members and move to grib folder 
[ -s ec-ens/ensmems/ECENS_${year}${month}${day}T000000_${era}_sfc+sde-nd-50.grib ] && [ ! -s grib/ECENS_${year}${month}${day}T000000_${era}_sfc+sde-nd.grib ] && \
grib_copy ec-ens/ensmems/ECENS_${year}${month}${day}T000000_${era}_sfc+sde-nd-*.grib grib/ECENS_${year}${month}${day}T000000_${era}_sfc+sde-nd.grib || echo "NOT joining all+sde ensemble members ECENS - no input or already produced"

# run XGBoost model to produce swi2 forecasts
! [ -s grib/ECXENS_$year${month}${day}T000000_swi2-nd.grib ] && echo 'start XGBoost predict for SWI2' && run-xgb-predict-swi2-ecens.sh $year $month $day || echo 'NOT XGBoost predict for SWI2 - no input or already produced'

#sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0

# bias adjustments for surface parameters
# adjust unbound variables 
#[ -s ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-all-nd-50.grib ] && ! [ -s ec-ens/ensmems/ec-ens-${bsf}_${DATE}_${era}_sfc-unbound-nd-50.grib ] && \
# seq 0 50 | parallel cdo -s -b P8 -O --eccodes ymonadd \
#    -selname,2d,2t,stl1,swvl1,swvl2,swvl3,swvl4 ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-all-nd-{}.grib \
#    -selname,2d,2t,stl1,swvl1,swvl2,swvl3,swvl4 $era/$era-ec-ens_2000-2019_unbound_bias_nd.grib \
#    ec-ens/ensmems/ec-ens-${bsf}_${DATE}_${era}_sfc-unbound-nd-{}.grib || echo "NOT adj unbound - input missing or already produced"

# adjust snow variables
#[ -s ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-all-nd-50.grib ] && ! [ -s ec-ens/ensmems/ec-ens-${bsf}_${DATE}_${era}_sfc-snow-nd-50.grib ] && \
# seq 0 50 | parallel cdo -s -O -b P12 --eccodes setmisstoc,0.0 -aexprf,ec-sde.instr -ymonadd \
#    -selname,rsn,sd ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-all-nd-{}.grib \
#    -selname,rsn,sd $era/$era-ec-ens_2000-2019_unbound_bias_nd.grib \
#    ec-ens/ensmems/ec-ens-${bsf}_${DATE}_${era}_sfc-snow-nd-{}.grib || echo "NOT adj snow - input missing or already produced"

# adjust wind
#[ -s ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-all-nd-50.grib ] && ! [ -s ec-ens/ensmems/ec-ens-${bsf}_${DATE}_${era}_sfc-bound-nd-50.grib ] && \
# seq 0 50 | parallel -q cdo -s -b P8 -O --eccodes ymonmul \
#    -aexpr,'ws=sqrt(10u^2+10v^2);' -selname,10u,10v ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-all-nd-{}.grib \
#    -aexpr,'10u=ws;10v=ws;' -selname,ws $era/$era-ec-ens_2000-2019_bound_bias_nd.grib \
#    ec-ens/ensmems/ec-ens-${bsf}_${DATE}_${era}_sfc-bound-nd-{}.grib || echo "NOT adj wind - input missing or already produced"
