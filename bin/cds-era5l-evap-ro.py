import cdsapi
import sys

syear = sys.argv[1]
eyear = sys.argv[2]
mon = sys.argv[3]
abr = sys.argv[4]
area = sys.argv[5]
years=list(range(int(syear),int(eyear)+1))
print(years)

c = cdsapi.Client()

c.retrieve(
    'reanalysis-era5-land',
    {
        'variable': [
            'evaporation_from_bare_soil', 'evaporation_from_open_water_surfaces_excluding_oceans', 'evaporation_from_the_top_of_canopy',
            'evaporation_from_vegetation_transpiration', 'potential_evaporation', 'runoff',
            'snow_evaporation', 'sub_surface_runoff', 'surface_runoff',
            'total_evaporation',
        ],
        'year': years,
        'month': mon,
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
        'area': area,
        'format': 'grib',
    },
    '/home/smartmet/data/grib/ERA5L_20000101T000000_%s%s01T000000-evap-runoff-12h-%s.grib'%(eyear,mon,abr)
    )