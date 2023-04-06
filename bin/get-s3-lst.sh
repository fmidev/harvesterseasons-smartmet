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
    e=$(date -d "$d 3 days" +%Y%m%d)
else
    d=$(date -d 'yesterday' +%Y%m%d)
    timeliness=NR
    e=$(date +%Y%m%d)
fi

sdate="${d:0:4}-${d:4:2}-${d:6:2}"
edate="${e:0:4}-${e:4:2}-${e:6:2}"
cd /home/smartmet/data/sen3
# OpenSearch
query="https://catalogue.dataspace.copernicus.eu/resto/api/collections/Sentinel3/search.json?startDate=$sdate&completionDate=$edate&productType=SL_2_LST___&box=-30,25,50,75&timeliness=$timeliness&maxRecords=200&sortParam=startDate"
# OpenSearch query
linkstxt=$(wget -qO - "$query" | jq -r '.features[].id')

#features[].properties.services.download.url')
if [ $linkstxt -eq '' ]
then
    echo "$query $linkstxt"
    exit 1
fi
links=$(echo $linkstxt| tr "\n" " ")
export token=$(curl -d 'client_id=cdse-public' -d 'username=mikko.strahlendorff@fmi.fi' -d 'password=Hehe-c3po2023' -d 'grant_type=password' 'https://identity.cloudferro.com/auth/realms/CDSE/protocol/openid-connect/token' | python -m json.tool | grep "access_token" | awk -F\" '{print $4}')

get-unzip-rm() {
    i=${1}
    wget -qcO "$i.zip" --header "Authorization: Bearer $token" "http://catalogue.dataspace.copernicus.eu/odata/v1/Products($i)/"'$value' \
     && unzip -qu "$i.zip" && rm $i.zip
}
export -f get-unzip-rm
echo $links
parallel -j1 get-unzip-rm ::: `echo $links`

start=$(ls -d *LST____${d}T*SEN3 | cut -d"_" -f8| cut -d"T" -f1 | tr "\n" ","| cut -d"," -f1)
orbits=$(ls -d S3*/ | cut -d"_" -f13 | awk '!seen[$0]++' | tr "\n" " ")
echo "Data is from $start with times $orbits"
#"${links[@]}"
#echo "$d SEN3 SYN combination:" `ls -d S3*_V10____${d}T*.SEN3`
cd ..
# -{1} sen3/S3B_SY_2_V10____${d}T*_{\2}_*.SEN3/'{=1 s:.*selname,:: =}'.nc\
#parallel cdo -s -O -f grb2 -b P8 ensmean -{1} sen3/S3?_SY_2_V10____${start}T*_{\2}_*${timeliness}_002.SEN3/'{=1 s:.*selname,:: =}'.nc\
# sen3/S3SY_${start:0:4}0101T000000_${end}T000000_'{=1 s:.*selname,:: =}'_{\2}.grib :::: sen3/sen3codes.lst ::: EUROPE AFRICA NORTH_AMERICA CENTRAL_AMERICA SOUTH_AMERICA NORTH_ASIA WEST_ASIA SOUTH_EAST_ASIA ASIAN_ISLANDS AUSTRALASIA\
#  && rm -rf S3?_SY_2_V10____$start*.SEN3

#parallel grib_set -r -s centre=97,jScansPositively=0,dataDate=$end sen3/S3SY_${start:0:4}0101T000000_${end}T000000_{\1}_{\2}.grib\
# grib/S3SY_${start:0:4}0101T000000_${end}T000000_97_{\1}_{\2}_$timeliness.grib ::: B0 B2 B3 MIR NDVI ::: EUROPE AFRICA NORTH_AMERICA CENTRAL_AMERICA SOUTH_AMERICA NORTH_ASIA WEST_ASIA SOUTH_EAST_ASIA ASIAN_ISLANDS AUSTRALASIA\
#  && rm sen3/S3SY_${start:0:4}0101T000000_${end}T000000_[BMN]*.grib

#sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0