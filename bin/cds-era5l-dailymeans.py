import sys
import cdsapi

year=sys.argv[1]
month=sys.argv[2]
day=sys.argv[3]

dataset = "derived-era5-land-daily-statistics"
request = {
    "variable": [
        "2m_dewpoint_temperature",
        "2m_temperature",
        "skin_temperature",
        "soil_temperature_level_1",
        "soil_temperature_level_2",
        "soil_temperature_level_3",
        "soil_temperature_level_4",
        "snow_albedo",
        "snow_cover",
        "snow_density",
        "snow_depth",
        "snow_depth_water_equivalent",
        "temperature_of_snow_layer",
        "volumetric_soil_water_layer_1",
        "volumetric_soil_water_layer_2",
        "volumetric_soil_water_layer_3",
        "volumetric_soil_water_layer_4",
        "10m_u_component_of_wind",
        "10m_v_component_of_wind",
        "leaf_area_index_high_vegetation",
        "leaf_area_index_low_vegetation"
    ],
    "year": year,
    "month": month,
    "day": [day],
    "daily_statistic": "daily_mean",
    "time_zone": "utc+00:00",
    "frequency": "1_hourly",
    "area": [75, -30, 25, 50]
}

client = cdsapi.Client()
output_filename = f'ERA5LD_{year}{month}{day}T000000_dailymeans.zip'
client.retrieve(dataset, request).download(output_filename)
