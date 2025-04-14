import cdsapi

dataset = "insitu-gridded-observations-europe"
request = {
    "product_type": "ensemble_mean",
    "variable": [
        "mean_temperature",
        "minimum_temperature",
        "maximum_temperature",
        "precipitation_amount",
        "sea_level_pressure",
        "surface_shortwave_downwelling_radiation",
        "relative_humidity",
        "wind_speed"
    ],
    "grid_resolution": "0_1deg",
    "period": "1995_2010", # 2011_2024
    "version": ["30_0e"]
}

client = cdsapi.Client()
target="eobs_1995_2010_all_30.0e.zip"
client.retrieve(dataset, request).download(target)
