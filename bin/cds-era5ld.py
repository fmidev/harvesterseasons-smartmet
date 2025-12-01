import cdsapi,sys

year=str(sys.argv[1])
month=str(sys.argv[2])

dataset = "derived-era5-land-daily-statistics"
request = {
    "variable": ["2m_temperature"],
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
    "daily_statistic": "daily_minimum", # "daily_maximum"
    "time_zone": "utc+00:00",
    "frequency": "1_hourly",
    "area": [83, -30, 25, 50]
}

client = cdsapi.Client()
output_filename = f'/home/ubuntu/data/era5ld/ERA5LD_20000101T000000_{year}{month}_2m_temp_dmin.nc'
client.retrieve(dataset, request).download(output_filename)
