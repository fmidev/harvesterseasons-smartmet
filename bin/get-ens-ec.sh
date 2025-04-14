#!/usr/bin/env bash
# This script fetches single and pressure level 15-days EC-ENS data from MARS archive,
# adds sde from snow variables, and performs XGBoost downscaling to get SWI2 forecasts
# for Nordic domain (72/3/52/33).
# Default date is yesterday.
# Give year month day as cmd for other dates.
# Default grid is ERA5-Land, give era5 as 4th cmd for ERA5 grid.
# (AK 2025)

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
SFC_PARAMS_FILE=${MARS_DIR}/"ec-ens_sfc_params.txt"
PL_PARAMS_FILE=${MARS_DIR}/"ec-ens_pl_params.txt"

# MARS requests
process_param() {
    PARAM=$1
    PARAMNAME=$2
    DATE=$3
    LEVEL=$4
    MARS_DIR=$5
    GRID=$6
    era=$7

    REQ_TEMP_0="ec-ens_${LEVEL}_req_temp_0.mars"
    REQ_TEMP_1TO50="ec-ens_${LEVEL}_req_temp_1to50.mars"
    
    TARGET_0="ec-ens_${DATE}_${era}_${LEVEL}-${PARAMNAME}-nd-0.grib"
    TARGET_1TO50="ec-ens_${DATE}_${era}_${LEVEL}-${PARAMNAME}-nd-1to50.grib"

    REQUEST_FILE_0="${MARS_DIR}/ec-ens_req_${PARAMNAME}_0.mars"
    REQUEST_FILE_1TO50="${MARS_DIR}/ec-ens_req_${PARAMNAME}_1to50.mars"
    
    # request control 0
    sed -e "s#DATE_CMD#$DATE#g" \
        -e "s#PARAM_CMD#$PARAM#g" \
        -e "s#PARAM_NAME_CMD#$PARAMNAME#g" \
        -e "s#GRID_CMD#$GRID#g" \
        -e "s#TARGET_CMD#$TARGET_0#g" \
        "${MARS_DIR}/${REQ_TEMP_0}" > "$REQUEST_FILE_0"

    # request members 1 to 50    
    sed -e "s#DATE_CMD#$DATE#g" \
        -e "s#PARAM_CMD#$PARAM#g" \
        -e "s#PARAM_NAME_CMD#$PARAMNAME#g" \
        -e "s#GRID_CMD#$GRID#g" \
        -e "s#TARGET_CMD#$TARGET_1TO50#g" \
        "${MARS_DIR}/${REQ_TEMP_1TO50}" > "$REQUEST_FILE_1TO50"

    # download control 0
    [ -s ec-ens/${TARGET_0} ] && echo "EC-ENS ${PARAMNAME} control file already downloaded" || cat $REQUEST_FILE_0 | mars
    
    # download members 1 to 50
    [ -s ec-ens/${TARGET_1TO50} ] && echo "EC-ENS ${PARAMNAME} members 1 to 50 file already downloaded" || cat $REQUEST_FILE_1TO50 | mars

    [ -s ec-ens/${TARGET_0} ] && [ -s ec-ens/${TARGET_1TO50} ] && echo "EC-ENS ${PARAMNAME} ready" || mv $TARGET_0 $TARGET_1TO50 ec-ens/

    rm $REQUEST_FILE_0 $REQUEST_FILE_1TO50
}

export -f process_param

cd /home/ubuntu/data

# Fetch data from MARS
cat "${SFC_PARAMS_FILE}" | parallel -j1 --colsep ' ' process_param {1} {2} $DATE sfc $MARS_DIR $GRID $era
cat "${PL_PARAMS_FILE}" | parallel -j1 --colsep ' ' process_param {1} {2} $DATE pl $MARS_DIR $GRID $era

# fix grib files for 10fg mn2t mx2t
parallel grib_copy -w stepType=max ec-ens/ec-ens_${DATE}_${era}_sfc-{}-nd-0.grib ec-ens/ec-ens_${DATE}_${era}_sfc-{}-nd-fix-0.grib ::: mn2t mx2t 10fg
parallel grib_copy -w stepType=max ec-ens/ec-ens_${DATE}_${era}_sfc-{}-nd-1to50.grib ec-ens/ec-ens_${DATE}_${era}_sfc-{}-nd-fix-1to50.grib ::: mn2t mx2t 10fg 

# join grib files 
# pl
[ ! -s ec-ens_${DATE}_${era}_pl-all-nd-0.grib ] && cdo --eccodes merge ec-ens/ec-ens_${DATE}_${era}_pl-*-nd-0.grib ec-ens_${DATE}_${era}_pl-all-nd-0.grib || echo "EC-ENS pl 0 merged already"
[ ! -s ec-ens_${DATE}_${era}_pl-all-nd-1to50.grib ] && cdo --eccodes merge ec-ens/ec-ens_${DATE}_${era}_pl-*-nd-1to50.grib ec-ens_${DATE}_${era}_pl-all-nd-1to50.grib || echo "EC-ENS pl 1-50 merged already"
# fixed
[ ! -s ec-ens_${DATE}_${era}_sfc-fix-nd-0.grib ] && cdo --eccodes merge ec-ens/ec-ens_${DATE}_${era}_sfc-*-nd-fix-0.grib ec-ens_${DATE}_${era}_sfc-fix-nd-0.grib || echo "EC-ENS fixed 0 merged already"
[ ! -s ec-ens_${DATE}_${era}_sfc-fix-nd-1to50.grib ] && cdo --eccodes merge ec-ens/ec-ens_${DATE}_${era}_sfc-*-nd-fix-1to50.grib ec-ens_${DATE}_${era}_sfc-fix-nd-1to50.grib || echo "EC-ENS fixed 1-50 merged already"
# swvls
[ ! -s ec-ens_${DATE}_${era}_sfc-swvls-nd-0.grib ] && cdo --eccodes merge \
  ec-ens/ec-ens_${DATE}_${era}_sfc-swvl1-nd-0.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-swvl2-nd-0.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-swvl3-nd-0.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-swvl4-nd-0.grib \
  ec-ens_${DATE}_${era}_sfc-swvls-nd-0.grib || echo "EC-ENS sfc swvls 0 merged already"
[ ! -s ec-ens_${DATE}_${era}_sfc-swvls-nd-1to50.grib ] && cdo --eccodes merge \
  ec-ens/ec-ens_${DATE}_${era}_sfc-swvl1-nd-1to50.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-swvl2-nd-1to50.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-swvl3-nd-1to50.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-swvl4-nd-1to50.grib \
  ec-ens_${DATE}_${era}_sfc-swvls-nd-1to50.grib || echo "EC-ENS sfc swvls 1-50 merged already"
# sfc
[ ! -s ec-ens_${DATE}_${era}_sfc-all-nd-0.grib ] && cdo --eccodes merge \
  ec-ens/ec-ens_${DATE}_${era}_sfc-ssr-nd-0.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-ssrd-nd-0.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-str-nd-0.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-strd-nd-0.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-ttr-nd-0.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-tsr-nd-0.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-sshf-nd-0.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-slhf-nd-0.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-tp-nd-0.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-e-nd-0.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-2t-nd-0.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-2d-nd-0.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-10v-nd-0.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-10u-nd-0.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-z-nd-0.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-lsm-nd-0.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-msl-nd-0.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-ro-nd-0.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-sst-nd-0.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-skt-nd-0.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-rsn-nd-0.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-sd-nd-0.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-sf-nd-0.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-stl1-nd-0.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-stl2-nd-0.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-stl3-nd-0.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-stl4-nd-0.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-slt-nd-0.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-ssro-nd-0.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-sro-nd-0.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-tcc-nd-0.grib \
  ec-ens_${DATE}_${era}_sfc-all-nd-0.grib || echo "EC-ENS sfc 0 merged already"
[ ! -s ec-ens_${DATE}_${era}_sfc-all-nd-1to50.grib ] && cdo --eccodes merge \
  ec-ens/ec-ens_${DATE}_${era}_sfc-ssr-nd-1to50.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-ssrd-nd-1to50.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-str-nd-1to50.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-strd-nd-1to50.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-ttr-nd-1to50.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-tsr-nd-1to50.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-sshf-nd-1to50.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-slhf-nd-1to50.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-tp-nd-1to50.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-e-nd-1to50.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-2t-nd-1to50.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-2d-nd-1to50.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-10v-nd-1to50.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-10u-nd-1to50.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-z-nd-1to50.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-lsm-nd-1to50.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-msl-nd-1to50.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-ro-nd-1to50.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-sst-nd-1to50.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-skt-nd-1to50.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-rsn-nd-1to50.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-sd-nd-1to50.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-sf-nd-1to50.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-stl1-nd-1to50.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-stl2-nd-1to50.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-stl3-nd-1to50.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-stl4-nd-1to50.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-slt-nd-1to50.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-ssro-nd-1to50.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-sro-nd-1to50.grib \
  ec-ens/ec-ens_${DATE}_${era}_sfc-tcc-nd-1to50.grib \
  ec-ens_${DATE}_${era}_sfc-all-nd-1to50.grib || echo "EC-ENS sfc 1-50 merged already"

# pl, fixed and sfc to ensemble members 1-50 and copy control 0 to ensmems/ too
[ ! -s ec-ens/ensmems/ec-ens_${DATE}_${era}_pl-all-nd-50.grib ] && grib_copy ec-ens_${DATE}_${era}_pl-all-nd-1to50.grib ec-ens/ensmems/ec-ens_${DATE}_${era}_pl-all-nd-[number].grib || echo "Already pl to members"
[ ! -s ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-all-nd-50.grib ] && grib_copy ec-ens_${DATE}_${era}_sfc-all-nd-1to50.grib ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-all-nd-[number].grib || echo "Already sfc to members"
[ ! -s ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-fix-nd-50.grib ] && grib_copy ec-ens_${DATE}_${era}_sfc-fix-nd-1to50.grib ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-fix-nd-[number].grib || echo "Already sfc-fix to members"
[ ! -s ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-swvls-nd-50.grib ] && grib_copy ec-ens_${DATE}_${era}_sfc-swvls-nd-1to50.grib ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-swvls-nd-[number].grib || echo "Already sfc swvls to members"
[ ! -s ec-ens/ensmems/ec-ens_${DATE}_${era}_pl-all-nd-0.grib ] && cp ec-ens_${DATE}_${era}_pl-all-nd-0.grib ec-ens/ensmems/ec-ens_${DATE}_${era}_pl-all-nd-0.grib || echo "Already pl control to members"
[ ! -s ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-all-nd-0.grib ] && cp ec-ens_${DATE}_${era}_sfc-all-nd-0.grib ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-all-nd-0.grib || echo "Already sfc control to members"
[ ! -s ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-fix-nd-0.grib ] && cp ec-ens_${DATE}_${era}_sfc-fix-nd-0.grib ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-fix-nd-0.grib || echo "Already sfc-fix control to members"
[ ! -s ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-swvls-nd-0.grib ] && cp ec-ens_${DATE}_${era}_sfc-swvls-nd-0.grib ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-swvls-nd-0.grib || echo "Already sfc swvls control to members"

## create disaccumulated variables
[ -s ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-all-nd-50.grib ] && ! [ -s ec-ens/ensmems/ec-ens-${bsf}_${DATE}_${era}_sfc-acc-nd-50.grib ] && \
 seq 0 50 | parallel "cdo -s --eccodes -O mergetime -seltimestep,1 -selname,e,tp,slhf,sshf,ro,str,strd,ssr,ssrd,sf,tsr,ttr ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-all-nd-{}.grib \
     -deltat -selname,e,tp,slhf,sshf,ro,str,strd,ssr,ssrd,sf,tsr,ttr ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-all-nd-{}.grib ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-disacc-nd-{}.grib"

# swvls
# fix grib attributes
[ -s ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-swvls-nd-50.grib ] && ! [ -s ec-ens/ensmems/ECENS_${year}${month}${day}T000000_${era}_sfc-swvls-nd-50.grib ]  && \
 seq 0 50 | parallel grib_set -r -s centre=98,setLocalDefinition=1,localDefinitionNumber=15,totalNumber=51,number={} ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-swvls-nd-{}.grib \
    ec-ens/ensmems/ECENS_${year}${month}${day}T000000_${era}_sfc-swvls-nd-{}.grib || echo "NOT fixing ECENS swvls gribs attributes - no input or already produced"
# join ensemble members and move to grib folder 
[ -s ec-ens/ensmems/ECENS_${year}${month}${day}T000000_${era}_sfc-swvls-nd-50.grib ] && ! [ -s grib/ECENS_${year}${month}${day}T000000_${era}_sfc-swvls-nd.grib ] && \
grib_copy ec-ens/ensmems/ECENS_${year}${month}${day}T000000_${era}_sfc-swvls-nd-*.grib grib/ECENS_${year}${month}${day}T000000_${era}_sfc-swvls-nd.grib || echo "NOT joining swvls ensemble members ECENS - no input or already produced"

# single level data
# add snow depth to ec-ens
[ -s ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-all-nd-50.grib ] && [ ! -s ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-all+sde-nd-50.grib ] && \
    seq 0 50 | parallel cdo -s --eccodes -O aexprf,ec-sde.instr ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-all-nd-{}.grib ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-all+sde-nd-{}.grib ||\
    echo "NOT adding snow - no input or already produced"
# fix grib attributes for ECENS
[ -s ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-all+sde-nd-50.grib ] && [ ! -s ec-ens/ensmems/ECENS_${year}${month}${day}T000000_${era}_sfc-all+sde-nd-50.grib ] && \
 seq 0 50 | parallel grib_set -r -s centre=98,setLocalDefinition=1,localDefinitionNumber=15,totalNumber=51,number={} ec-ens/ensmems/ec-ens_${DATE}_${era}_sfc-all+sde-nd-{}.grib \
    ec-ens/ensmems/ECENS_${year}${month}${day}T000000_${era}_sfc-all+sde-nd-{}.grib || echo "NOT fixing ECENS all+sde gribs attributes - no input or already produced"
# join ensemble members and move to grib folder 
[ -s ec-ens/ensmems/ECENS_${year}${month}${day}T000000_${era}_sfc-all+sde-nd-50.grib ] && [ ! -s grib/ECENS_${year}${month}${day}T000000_${era}_sfc-all+sde-nd.grib ] && \
grib_copy ec-ens/ensmems/ECENS_${year}${month}${day}T000000_${era}_sfc-all+sde-nd-*.grib grib/ECENS_${year}${month}${day}T000000_${era}_sfc-all+sde-nd.grib || echo "NOT joining all+sde ensemble members ECENS - no input or already produced"

# pressure level data 
# fix grib attributes for ECENS
[ -s ec-ens/ensmems/ec-ens_${DATE}_${era}_pl-all-nd-50.grib ] && [ ! -s ec-ens/ensmems/ECENS_${year}${month}${day}T000000_${era}_pl-all-nd-50.grib ] && \
 seq 0 50 | parallel grib_set -r -s centre=98,setLocalDefinition=1,localDefinitionNumber=15,totalNumber=51,number={} ec-ens/ensmems/ec-ens_${DATE}_${era}_pl-all-nd-{}.grib \
    ec-ens/ensmems/ECENS_${year}${month}${day}T000000_${era}_pl-all-nd-{}.grib || echo "NOT fixing ECENS pl gribs attributes - no input or already produced"
# join ensemble members and move to grib folder 
[ -s ec-ens/ensmems/ECENS_${year}${month}${day}T000000_${era}_pl-all-nd-50.grib ] && [ ! -s grib/ECENS_${year}${month}${day}T000000_${era}_pl-all-nd.grib ] && \
grib_copy ec-ens/ensmems/ECENS_${year}${month}${day}T000000_${era}_pl-all-nd-*.grib grib/ECENS_${year}${month}${day}T000000_${era}_pl-all-nd.grib || echo "NOT joining pl ensemble members ECENS - no input or already produced"


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


