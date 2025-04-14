#!/usr/bin/env python
import cdsapi
import sys
# CMIP6 monthly 1995-2014 (historical) Europe

mod=sys.argv[1]
var=sys.argv[2]
period=sys.argv[3]
exp=sys.argv[4]

target='/home/ubuntu/data/cmip6/%s_%s_%s_CMIP6_monthly_euro.zip'%(mod,var,period)
print(target)

c = cdsapi.Client()
dataset='multi-origin-c3s-atlas'

c.retrieve(
    dataset,{
        'origin': mod,
        "experiment": exp,
        "domain": "global",
        "period": period,
        'variable': var,
        'area': [
            75, -30, 25,
            50,
        ],
    }).download(target)

