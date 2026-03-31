#!/usr/bin/env python
import cdsapi
import sys
# CMIP6 monthly 1995-2014 (historical) Europe
# Usage: python3 cds-cmip6-sl-monthly.py model variable period experiment
# mod(el)=='hadgem3-gc31-mm','inm-cm4-8','inm-cm5-0','ipsl-cm6a-lr','mpi-esm1-2-lr','mri-esm2-0','ecearth3-hr','ec-earth3-vhr','ec-earth3-veg','ec-earth3-wam','ec-earth3'
# var(iable)=='daily_maximum_near_surface_air_temperature','daily_minimum_near_surface_air_temperature','near_surface_air_temperature',...

mod=sys.argv[1]
var=sys.argv[2]
# period='1995-2014','2015-2034','2035-2054','2055-2074','2075-2099'
periods=sys.argv[3]
# exp='historical','ssp1_2_6','ssp2_4_5','ssp3_7_0','ssp5_8_5'
exp=sys.argv[4]

target='/home/ubuntu/data/cmip6/arc/%s_%s_%s_CMIP6_%s_monthly_euro.zip'%(mod,var,periods,exp)
print(target)

c = cdsapi.Client()
dataset='projections-cmip6'
#'multi-origin-c3s-atlas'
# expand period 'YYYY-YYYY' into list of years
if '-' in periods:
    start, end = periods.split('-', 1)
    start = start.strip(); end = end.strip()
    try:
        period = [str(y) for y in range(int(start), int(end) + 1)]
    except ValueError:
        period = [periods]
else:
    period = [periods]

c.retrieve(
    dataset,{
        "temporal_resolution": "monthly",
        'model': mod,
        "experiment": exp,
#        "domain": "global",
#        "period": period,
#        "level": ["1000"],
        "month": [
         "01", "02", "03",
         "04", "05", "06",
         "07", "08", "09",
         "10", "11", "12"
        ],
        "year" : period,
        'variable': var,
        'area': [
            83, -33, 28,
            55,
        ],
    }).download(target)

