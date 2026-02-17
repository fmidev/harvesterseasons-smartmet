#!/usr/bin/env bash
set -euo pipefail
cd /home/smartmet/data
CCI_SKT=grib/CCI_20000101T000000_2014_skt-12h.grib2
CCI_STSKTD=grib/CCI_20000101T000000_2014_stsktd-12h.grib2
ERA5=grib/CCI_20000101T000000_20140401T000000_sl_12h_euro.grib2
TARGET_LOCAL=(3 15)
LOCAL_OFFSET=0                     # offset in seconds (positive means ERA5 UTC = local - offset)

declare -a ERA5_TARGET_FILES=()

# produce ERA5 hourly subsets at the requested local hours (outputs remain GRIB2)
mapfile -t ERA5_TARGET_FILES < <(printf 'era5_target_%s.grib2\n' "${TARGET_LOCAL[@]}")
export ERA5 LOCAL_OFFSET
parallel --no-notice --line-buffer --bar --jobs 0 '
  hour={};
  local_secs=$(( hour * 3600 ));
  utc_secs=$(( (local_secs - LOCAL_OFFSET) % 86400 ));
  utc_secs=$(( (utc_secs + 86400) % 86400 ));
  utc_hour=$(( utc_secs / 3600 ));
  target_file=era5_target_${hour}.grib2;
  cdo -f grb2 chname,skt,era5_target_${hour} -selhour,$utc_hour "$ERA5" "$target_file"
' ::: "${TARGET_LOCAL[@]}"

# remap ERA5 so both the observation-hour field and the target-hour fields share the CCI grid
cdo -f grb2 remapbil,"$CCI_STSKTD" "$ERA5" era5_on_cci.grib2
cdo -f grb2 merge "$CCI_STSKTD" era5_on_cci.grib2 "${ERA5_TARGET_FILES[@]}" merged.grib2

# apply the diurnal offset derived from ERA5 to the CCI `stsktd` measurements so we output `skt` tuned to 03/15 local time
cdo -f grb2 aexprf,"skt_03_local=stsktd +(era5_target_3 - skt); skt_15_local=stsktd +(era5_target_15 - skt)" merged.grib2 cci_corrected.grib2