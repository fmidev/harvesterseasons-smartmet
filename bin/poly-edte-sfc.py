#!/usr/bin/env python
from polytope.api import Client
import json
import io,sys

apirc=json.load(io.open('/home/ubuntu/.ecmwfapirc'))
date=sys.argv[1]
client = Client(address='polytope.apps.lumi.ewctest.link', 
                    user_email=apirc['email'], 
                    user_key=apirc['key'])

request = {
        "class": "rd",
        "expver": "i7yv",
        "stream": "oper",
        "date": date,
        "time": "0000",
        "type": "fc",
        "levtype": "sfc",
        "step": "0",
#        "area": "75/-30/25/50",
        "param": "8.128/9.128/32.128/33.128/34.128/39.128/40.128/41.128/42.128/44.128/45.128/58.128/129.128/139.128/141.128/144.128/146.128/147.128/151.128/164.128/165.128/166.128/167.128/168.128/169.128/170.128/175.128/176.128/177.128/178.128/179.128/182.128/183.128/189.128/205.128/228.128/235.128/236.128/238.128/243.128/251.228/260015/260121",
    }

# The data will be saved in the current working directory
files = client.retrieve('destination-earth', request,"edte_%s_sfc-eu.grib"%(date))