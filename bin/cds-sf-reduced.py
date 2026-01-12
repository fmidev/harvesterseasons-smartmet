import cdsapi
import sys

y1=sys.argv[1]
y2=sys.argv[2]
ylist=list(range(int(y1),int(y2)+1))
ylist_str = [str(y) for y in ylist]
print(ylist_str)

dataset = "seasonal-original-single-levels"
request = {
    "originating_centre": "ecmwf",
    "system": "51",
    "variable": [
        "10m_u_component_of_wind",
        "10m_v_component_of_wind",
        "10m_wind_gust_since_previous_post_processing",
        "2m_dewpoint_temperature",
        "2m_temperature",
        "eastward_turbulent_surface_stress",
        "evaporation",
        "land_sea_mask",
        "maximum_2m_temperature_in_the_last_24_hours",
        "mean_sea_level_pressure",
        "minimum_2m_temperature_in_the_last_24_hours",
        "northward_turbulent_surface_stress",
        "orography",
        "runoff",
        "sea_surface_temperature",
        "sea_ice_cover",
        "snow_density",
        "snow_depth",
        "snowfall",
        "soil_temperature_level_1",
        "sub_surface_runoff",
        "surface_latent_heat_flux",
        "surface_net_solar_radiation",
        "surface_net_thermal_radiation",
        "surface_runoff",
        "surface_sensible_heat_flux",
        "surface_solar_radiation_downwards",
        "surface_thermal_radiation_downwards",
        "toa_incident_solar_radiation",
        "top_net_solar_radiation",
        "top_net_thermal_radiation",
        "total_cloud_cover",
        "total_column_cloud_ice_water",
        "total_column_cloud_liquid_water",
        "total_column_water_vapour",
        "total_precipitation"
    ],
    "year": ylist_str,
    "month": [
        "01", "02", "03",
        "04", "05", "06",
        "07", "08", "09",
        "10", "11", "12"
    ],
    "day": ["01"],
    "leadtime_hour": [
        "0",
        "24",
        "48",
        "72"
    ],
    "data_format": "grib",
    "area": [83, -30, 25, 50]
}

client = cdsapi.Client()
output_file = f"ecsf-{y1}-{y2}-sfc-eu+.grib"
client.retrieve(dataset, request).download(output_file)