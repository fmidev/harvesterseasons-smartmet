#!/usr/bin/python3
import cdsapi
import sys

year= sys.argv[1]
month=sys.argv[2]
print('/home/smartmet/data/era5-%s%s-sl-12h-euro.grib'%(year,month))

c = cdsapi.Client()

c.retrieve(
    'reanalysis-era5-single-levels',
    {
        'product_type': 'reanalysis',
        'variable': [
            '10m_u_component_of_wind', '10m_v_component_of_wind', '10m_wind_gust_since_previous_post_processing',
            '2m_dewpoint_temperature', '2m_temperature', 'convective_available_potential_energy',
            'convective_inhibition', 'convective_precipitation', 'eastward_turbulent_surface_stress',
            'evaporation', 'k_index', 'maximum_2m_temperature_since_previous_post_processing',
            'mean_sea_level_pressure', 'minimum_2m_temperature_since_previous_post_processing', 'northward_gravity_wave_surface_stress',
            'potential_evaporation', 'precipitation_type', 'runoff',
            'sea_surface_temperature', 'skin_temperature', 'snow_density',
            'snow_depth', 'snowfall', 'soil_temperature_level_1',
            'soil_temperature_level_2', 'soil_temperature_level_3', 'soil_temperature_level_4',
            'sub_surface_runoff', 'surface_latent_heat_flux', 'surface_net_solar_radiation_clear_sky',
            'surface_net_thermal_radiation_clear_sky', 'surface_runoff', 'surface_sensible_heat_flux',
            'surface_solar_radiation_downwards', 'surface_thermal_radiation_downwards', 'top_net_solar_radiation',
            'top_net_thermal_radiation', 'total_cloud_cover', 'total_precipitation',
            'volumetric_soil_water_layer_1', 'volumetric_soil_water_layer_2', 'volumetric_soil_water_layer_3',
            'volumetric_soil_water_layer_4',
        ],
        'year': year,
        'month': month,
        'day': [
            '01', '02', '03',
            '04', '05', '06',
            '07', '08', '09',
            '10', '11', '12',
            '13', '14', '15',
            '16', '17', '18',
            '19', '20', '21',
            '22', '23', '24',
            '25', '26', '27',
            '28', '29', '30',
            '31',
        ],
        'time': [
            '00:00', '12:00',
        ],
        'area': [
            75, -30, 25,
            50,
        ],
        'format': 'grib',
    },
    '/home/smartmet/data/era5-%s%s-sl-12h-euro.grib'%(year,month))
