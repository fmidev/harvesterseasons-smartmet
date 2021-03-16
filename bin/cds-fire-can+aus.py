#!/usr/bin/env python3
import sys
import cdsapi

c = cdsapi.Client()
year= sys.argv[1]

c.retrieve(
    'cems-fire-historical',
    {
        'format': 'zip',
        'variable': [
            'build_up_index', 'danger_risk', 'drought_code',
            'duff_moisture_code', 'fine_fuel_moisture_code', 'fire_daily_severity_rating',
            'fire_danger_index', 'fire_weather_index', 'initial_fire_spread_index',
            'keetch_byram_drought_index',
        ],
        'version': '3.1',
        'dataset': 'Consolidated dataset',
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
        'product_type': 'reanalysis',
    },
    '/home/smartmet/data/fire/fwi_{:0>4}_can+aus.zip'.format(year)
)