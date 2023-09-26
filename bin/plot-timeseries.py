import os, glob,requests,json,sys
import pandas as pd
import xarray as xr
from matplotlib import pyplot as plt
import time

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
#swi='SWI2:SWI:5059:1:0:0' # swi2
swi='SWI2:SWIC:5022:1:0:0' # swi2clim

source='desm.harvesterseasons.com:8080'

filename = '404points-latlons.txt' 
df = pd.read_csv(filename)
print(df)
#to get first column data, use:
points = df['POINT_ID']
lats = df['TH_LAT']
lons = df['TH_LONG']
countries=df['NUTS0']
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
    hour='00' #swi2clim
    #hour='12' #swi2
    query='http://'+source+'/timeseries?latlon='+lat+','+lon+'&param=utctime,'+swi+'&starttime='+start+'&timesteps=215&hour='+hour+'&format=json&precision=full&tz=utc&timeformat=sql'
    print(query)
    response=requests.get(url=query)
    df2=pd.DataFrame(json.loads(response.content))
    #df2.columns=['utctime','swi2']  
    df2.columns=['utctime','swi2clim'] 
    df2['utctime']=pd.to_datetime(df2['utctime']).dt.date # swi2clim
    df2['utctime']=pd.to_datetime(df2['utctime']) # swi2clim
    #day1='2023-09-02'
    mons=12 #(int(day1[0:4])-2020)*12
    df2['utctime'] = pd.DatetimeIndex( df2['utctime'] ) + pd.DateOffset(months = mons) # swi2clim
    print(df2.dropna())

    df3 = pd.merge(df,df2, on=['utctime'])
    df_apu=df3.dropna()
    if df_apu.empty:
        print('empty df')
        continue
    else:
        df3=df3.set_index('utctime')

        colorsdict={
            'ens0':'pink','ens1':'blue','ens2':'yellow','ens3':'green','ens4':'purple','ens5':'pink','ens6':'blue','ens7':'yellow','ens8':'green','ens9':'purple','ens10':'pink',
            'ens11':'blue','ens12':'yellow','ens13':'green','ens14':'purple','ens15':'pink','ens16':'blue','ens17':'yellow','ens18':'green','ens19':'purple','ens20':'pink',
            'ens21':'blue','ens22':'yellow','ens23':'green','ens24':'purple','ens25':'pink','ens26':'blue','ens27':'yellow','ens28':'green','ens29':'purple','ens30':'pink',
            'ens31':'blue','ens32':'yellow','ens33':'green','ens34':'purple','ens35':'pink','ens36':'blue','ens37':'yellow','ens38':'green','ens39':'purple','ens40':'pink',
            'ens41':'blue','ens42':'yellow','ens43':'green','ens44':'purple','ens45':'pink','ens46':'blue','ens47':'yellow','ens48':'green','ens49':'purple','ens50':'pink',
            'swi2clim':'red'
            #'swi2':'red'
        }

        #df3=df3.dropna()
        mytitle=country+', '+pointid+', '+lat+', '+lon
        print(df3)    
        plot = df3.plot(figsize=(15,10),color=colorsdict, title=mytitle)
        fig = plot.get_figure()
        plt.legend(bbox_to_anchor=(1.0, 1.0))
        fig.savefig('/home/ubuntu/data/mlbias/figures/swi2clim/swi2clim_vs_'+name+'-swi2_'+pointid+'_'+country+'.png')
        #df.plot()
    