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
            'skin_reservoir_content', 'volumetric_soil_water_layer_1', 'volumetric_soil_water_layer_2',
            'volumetric_soil_water_layer_3', 'volumetric_soil_water_layer_4',
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
    '/home/smartmet/data/grib/ERA5L_20000101T000000_%s%s01T000000-soilwater-12h-%s.grib'%(eyear,mon,abr)
    )