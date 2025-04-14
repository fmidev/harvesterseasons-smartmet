import cdsapi
import sys

yr=sys.argv[1]


dataset = "reanalysis-era5-single-levels-monthly-means"
request = {
    "product_type": ["monthly_averaged_reanalysis"],
    "variable": [
        "2m_dewpoint_temperature",
        "2m_temperature",
        "mean_sea_level_pressure",
        "total_precipitation",
        "surface_latent_heat_flux",
        "surface_net_solar_radiation",
        "surface_net_thermal_radiation",
        "surface_sensible_heat_flux",
        "surface_solar_radiation_downwards",
        "surface_thermal_radiation_downwards",
        "top_net_solar_radiation",
        "top_net_thermal_radiation",
        "total_cloud_cover",
        "total_column_cloud_liquid_water",
        "evaporation",
        "eastward_turbulent_surface_stress",
        "northward_turbulent_surface_stress",
        "geopotential",
        "k_index",
        "total_column_water_vapour",
        "land_sea_mask"
    ],
    "year": [
                "1995", "1996", "1997",
        "1998", "1999", "2000",
        "2001", "2002", "2003",
        "2004", "2005", "2006",
        "2007", "2008", "2009",
        "2010", "2011", "2012",
        "2013", "2014", "2015",
        "2016", "2017", "2018",
        "2019", "2020", "2021",
        "2022", "2023", "2024"
    ],
    "month": [
        "01", "02", "03",
        "04", "05", "06",
        "07", "08", "09",
        "10", "11", "12"
    ],
    "time": ["00:00"],
    "data_format": "grib",
    "download_format": "unarchived",
    "area": [75, -30, 25, 50]
}

client = cdsapi.Client()
output_filename = "/home/ubuntu/data/era5/ERA5_19950101T000000_"+yr+"_sl-mon-eu.grib"
client.retrieve(dataset, request).download(output_filename)