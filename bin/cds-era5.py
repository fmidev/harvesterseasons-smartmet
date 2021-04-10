#!/usr/bin/env python3
import sys
import cdsapi

c = cdsapi.Client()
year= sys.argv[1]
month= sys.argv[2]
day= sys.argv[3]

c.retrieve(
    'reanalysis-era5-single-levels',
    {
        'product_type':'reanalysis',
        'format':'grib',
	    'area' : '75/-30/25/50',
        'variable':[
            '10m_u_component_of_wind', '10m_v_component_of_wind', '2m_dewpoint_temperature',
            '2m_temperature', 'evaporation', 'high_vegetation_cover',
            'leaf_area_index_high_vegetation', 'leaf_area_index_low_vegetation', 'low_vegetation_cover',
            'mean_sea_level_pressure', 'potential_evaporation', 'runoff',
            'snow_density', 'snow_depth', 'snowfall',
            'soil_temperature_level_1', 'soil_temperature_level_2', 'soil_temperature_level_3',
            'soil_temperature_level_4', 'soil_type', 'sub_surface_runoff',
            'surface_runoff', 'total_column_snow_water', 'total_precipitation',
            'type_of_high_vegetation', 'type_of_low_vegetation', 'volumetric_soil_water_layer_1',
            'volumetric_soil_water_layer_2', 'volumetric_soil_water_layer_3', 'volumetric_soil_water_layer_4',
        ],
        'year':year,
        'month':month,
        'day':day,
        'time': [
                        '00:00', '01:00', '02:00',
                        '03:00', '04:00', '05:00',
                        '06:00', '07:00', '08:00',
                        '09:00', '10:00', '11:00',
                        '12:00', '13:00', '14:00',
                        '15:00', '16:00', '17:00',
                        '18:00', '19:00', '20:00',
                        '21:00', '22:00', '23:00',
        ]
    },
    '/home/smartmet/data/ERA5_{:0>4}{:0>2}{:0>2}T000000_base+soil.grib'.format(year,month,day))
