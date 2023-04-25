#!/usr/bin/env python
import sys
import cdsapi

year = sys.argv[1]
month = sys.argv[2]
area = sys.argv[3]
abr = sys.argv[4]

c = cdsapi.Client()

c.retrieve(
    'reanalysis-era5-single-levels',
    {
        'product_type': 'reanalysis',
        'format': 'grib',
        'variable': [
            'angle_of_sub_gridscale_orography', 'geopotential', 'land_sea_mask',
            'slope_of_sub_gridscale_orography', 'standard_deviation_of_orography',
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
        'time': '00:00',
        'area': area,
    },
    '/home/smartmet/data/era5-orography-%s%s-%s.grib'%(year,month,abr)
)