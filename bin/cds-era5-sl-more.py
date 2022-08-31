#!/usr/bin/python3
import cdsapi
import sys

year= sys.argv[1]
month=sys.argv[2]
print('/home/smartmet/data/era5-%s%s-sl-12h-euro-add-params.grib'%(year,month))

c = cdsapi.Client()

c.retrieve(
    'reanalysis-era5-single-levels',
    {
        'product_type': 'reanalysis',
        'variable': [
            '100m_u_component_of_wind', '100m_v_component_of_wind', 'cloud_base_height',
            'high_cloud_cover', 'instantaneous_10m_wind_gust', 'low_cloud_cover',
            'mean_convective_precipitation_rate', 'mean_evaporation_rate', 'mean_large_scale_precipitation_rate',
            'mean_runoff_rate', 'mean_snowfall_rate', 'mean_sub_surface_runoff_rate',
            'mean_surface_latent_heat_flux', 'mean_surface_runoff_rate', 'mean_surface_sensible_heat_flux',
            'mean_total_precipitation_rate', 'medium_cloud_cover',
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
    '/home/smartmet/data/era5-%s%s-sl-12h-euro-add-params.grib'%(year,month))
