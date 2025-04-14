#!/usr/bin/env python3
import time, warnings,requests,json
import pandas as pd
import warnings
warnings.simplefilter(action='ignore', category=FutureWarning)
# SmarMet-server timeseries query to fetch ERA5 training data for ML
# training data preprocessed to match seasonal forecast (sf) data for prediction
# remember to: conda activate xgb 

startTime=time.time()

def filter_points(df,lat,lon,nro,name):
    df0=df.copy()
    filter1 = df0['latitude'] == lat
    filter2 = df0['longitude'] == lon
    df0.where(filter1 & filter2, inplace=True)
    df0.columns=['lat-'+str(nro),'lon-'+str(nro),name+'-'+str(nro)] # change headers      
    df0=df0.dropna()
    return df0

data_dir='/home/ubuntu/data/ML/training-data/OCEANIDS/'+harbor+'/' 

# static predictors
'''statics = [
    #{'z': 'Z-M2S2:ERA5:5021:1:0:1:0'}, # geopotential in m2 s-2
    #{'lsm': 'LC-0TO1:ERA5:5021:1:0:1:0'}, # Land sea mask: 1=land, 0=sea
    #{'sdor': 'SDOR-M:ERA5:5021:1:0:1:0'}, # Standard deviation of orography
    #{'slor': 'SLOR:ERA5:5021:1:0:1:0'}, # Slope of sub-gridscale orography
    #{'anor': 'ANOR-RAD:ERA5:5021:1:0:1:0'}, # Angle of sub-gridscale orography
]
'''

# 00 UTC predictors
predictors_instant = [
    #{'u10':'U10-MS:ERA5:5021:1:0:1:0'}, # 10m u-component of wind (6h instantanous)
    #{'v10':'V10-MS:ERA5:5021:1:0:1:0'}, # 10m v-component of wind (6h instantanous)
    #{'td2':'TD2-K:ERA5:5021:1:0:1:0'}, # 2m dewpoint temperature (6h instantanous)
    #{'t2':'T2-K:ERA5:5021:1:0:1:0'}, # 2m temperature (6h instantanous)
    #{'lsm':'LC-0TO1:ERA5:5021:1:0:1:0'}, # land-sea mask (static)
    #{'msl':'PSEA-HPA:ERA5:5021:1:0:1:0'}, # mean sea level pressure (6h instantanous)
    #{'tsea':'TSEA-K:ERA5:5021:1:0:1'}, # sea surface temperature (6h instantanous)
    #{'tcc':'N-0TO1:ERA5:5021:1:0:1:0'}, # total cloud cover (6h instantanous)
    #{'tlwc':'TCLW-KGM2:ERA5:5021:1:0:1:0'}, # total column cloud liquid water (24h instantanous) 
    #{'kx': 'KX:ERA5:5021:1:0:0'}, # K index
    #{'t850': 'T-K:ERA5:5021:2:850:1:0'}, # temperature in K        
    #{'t700': 'T-K:ERA5:5021:2:700:1:0'},  
    #{'t500': 'T-K:ERA5:5021:2:500:1:0'},
    #{'q850': 'Q-KGKG:ERA5:5021:2:850:1:0'}, # specific humidity in kg/kg
    #{'q700': 'Q-KGKG:ERA5:5021:2:700:1:0'},
    #{'q500': 'Q-KGKG:ERA5:5021:2:500:1:0'},
    #{'u850': 'U-MS:ERA5:5021:2:850:1:0'}, # U comp of wind in m/s
    #{'u700': 'U-MS:ERA5:5021:2:700:1:0'},
    #{'u500': 'U-MS:ERA5:5021:2:500:1:0'},
    #{'v850': 'V-MS:ERA5:5021:2:850:1:0'}, # V comp of wind in m/s
    #{'v700': 'V-MS:ERA5:5021:2:700:1:0'},
    #{'v500': 'V-MS:ERA5:5021:2:500:1:0'},
    #{'z850': 'Z-M2S2:ERA5:5021:2:850:1:0'}, # geopotential in m2 s-2
    #{'z700': 'Z-M2S2:ERA5:5021:2:700:1:0'},
    #{'z500': 'Z-M2S2:ERA5:5021:2:500:1:0'},   
    #{'tcwv':'TOTCWV-KGM2:ERA5:5021:1:0:1:0'}, # total column water vapor here
    #{'swvl1':'SOILWET-M3M3:ERA5:5021:9:7:1:0'}, # volumetric soil water layer 1 (0-7cm) (24h instantanous)
    #{'swvl2':'SWVL2-M3M3:ERA5:5021:9:1820:1:0'}, # volumetric soil water layer 2 (7-28cm) (24h instantanous)
    #{'swvl3':'SWVL3-M3M3:ERA5:5021:9:7268:1:0'}, # volumetric soil water layer 3 (28-100cm) (24h instantanous)
    #{'swvl4':'SWVL4-M3M3:ERA5:5021:9:25855:1:0'} # volumetric soil water layer 4 (100-289cm) (24h instantanous)
 
]
# previous day 24h sums 
predictors_24hAgg = [
    #{'ewss':'sum_t(EWSS-NM2S:ERA5:5021:1:0:1:0/24h/0h)'}, # eastward turbulent surface stress (24h aggregation since beginning of forecast)
    #{'e':'sum_t(EVAP-M:ERA5:5021:1:0:1:0/24h/0h)'}, # evaporation (24h aggregation since beginning of forecast)
    #{'nsss':'sum_t(NSSS-NM2S:ERA5:5021:1:0:1:0/24h/0h)'}, # northward turbulent surface stress (24h aggregation since beginning of forecast)
    #{'slhf':'sum_t(FLLAT-JM2:ERA5:5021:1:0:1:0/24h/0h)'}, # surface latent heat flux (24h aggregation since beginning of forecast)
    #{'ssr':'sum_t(RNETSWA-JM2:ERA5:5021:1:0:1:0/24h/0h)'}, # surface net solar radiation (24h aggregation since beginning of forecast)
    #{'str':'sum_t(RNETLWA-JM2:ERA5:5021:1:0:1:0/24h/0h)'}, # surface net thermal radiation (24h aggregation since beginning of forecast)
    #{'sshf':'sum_t(FLSEN-JM2:ERA5:5021:1:0:1:0/24h/0h)'}, # surface sensible heat flux (24h aggregation since beginning of forecast)
    #{'ssrd':'sum_t(RADGLOA-JM2:ERA5:5021:1:0:1:0/24h/0h)'}, # surface solar radiation downwards (24h aggregation since beginning of forecast)
    #{'strd':'sum_t(RADLWA-JM2:ERA5:5021:1:0:1:0/24h/0h)'}, # surface thermal radiation downwards (24h aggregation since beginning of forecast)
    #{'tp':'sum_t(RR-M:ERA5:5021:1:0:1:0/24h/0h)'} # total precipitation (24h aggregation since beginning of forecast)
    #{'ttr':'sum_t(RTOPLWA-JM2:ERA5:5021:1:0:1:0/24h/0h)'}, # top net thermal radiation (24h aggregation since beginning of forecast)
]
# previous day maximum 
predictor_24hmax = [
    #{'fg10':'max_t(FFG-MS:ERA5:5021:1:0:1:0/24h/0h)'}, # 10m wind gust since previous post-processing (24h aggregation: max value of previous day)
    {'mx2t':'max_t(TMAX-K:ERA5:5021:1:0:1:0/24h/0h)'}, # Maximum temperature in the last 24h
    #{'mn2t':'min_t(TMIN-K:ERA5:5021:1:0:1:0/24h/0h)'} # Minimum temperature in the last 24h
]
source='desm.harvesterseasons.com:8080' # server for timeseries query
# get grid point lats lons (have to add parameter to query otherwise only one grid point is returned...)
query='http://'+source+'/timeseries?bbox='+bbox+'&param=utctime,latitude,longitude,U10-MS:ERA5:5021:1:0:1:0&starttime='+start+'&endtime='+start+'&hour=0&format=json&precision=full&tz=utc&timeformat=sql'
#print(query)
response=requests.get(url=query)
results_json=json.loads(response.content)
rs=results_json[0]
for key,val in rs.items():
    if key=='latitude':   
        lats=val.strip('[]').split()
    if key=='longitude':   
        lons=val.strip('[]').split()
lat1,lon1,lat2,lon2,lat3,lon3,lat4,lon4=lats[0],lons[0],lats[1],lons[1],lats[2],lons[2],lats[3],lons[3]
# Vuosaari latlons (manually chosen before)
#lat1,lon1,lat2,lon2,lat3,lon3,lat4,lon4='60.0000000000000000','25.0000000000000000','60.2500000000000000','25.2500000000000000','60.2500000000000000','25.0000000000000000','60.0000000000000000','25.2500000000000000'
#print(lat1,lon1,lat2,lon2,lat3,lon3,lat4,lon4)

# Timeseries query for predictors_instants at 00 UTC
for pred in predictors_instant:
    key,value=list(pred.items())[0]
    name=key
    print(key)
    query='http://'+source+'/timeseries?bbox='+bbox+'&param=utctime,latitude,longitude,'+value+'&starttime='+start+'&endtime='+end+'&hour=0&format=json&precision=full&tz=utc&timeformat=sql'
    print(query)
    response=requests.get(url=query)
    results_json=json.loads(response.content)
    print(results_json)
    for i in range(len(results_json)):
        res1=results_json[i]
        for key,val in res1.items():
            if key!='utctime':   
                res1[key]=val.strip('[]').split()
    df=pd.DataFrame(results_json)  
    df.columns=['utctime','latitude','longitude',name] # change headers      
    expl_cols=['latitude','longitude',name]
    df=df.explode(expl_cols)
    print(df)
    df.set_index('utctime',inplace=True)
    # filter points
    df1=filter_points(df,lat1,lon1,1,name)
    df2=filter_points(df,lat2,lon2,2,name)
    df3=filter_points(df,lat3,lon3,3,name)
    df4=filter_points(df,lat4,lon4,4,name)
    # merge dataframes
    df_new = pd.concat([df1,df2,df3,df4],axis=1,sort=False).reset_index()
    print(df_new)
    # save to csv file
    df_new.to_csv(data_dir+'era5-oceanids-'+name+'-'+start+'-'+end+'-check-'+harbor+'.csv',index=False) 
    df_new = df_new.drop(['utctime', 'lat-1','lon-1','lat-2','lon-2','lat-3','lon-3','lat-4','lon-4'], axis=1)
    df_new.to_csv(data_dir+'era5-oceanids-'+name+'-'+start+'-'+end+'-use-'+harbor+'.csv',index=False) 
    
    # save utctime, lat/lon info to csv file (run once with u10, then comment out)
    #df_new = df_new.drop(['u10-1', 'u10-2','u10-3','u10-4'], axis=1)
    #print(df_new)
    #df_new.to_csv(data_dir+'era5-oceanids-utctime-lat-lon-'+start+'-'+end+'-'+harbor+'.csv',index=False) 

# Timeseries query for predictors_24hAgg
for pred in predictors_24hAgg:
    key,value=list(pred.items())[0]
    name=key
    print(key)
    query='http://'+source+'/timeseries?bbox='+bbox+'&param=utctime,latitude,longitude,'+value+'&starttime='+start+'&endtime='+end+'&hour=0&format=json&precision=full&tz=utc&timeformat=sql'
    print(query)
    response=requests.get(url=query)
    results_json=json.loads(response.content)
    print(results_json)    
    for i in range(len(results_json)):
        res1=results_json[i]
        for key,val in res1.items():
            if key!='utctime':   
                res1[key]=val.strip('[]').split()
    df=pd.DataFrame(results_json)  
    df.columns=['utctime','latitude','longitude',name] # change headers      
    expl_cols=['latitude','longitude',name]
    df=df.explode(expl_cols)
    print(df)
    df['utctime']= pd.to_datetime(df['utctime'])
    df.set_index('utctime',inplace=True)
    # filter points
    df1=filter_points(df,lat1,lon1,1,name)
    df2=filter_points(df,lat2,lon2,2,name)
    df3=filter_points(df,lat3,lon3,3,name)
    df4=filter_points(df,lat4,lon4,4,name)
    # merge dataframes
    df_new = pd.concat([df1,df2,df3,df4],axis=1,sort=False).reset_index()
    print(df_new)
    # save to csv file
    df_new.to_csv(data_dir+'era5-oceanids-'+name+'-'+start+'-'+end+'-check-'+harbor+'.csv',index=False) 
    df_new = df_new.drop(['utctime', 'lat-1','lon-1','lat-2','lon-2','lat-3','lon-3','lat-4','lon-4'], axis=1)
    df_new.to_csv(data_dir+'era5-oceanids-'+name+'-'+start+'-'+end+'-use-'+harbor+'.csv',index=False)

# Timeseries query for predictor_24hmax
for pred in predictor_24hmax:
    key,value=list(pred.items())[0]
    name=key
    print(key)
    query='http://'+source+'/timeseries?bbox='+bbox+'&param=utctime,latitude,longitude,'+value+'&starttime='+start+'&endtime='+end+'&hour=0&format=json&precision=full&tz=utc&timeformat=sql'
    print(query)
    response=requests.get(url=query)
    results_json=json.loads(response.content)
    #print(results_json)    
    for i in range(len(results_json)):
        res1=results_json[i]
        for key,val in res1.items():
            if key!='utctime':   
                res1[key]=val.strip('[]').split()
    df=pd.DataFrame(results_json)  
    df.columns=['utctime','latitude','longitude',name] # change headers      
    expl_cols=['latitude','longitude',name]
    df=df.explode(expl_cols)
    print(df)
    df['utctime']= pd.to_datetime(df['utctime'])
    df.set_index('utctime',inplace=True)
    # filter points
    df1=filter_points(df,lat1,lon1,1,name)
    df2=filter_points(df,lat2,lon2,2,name)
    df3=filter_points(df,lat3,lon3,3,name)
    df4=filter_points(df,lat4,lon4,4,name)
    # merge dataframes
    df_new = pd.concat([df1,df2,df3,df4],axis=1,sort=False).reset_index()
    print(df_new)
    # save to csv file
    df_new.to_csv(data_dir+'era5-oceanids-'+name+'-'+start+'-'+end+'-check-'+harbor+'.csv',index=False) 
    df_new = df_new.drop(['utctime', 'lat-1','lon-1','lat-2','lon-2','lat-3','lon-3','lat-4','lon-4'], axis=1)
    df_new.to_csv(data_dir+'era5-oceanids-'+name+'-'+start+'-'+end+'-use-'+harbor+'.csv',index=False)

executionTime=(time.time()-startTime)
print('Execution time in minutes: %.2f'%(executionTime/60))