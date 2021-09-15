#!/bin/python
#%%
import sys
import cdsapi

c = cdsapi.Client()
period=sys.argv[1]
product=sys.argv[2]
cperiod=period.replace('-','_')
c.retrieve(
    'insitu-gridded-observations-europe',
    {
        'product_type': 'ensemble_' + product,
        'variable': [
            'maximum_temperature', 'mean_temperature', 'minimum_temperature',
            'precipitation_amount', 'sea_level_pressure',
        ],
        'grid_resolution': '0.1deg',
        'period': cperiod,
        'version': '22.0e',
        'format': 'zip',
    },
    '/mnt/data/eobs/eobs_%s_all_%s_22.0e.zip'%(period,product))
