#!/bin/env python
import earthkit.data
import sys
sdate=20250606
date = -1 # yesterday
params = [ 8, 9, 33, 34, 39, 40, 41, 42, 43, 49, 129, 141, 144, 146, 147, 151, 169, 164, 165, 166, 167, 168, 170, 172, 175, 176, 177, 178, 179, 180, 181, 182, 183, 201, 202, 205, 228, 235, 236, 260121 ]

members = [ m for m in range(1, 51) ] # 50 members

steps = [step for step in range(0, 361, 12)] # forecast steps in hours

print (f"Requesting {len(params)} parameters, {len(members)} members, and {len(steps)} steps for date {date}")

print(f"steps : {steps}")
print(f"members : {members}")
print(f"params : {params}")

request = { 
"class" : "od", 
"stream" : "enfo", 
"type" : "pf", 
"domain" : "g", 
"levtype" : "sfc",
"date" : date,
"time" : 12,
"expver" : '0001',
"param" : params,
"number" : members,
"step" : steps,
"area" : '72/3/52/33', # North/West/South/East
"packing" : "simple",
"accuracy" : "10",
}

ds = earthkit.data.from_source("polytope", "ecmwf-mars", request, stream=False, address="polytope.ecmwf.int")

ds.to_target("file", "/home/smartmet/data/ECENS_${sdate}T000000_sfc-nd.grib")