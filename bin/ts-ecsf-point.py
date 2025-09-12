#!/usr/bin/env python3
import time, warnings,requests,json,sys,os
import numpy as np
import pandas as pd
import warnings
warnings.simplefilter(action='ignore', category=FutureWarning)
# SmarMet-server timeseries (ts) query to fetch ECSF data
# ts query for six point locations
# output is csv files
# also plots timeseries as png for one location
# EXAMPLE SCRIPT FOR CryoSCOPE
# usage: python ts-ecsf-point.py
# (AK 2025)

###
def ts_multipoints_query(source, start, end, h, pardict, latlons, origintime):
    ''' timeseries query to smartmet-server
    start date, end date, hour, list of lats&lons, parameters as dictionary (colname:smartmet-fmikey)
    returns dataframe
    '''

    # Timeseries query
    query='http://'+source+'/timeseries?latlon='
    for nro in latlons:
        query+=str(nro)+','
    query=query[0:-1]
    query+='&param=utctime,latitude,longitude,'
    for par in pardict.values():
        query+=par+','
    query=query[0:-1]
    query+='&starttime='+start+'&endtime='+end+'&hour='+h+'&format=json&precision=full&tz=utc&timeformat=sql&grouplocations=1&origintime='+origintime
    print(query)

    # Response to dataframe
    response=requests.get(url=query)
    results_json=json.loads(response.content)
    #print(results_json)
    for i in range(len(results_json)):
        res1=results_json[i]
        for key,val in res1.items():
            if key!='utctime':   
                res1[key]=val.strip('[]').split()
    df=pd.DataFrame(results_json)  
    df.columns = ['utctime', 'latitude', 'longitude'] + list(pardict.keys())  # Correct column headers
    df['utctime']=pd.to_datetime(df['utctime'])
    expl_cols=['latitude','longitude']+list(pardict.keys())
    df=df.explode(expl_cols)
    cols_to_fix = ['latitude', 'longitude'] 
    for col in cols_to_fix:
        df[col] = pd.to_numeric(df[col], errors='coerce').round(6)
    #print(df)
    return df

# 5 Indian cities as lat/lon pairs
latlons = [
    '28.6139', '77.2090',   # New Delhi
    '19.0760', '72.8777',   # Mumbai
    '13.0827', '80.2707',   # Chennai
    '22.5726', '88.3639',   # Kolkata
    '12.9716', '77.5946'    # Bengaluru
]

y_start,y_end='2000','2024'
origintime='20250801T000000Z' # generation

# lisää tänne ensemble memberit
parameters = [
    {'t2':'T2-K:ECSF:5081:1:0:1:0'}, # 2m temperature
]

source='sm.cryo-scope.eu' # server for timeseries query

start='20250815T000000Z'
end='20260304T000000Z'

# Timeseries query for multiple points
for pardict in parameters:
    hour='00'
    key,value=list(pardict.items())[0]
    df_fin=ts_multipoints_query(source,start,end,hour,pardict,latlons,origintime)
    print(df_fin)

    #df_fin.to_csv(filename, index=False)

# Plot timeseries (plots for latest df_fin)
import matplotlib.pyplot as plt

df=df_fin[df_fin['longitude']==77.2090] # New Delhi
df['utctime'] = pd.to_datetime(df['utctime'])
print(df)

# Plot
plt.figure(figsize=(12, 6))
plt.plot(df['utctime'], df['t2'], marker='o', linestyle='-')
plt.xlabel('Time')
plt.ylabel('T2 (K)')
plt.title('Time Series of T2')
plt.grid(True)
plt.tight_layout()
plt.savefig('timeseries_plot.png')