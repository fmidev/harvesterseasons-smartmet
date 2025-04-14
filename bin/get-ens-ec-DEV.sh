#!/usr/bin/env bash
# DEV version

if [ $# -ne 0 ]
then
    year=$1
    month=$2
    day=$3
    if [[ $4 == 'era5' ]] 
        then bsf='B2SF'; era='era5'; GRID='0.25/0.25';
        else bsf='BSF'; era='era5l'; GRID='0.1/0.1';
    fi
else
    year=$(date --date="yesterday" +%Y)
    month=$(date --date="yesterday" +%m)
    day=$(date --date="yesterday" +%d)
    bsf='BSF'; era='era5l'; GRID='0.1/0.1';
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
    
    TARGET_0="ec-ens/ec-ens_${DATE}_${era}_${LEVEL}-${PARAMNAME}-nd-6h-0.grib"
    TARGET_1TO50="ec-ens/ec-ens_${DATE}_${era}_${LEVEL}-${PARAMNAME}-nd-6h-1to50.grib"

    REQUEST_FILE_0="${MARS_DIR}/ec-ens_req_${PARAMNAME}_0.mars"
    REQUEST_FILE_1TO50="${MARS_DIR}/ec-ens_req_${PARAMNAME}_1to50.mars"
    
    # request control 0
    sed -e "s/DATE_CMD/$DATE/g" \
        -e "s/PARAM_CMD/$PARAM/g" \
        -e "s/PARAM_NAME_CMD/$PARAMNAME/g" \
        -e "s/GRID_CMD/$GRID/g" \
        -e "s/TARGET_CMD/$TARGET_0/g" \
        "${MARS_DIR}/${REQ_TEMP_0}" > "$REQUEST_FILE_0"
    
    # request members 1 to 50
    sed -e "s/DATE_CMD/$DATE/g" \
        -e "s/PARAM_CMD/$PARAM/g" \
        -e "s/PARAM_NAME_CMD/$PARAMNAME/g" \
        -e "s/GRID_CMD/$GRID/g" \
        -e "s/TARGET_CMD/$TARGET_1TO50/g" \
        "${MARS_DIR}/${REQ_TEMP_1TO50}" > "$REQUEST_FILE_1TO50"

    # download control 0
    [ -s ec-ens/${TARGET_0} ] && echo "EC-ENS ${PARAMNAME} control file already downloaded" || cat $REQUEST_FILE_0 | mars
    
    # download members 1 to 50
    [ -s ec-ens/${TARGET_1TO50} ] && echo "EC-ENS ${PARAMNAME} members 1 to 50 file already downloaded" || cat $REQUEST_FILE_1TO50 | mars

    rm $REQUEST_FILE_0 $REQUEST_FILE_1TO50

    echo "EC-ENS ${PARAMNAME} files downloaded"
}

export -f process_param

cd /home/ubuntu/data

# Fetch data from MARS
cat "${SFC_PARAMS_FILE}" | parallel -j1 --colsep ' ' process_param {1} {2} $DATE sfc $MARS_DIR $GRID $era
cat "${PL_PARAMS_FILE}" | parallel -j1 --colsep ' ' process_param {1} {2} $DATE pl $MARS_DIR $GRID $era

# join surface and pressure level grib files
cdo --eccodes merge ec-end/ec-ens_${DATE}_${GRID}_sfc-*.grib ec-ens/ec-ens_${DATE}_${GRID}_sfc_all.grib
cdo --eccodes merge ec-end/ec-ens_${DATE}_${GRID}_pl-*.grib ec-ens/ec-ens_${DATE}_${GRID}_pl_all.grib

# ensemble members
grib_copy ec-ens/ec-ens_${DATE}_${GRID}_sfc_all.grib ec-ens/ec-ens_${DATE}_${GRID}_sfc_all-[number].grib
grib_copy ec-end/ec-ens_${DATE}_${GRID}_pl_all.grib ec-ens/ec-ens_${DATE}_${GRID}_pl_all-[number].grib

# bias adjustments for surface parameters
# adjust swvl1/2 
# adjust unbound variables 
# adjust snow variables
# adjust wind
# adjust accumulating variables and create disaccumulated variables

# fix grib attributes (surface and pressure level)

# join ensemble members and move to grib folder (surface and pressure level)

# add snow depth to ens-ec

# run XGBoost model to produce swi2 forecasts


