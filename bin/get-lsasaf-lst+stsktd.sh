#!/bin/env bash
# get ESA CCI LST data from CEDA
# syntax: get-esa-cci-lst.sh <date>

# Function to read credentials from .netrc
read_netrc_credentials() {
    local host="thredds.lsasvcs.ipma.pt"
    local netrc_file="/home/ubuntu/.netrc"
    
    if [[ ! -f "$netrc_file" ]]; then
        echo "Error: .netrc file not found in $HOME" >&2
        exit 1
    fi
    
    # Extract credentials using grep
    login=$(grep "machine $host" "$netrc_file" | awk '{print $4}')
    passwd=$(grep "machine $host" "$netrc_file" | awk '{print $6}')
    
    if [[ -z "$login" || -z "$passwd" ]]; then
        echo "Error: Could not find credentials for $host in .netrc" >&2
        exit 1
    fi
}

# Read credentials from .netrc
read_netrc_credentials
#echo $login $passwd 
date=$1
cd /home/ubuntu/data
 [[ -s lsasaf/LSASAF_${date}120000_skt-eu.grib ]] && echo "LST-day $date already downloaded" || cdo -O -a -s -f grb2 -b P12 copy -setname,skt -settime,12:00:00\
  https://$login:$passwd@thredds.lsasvcs.ipma.pt/thredds/dodsC/EPS/EDLST/NETCDF/${date:0:4}/${date:4:2}/${date:6:2}/NETCDF4_LSASAF_M01-AVHR_EDLST-DAY_GLOBE_${date}0000.nc?LST-day[0:1:0][11500:1:16500][15000:1:23000],lat[11500:1:16500],lon[15000:1:23000],time[0:1:0],crs\
  lsasaf/LSASAF_${date}120000_skt-eu.grib &
 [[ -s lsasaf/LSASAF_${date}000000_skt-eu.grib ]] && echo "LST-night $date already downloaded" || cdo -O -a -s -f grb2 -b P12 copy -setname,skt -settime,00:00:00\
  https://$login:$passwd@thredds.lsasvcs.ipma.pt/thredds/dodsC/EPS/EDLST/NETCDF/${date:0:4}/${date:4:2}/${date:6:2}/NETCDF4_LSASAF_M01-AVHR_EDLST-NIGHT_GLOBE_${date}0000.nc?LST-night[0:1:0][11500:1:16500][15000:1:23000],lat[11500:1:16500],lon[15000:1:23000],time[0:1:0],crs\
  lsasaf/LSASAF_${date}000000_skt-eu.grib 
# wait
[[ -s lsasaf/LSASAF_${date}120000_stsktd-eu.grib ]] && echo "obs-time-day $date already downloaded" || cdo -O -a -s -f grb2 -b P12 copy -setparam,63.128.192 -settime,12:00:00 -mulc,60\
 https://$login:$passwd@thredds.lsasvcs.ipma.pt/thredds/dodsC/EPS/EDLST/NETCDF/${date:0:4}/${date:4:2}/${date:6:2}/NETCDF4_LSASAF_M01-AVHR_EDLST-DAY_GLOBE_${date}0000.nc?aquisition_time-day[0:1:0][11500:1:16500][15000:1:23000],lat[11500:1:16500],lon[15000:1:23000],time[0:1:0],crs\
 lsasaf/LSASAF_${date}120000_stsktd-eu.grib &
[[ -s lsasaf/LSASAF_${date}000000_stsktd-eu.grib ]] && echo "obs-time-night $date already downloaded" || cdo -O -a -s -f grb2 -b P12 copy -setparam,63.128.192 -settime,00:00:00 -mulc,60\
 https://$login:$passwd@thredds.lsasvcs.ipma.pt/thredds/dodsC/EPS/EDLST/NETCDF/${date:0:4}/${date:4:2}/${date:6:2}/NETCDF4_LSASAF_M01-AVHR_EDLST-NIGHT_GLOBE_${date}0000.nc?time[0:1:0],lat[11500:1:16500],lon[15000:1:23000],aquisition_time-night[0:1:0][11500:1:16500][15000:1:23000],crs\
 lsasaf/LSASAF_${date}000000_stsktd-eu.grib

#sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0