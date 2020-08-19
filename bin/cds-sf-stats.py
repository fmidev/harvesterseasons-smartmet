#!/usr/bin/env python3
import sys
import cdsapi

c = cdsapi.Client()
years= sys.argv[1:]
year=sys.argv[1]+'-'+sys.argv[-1]
print(years, year)
c.retrieve(
    'seasonal-monthly-single-levels',
    {
        'format': 'grib',
        'originating_centre': 'ecmwf',
        'system': '5',
        'variable': [
#            '10m_u_component_of_wind', '10m_v_component_of_wind',
#            '10m_wind_gust_since_previous_post_processing',
            '10m_wind_speed',
            '2m_dewpoint_temperature', '2m_temperature',
            'evaporation', 'maximum_2m_temperature_in_the_last_24_hours', 'mean_sea_level_pressure',
            'minimum_2m_temperature_in_the_last_24_hours', 'runoff', 'sea_ice_cover',
            'sea_surface_temperature', 'snow_density', 'snow_depth','snowfall','soil_temperature_level_1',
            '39.128', '40.128', '41.128','42.128',
#            'soil_temperature_level_2','soil_temperature_level_3','soil_temperature_level_4',
            'surface_latent_heat_flux','surface_sensible_heat_flux', 'surface_solar_radiation', 'surface_solar_radiation_downwards',
            'surface_thermal_radiation', 'surface_thermal_radiation_downwards',
#            'top_solar_radiation','top_thermal_radiation',
            'total_cloud_cover', 'total_precipitation',
        ],
        'product_type': [
#            'ensemble_mean', 'hindcast_climate_mean', 'monthly_maximum','monthly_minimum',
            'monthly_mean', 
        ],
        'month': [
            '01', '02', '03',
            '04', '05', '06',
            '07', '08', '09',
            '10', '11', '12',
        ],
        'leadtime_month': [
            '1', '2', '3',
            '4', '5', '6',
        ],
        'area': [ 75, -30, 25, 50
        ],
        'year': years,
    },
    '/home/smartmet/data/ec-sf-'+year+'-stats-monthly-euro-fcmean.grib')
