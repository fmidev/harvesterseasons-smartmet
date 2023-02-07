#!/bin/bash
###################
# download Sentinel 3 Synergy data from CreoDIAS, combine and transform to grib for smartmet-server ingestion 
# Mikko Strahlendorff 20.4.2022
###################
eval "$(conda shell.bash hook)"
conda activate xr
if [ $# -ne 0 ]
then
    d=$1
    e=$(date -d "$d 9 days" +%Y%m%d)
else
    d=$(date -d '9 days ago' +%Y%m%d)
    d=${d:0:-1}1
    e=$(date -d "$d 9 days" +%Y%m%d)
fi
if [ ${d:6:2} == "21" ] 
then 
    e=${e:0:6}`date -d "${e:4:2}/1 + 1 month - 1 day" +%d`
fi
echo $e
sdate="${d:0:4}-${d:4:2}-${d:6:2}"
edate="${e:0:4}-${e:4:2}-${e:6:2}"
cd /home/smartmet/data/sen3
#token='eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJ5RUhvWks0aWR2WHFmeExZWFhabjFmTi1YSU1UTXJvdTJ2NmVIQXI5ZWE0In0.eyJleHAiOjE2NDk1NTkxNzgsImlhdCI6MTY0OTUyMzE4MCwiYXV0aF90aW1lIjoxNjQ5NTIzMTc4LCJqdGkiOiIxMGNjNmIwYy0xM2I2LTQyNDItYmE2Mi01Y2NjZjE2MWYwMzkiLCJpc3MiOiJodHRwczovL2lkZW50aXR5LmNsb3VkZmVycm8uY29tL2F1dGgvcmVhbG1zL2RpYXMiLCJhdWQiOlsiQ0xPVURGRVJST19QQVJUTkVSUyIsIkNMT1VERkVSUk9fUFVCTElDIiwiY3Jlb2RpYXMtd2ViYXBwIiwiYWNjb3VudCJdLCJzdWIiOiIyNTE3YWYwOC03OTI4LTQzMjYtOWZhYS0wMThjMzk4YmFiMmEiLCJ0eXAiOiJCZWFyZXIiLCJhenAiOiJjcmVvZGlhcy13ZWJhcHAiLCJub25jZSI6IjZhOTM4MTZlLTk4MDItNGRjZi04N2YzLTljZTcxOTYyY2Q4ZCIsInNlc3Npb25fc3RhdGUiOiI1Nzk3ZDAzNC1kYWZjLTQyMDEtOWJmYi05NzZhMDc1MjZlNWQiLCJhY3IiOiIxIiwiYWxsb3dlZC1vcmlnaW5zIjpbImh0dHBzOi8vZmluZGVyMi5pbnRyYS5jbG91ZGZlcnJvLmNvbS8qIiwiaHR0cHM6Ly9ob3Jpem9uLmNmMi5jbG91ZGZlcnJvLmNvbSIsImh0dHBzOi8vZmluZGVyLmNyZW9kaWFzLmV1IiwiaHR0cHM6Ly9wb3J0YWwuY3Jlb2RpYXMuZXUiLCJodHRwczovL2NmMi5jbG91ZGZlcnJvLmNvbSIsImh0dHBzOi8vZGlzY292ZXJ5LmNyZW9kaWFzLmV1IiwiKiIsImh0dHBzOi8vMTg1LjE3OC44NS4yMjIiLCJodHRwczovL3d3dy5jcmVvZGlhcy5ldSIsImh0dHBzOi8vZGFzaGJvYXJkLmNyZW9kaWFzLmV1IiwiaHR0cHM6Ly9zZXJ2aWNlcy5zZW50aW5lbC1odWIuY29tIiwiaHR0cHM6Ly93aG1jcy5jbG91ZGZlcnJvLmNvbSIsImh0dHBzOi8vMTg1LjE3OC44NC4xOCIsImh0dHBzOi8vYXV0aC5jbG91ZC5jb2RlLWRlLm9yZy8qIiwiaHR0cHM6Ly9wb3J0YWwuY3Jlb2RpYXMuZXUvKiIsImh0dHBzOi8vZmluZGVyZGV2LmludHJhLmNsb3VkZmVycm8uY29tIiwiaHR0cHM6Ly9jcmVvZGlhcy5ldSIsImh0dHBzOi8vY3Jlb2FwcHMuc2VudGluZWwtaHViLmNvbS8qIiwiaHR0cDovL2ZpbmRlcjIuaW50cmEuY2xvdWRmZXJyby5jb20iLCJodHRwczovL2Jyb3dzZXIuY3Jlb2RpYXMuZXUiXSwicmVhbG1fYWNjZXNzIjp7InJvbGVzIjpbIm9mZmxpbmVfYWNjZXNzIiwidW1hX2F1dGhvcml6YXRpb24iXX0sInJlc291cmNlX2FjY2VzcyI6eyJhY2NvdW50Ijp7InJvbGVzIjpbIm1hbmFnZS1hY2NvdW50IiwibWFuYWdlLWFjY291bnQtbGlua3MiLCJ2aWV3LXByb2ZpbGUiXX19LCJzY29wZSI6Im9wZW5pZCBhdWQtZml4IHByb2ZpbGUgYXVkLWZpeC1wYXJ0bmVycyBhZGRyZXNzIGVtYWlsIiwic2lkIjoiNTc5N2QwMzQtZGFmYy00MjAxLTliZmItOTc2YTA3NTI2ZTVkIiwiYWRkcmVzcyI6e30sImVtYWlsX3ZlcmlmaWVkIjpmYWxzZSwibmFtZSI6Ik1pa2tvIFN0cmFobGVuZG9yZmYiLCJwcmVmZXJyZWRfdXNlcm5hbWUiOiJtaWtrby5zdHJhaGxlbmRvcmZmQGZtaS5maSIsImdpdmVuX25hbWUiOiJNaWtrbyIsImZhbWlseV9uYW1lIjoiU3RyYWhsZW5kb3JmZiIsImVtYWlsIjoibWlra28uc3RyYWhsZW5kb3JmZkBmbWkuZmkifQ.Y97-ouHLXUk4SRv_t42EsVkkEDFIP4UFg20dQp4LjjycH4v-uWbXdeyM71KjPLIM60gu6iR8lj6J2lt28nTzojZNiOKuTTRLuIBnRC0ZZprPl7WYw9Fqtaa9N18yASOUo7GW7SG70IkLBu1jjP8FuEmWODRecbca93ZS_tMI537nszqGZN6LJ_yW9X0lnmMH55lQG_FltaXASb8jg3Ai3oNYve0Uir1MOIc-4DM979YVkUEiDYQlwbEqfNXwvq0ENQCZVxeipqGzjgxI6ghymDewjGjmk5y0QNb8HYFF7B17DAY5r7PFTtbX4lS07_dgekw_EAzA19TaOfWm5mdrXA'
export token=$(curl -s -d 'client_id=CLOUDFERRO_PUBLIC' \
                             -d "username=mikko.strahlendorff@fmi.fi" \
                             -d "password=Hehec3po" \
                             -d 'grant_type=password' \
                             'https://auth.creodias.eu/auth/realms/DIAS/protocol/openid-connect/token' | \
                             python -m json.tool | grep "access_token" | awk -F\" '{print $4}')
# Sentinel3/search.json?maxRecords=10&instrument=SYNERGY&processingLevel=LEVEL2&productType=SY_2_V10___&timeliness=Short+Time+Critical&sortParam=startDate&sortOrder=descending&status=all&dataset=ESA-DATASET
query="https://finder.creodias.eu/resto/api/collections/Sentinel3/search.json?maxRecords=2000&startDate=${sdate}T00:00:00Z&completionDate=${edate}T23:59:59Z&timeliness=Short+Time+Critical&processingLevel=LEVEL2&productType=SY_2_V10___&geometry=POLYGON((-80+75,-80+-25,50+-25,50+75,-80+75))&sortParam=startDate&sortOrder=descending&status=all&dataset=ESA-DATASET"
echo $query
linkstxt=$(curl -s "$query" | jq -r '.features[].properties.services.download.url')
IFS=' ' readarray links <<< "$linkstxt"
get-unzip-rm() {
    wget -qcO "${1:36:36}.zip" "${1:0:72}?token=$token" && unzip -qu "${1:36:36}.zip" \
     && rm "${1:36:36}.zip"
}
export -f get-unzip-rm

parallel get-unzip-rm ::: "${links[@]}"
echo "$d SEN3 SYN combination:" `ls -d S3*_V10____${d}T*.SEN3`
cd ..
parallel cdo -s -O -f grb2 -b P12 ensmean -{1} sen3/S3A_SY_2_V10____${d}T*_{\2}_*.SEN3/'{=1 s:.*selname,:: =}'.nc\
 -{1} sen3/S3B_SY_2_V10____${d}T*_{\2}_*.SEN3/'{=1 s:.*selname,:: =}'.nc\
 sen3/S3SY_${d:0:4}0101T000000_${e}T000000_'{=1 s:.*selname,:: =}'_{\2}.grib :::: sen3/sen3codes.lst ::: EUROPE AFRICA NORTH_AMERICA NORTH_ASIA WEST_ASIA\
  && rm -rf S3?_SY_2_V10____*.SEN3

parallel grib_set -r -s centre=97,dataDate=$e sen3/S3SY_${d:0:4}0101T000000_${e}T000000_{\1}_{\2}.grib\
 grib/S3SY_${d:0:4}0101T000000_${e}T000000_97_{\1}_{\2}.grib ::: B0 B2 B3 MIR NDVI ::: EUROPE AFRICA NORTH_AMERICA NORTH_ASIA WEST_ASIA\
  && rm sen3/S3SY_${d:0:4}0101T000000_${e}T000000_[BMN]*.grib

#sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0