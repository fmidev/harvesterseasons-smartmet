import cdsapi,sys

year=str(sys.argv[1])
month=str(sys.argv[2])

dataset = "reanalysis-era5-land"
request = {
    "variable": [
        "snow_density",
        "snow_depth",
        "snow_depth_water_equivalent",
        "snowfall"
    ],
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
    "time": [
        "00:00", "06:00", "12:00",
        "18:00"
    ],
    "data_format": "grib",
    "download_format": "unarchived",
    "area": [83, -30, 25, 50]
}


client = cdsapi.Client()
output_filename = f'/home/ubuntu/data/grib/ERA5L_20000101T000000_{year}{month}_snow.grib'
client.retrieve(dataset, request).download(output_filename)