#!/bin/bash
###################
# download Sentinel 3 Synergy data from CreoDIAS, combine and transform to grib for smartmet-server ingestion 
# Mikko Strahlendorff 20.4.2022
###################
eval "$(conda shell.bash hook)"
#conda activate xr
if [ $# -ne 0 ]
then
    d=$1
    timeliness=NT
    qe=$(date -d "$d 15 days" +%Y%m%d)
    e=$(date -d "$d 9 days" +%Y%m%d)
else
    d=$(date -d '9 days ago' +%Y%m%d)
    d=${d:0:-1}1
    timeliness=ST
    qe=$(date -d "$d 15 days" +%Y%m%d)
    e=$(date -d "$d 9 days" +%Y%m%d)
fi
if [ ${d:6:2} == "21" ] 
then 
    if [ ${d:4:2} != "02" ]
    then
        e=${e:0:6}`date -d "${e:4:2}/1 + 1 month - 1 day" +%d`
    else 
        e=${e:0:6}`date -d "3/1/${e:0:4} - 1 day" +%d`
    fi
fi
sdate="${d:0:4}-${d:4:2}-${d:6:2}"
qedate="${qe:0:4}-${qe:4:2}-${qe:6:2}"
cd /home/smartmet/data/sen3
# old CreoDIAS Finder Opensearch search
#query="https://finder.creodias.eu/resto/api/collections/Sentinel3/search.json?maxRecords=2000&startDate=${sdate}T00:00:00Z&completionDate=${edate}T23:59:59Z&timeliness=Short+Time+Critical&processingLevel=LEVEL2&productType=SY_2_V10___&geometry=POLYGON((-80+75,-80+-25,50+-25,50+75,-80+75))&sortParam=startDate&sortOrder=descending&status=all&dataset=ESA-DATASET"
# new dataspace ODATA search
#query='https://catalogue.dataspace.copernicus.eu/odata/v1/Products?$filter=contains(Name,%27SY_2_V10___%27)%20and%20ContentDate/Start%20gt%20'"$sdate"'T00:00:00.000Z%20and%20ContentDate/Start%20lt%20'"$edate"'T23:59:59.999Z&$count=True&$orderby=ContentDate/Start%20asc&$top=100'
# new OpenSearch
query="https://catalogue.dataspace.copernicus.eu/resto/api/collections/Sentinel3/search.json?startDate=$sdate&completionDate=$qedate&productType=SY_2_V10___&maxRecords=100"
# OData search with wget in separate body_data
#filter='$'"filter=contains(Name,%27SY_2_V10___%27)%20and%20ContentDate/Start%20ge%20${sdate}T00:00:00.000Z%20and%20ContentDate/Start%20lt%20${edate}T23:59:59.999Z"
#$orderby=ContentDate/Start%20desc
#$expand=Attributes
#$count=True
#$top=50
#$skip=0
# Odata query
#linkstxt=$(wget -dO - --body-data "$filter" --body-data '$orderby=ContentDate/Start%20desc' --body-data '$expand=Attributes' --body-data '$top=50' --body-data '$skip=0' --body-data '$count=True' --method GET  "https://catalogue.dataspace.copernicus.eu/odata/v1/Products" |jq '.value[].Id')
# OpenSearch query
linkstxt=$(wget -qO - "$query" | jq -r '.features[].id')

#features[].properties.services.download.url')
if [ -z "$linkstxt" ]
then
    echo "$query $linkstxt"
    exit 1
fi
links=$(echo $linkstxt| tr "\n" " ")
# old token call for CreoDIAS finder
#export token=$(curl -s -d 'client_id=CLOUDFERRO_PUBLIC' \
#                             -d "username=mikko.strahlendorff@fmi.fi" \
#                             -d "password=Hehec3po" \
#                             -d 'grant_type=password' \
#                             'https://auth.creodias.eu/auth/realms/DIAS/protocol/openid-connect/token' | \
#                             python -m json.tool | grep "access_token" | awk -F\" '{print $4}')
export token=$(curl -d 'client_id=cdse-public' -d 'username=mikko.strahlendorff@fmi.fi' -d 'password=Hehe-c3po2023' -d 'grant_type=password' 'https://identity.cloudferro.com/auth/realms/CDSE/protocol/openid-connect/token' | python -m json.tool | grep "access_token" | awk -F\" '{print $4}')
#refresh_token="eyJhbGciOiJIUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJhZmFlZTU2Zi1iNWZiLTRiMzMtODRlYS0zMWY2NzMyMzNhNzgifQ.eyJleHAiOjE2Nzc2ODExNzAsImlhdCI6MTY3NzY3OTM3MCwianRpIjoiNTIxN2VhMGYtODZlYy00ZDNkLWI0M2MtMzdjZTljZjUxZWZmIiwiaXNzIjoiaHR0cHM6Ly9pZGVudGl0eS5jbG91ZGZlcnJvLmNvbS9hdXRoL3JlYWxtcy9DRFNFIiwiYXVkIjoiaHR0cHM6Ly9pZGVudGl0eS5jbG91ZGZlcnJvLmNvbS9hdXRoL3JlYWxtcy9DRFNFIiwic3ViIjoiYTIxZTQ3YzctZmE1NS00NGRlLWJhMDItY2I3ZjZhNWIwYzkzIiwidHlwIjoiUmVmcmVzaCIsImF6cCI6ImNkc2UtcHVibGljIiwic2Vzc2lvbl9zdGF0ZSI6ImU5ZmZmNTc4LWMwNmQtNDQwMy04MTUxLWQyNjQyYTIyNjUxYSIsInNjb3BlIjoiQVVESUVOQ0VfUFVCTElDIGVtYWlsIHByb2ZpbGUgdXNlci1jb250ZXh0Iiwic2lkIjoiZTlmZmY1NzgtYzA2ZC00NDAzLTgxNTEtZDI2NDJhMjI2NTFhIn0.8PpzALbR6hjFOGVg9eZfkCEgdhc-Bq2OOhHzNv6rG3I"
#export token=$(curl --location --request POST 'https://identity.dataspace.copernicus.eu/auth/realms/CDSE/protocol/openid-connect/token' \
#  --header 'Content-Type: application/x-www-form-urlencoded' \
#  --data-urlencode 'grant_type=refresh_token' \
#  --data-urlencode "refresh_token=$refresh_token" \
#  --data-urlencode 'client_id=cdse-public')

get-unzip-rm() {
    i=${1}
    wget -qcO "$i.zip" --header "Authorization: Bearer $token" "http://catalogue.dataspace.copernicus.eu/odata/v1/Products($i)/"'$value' \
     && unzip -qu "$i.zip" && rm $i.zip
}
export -f get-unzip-rm
echo $links
parallel -j1 get-unzip-rm ::: `echo $links`

start=$(ls -d *${d}*EUROPE*SEN3 | cut -d"_" -f8| cut -d"T" -f1 | tr "\n" ","| cut -d"," -f1)
end=$(ls -d *${d}*EUROPE*SEN3 | cut -d"_" -f9| cut -d"T" -f1 | tr "\n" ","| cut -d"," -f1)
echo "Data is from $start to $end"
#"${links[@]}"
#echo "$d SEN3 SYN combination:" `ls -d S3*_V10____${d}T*.SEN3`
cd ..
# -{1} sen3/S3B_SY_2_V10____${d}T*_{\2}_*.SEN3/'{=1 s:.*selname,:: =}'.nc\
parallel cdo -s -O -f grb2 -b P8 ensmean -{1} sen3/S3?_SY_2_V10____${start}T*_{\2}_*${timeliness}_002.SEN3/'{=1 s:.*selname,:: =}'.nc\
 sen3/S3SY_${start:0:4}0101T000000_${end}T000000_'{=1 s:.*selname,:: =}'_{\2}.grib :::: sen3/sen3codes.lst ::: EUROPE AFRICA NORTH_AMERICA CENTRAL_AMERICA SOUTH_AMERICA NORTH_ASIA WEST_ASIA SOUTH_EAST_ASIA ASIAN_ISLANDS AUSTRALASIA\
  && rm -rf S3?_SY_2_V10____$start*.SEN3

parallel grib_set -r -s centre=97,jScansPositively=0,dataDate=$end sen3/S3SY_${start:0:4}0101T000000_${end}T000000_{\1}_{\2}.grib\
 grib/S3SY_20000101T000000_${end}T000000_97_{\1}_{\2}_$timeliness.grib ::: B0 B2 B3 MIR NDVI ::: EUROPE AFRICA NORTH_AMERICA CENTRAL_AMERICA SOUTH_AMERICA NORTH_ASIA WEST_ASIA SOUTH_EAST_ASIA ASIAN_ISLANDS AUSTRALASIA\
  && rm sen3/S3SY_${start:0:4}0101T000000_${end}T000000_[BMN]*.grib

#sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0