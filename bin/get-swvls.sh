#!/bin/bash
if [ $# -ne 0 ]
then
    y=$1
    m=$2
else 
    y=$(date +%Y)
    m=$(date +%m)
fi
cd ~/data
cat << EOF > ecsf-$y-$m-sfc-swvls-eu.mars
RETRIEVE,
    CLASS      = OD,
    TYPE       = FC,
    STREAM     = MMSF,
    EXPVER     = 0001,
    REPRES     = SH,
    LEVTYPE    = SFC,
    PARAM      = 39.128/40.128/41.128/42.128,
    TIME       = 0000,
    STEP       = 0/TO/5160/BY/24,
    NUMBER     = 0/TO/50,
    AREA       = 75/-30/25/50,
    ORIGIN     = ECMF,
    SYSTEM     = 5,
    METHOD     = 1,
    PADDING    = 0,
    EXPECT     = ANY,
    DATE       = $y${m}01,
    TARGET     = "ECSF_$y$m01T000000_sfc-swvls-24h-eu.grib"
EOF
mars ecsf-${y}-${m}-sfc-swvls-eu.mars
if [ $? -eq 0 ]; then
    rm -f ecsf-${y}-${m}-sfc-swvls-eu.mars
fi
