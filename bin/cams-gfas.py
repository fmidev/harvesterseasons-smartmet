#!/usr/bin/env python
import sys
if ( len(sys.argv) > 2):
    year= sys.argv[1]
    month= sys.argv[2]
    day= sys.argv[3]

from ecmwfapi import ECMWFDataServer
server = ECMWFDataServer()
server.retrieve({
    "class": "mc",
    "dataset": "cams_gfas",
    "date": "%s-%s-01/to/%s-%s-%s" % (year,month,year,month,day),
    "expver": "0001",
    "levtype": "sfc",
    "param": "92.210/97.210/99.210/100.210",
    "step": "0-24",
    "stream": "gfas",
    "target": "GFAS_%s%s01T0000_%s%s%sT000000_fire.grib" % (year,month,year,month,day),
    "time": "0000",
    "type": "ga",
})