#!/usr/bin/env python
from polytope.api import Client
import json
import io,sys

apirc=json.load(io.open('/home/ubuntu/.ecmwfapirc'))
date=sys.argv[1]
client = Client(address='polytope.apps.lumi.ewctest.link', 
                    user_email=apirc['email'], 
                    user_key=apirc['key'])
# Optionally revoke previous requests
client.revoke('all')
request = {
    'activity': 'ScenarioMIP',
    'class': 'd1',
    'dataset': 'climate-dt',
    'date': date,
    'experiment': 'SSP3-7.0',
    'expver': '0001',
    'generation': '1',
    'levtype': 'sfc',
    'model': 'IFS-NEMO',
    'param': '8/9/32/33/34/39/40/41/42/44/45/58/129/139/141/144/146/147/151/164/165/166/167/168/169/170/175/176/177/178/179/182/183/189/205/228/235/236/238/243/251/260015/260121',
    'realization': '1',
    'resolution': 'standard',
    'stream': 'clte',
    'type': 'fc'
}
fdate = date.replace('/to/','-')
print(fdate)
# The data will be saved in the current working directory
files = client.retrieve('destination-earth', request,"cdte_%s_sfc-eu.grib"%(fdate))