import cdsapi
c = cdsapi.Client()

c.retrieve(
    'derived-near-surface-meteorological-variables',
        {
	        'format': 'zip',
	    'variable': [
		'grid_point_altitude', 'near_surface_air_temperature', 'near_surface_specific_humidity',
		'near_surface_wind_speed', 'rainfall_flux', 'snowfall_flux',
		'surface_air_pressure', 'surface_downwelling_longwave_radiation', 'surface_downwelling_shortwave_radiation',
	    ],
	    'reference_dataset': 'cru',
	    'year': [
		'2015', '2016', '2017', '2018',
	    ],
	    'month': [
		'01', '02', '03','04', '05', '06','07', '08', '09','10', '11', '12',
	    ],
            'area' : '74/0/51/42',
	},
    'era5-watch2015-2018.zip')
