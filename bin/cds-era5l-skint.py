import cdsapi
import sys

syear = sys.argv[1]
eyear = sys.argv[2]
mon = sys.argv[3]
abr = sys.argv[4]
area = sys.argv[5]
years=list(range(int(syear),int(eyear)+1))
print(years)

import cdsapi

c = cdsapi.Client()

c.retrieve(
    'reanalysis-era5-land',
    {
        'variable': 'skin_temperature',
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
            '01:00', '02:00', '03:00',
            '04:00', '05:00', '07:00',
            '08:00', '09:00', '10:00',
            '11:00', '13:00', '14:00',
            '15:00', '16:00', '17:00',
            '19:00', '20:00', '21:00',
            '22:00', '23:00',
        ],
        'area':area,
        'format': 'grib',
    },
    '/home/smartmet/data/grib/ERA5L_20000101T000000_%s%s01T000000-skintemp-hours-filled-%s.grib'%(eyear,mon,abr)
    )