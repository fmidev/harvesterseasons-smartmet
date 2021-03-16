#!/bin/bash
#
# copy zip with fire indices netcdf to yearly grib
cd /home/smartmet/data/fire
[ ! -f ECMWF_MARK5_KBDI_${1:4:4}1231_1200_hr_v3.1_con.nc ] && unzip -q $1 || echo "no $1 or unzip done already"

ls ECMWF_FWI_FFMC_${1:4:4}*.nc | sed '
#Save the original filename
h
# Do the replacement
s:ECMWF_\(.*\)_\(.*\)_\([0-9]\{4\}\)\([0-9]\{4\}\)_\([0-9]*\)_:EC\1_\31231T1200_\3T\4_\2_:
s:\.nc:\.grib:
# fix Danger
#s:ECFWI_DANGER_\(.*\)_\(.*\)_:ECFWI_\31231T1200_\1_DANGER-\2_:
#Bring the original filename back
x
G
s/^\(.*\)\n\(.*\)$/cdo -f grb2 -b P16 -s copy -setltype,1 -setname,ffmcode "\1" "\2"/' | bash &

ls ECMWF_FWI_ISI_${1:4:4}*.nc | sed '
#Save the original filename
h
# Do the replacement
s:ECMWF_\(.*\)_\(.*\)_\([0-9]\{4\}\)\([0-9]\{4\}\)_\([0-9]*\)_:EC\1_\31231T1200_\3T\4_\2_:
s:\.nc:\.grib:
# fix Danger
#s:ECFWI_DANGER_\(.*\)_\(.*\)_:ECFWI_\31231T1200_\1_DANGER-\2_:
#Bring the original filename back
x
G
s/^\(.*\)\n\(.*\)$/cdo -f grb2 -b P16 -s copy -setltype,1 -setname,infsinx "\1" "\2"/' | bash \
&& cat ECFWI_*_ISI*.grib > ../grib/ECFWI_${1:4:4}1231T1200_ISI_hr_v3.1_con.grib &

ls ECMWF_FWI_BUI_${1:4:4}*.nc | sed '
#Save the original filename
h
# Do the replacement
s:ECMWF_\(.*\)_\(.*\)_\([0-9]\{4\}\)\([0-9]\{4\}\)_\([0-9]*\)_:EC\1_\31231T1200_\3T\4_\2_:
s:\.nc:\.grib:
# fix Danger
#s:ECFWI_DANGER_\(.*\)_\(.*\)_:ECFWI_\31231T1200_\1_DANGER-\2_:
#Bring the original filename back
x
G
s/^\(.*\)\n\(.*\)$/cdo -f grb2 -b P16 -s copy -setltype,1 -setname,fbupinx "\1" "\2"/' | bash \
&& cat ECFWI_*_BUI*.grib > ../grib/ECFWI_${1:4:4}1231T1200_BUI_hr_v3.1_con.grib &

ls ECMWF_FWI_DMC_${1:4:4}*.nc | sed '
#Save the original filename
h
# Do the replacement
s:ECMWF_\(.*\)_\(.*\)_\([0-9]\{4\}\)\([0-9]\{4\}\)_\([0-9]*\)_:EC\1_\31231T1200_\3T\4_\2_:
s:\.nc:\.grib:
# fix Danger
#s:ECFWI_DANGER_\(.*\)_\(.*\)_:ECFWI_\31231T1200_\1_DANGER-\2_:
#Bring the original filename back
x
G
s/^\(.*\)\n\(.*\)$/cdo -f grb2 -b P16 -s copy -setltype,1 -setname,dufmcode "\1" "\2"/' | bash \
&& cat ECFWI_*_DMC*.grib > ../grib/ECFWI_${1:4:4}1231T1200_DMC_hr_v3.1_con.grib &

ls ECMWF_FWI_DC_${1:4:4}*.nc | sed '
#Save the original filename
h
# Do the replacement
s:ECMWF_\(.*\)_\(.*\)_\([0-9]\{4\}\)\([0-9]\{4\}\)_\([0-9]*\)_:EC\1_\31231T1200_\3T\4_\2_:
s:\.nc:\.grib:
# fix Danger
#s:ECFWI_DANGER_\(.*\)_\(.*\)_:ECFWI_\31231T1200_\1_DANGER-\2_:
#Bring the original filename back
x
G
s/^\(.*\)\n\(.*\)$/cdo -f grb2 -b P16 -s copy -setltype,1 -setname,drtcode "\1" "\2"/' | bash \
&& cat ECFWI_*_DC*.grib > ../grib/ECFWI_${1:4:4}1231T1200_DC_hr_v3.1_con.grib &

ls ECMWF_FWI_DSR_${1:4:4}*.nc | sed '
#Save the original filename
h
# Do the replacement
s:ECMWF_\(.*\)_\(.*\)_\([0-9]\{4\}\)\([0-9]\{4\}\)_\([0-9]*\)_:EC\1_\31231T1200_\3T\4_\2_:
s:\.nc:\.grib:
# fix Danger
#s:ECFWI_DANGER_\(.*\)_\(.*\)_:ECFWI_\31231T1200_\1_DANGER-\2_:
#Bring the original filename back
x
G
s/^\(.*\)\n\(.*\)$/cdo -f grb2 -b P16 -s copy -setltype,1 -setname,fdsrte "\1" "\2"/' | bash \
&& cat ECFWI_*_DSR*.grib > ../grib/ECFWI_${1:4:4}1231T1200_DSR_hr_v3.1_con.grib &

ls ECMWF_FWI_FWI_${1:4:4}*.nc | sed '
#Save the original filename
h
# Do the replacement
s:ECMWF_\(.*\)_\(.*\)_\([0-9]\{4\}\)\([0-9]\{4\}\)_\([0-9]*\)_:EC\1_\31231T1200_\3T\4_\2_:
s:\.nc:\.grib:
# fix Danger
#s:ECFWI_DANGER_\(.*\)_\(.*\)_:ECFWI_\31231T1200_\1_DANGER-\2_:
#Bring the original filename back
x
G
s/^\(.*\)\n\(.*\)$/cdo -f grb2 -b P16 -s copy -setltype,1 -setname,fwinx "\1" "\2"/' | bash \
&& cat ECFWI_*_FWI*.grib > ../grib/ECFWI_${1:4:4}1231T1200_FWI_hr_v3.1_con.grib &

ls ECMWF_MARK5_KBDI_${1:4:4}*.nc | sed '
#Save the original filename
h
# Do the replacement
s:ECMWF_\(.*\)_\(.*\)_\([0-9]\{4\}\)\([0-9]\{4\}\)_\([0-9]*\)_:EC\1_\31231T1200_\3T\4_\2_:
s:\.nc:\.grib:
# fix Danger
#s:ECFWI_DANGER_\(.*\)_\(.*\)_:ECFWI_\31231T1200_\1_DANGER-\2_:
#Bring the original filename back
x
G
s/^\(.*\)\n\(.*\)$/cdo -f grb2 -b P16 -s copy -setltype,1 -setname,kbdi "\1" "\2"/' | bash \
&& cat ECMARK5_*_KBDI*.grib > ../grib/ECMARK5_${1:4:4}1231T1200_KBDI_hr_v3.1_con.grib &

ls ECMWF_MARK5_FDI_${1:4:4}*.nc | sed '
#Save the original filename
h
# Do the replacement
s:ECMWF_\(.*\)_\(.*\)_\([0-9]\{4\}\)\([0-9]\{4\}\)_\([0-9]*\)_:EC\1_\31231T1200_\3T\4_\2_:
s:\.nc:\.grib:
# fix Danger
#s:ECFWI_DANGER_\(.*\)_\(.*\)_:ECFWI_\31231T1200_\1_DANGER-\2_:
#Bring the original filename back
x
G
s/^\(.*\)\n\(.*\)$/cdo -f grb2 -b P16 -s copy -setltype,1 -setname,fdimrk "\1" "\2"/' | bash \
&& cat ECMARK5_*_FDI*.grib > ../grib/ECMARK5_${1:4:4}1231T1200_FDI_hr_v3.1_con.grib &
wait
rm ECMWF_*.nc ECFWI_*.grib ECMARK5_*.grib
