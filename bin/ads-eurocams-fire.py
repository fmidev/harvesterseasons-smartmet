#!/usr/bin/env python
import sys
import cdsapi
if ( len(sys.argv) > 2):
    year= sys.argv[1]
    month= sys.argv[2]
    day= sys.argv[3]

c = cdsapi.Client(url="https://ads.atmosphere.copernicus.eu/api/v2" , 
key="1990:211cb5c3-3923-4f49-a5cd-214a4c3bc2b0"
)

c.retrieve(
    'cams-europe-air-quality-forecasts',
    {
        'variable': 'pm10_wildfires',
        'model': 'ensemble',
        'level': '0',
        'date': '%s-%s-01/%s-%s-%s' % (year,month,year,month,day),
        'type': ['analysis','forecast'],
        'time': [ '00:00', '12:00', ],
        'leadtime_hour': ['0','12', '24','36', '48', '60','72', '84', '96'],
        'format': 'grib',
    },
    '/home/smartmet/data/grib/CAMSE_%s%s01T0000_%s%s%s_WFPM10_12h.grib' % (year,month,year,month,day))