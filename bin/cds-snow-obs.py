#!/bin/env python3
import sys
import cdsapi

c = cdsapi.Client()
year=sys.argv[1]
mon=sys.argv[2]

c.retrieve(
    'insitu-observations-surface-land',
    {
        'format': 'zip',
        'time_aggregation': 'daily',
        'variable': [
            'fresh_snow', 'snow_depth', 'snow_water_equivalent',
        ],
        'usage_restrictions': [
            'restricted', 'unrestricted',
        ],
        'data_quality': [
            'failed', 'passed',
        ],
        'year': year,
        'area': [
            75, -30, 25,
            50,
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
        'month': mon,
    },
    '/home/ubuntu/data/eobs/synop-%s-%s.zip'%(year,mon))