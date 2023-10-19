import cdsapi,sys

year=sys.argv[1]
print(year)

c = cdsapi.Client()
c.retrieve(
    'reanalysis-era5-single-levels',
    {
        'product_type': 'reanalysis',
        'variable': [
            '10m_u_component_of_wind', '10m_v_component_of_wind', '10m_wind_gust_since_previous_post_processing',
            '2m_dewpoint_temperature', '2m_temperature', 'angle_of_sub_gridscale_orography',
            'geopotential', 'k_index',
            'land_sea_mask', 'maximum_2m_temperature_since_previous_post_processing', 'mean_sea_level_pressure',
            'minimum_2m_temperature_since_previous_post_processing', 'sea_surface_temperature',
            'skin_temperature', 'slope_of_sub_gridscale_orography', 'snow_density',
            'snow_depth', 'standard_deviation_of_orography',
            'total_cloud_cover'
        ],
        'year': year,
        'month': [
            '01', '02', '03',
            '04', '05', '06',
            '07', '08', '09',
            '10', '11', '12',
        ],
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
    '/home/ubuntu/data/grib/ERA5_20000101T000000_%s0101T000000_sl-12h-eu.grib'%(year))