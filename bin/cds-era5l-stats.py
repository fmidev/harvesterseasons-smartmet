#!/usr/bin/env python3                                                                                                                                                     
import sys
import cdsapi
# run source ~/.smart for $area $abr 

c = cdsapi.Client()
abr = sys.argv[1]
area = sys.argv[2]
mon = sys.argv[3]
years = sys.argv[4:]
year = sys.argv[4]+'-'+sys.argv[-1]
print(years, year, abr, area)
c.retrieve(
    'reanalysis-era5-land-monthly-means',
    {
        'format': 'grib',
#nordic        'area' : '74/0/51/42',
        'area' : area,
        'product_type': ['monthly_averaged_reanalysis','monthly_standard_deviation'],
        'variable': [
            'maximum_2m_temperature_in_the_last_24_hours','minimum_2m_temperature_in_the_last_24_hours',
            '2m_dewpoint_temperature', '2m_temperature',
            'evaporation_from_bare_soil','evaporation_from_open_water_surfaces_excluding_oceans',
            'evaporation_from_the_top_of_canopy', 'evaporation_from_vegetation_transpiration',
            'evaporation', 'potential_evaporation', 'runoff',
            'skin_reservoir_content', 'skin_temperature', 'snow_albedo',
            'snow_cover', 'snow_density', 'snow_depth',
            'snow_depth_water_equivalent', 'snow_evaporation', 'snowfall',
            'snowmelt', 'soil_temperature_level_1', 'soil_temperature_level_2',
            'soil_temperature_level_3', 'soil_temperature_level_4', 'sub_surface_runoff',
            'surface_runoff', 'temperature_of_snow_layer', 'volumetric_soil_water_layer_1',
            'volumetric_soil_water_layer_2', 'volumetric_soil_water_layer_3', 'volumetric_soil_water_layer_4',
            '10m_u_component_of_wind', '10m_v_component_of_wind', 'surface_pressure',
            'total_precipitation'
        ],
        'year': years,
        'month': mon,
        'time': '00:00',
    },
    '/mnt/data/era5l_%s_stats_%s.grib'%(year,mon))
