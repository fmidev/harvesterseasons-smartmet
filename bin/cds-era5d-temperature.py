import cdsapi
import sys

year=sys.argv[1]
var="2m_temperature"
#var="skin_temperature"

print(var)

dataset = "derived-era5-single-levels-daily-statistics"
request = {
    "product_type": "reanalysis",
    "variable": [var],
    "year": year,
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
    "daily_statistic": "daily_mean",
    "time_zone": "utc+00:00",
    "frequency": "1_hourly",
    "area": [75, -30, 25, 50]
}

client = cdsapi.Client()
output_filename = f'/home/ubuntu/data/xgb-bias/era5-targets/ERA5D_{year}_{var}.grib'
client.retrieve(dataset, request).download(output_filename)