#!/usr/bin/env python3
import sys
import cdsapi

c = cdsapi.Client()
year= 2019 #sys.argv[1]
month= 12 #sys.argv[2]
day= 31 #sys.argv[3]

c.retrieve(
    'reanalysis-uerra-europe-soil-levels',
    {
        'origin': 'uerra_harmonie',
        'variable': ['soil_temperature','volumetric_soil_moisture'],
        'soil_level': [
            '1', '2', '3',
        ],
        'year': [
            '2000', '2001', '2002',
            '2003', '2004', '2005',
            '2006', '2007', '2008',
            '2009', '2010', '2011',
            '2012', '2013', '2014',
            '2015', '2016', '2017',
            '2018', '2019',
        ],
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
        'time': [
            '00:00', '06:00', '12:00',
            '18:00',
        ],
        'format': 'grib',
    },
    '/home/smartmet/data/grib/uerra_{:0>4}{:0>2}{:0>2}T0000_soil.grib'.format(year,month,day)
)
