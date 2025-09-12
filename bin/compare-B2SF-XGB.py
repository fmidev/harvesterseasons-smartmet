import os, glob,requests,json,sys
import pandas as pd
import xarray as xr
from matplotlib import pyplot as plt
import time
from dataclasses import dataclass
import geopandas as gpd
import numpy as np
import matplotlib as mpl
from matplotlib.cm import ScalarMappable
from matplotlib.colors import Normalize
import matplotlib.colors as mcolors

sf_control='RR-M:ECSF:5014:1:0:1:0' #'T2-K:ECSF:5014:1:0:1:0'
sf='RR-M:ECSF:5014:1:0:3' #'T2-K:ECSF:5014:1:0:3'

b2sf_control='RR-M:ECB2SF:5021:1:0:1:0' #'T2-K:ECB2SF:5021:1:0:1:0'
b2sf='RR-M:ECB2SF:5021:1:0:3' # 'T2-K:ECB2SF:5021:1:0:3'

xsf_control='RR-M:ECXSF:5079:1:0:1:0'
xsf='RR-M:ECXSF:5079:1:0:3'

era5='RR-M:ERA5:5021:1:0:1:0'

target='tp'#'2t'

sf_ensdict={
    'ens0':''+sf_control+'','ens1':''+sf+':1','ens2':''+sf+':2','ens3':''+sf+':3','ens4':''+sf+':4','ens5':''+sf+':5','ens6':''+sf+':6','ens7':''+sf+':7','ens8':''+sf+':8','ens9':''+sf+':9',
    'ens10':''+sf+':10','ens11':''+sf+':11','ens12':''+sf+':12','ens13':''+sf+':13','ens14':''+sf+':14','ens15':''+sf+':15','ens16':''+sf+':16','ens17':''+sf+':17','ens18':''+sf+':18','ens19':''+sf+':19',
    'ens20':''+sf+':20','ens21':''+sf+':21','ens22':''+sf+':22','ens23':''+sf+':23','ens24':''+sf+':24','ens25':''+sf+':25','ens26':''+sf+':26','ens27':''+sf+':27','ens28':''+sf+':28','ens29':''+sf+':29',
    'ens30':''+sf+':30','ens31':''+sf+':31','ens32':''+sf+':32','ens33':''+sf+':33','ens34':''+sf+':34','ens35':''+sf+':35','ens36':''+sf+':36','ens37':''+sf+':37','ens38':''+sf+':38','ens39':''+sf+':39',
    'ens40':''+sf+':40','ens41':''+sf+':41','ens42':''+sf+':42','ens43':''+sf+':43','ens44':''+sf+':44','ens45':''+sf+':45','ens46':''+sf+':46','ens47':''+sf+':47','ens48':''+sf+':48','ens49':''+sf+':49','ens50':''+sf+':50'
    }

b2sf_ensdict={
    'ens0':''+b2sf_control+'','ens1':''+b2sf+':1','ens2':''+b2sf+':2','ens3':''+b2sf+':3','ens4':''+b2sf+':4','ens5':''+b2sf+':5','ens6':''+b2sf+':6','ens7':''+b2sf+':7','ens8':''+b2sf+':8','ens9':''+b2sf+':9',
    'ens10':''+b2sf+':10','ens11':''+b2sf+':11','ens12':''+b2sf+':12','ens13':''+b2sf+':13','ens14':''+b2sf+':14','ens15':''+b2sf+':15','ens16':''+b2sf+':16','ens17':''+b2sf+':17','ens18':''+b2sf+':18','ens19':''+b2sf+':19',
    'ens20':''+b2sf+':20','ens21':''+b2sf+':21','ens22':''+b2sf+':22','ens23':''+b2sf+':23','ens24':''+b2sf+':24','ens25':''+b2sf+':25','ens26':''+b2sf+':26','ens27':''+b2sf+':27','ens28':''+b2sf+':28','ens29':''+b2sf+':29',
    'ens30':''+b2sf+':30','ens31':''+b2sf+':31','ens32':''+b2sf+':32','ens33':''+b2sf+':33','ens34':''+b2sf+':34','ens35':''+b2sf+':35','ens36':''+b2sf+':36','ens37':''+b2sf+':37','ens38':''+b2sf+':38','ens39':''+b2sf+':39',
    'ens40':''+b2sf+':40','ens41':''+b2sf+':41','ens42':''+b2sf+':42','ens43':''+b2sf+':43','ens44':''+b2sf+':44','ens45':''+b2sf+':45','ens46':''+b2sf+':46','ens47':''+b2sf+':47','ens48':''+b2sf+':48','ens49':''+b2sf+':49','ens50':''+b2sf+':50'
    }

xsf_ensdict={
    'ens0':''+xsf_control+'','ens1':''+xsf+':1','ens2':''+xsf+':2','ens3':''+xsf+':3','ens4':''+xsf+':4','ens5':''+xsf+':5','ens6':''+xsf+':6','ens7':''+xsf+':7','ens8':''+xsf+':8','ens9':''+xsf+':9',
    'ens10':''+xsf+':10','ens11':''+xsf+':11','ens12':''+xsf+':12','ens13':''+xsf+':13','ens14':''+xsf+':14','ens15':''+xsf+':15','ens16':''+xsf+':16','ens17':''+xsf+':17','ens18':''+xsf+':18','ens19':''+xsf+':19',
    'ens20':''+xsf+':20','ens21':''+xsf+':21','ens22':''+xsf+':22','ens23':''+xsf+':23','ens24':''+xsf+':24','ens25':''+xsf+':25','ens26':''+xsf+':26','ens27':''+xsf+':27','ens28':''+xsf+':28','ens29':''+xsf+':29',
    'ens30':''+xsf+':30','ens31':''+xsf+':31','ens32':''+xsf+':32','ens33':''+xsf+':33','ens34':''+xsf+':34','ens35':''+xsf+':35','ens36':''+xsf+':36','ens37':''+xsf+':37','ens38':''+xsf+':38','ens39':''+xsf+':39',
    'ens40':''+xsf+':40','ens41':''+xsf+':41','ens42':''+xsf+':42','ens43':''+xsf+':43','ens44':''+xsf+':44','ens45':''+xsf+':45','ens46':''+xsf+':46','ens47':''+xsf+':47','ens48':''+xsf+':48','ens49':''+xsf+':49','ens50':''+xsf+':50'
    }

source='desm.harvesterseasons.com:8080'

city_coords = {
    "Rovaniemi": (66.5, 25.73),
    "Tampere": (61.5, 23.8),
    "Helsinki": (60.17, 24.94),
    "Oulu": (65.01, 25.47),
    "Joensuu": (62.60, 29.76),
    "Kuopio": (62.89, 27.68)
}
city=sys.argv[1] # city name
lat, lon = city_coords[city]
print("City:", city)
print("Latitude:", lat)
print("Longitude:", lon)

start='20250202T000000Z'
origintime='20250201T000000Z'

# ECSF
query=f'http://{source}/timeseries?latlon={str(lat)},{str(lon)}&param=utctime,'
for em in sf_ensdict.values():
    query+=em+','
query=query[0:-1]
query+=f'&starttime={start}&hour=0&timesteps=215&format=json&precision=full&tz=utc&timeformat=sql&origintime={origintime}'
print(query)
response=requests.get(url=query)
df_sf=pd.DataFrame(json.loads(response.content))
df_sf.columns=['utctime']+list(sf_ensdict.keys())
df_sf['utctime']=pd.to_datetime(df_sf['utctime'])
df_sf=df_sf.set_index('utctime')
print(df_sf)

# ECXSF 
query=f'http://{source}/timeseries?latlon={str(lat)},{str(lon)}&param=utctime,'
for em in xsf_ensdict.values():
    query+=em+','
query=query[0:-1]
query+=f'&starttime={start}&hour=0&timesteps=215&format=json&precision=full&tz=utc&timeformat=sql&origintime={origintime}'
print(query)
response=requests.get(url=query)
df_xsf=pd.DataFrame(json.loads(response.content))
df_xsf.columns=['utctime']+list(xsf_ensdict.keys())
df_xsf['utctime']=pd.to_datetime(df_xsf['utctime'])
df_xsf=df_xsf.set_index('utctime')
print(df_xsf)

# ECB2SF
query=f'http://{source}/timeseries?latlon={str(lat)},{str(lon)}&param=utctime,'
for em in b2sf_ensdict.values():
    query+=em+','
query=query[0:-1]
query+=f'&starttime={start}&hour=0&timesteps=215&format=json&precision=full&tz=utc&timeformat=sql&origintime={origintime}'
print(query)
response=requests.get(url=query)
df_b2sf=pd.DataFrame(json.loads(response.content))
df_b2sf.columns=['utctime']+list(b2sf_ensdict.keys())
df_b2sf['utctime']=pd.to_datetime(df_b2sf['utctime'])
df_b2sf=df_b2sf.set_index('utctime')
print(df_b2sf)

# ERA5
query=f'http://{source}/timeseries?latlon={str(lat)},{str(lon)}&param=utctime,{era5}&starttime={start}&hour=0&timesteps=215&format=json&precision=full&tz=utc&timeformat=sql&origintime=20000101T000000Z'
print(query)
response=requests.get(url=query)
df_era5=pd.DataFrame(json.loads(response.content))
df_era5['utctime']=pd.to_datetime(df_era5['utctime'])
df_era5=df_era5.set_index('utctime')
print(df_era5)
df_era5=  df_era5.cumsum()
print(df_era5)
# accumulate era5 daily


#plt.ylim(240, 300)

# plot sf vs era5
mytitle = f'sf vs era5 {city} 2m temperature'
ax = df_sf.plot(figsize=(15,10), title=mytitle, legend=False, color="blue", alpha=0.6)
df_era5.plot(ax=ax, linewidth=3, color="red", legend=False)  # ERA5 thick red line
plt.legend(list(df_sf.columns) + ["ERA5"], bbox_to_anchor   =(1.0, 1.0))
fig = ax.get_figure()
fig.savefig(f'//home/ubuntu/data/MLmodels/xgb-bias/ecsf-{target}-{city}.png')

# plot xsf vs era5
mytitle = f'xsf vs era5 {city} 2m temperature'
ax = df_xsf.plot(figsize=(15,10), title=mytitle, legend=False, color="blue", alpha=0.6)
df_era5.plot(ax=ax, linewidth=3, color="red", legend=False)  # ERA5 thick red line
plt.legend(list(df_xsf.columns) + ["ERA5"], bbox_to_anchor=(1.0, 1.0))
fig = ax.get_figure()
fig.savefig(f'//home/ubuntu/data/MLmodels/xgb-bias/ecxsf-{target}-{city}.png')

# plot b2sf vs era5
mytitle = f'b2sf vs era5 {city} 2m temperature'
ax = df_b2sf.plot(figsize=(15,10), title=mytitle, legend=False, color="blue", alpha=0.6)
df_era5.plot(ax=ax, linewidth=3, color="red", legend=False)  # ERA5 thick red line
plt.legend(list(df_b2sf.columns) + ["ERA5"], bbox_to_anchor=(1.0, 1.0))
fig = ax.get_figure()
fig.savefig(f'//home/ubuntu/data/MLmodels/xgb-bias/ecb2sf-{target}-{city}.png')

