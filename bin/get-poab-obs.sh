#!/bin/bash
# Usage: ./get-poab-obs.sh <location> <date>
# location is one of: kas, kis, bos, ros, zas, k102
#
#'https://api.nxtport.com/opendata/meteo/v1'\
# -H 'Ocp-Apim-Subscription-Key: d18b0f88d0594b169b3cb47442198fe2'\

loc=$1
date=$2
edate=$(date -d "$date +1 hour" +"%Y-%m-%dT%H:00:00Z")
# Use POST to get the token and extract the access_token using jq
token_response=$(curl --location 'https://login.nxtport.com/connect/token' \
--header 'Content-Type: application/x-www-form-urlencoded' \
--data-urlencode 'username=anni.kroger@fmi.fi' \
--data-urlencode 'password=4qHDsqaYwCpgXhSvR2yNnAa7bwueb6g8' \
--data-urlencode 'grant_type=password' \
--data-urlencode 'client_id=E9197A6E-371E-4628-B7D7-A78B50BB48A0' \
--data-urlencode 'client_secret=y6D8idUdZMyqTc9SRFU72XgZWlZOfBXA' \
--data-urlencode 'scope=openid')
    # -H "Ocp-Apim-Subscription-Key: d18b0f88d0594b169b3cb47442198fe2")
    
#	-d '')
#echo $token_response
access_token=$(echo "$token_response" | jq -r .access_token)
#echo "$access_token"
query=$(curl -s -X GET "https://api.nxtport.com/opendata/meteo/v1/readings?location=$loc&from=${date}T00:00:00Z&to=${edate}T00:00:00Z" \
	-H "accept: application/json" \
	-H "Authorization: Bearer $access_token" \
	-H "Ocp-Apim-Subscription-Key: d18b0f88d0594b169b3cb47442198fe2")
echo "$query"