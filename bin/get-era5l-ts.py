#!/usr/bin/env python3
import requests, os, time, glob, json,sys
import pandas as pd
import functions as fcts
import numpy as np
### SmarMet-server timeseries query to fetch ERA5-Land training data for machine learning
# annin notes: sademäärää vko etc taaksepäin? tp-1 tp-2 tp-3...tp-7 tai weeksum? Mitkä muuttujat?
startTime=time.time()

data_dir='/home/ubuntu/data/'
era5l_dir=data_dir+'ml-training-data/era5l' # era5l training data
lucas=data_dir+'LUCAS_2018_Copernicus_attr+additions.csv' # LUCAS data
#os.chdir(data_dir)
#print(os.getcwd())

# ERA5-Land predictors
paramsPL = {
    'fal-0to1':'ALBEDOSLR-0TO1:ERA5L:5022:1:0:1:0', # Forecast albedo (0-1)
    'asn-0to1':'ASN-0TO1:ERA5L:5022:1:0:1:0', # Snow albedo (0-1)
    'es-m':'ES-M:ERA5L:5022:1:0:1:0', # Snow evaporation (m of water eq.)
    'evabs-m':'EVABS-M:ERA5L:5022:1:0:0', # Evaporation from bare soil (m of water eq.)
    'evaow-m':'EVAOW-M:ERA5L:5022:1:0:0', # Evaporation from open water surfaces excluding oceans (m of water eq.)
    'evap-m':'EVAP-M:ERA5L:5022:1:0:1:0', # Evaporation (m of water eq.)
    'evapp-m':'EVAPP-M:ERA5L:5022:1:0:1:0', # Potential evaporation (m)
    'evatc-m':'EVATC-M:ERA5L:5022:1:0:0', # Evaporation from the top of canopy (m of water eq.)
    'evavt-m':'EVAVT-M:ERA5L:5022:1:0:0', # Evaporation from vegetation transpiration (m of water eq)
    'slhf-Jm2':'FLLAT-JM2:ERA5L:5022:1:0:1:0', # Surface latent heat flux (J m-2)
    'sshf-Jm2':'FLSEN-JM2:ERA5L:5022:1:0:1:0', # Surface sensible heat flux (J m-2)
    'laihv-m2m2':'LAI_HV-M2M2:ERA5L:5022:1:0:1:0', # Leaf area index, high vegetation (m2 m-2)
    'lailv-m2m2':'LAI_LV-M2M2:ERA5L:5022:1:0:1:0', # Leaf area index, low vegetation (m2 m-2)
    'lshf':'LSHF:ERA5L:5022:1:0:1:0', # Lake shape factor (dimensionless)
    'sp-Pa':'PGR-PA:ERA5L:5022:1:0:1:0', # Surface pressure/ Pressure on ground (Pa)
    'ssrd-Jm2':'RADGLOA-JM2:ERA5L:5022:1:0:1:0', # Surface shortwave radiation downwards (J m-2)
    'strd-Jm2':'RADLWA-JM2:ERA5L:5022:1:0:1:0', # Surface longwave radiation downwards (J m-2)
    '':'RNETLWA-JM2:ERA5L:5022:1:0:1:0', #
    '':'RNETSWA-JM2:ERA5L:5022:1:0:1:0', #
    '':'RO-M:ERA5L:5022:1:0:1:0', #
    '':'RR-M:ERA5L:5022:1:0:1:0', #
    '':'', #

    '''
    't850-K-00': 'T-K:ERA5:5021:2:850:1:0', # temperature in K        
    't700-K-00': 'T-K:ERA5:5021:2:700:1:0',  
    't500-K-00': 'T-K:ERA5:5021:2:500:1:0',
    'q850-kgkg-00': 'Q-KGKG:ERA5:5021:2:850:1:0', # specific humidity in kg/kg
    'q700-kgkg-00': 'Q-KGKG:ERA5:5021:2:700:1:0',
    'q500-kgkg-00': 'Q-KGKG:ERA5:5021:2:500:1:0',
    'u850-ms-00': 'U-MS:ERA5:5021:2:850:1:0', # U comp of wind in m/s
    'u700-ms-00': 'U-MS:ERA5:5021:2:700:1:0',
    'u500-ms-00': 'U-MS:ERA5:5021:2:500:1:0',
    'v850-ms-00': 'V-MS:ERA5:5021:2:850:1:0', # V comp of wind in m/s
    'v700-ms-00': 'V-MS:ERA5:5021:2:700:1:0',
    'v500-ms-00': 'V-MS:ERA5:5021:2:500:1:0',
    'z850-m-00': 'Z-M:ERA5:5021:2:850:1:0', # geopotential in m
    'z700-m-00': 'Z-M:ERA5:5021:2:700:1:0',
    'z500-m-00': 'Z-M:ERA5:5021:2:500:1:0',            
    'kx-00': 'KX:ERA5:5021:1:0:0', # K index
'''
}


y_start='1995'
y_end='2020'
rr_yrs=list(range(int(y_start),int(y_end)+1))
nan=float('nan')

# make a dictionary of {staid: [lat,lon,elev]} 
dict_all=fcts.read_eobs_staids_latlons_elevs() # key: staid, values: [lat,lon.elev]
keys = [s.lstrip("0") for s in staids]
staDict = {x:dict_all[x] for x in keys}
# list of latlons for ts query
latlonlst=[]
for staid in staids: 
    lat,lon=staDict[str(int(staid))][0],staDict[str(int(staid))][1]
    if 25 > float(lat) or float(lat) > 75 or -30 > float(lon) or float(lon) > 50: # skip non-EU
        print(staid+': not in EU, skip...')
    else:
        latlonlst.append(lat)
        latlonlst.append(lon)
#print(latlonlst)

### ERA5 pl for 00 and 12UTC ###
# note: kx is in 3 generations even though rest is in 2
tstep='720' # 12h
# 0: generation 19900101T000000_19991231T000000
start='19950101T000000Z'
end='19991231T120000Z'
era5pl0=fcts.smartmet_ts_query_multiplePoints(start,end,tstep,latlonlst,paramsPL,staids)
# 1: generation 20000101T000000_20091231T12000000
start='20000101T000000Z'
end='20091231T120000Z'
era5pl1=fcts.smartmet_ts_query_multiplePoints(start,end,tstep,latlonlst,paramsPL,staids)
# 2: generation 20100101T000000_20191231T120000
start='20100101T000000Z'
end='20191231T120000Z'
era5pl2=fcts.smartmet_ts_query_multiplePoints(start,end,tstep,latlonlst,paramsPL,staids)
# 3: generation 20200101T000000_20220320T120000
start='20200101T000000Z'
end='20201231T120000Z'
era5pl3=fcts.smartmet_ts_query_multiplePoints(start,end,tstep,latlonlst,paramsPL,staids)
# join generations
era5pl=pd.concat([era5pl0,era5pl1,era5pl2,era5pl3],ignore_index=True)
# group together same staids and keep dates in order
era5pl=era5pl.sort_values(by=['staid','utctime'],ignore_index=True) 
# 00utc and 12utc values to different columns
names={'t850-K-00':'t850-K-12','t700-K-00':'t700-K-12','t500-K-00':'t500-K-12',
    'q850-kgkg-00':'q850-kgkg-12','q700-kgkg-00':'q700-kgkg-12','q500-kgkg-00':'q500-kgkg-12',
    'u850-ms-00':'u850-ms-12','u700-ms-00':'u700-ms-12','u500-ms-00':'u500-ms-12',
    'v850-ms-00':'v850-ms-12','v700-ms-00':'v700-ms-12','v500-ms-00':'v500-ms-12',
    'z850-m-00':'z850-m-12','z700-m-00':'z700-m-12','z500-m-00':'z500-m-12',
    'kx-00':'kx-12'}
# filter out 12:00:00 from utctime and copy to df 
df=era5pl[['utctime','latitude','longitude','staid']].copy()
df= df[~df.utctime.str.contains("12:00:00")]
df = df.reset_index(drop=True)
# split 00UTC and 12UTC times to different columns and join to df
era5pl_tmp=era5pl.drop(columns=['staid','longitude','latitude'])
for old,new in names.items():
    dfnew = pd.DataFrame({old:era5pl_tmp[old].iloc[::2].values, new:era5pl_tmp[old].iloc[1::2].values})
    df=df.join(dfnew)
era5pl=df
print(era5pl)
print(era5pl['kx-12'],era5pl['kx-00'])

### ERA5 data 24h aggregation ###
tstep='60' # 1h
for name,par in params24h.items():
    key=[name]
    par24h={x:params24h[x] for x in key}
    # might return empty df (json error) if not split to years like this
    # split to diff. generations also to avoid NaN values 
    # 0: generation 1995-1999
    start='19950101T000000Z'
    end= '19991231T230000Z'
    df0=fcts.smartmet_ts_query_multiplePoints(start,end,tstep,latlonlst,par24h,staids)
    print('df0 ready')
    # 1: generation 2000-2010
    start='20000101T000000Z'
    end= '20051231T230000Z'
    df1=fcts.smartmet_ts_query_multiplePoints(start,end,tstep,latlonlst,par24h,staids)
    print('df1 ready')
    # 2
    start='20060101T000000Z'
    end= '20101231T230000Z'
    df2=fcts.smartmet_ts_query_multiplePoints(start,end,tstep,latlonlst,par24h,staids)
    print('df2 ready')
    # 3: generation 2011-2021
    start='20110101T000000Z'
    end= '20151231T230000Z'
    df3=fcts.smartmet_ts_query_multiplePoints(start,end,tstep,latlonlst,par24h,staids)
    print('df3 ready')
    # 4
    start='20160101T000000Z'
    end= '20210101T000000Z'
    df4=fcts.smartmet_ts_query_multiplePoints(start,end,tstep,latlonlst,par24h,staids)
    print('df4 ready')
    df=pd.concat([df0,df1,df2,df3,df4],ignore_index=True)
    df=df.sort_values(by=['staid','utctime'],ignore_index=True)
    df['utctime']=pd.to_datetime(df['utctime'])
    df[name] = pd.to_numeric(df[name],errors = 'coerce') # from object to float64
    if name=='tp-m':
        era524h=df
    else:
        df=df.drop(columns=['utctime','longitude','latitude','staid'])
        era524h=era524h.join(df)
era524h=era524h.set_index('utctime')
'''
ERA5 hourly rain to daily sums per station
hour 00:00:00 rain always summed to the previous day daily sum:
"To cover total precipitation for 1st January 2017, we need two days of data. 
a) 1st January 2017 time = 01 - 23  will give you total precipitation data to cover 00 - 23 UTC for 1st January 2017 
b) 2nd January 2017 time = 00 will give you total precipitation data to cover 23 - 24 UTC for 1st January 2017"
'''
era524h=era524h.groupby(['staid'])[['tp-m','e-m','tsr-jm2','fg10-ms','slhf-Jm2','sshf-Jm2','ro-m','sf-m','latitude','longitude','staid']].shift(-1, axis = 0) # shift columns 1 up for daily sum calc to be correct
era524h=era524h.dropna()
era524h['utctime'] = pd.to_datetime(era524h.index)
era524h=era524h.groupby(['staid','latitude','longitude'])[['utctime','tp-m','e-m','tsr-jm2','fg10-ms','slhf-Jm2','sshf-Jm2','ro-m','sf-m']].resample('D',on='utctime').sum()
era524h=(era524h.reset_index())
era524h=era524h.sort_values(by=['staid','utctime'],ignore_index=True) # probably not necessary
print(era524h)

### Terrain information 
dtwfile=eobs_path+'stations+_rr+.txt'
df = pd.DataFrame(columns=['staid','dtw','slope','aspect','tpi','tri','dtr','dtl','dto','fch'])
if os.path.exists(dtwfile):
    terrain = era5pl[['utctime','staid','latitude','longitude']].copy()
    dtwdf=pd.read_csv(dtwfile,skiprows=16,sep=';')
    for staid in staids:
        sta=staid.lstrip("0")
        if np.isin(sta,dtwdf['STAID']):
            terrain.loc[terrain['staid']==staid,'dtw'] = dtwdf.query('STAID=='+sta)['DTW'].item()
            terrain.loc[terrain['staid']==staid,'slope'] = dtwdf.query('STAID=='+sta)['SLOPE'].item()
            terrain.loc[terrain['staid']==staid,'aspect'] = dtwdf.query('STAID=='+sta)['ASPECT'].item()
            terrain.loc[terrain['staid']==staid,'tpi'] = dtwdf.query('STAID=='+sta)['TPI'].item()
            terrain.loc[terrain['staid']==staid,'tri'] = dtwdf.query('STAID=='+sta)['TRI'].item()
            terrain.loc[terrain['staid']==staid,'dtr'] = dtwdf.query('STAID=='+sta)['DTR'].item()
            terrain.loc[terrain['staid']==staid,'dtl'] = dtwdf.query('STAID=='+sta)['DTL'].item()
            terrain.loc[terrain['staid']==staid,'dto'] = dtwdf.query('STAID=='+sta)['DTO'].item()
            terrain.loc[terrain['staid']==staid,'fch'] = dtwdf.query('STAID=='+sta)['FCH'].item()
    print(terrain)

    # next station at time stuff bc got Killed otherwise...
    for staid in staids:
        cols_own=['utctime','t2m-K','td-K','msl-Pa',
            'cape-Jkg',
            #'cin-Jkg',
            'u10-ms','v10-ms',
            'z-m','sdor-m','slor','anor-rad',
            #'cbh-m',
            'i10fg-ms','tcc-0to1','hcc-0to1','lcc-0to1','mcc-0to1',
            'cp-m','sd-kgm2','skt-K','rsn-kgm2','swvl1-m3m3','sro-m','ssro-m',
            'stl1-K','stl3-K','stl4-K','swvl2-m3m3','swvl3-m3m3','swvl4-m3m3',
            'mx2t-K','mn2t-K','stl2-K','u100-ms','v100-ms',
            'mcpr-kgm2s','mer-kgm2s','mlspr-kgm2s','mror-kgm2s','mslhf-Wm2',
            'msr-kgm2s','msror-kgm2s','msshf-Wm2','mssror-kgm2s','mtpr-kgm2s','pev-m',
            'cl-0to1','cvh-n','cvl-n','dl-m','laihv-m2m2','lailv-m2m2','lsm-0to1',
            'lshf','slt','tvh-n','tvl-n',
            'STAID','RR','HGHT','LAT','LON'
        ]
        era5_old=pd.read_csv(old_data+'era5+_eobs_1995-2020_'+staid+'.csv',usecols=cols_own)
        era5_old['utctime']=pd.to_datetime(era5_old['utctime'])
        era5_old['dayOfYear'] = era5_old['utctime'].dt.dayofyear
        era5_old.to_csv('data/training-data/era5-sl-24h_eobs_'+y_start+'-'+y_end+'_'+staid+'.csv',index=False)
        
        dfpl = era5pl[era5pl['staid'] == staid]
        dfpl.to_csv('data/training-data/era5-pl-12h_'+y_start+'-'+y_end+'_'+staid+'.csv',index=False)
        
        dfsl24 = era524h[era524h['staid'] == staid]
        dfsl24.to_csv('data/training-data/era5-sl-dailysum_'+y_start+'-'+y_end+'_'+staid+'.csv',index=False)
        
        dfTerr = terrain[terrain['staid'] == staid]
        dfTerr.to_csv('data/training-data/terrain_'+y_start+'-'+y_end+'_'+staid+'.csv',index=False)
        
else:
    print('No file for staid '+staid)

# join ERA5 sl, pl, 24h, E-OBS data and terrain info
#era524h=era524h.drop(columns='utctime')
#era5pl=era5pl.drop(columns='utctime')
#terrain=terrain.drop(columns='utctime')
#slpl=era5_old.join(era5pl)
#era5eobs=slpl.join(era524h)
#era5eobsTerr=era5eobs.join(terrain)
'''        
# day of year
era5eobsTerr['utctime']=pd.to_datetime(era5eobsTerr['utctime'])
        era5eobsTerr['dayOfYear'] = era5eobsTerr['utctime'].dt.dayofyear
        
        print(era5eobsTerr)
        era5eobsTerr.to_csv('data/training-data/era5-SL-PL-24H_eobs_terrain_'+y_start+'-'+y_end+'_'+staid+'.csv',index=False)
'''
#for sta in staid:
# here join with sl data previously downloaded
#sta='001052'
#df1 = era5pl[era5pl['staid'] == sta]
#print(df1)

executionTime=(time.time()-startTime)
print('Execution time in minutes: %.2f'%(executionTime/60))