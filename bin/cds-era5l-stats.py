#!/usr/bin/env python3                                                                                                                                                     
import sys
import cdsapi

c = cdsapi.Client()
years= sys.argv[1:]

c.retrieve(
    'reanalysis-era5-land-monthly-means',
    {
        'format': 'grib',
#nordic        'area' : '74/0/51/42',
        'area' : '75/-30/25/50',
        'product_type': 'monthly_averaged_reanalysis',
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
        'year': [
            '2010', '2011', '2012',
            '2013', '2014', '2015',
            '2016', '2017', '2018',
            '2019',
        ],
        'month': [
            '01', '02', '03',
            '04', '05', '06',
            '07', '08', '09',
            '10', '11', '12',
        ],
        'time': '00:00',
    },
    'era5l_2010-2019_stats.grib')
