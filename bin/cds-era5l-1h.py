#!/usr/bin/env python3
import sys
import cdsapi

#c = cdsapi.Client()
year= sys.argv[1]
month= sys.argv[2]
day= sys.argv[3]
#abr = sys.argv[4]
#area = sys.argv[5]

dataset = "reanalysis-era5-land"
request = {
    "variable": [
        "snowfall",
        "surface_latent_heat_flux",
        "surface_net_solar_radiation",
        "surface_net_thermal_radiation",
        "surface_sensible_heat_flux",
        "surface_solar_radiation_downwards",
        "surface_thermal_radiation_downwards",
        "potential_evaporation",
        "runoff",
        "sub_surface_runoff",
        "surface_runoff",
        "total_evaporation",
        "total_precipitation"
    ],
    "year": year,
    "month": month,
    "day": [day],
    "time": [
        "00:00", "01:00", "02:00",
        "03:00", "04:00", "05:00",
        "06:00", "07:00", "08:00",
        "09:00", "10:00", "11:00",
        "12:00", "13:00", "14:00",
        "15:00", "16:00", "17:00",
        "18:00", "19:00", "20:00",
        "21:00", "22:00", "23:00"
    ],
    "data_format": "grib",
    "download_format": "unarchived",
    "area": [75, -30, 25, 50]
}

client = cdsapi.Client()
output_filename = f'ERA5L_{year}{month}{day}T000000_sfc-1h.grib'
client.retrieve(dataset, request).download(output_filename)
