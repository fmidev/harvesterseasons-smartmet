#!/usr/bin/env python3
import cdsapi
import sys

year=sys.argv[1]
var=sys.argv[2]
stat=sys.argv[3]

#print(f'year: {year}, var: {var}, stat: {stat}')

dataset = 'derived-era5-single-levels-daily-statistics'
request = {
    'product_type': 'reanalysis',
    'variable': [var],
    'year': year,
    'month': [
        '01', '02', '03',
        '04', '05', '06',
        '07', '08', '09',
        '10', '11', '12'
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
        '31'
    ],
    'daily_statistic': stat,
    'time_zone': 'utc+00:00',
    'frequency': '1_hourly',
    'area': [75, -30, 25, 50]
}

client = cdsapi.Client()
output_filename = '/home/ubuntu/data/ERA5D_'+year+'0101T000000_'+year+'1231T120000_'+var+'.nc'
client.retrieve(dataset, request).download(output_filename)
