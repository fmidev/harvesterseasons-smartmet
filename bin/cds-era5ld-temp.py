import cdsapi
import sys

var='2m_temperature'
stat='daily_minimum'
year=sys.argv[1]
month=sys.argv[2]

dataset = "derived-era5-land-daily-statistics"
request = {
    "variable": [var],
    "year": year,
    "month": month,
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
    "daily_statistic": "daily_maximum",
    "time_zone": "utc+00:00",
    "frequency": "1_hourly",
    "area": [75, -30, 25, 50]
}

client = cdsapi.Client()
output = f'/home/ubuntu/data/grib/ERA5LD_20250101T000000_{year}{month}_{var}-{stat}.grib'
client.retrieve(dataset, request).download(output)