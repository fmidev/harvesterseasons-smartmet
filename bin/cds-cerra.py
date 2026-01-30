#!/usr/bin/env python3
import cdsapi

dataset = "reanalysis-cerra-single-levels"
request = {
    "variable": [
        "evaporation",
        "surface_latent_heat_flux",
        "surface_net_solar_radiation",
        "surface_net_thermal_radiation",
        "surface_sensible_heat_flux",
        "surface_solar_radiation_downwards",
        "surface_thermal_radiation_downwards",
        "total_precipitation"
    ],
    "level_type": "surface_or_atmosphere",
    "data_type": ["reanalysis"],
    "product_type": "forecast",
    "year": [
        "2015"
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
    "time": ["00:00"],
    "leadtime_hour": ["24"],
    "data_format": "grib"
}

client = cdsapi.Client()
output_file=f"/home/ubuntu/data/cerra/cerra-24hacc.grib"
client.retrieve(dataset, request).download(output_file)