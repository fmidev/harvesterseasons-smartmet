import cdsapi,sys

year=sys.argv[1]
print(year)

c = cdsapi.Client()

c.retrieve(
    'reanalysis-era5-single-levels',
    {
        'product_type': 'reanalysis',
        'variable': [
            'evaporation', 'runoff', 'snowfall',
            'surface_latent_heat_flux', 'surface_net_solar_radiation', 'surface_sensible_heat_flux',
            'surface_solar_radiation_downwards', 'surface_thermal_radiation_downwards', 'top_net_solar_radiation',
            'top_net_thermal_radiation', 'total_precipitation',
        ],
        'year': year,
        'month':'01',
        'day': '01',
        'time':'00:00',
        'area': [
            75, -30, 25,
            50,
        ],
        'format': 'grib',
    },
    '/home/ubuntu/data/era5-%s-sl-1h-eu.grib'%(year))