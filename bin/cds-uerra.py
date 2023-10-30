import cdsapi

c = cdsapi.Client()

c.retrieve(
#        'reanalysis-uerra-europe-soil-levels',
        'reanalysis-uerra-europe-single-levels',
        {
                    'format': 'grib',
                    'origin': 'uerra_harmonie',
                    'variable': [
#                        'soil_temperature','volumetric_soil_moisture','2m_temperature'
                        'snow_density','snow_depth_water_equivilant'
                        ],
#                    'soil_level': ['1', '2', '3',],
                    'year': list(range(2000,2019)),
                    'month': list(range(1,12)),
                    'day': list(range(1,31)),
                    'time': ['00:00', '12:00',],
                },
        '/home/smartmet/data/uerra-harmonie_2000-2019_snow.grib')
