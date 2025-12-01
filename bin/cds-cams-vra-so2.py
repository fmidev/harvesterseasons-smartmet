import cdsapi
import sys
# CAMS VRA SO2 2016-2022 Europe
mon=sys.argv[1]

dataset = "cams-europe-air-quality-reanalyses"
request = {
    "variable": ["sulphur_dioxide"],
    "model": ["ensemble"],
    "level": ["0"],
    "data_format": ["grib"],
    "area": [75, -25, 34, 45],
    "type": ["interim_reanalysis"],
    "year": ["2021"],
    "time": ["00:00", "06:00", "12:00", "18:00"],
    "month": [mon]
}

client = cdsapi.Client()-
client.retrieve(dataset, request, target='/home/smartmet/data/cams/CAMS_20000101T000000_2016-2022_so2-euro-%s.grib'%mon)
