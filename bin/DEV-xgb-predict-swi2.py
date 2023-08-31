import xarray as xr
import cfgrib,time,sys
import pandas as pd
import numpy as np
import xgboost as xgb
startTime=time.time()
# Prediction for swi2
pd.set_option('mode.chained_assignment', None) # turn off SettingWithCopyWarning 

#mod_dir='/home/ubuntu/data/ML/models/soilwater/' # saved mdl
#data_dir='/home/ubuntu/data/ens/'

# input files 
swvls_ecsf=sys.argv[1] # vsw (swvl layers)
sl00_ecsf=sys.argv[2] # u10,v10,d2m,t2m,rsn,sd,stl1
sl_runsum=sys.argv[3] # 15-day runnins sums for disaccumulated tp,e,ro
sl_disacc=sys.argv[4] # disaccumulated tp,e,slhf,sshf,ro,str,strd,ssr,ssrd,sf 
laihv=sys.argv[5] # laihv
lailv=sys.argv[6] # lailv 
dtm_aspect='grib/COPERNICUS_20000101T000000_20110701T000000_anor-dtm-aspect-avg_eu-era5l.grb' 
dtm_slope='grib/COPERNICUS_20000101T000000_20110701T000000_slor-dtm-slope-avg_eu-era5l.grb'
dtm_height='grib/COPERNICUS_20000101T000000_20110701T000000_h-dtm-height-avg_eu-era5l.grb'
soilgrids='grib/SG_2020050101T000000_soilgrids-0-200cm-eu-era5l.grib' # sand ssfr, silt soilp, clay scfr, soc stf
outfile=sys.argv[7]

# read in swvl2 and static values
swvls=xr.open_dataset(swvls_ecsf, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
swvl_df=swvls.to_dataframe()
swvls=[]
swvl_df.reset_index(inplace=True)
swvl_df=swvl_df[['valid_time','depthBelowLandLayer','latitude','longitude','vsw']]
swvl_df[['depthBelowLandLayer','latitude','longitude']]=swvl_df[['depthBelowLandLayer','latitude','longitude']].astype('float32')
swvl_df['depthBelowLandLayer']=swvl_df['depthBelowLandLayer'].round(2)
swvl_df = swvl_df[swvl_df.depthBelowLandLayer == 0.07]
swvl_df.rename(columns = {'vsw':'swvl2-00'}, inplace = True)
swvl_df=swvl_df[['valid_time','latitude','longitude','swvl2-00']]

# sl, disacc, dtm
sl_UTC00_var = ['u10','v10','d2m','t2m',
        'rsn','sd','stl1'] 
sl_disacc_var=['tp','e','slhf','sshf','ro','str','strd','ssr','ssrd','sf']
dtm_var=['p3008','slor','anor']
sl00=xr.open_dataset(sl00_ecsf, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))[sl_UTC00_var]
sldisacc=xr.open_dataset(sl_disacc, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))[sl_disacc_var]
height=xr.open_dataset(dtm_height, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
slope=xr.open_dataset(dtm_slope, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
aspect=xr.open_dataset(dtm_aspect, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
dtm=xr.merge([height,slope,aspect],compat='override')
dtm=dtm.to_dataframe()
dtm.reset_index(inplace=True)
# dtm has only 1 timestep: shift date, change NaN to -99999, merge with sls, reorder df,forward-fill in new dtm-NaNs, change -99999 back to NaN and drop nans
day1=swvl_df['valid_time'].iloc[0]
dtm['valid_time'] = dtm['valid_time'].replace('2011-07-01',day1)
dtm['p3008'] = dtm['p3008'].replace(np.nan,-99999) 
dtm['slor'] = dtm['slor'].replace(np.nan,-99999) 
dtm['anor'] = dtm['anor'].replace(np.nan,-99999) 
dtm=dtm.set_index(['latitude','longitude','valid_time', 'surface'])
dtm=dtm.to_xarray()
ds1=xr.merge([sl00,sldisacc,dtm],compat='override')
sl00,sldisacc,dtm=[],[],[]
df1=ds1.to_dataframe()
df1 = df1.reorder_levels(['latitude','longitude','valid_time','surface']).sort_index()
print(df1) # check order
df1[['p3008', 'slor', 'anor']] = df1[['p3008', 'slor', 'anor']].fillna(method='ffill') # note: row order important
df1['p3008'] = df1['p3008'].replace(-99999,np.nan)
df1['anor'] = df1['anor'].replace(-99999,np.nan)
df1['slor'] = df1['slor'].replace(-99999,np.nan)
df1=df1.dropna()
df1.reset_index(inplace=True)
df1=df1[['valid_time','latitude','longitude']+sl_UTC00_var+sl_disacc_var+dtm_var]
df1[['latitude','longitude']]=df1[['latitude','longitude']].astype('float32')
df1.rename(columns = {'u10':'u10-00','v10':'v10-00','d2m':'td2-00','t2m':'t2-00','rsn':'rsn-00','sd':'sd-00','stl1':'stl1-00','e':'evap','p3008':'DTM_height','slor':'DTM_slope','anor':'DTM_aspect'}, inplace = True)
df2 = pd.merge(swvl_df,df1, on=['valid_time','latitude','longitude'])
df1,swvl_df=[],[]

### Read in runsums
sl_runsum_var=['tp','e','ro']
slrunsum=xr.open_dataset(sl_runsum, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))[sl_runsum_var]
runsum_df=slrunsum.to_dataframe()
slrunsum=[]
runsum_df.reset_index(inplace=True)
runsum_df=runsum_df[['valid_time','latitude','longitude']+sl_runsum_var]
runsum_df[['latitude','longitude']]=runsum_df[['latitude','longitude']].astype('float32')
runsum_df.rename(columns = {'ro':'ro15d','e':'evap15d','tp':'tp15d'}, inplace = True)
df3=pd.merge(df2,runsum_df, on=['valid_time','latitude','longitude'])
# store grid for final result
df_grid=runsum_df[['valid_time','latitude','longitude']]
df_grid['swi2'] = np.nan
df_grid=df_grid.set_index(['valid_time', 'latitude','longitude'])
df2,runsum_df=[],[]

### Read in laihv lailv
laihv_ds=xr.open_dataset(laihv, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
lailv_ds=xr.open_dataset(lailv, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
laids=xr.merge([laihv_ds,lailv_ds],compat='override')
laidf=laids.to_dataframe()
laidf.reset_index(inplace=True)
laidf=laidf[['valid_time','latitude','longitude','lai_hv','lai_lv']]
laidf[['latitude','longitude']]=laidf[['latitude','longitude']].astype('float32')
laidf['valid_time']=pd.to_datetime(laidf['valid_time'])
laidf['valid_time']=laidf['valid_time'].dt.date
laidf['valid_time']=pd.to_datetime(laidf['valid_time'])
laidf.rename(columns = {'lai_lv':'lailv-00','lai_hv':'laihv-00'}, inplace = True)
df=pd.merge(df3,laidf, on=['valid_time','latitude','longitude'])
df3,laidf=[],[]

df['valid_time']=pd.to_datetime(df['valid_time'])
df['dayOfYear'] = df['valid_time'].dt.dayofyear
df.rename(columns = {'latitude':'TH_LAT', 'longitude':'TH_LONG'}, inplace = True)

df=df.dropna()
swicols=['valid_time','TH_LAT','TH_LONG']
preds=[
        'evap','evap15d','laihv-00','lailv-00','ro','ro15d',
        'rsn-00','sd-00','sf','slhf','sshf','ssr','ssrd','stl1-00',
        'str','strd','swvl2-00','t2-00','td2-00','tp','tp15d','u10-00','v10-00',
        'TH_LAT','TH_LONG','DTM_height','DTM_slope','DTM_aspect','dayOfYear'
]
df_preds = df[preds]
df=df[swicols]

### Predict with XGBoost fitted model 
mdl_name='mdl_swi2_2015-2022_10000points-6.txt'
fitted_mdl=xgb.XGBRegressor()
fitted_mdl.load_model(mdl_name)

print('start fit')
result=fitted_mdl.predict(df_preds)
print('end fit')

# result df to ds, and nc file as output
df['swi2']=result.tolist()
df.rename(columns = {'TH_LAT':'latitude','TH_LONG':'longitude'}, inplace = True)
df=df.set_index(['valid_time', 'latitude','longitude'])
print(df)
result=df_grid.fillna(df)
#print(result)
ds=result.to_xarray()
#print(ds)
nc=ds.to_netcdf(outfile)

executionTime=(time.time()-startTime)
print('Fitting execution time per member in minutes: %.2f'%(executionTime/60))
