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

sf='VSW-M3M3:ECBSF:5022:9:1:0'#:ensnro
#sf='SWI2:ECXSF:5062:1:0:0'#:ensnro
name='ecbsf'
#name='ecxsf'

pardict={
    'ens0':''+sf+':0','ens1':''+sf+':1','ens2':''+sf+':2','ens3':''+sf+':3','ens4':''+sf+':4','ens5':''+sf+':5','ens6':''+sf+':6','ens7':''+sf+':7','ens8':''+sf+':8','ens9':''+sf+':9',
    'ens10':''+sf+':10','ens11':''+sf+':11','ens12':''+sf+':12','ens13':''+sf+':13','ens14':''+sf+':14','ens15':''+sf+':15','ens16':''+sf+':16','ens17':''+sf+':17','ens18':''+sf+':18','ens19':''+sf+':19',
    'ens20':''+sf+':20','ens21':''+sf+':21','ens22':''+sf+':22','ens23':''+sf+':23','ens24':''+sf+':24','ens25':''+sf+':25','ens26':''+sf+':26','ens27':''+sf+':27','ens28':''+sf+':28','ens29':''+sf+':29',
    'ens30':''+sf+':30','ens31':''+sf+':31','ens32':''+sf+':32','ens33':''+sf+':33','ens34':''+sf+':34','ens35':''+sf+':35','ens36':''+sf+':36','ens37':''+sf+':37','ens38':''+sf+':38','ens39':''+sf+':39',
    'ens40':''+sf+':40','ens41':''+sf+':41','ens42':''+sf+':42','ens43':''+sf+':43','ens44':''+sf+':44','ens45':''+sf+':45','ens46':''+sf+':46','ens47':''+sf+':47','ens48':''+sf+':48','ens49':''+sf+':49','ens50':''+sf+':50'
    }
#swi='SWI2:SWI:5059:1:0:0' # swi2 swi grid
swi='SWI2:SWIC:5022:1:0:0' # swi2clim
#swi='SWI2:SWI:5062:1:0:0' # swi2 era5l grid

source='desm.harvesterseasons.com:8080'

#filename = '404points-latlons.txt' 
#df = pd.read_csv(filename)
#points = df['POINT_ID']
#lats = df['TH_LAT']
#lons = df['TH_LONG']
#countries=df['NUTS0']
points=['1','2','3','4','5','6','7']
lats=[63.91,
      50.00,
      37.91,
      52.95,
      46.00,
      44.31,
      66.57]
lons=[25.72,
      9.48,
      -5.30,
      18.43,
      23.80,
      -0.15,
      21.14]
'''points=['1','2','3','4',
        '5','6','7',
        '8','9',
        '10','11',
        '12',
        '13','14']
lats=[63.91,60.96,64.07,61.56,
      51.69,50.00,48.12,
      40.41,37.91,
      52.95,54.46,
      46.00,
      44.31,66.57]
lons=[25.72,23.97,28.98,28.83,
      10.33,9.48,11.90,
      -1.85,-5.30,
      18.43,17.69,
      23.80,
      -0.15,21.14]'''
countries=['Finland',#'Finland','Finland','Finland',
           'Germany',#'Germany','Germany',
           'Spain',#'Spain',
           'Poland',#'Poland',
           'Romania',
           'France','Sweden']
for i in range(len(lats)):
    pointid=str(points[i])
    lat=str(lats[i])
    lon=str(lons[i])
    country=str(countries[i])
    
    print(pointid,lat,lon,country)

    start='20210402T000000Z'
    origintime='20210401T000000Z'
    query='http://'+source+'/timeseries?latlon='+lat+','+lon+'&param=utctime,'
    for par in pardict.values():
        query+=par+','
    query=query[0:-1]
    query+='&starttime='+start+'&timesteps=215&hour=00&format=json&precision=full&tz=utc&timeformat=sql&origintime='+origintime
    print(query)
    response=requests.get(url=query)
    df=pd.DataFrame(json.loads(response.content))
    df.columns=['utctime']+list(pardict.keys()) # change headers to params.keys
    df['utctime']=pd.to_datetime(df['utctime'])
    df=df.set_index('utctime') # vsw
    df=df.multiply(100) # vsw
    df=df.reset_index() # vsw

    start='20200402T000000Z' # swi2clim
    #start='20210402T000000Z' # swi2
    hour='00' #swi2clim
    #hour='12' #swi2
    query='http://'+source+'/timeseries?latlon='+lat+','+lon+'&param=utctime,'+swi+'&starttime='+start+'&timesteps=215&hour='+hour+'&format=json&precision=full&tz=utc&timeformat=sql'
    print(query)
    response=requests.get(url=query)
    df2=pd.DataFrame(json.loads(response.content))
    #df2.columns=['utctime','swi2']  
    df2.columns=['utctime','swi2clim'] 
    df2['utctime']=pd.to_datetime(df2['utctime']).dt.date 
    df2['utctime']=pd.to_datetime(df2['utctime'])
    df2=df2.set_index('utctime') # vsw
    df2=df2.subtract(15) # vsw
    df2=df2.reset_index() # vsw

    mons=12 
    df2['utctime'] = pd.DatetimeIndex( df2['utctime'] ) + pd.DateOffset(months = mons) # swi2clim

    print(df2.dropna())
    
    df3 = pd.merge(df,df2, on=['utctime'])
    
    df3=df3.set_index('utctime')
    df_apu=df3.dropna()
    print(df_apu)
    if df_apu.empty:
        print('empty df')
        continue
    else:
        colorsdict={
            'ens0':'blue','ens1':'blue','ens2':'blue','ens3':'blue','ens4':'blue','ens5':'blue','ens6':'blue','ens7':'blue','ens8':'blue','ens9':'blue','ens10':'blue',
            'ens11':'blue','ens12':'blue','ens13':'blue','ens14':'blue','ens15':'blue','ens16':'blue','ens17':'blue','ens18':'blue','ens19':'blue','ens20':'blue',
            'ens21':'blue','ens22':'blue','ens23':'blue','ens24':'blue','ens25':'blue','ens26':'blue','ens27':'blue','ens28':'blue','ens29':'blue','ens30':'blue',
            'ens31':'blue','ens32':'blue','ens33':'blue','ens34':'blue','ens35':'blue','ens36':'blue','ens37':'blue','ens38':'blue','ens39':'blue','ens40':'blue',
            'ens41':'blue','ens42':'blue','ens43':'blue','ens44':'blue','ens45':'blue','ens46':'blue','ens47':'blue','ens48':'blue','ens49':'blue',
            'ens50':'blue',
            'swi2clim':'red'
            #'swi2':'red'
        }

        #df3=df3.dropna()
        mytitle=country+', '+pointid+', '+lat+', '+lon
        plot = df3.plot(figsize=(15,10),color=colorsdict, title=mytitle)
        fig = plot.get_figure()
        plt.legend(bbox_to_anchor=(1.0, 1.0))
        fig.savefig('/home/ubuntu/data/mlbias/figures/swi2/swi2c_'+name+'-vsw2_'+pointid+'_'+country+'.png')
        #df.plot()

'''# plot latlons on map
nuts='/home/ubuntu/data/mlbias/NUTS_RG_20M_2021_4326.json'
df = pd.DataFrame(list(zip(lats, lons)),
               columns =['lat', 'lon'])
print(df)
#color_list = ['red','saddlebrown','darkgoldenrod','gold', 'blueblue', 'olive','darkoliveblue'] 
#cmap = mpl.cm.plasma
#cmap = mcolors.LinearSegmentedColormap.from_list("my_colormap", color_list)

countries = gpd.read_file(nuts)
df.plot(ax=countries.plot(),x="lon",y="lat",kind="scatter",color="red")#,s=0.1)
#rr_data.plot(ax=countries.plot(),x="lon", y="lat", kind="scatter", c="slope",colormap=cmap)
#rr_data.plot(ax=countries.plot(),x="lon", y="lat", kind="scatter",color='red')
plt.xlim(-12, 32)
plt.ylim(33, 72) 
#plt.savefig(res_dir+'63287points-on-map.png',dpi=200)
plt.savefig('/home/ubuntu/data/mlbias/figures/TS-points-on-map.png',dpi=800)
'''