#!/usr/bin/env python3
import sys
import cdsapi

c = cdsapi.Client()
year= sys.argv[1]
month= sys.argv[2]
day= sys.argv[3]
abr = sys.argv[4]
area = sys.argv[5]

c.retrieve(
    'reanalysis-era5-land',
    {
        'variable': [
            '10m_u_component_of_wind', '10m_v_component_of_wind', '2m_dewpoint_temperature',
            '2m_temperature', 'evaporation_from_bare_soil', 'evaporation_from_open_water_surfaces_excluding_oceans',
            'evaporation_from_the_top_of_canopy', 'evaporation_from_vegetation_transpiration',
            'leaf_area_index_high_vegetation', 'leaf_area_index_low_vegetation', 
            'potential_evaporation','runoff', 'skin_reservoir_content', 'skin_temperature',
            'snow_albedo', 'snow_cover', 'snow_density',
            'snow_depth', 'snow_depth_water_equivalent', 'snow_evaporation',
            'snowfall', 'snowmelt', 'soil_temperature_level_1',
            'soil_temperature_level_2', 'soil_temperature_level_3', 'soil_temperature_level_4',
            'sub_surface_runoff', 'surface_pressure', 'surface_runoff',
            'temperature_of_snow_layer', 'total_precipitation', 'volumetric_soil_water_layer_1',
            'volumetric_soil_water_layer_2', 'volumetric_soil_water_layer_3', 'volumetric_soil_water_layer_4',
            'total_evaporation', 'surface_latent_heat_flux', 'surface_sensible_heat_flux',
            'surface_net_solar_radiation', 'surface_solar_radiation_downwards',
            'surface_thermal_radiation_downwards', 'surface_net_thermal_radiation'
        ],
        'year': year,
        'month': month,
        'day': day,
        'time': [
            '00:00','01:00', '02:00','03:00', '04:00', '05:00','06:00', '07:00', '08:00','09:00', '10:00', '11:00',
            '12:00','13:00', '14:00','15:00', '16:00', '17:00','18:00', '19:00', '20:00','21:00', '22:00', '23:00',
        ],
        'area' : area,
        'format': 'grib',
    },
    '/home/smartmet/data/ERA5L_{:0>2}{:0>2}{:0>2}T000000_sfc-1h.grib'.format(year,month,day))
