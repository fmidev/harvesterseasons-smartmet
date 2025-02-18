#!/usr/bin/env python
import cdsapi
import sys
# CMIP6 monthly 1995-2014 (historical) Europe

mod=sys.argv[1]
var=sys.argv[2]

target='/home/smartmet/data/cmip6/%s_%s_2015-2100_CMIP6_daily_euro.zip'%(mod,var)
print(target)

dataset = "projections-cmip6"
request = {
    "temporal_resolution": "daily",
    "experiment": "historical",
#    "data_format": "grib",
    "variable": var,
    "model": mod,
#    "base_year": "2020",
    "year": [
        "2000",
        "2001", "2002", "2003",
        "2004", "2005", "2006",
        "2007", "2008", "2009",
        "2010", "2011", "2012",
        "2013", "2014"
    ],
    "month": [
        "01", "02", "03",
        "04", "05", "06",
        "07", "08", "09",
        "10", "11", "12"
    ],
    "day": [
        "01", "02", "03",
        "04", "05", "06",
        "07", "08", "09",
        "10", "11", "12",
        "13", "14", "15",
        "16", "17", "18",
        "19", "20", "21",
        "22", "23", "24",
        "25", "26", "27",
        "28", "29", "30",
        "31"
    ],
    "area": [75, -30, 25, 50]
}

client = cdsapi.Client()
client.retrieve(dataset, request,target)
