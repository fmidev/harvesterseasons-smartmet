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
laihv='grib/ECC_20000101T000000_laihv-eu-day.grib' 
lailv='grib/ECC_20000101T000000_lailv-eu-day.grib' 
dtm_aspect='grib/COPERNICUS_20000101T000000_20110701T000000_anor-dtm-aspect-avg_eu-era5l.grb' 
dtm_slope='grib/COPERNICUS_20000101T000000_20110701T000000_slor-dtm-slope-avg_eu-era5l.grb'
dtm_height='grib/COPERNICUS_20000101T000000_20110701T000000_h-dtm-height-avg_eu-era5l.grb'
soilgrids='grib/SWIC_2020050101T000000_soilgrids-0-200cm-eu-era5l.grib' # sand ssfr, silt soilp, clay scfr, soc stf

outfile=sys.argv[5]

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

# sl, disacc, dtm, soilgrids
sl_UTC00_var = ['u10','v10','d2m','t2m',
        'rsn','sd','stl1'] # sde instead of sd?? FIX
dtm_var=['p3008','slor','anor']
sg_var=['clay_0-5cm','sand_0-5cm','silt_0-5cm','soc_0-5cm',
     'clay_5-15cm','sand_5-15cm','silt_5-15cm','soc_5-15cm',
     'clay_15-30cm','sand_15-30cm','silt_15-30cm','soc_15-30cm',
     'clay_30-60cm','sand_30-60cm','silt_30-60cm','soc_30-60cm',
     'clay_60-100cm','sand_60-100cm','silt_60-100cm','soc_60-100cm',
     'clay_100-200cm','sand_100-200cm','silt_100-200cm','soc_100-200cm']
sl00=xr.open_dataset(sl00_ecsf, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))[sl_UTC00_var]
height=xr.open_dataset(dtm_height, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
slope=xr.open_dataset(dtm_slope, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
aspect=xr.open_dataset(dtm_aspect, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
soilg_ds=xr.open_dataset(soilgrids, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
sg_df=soilg_ds.to_dataframe()
soilg_ds=[]
sg_df.reset_index(inplace=True)
sg_df=sg_df[['valid_time','depthBelowLand','latitude','longitude','scfr','ssfr','soilp','stf']]
sg_df['depthBelowLand']=sg_df['depthBelowLand'].round(2)
sg_df1 = sg_df[sg_df.depthBelowLand == 0.05]
sg_df2 = sg_df[sg_df.depthBelowLand == 0.15]
sg_df3 = sg_df[sg_df.depthBelowLand == 0.3]
sg_df4 = sg_df[sg_df.depthBelowLand == 0.6]
sg_df5 = sg_df[sg_df.depthBelowLand == 1.0]
sg_df6 = sg_df[sg_df.depthBelowLand == 2.0]
sg_df1 = sg_df1.drop(columns='depthBelowLand')
sg_df2 = sg_df2.drop(columns='depthBelowLand')
sg_df3 = sg_df3.drop(columns='depthBelowLand')
sg_df4 = sg_df4.drop(columns='depthBelowLand')
sg_df5 = sg_df5.drop(columns='depthBelowLand')
sg_df6 = sg_df6.drop(columns='depthBelowLand')
sg_df1.rename(columns = {'scfr':'clay_0-5cm','ssfr':'sand_0-5cm','soilp':'silt_0-5cm','stf':'soc_0-5cm'}, inplace = True)
sg_df2.rename(columns = {'scfr':'clay_5-15cm','ssfr':'sand_5-15cm','soilp':'silt_5-15cm','stf':'soc_5-15cm'}, inplace = True)
sg_df3.rename(columns = {'scfr':'clay_15-30cm','ssfr':'sand_15-30cm','soilp':'silt_15-30cm','stf':'soc_15-30cm'}, inplace = True)
sg_df4.rename(columns = {'scfr':'clay_30-60cm','ssfr':'sand_30-60cm','soilp':'silt_30-60cm','stf':'soc_30-60cm'}, inplace = True)
sg_df5.rename(columns = {'scfr':'clay_60-100cm','ssfr':'sand_60-100cm','soilp':'silt_60-100cm','stf':'soc_60-100cm'}, inplace = True)
sg_df6.rename(columns = {'scfr':'clay_100-200cm','ssfr':'sand_100-200cm','soilp':'silt_100-200cm','stf':'soc_100-200cm'}, inplace = True)
m1=pd.merge(sg_df1,sg_df2, on=['valid_time','latitude','longitude'])
m2=pd.merge(m1,sg_df3, on=['valid_time','latitude','longitude'])
m3=pd.merge(m2,sg_df4, on=['valid_time','latitude','longitude'])
m4=pd.merge(m3,sg_df5, on=['valid_time','latitude','longitude'])
sg_df_all=pd.merge(m4,sg_df6, on=['valid_time','latitude','longitude'])
m1,m2,m3,m4,sg_df1,sg_df2,sg_df3,sg_df4,sg_df5,sg_df6=[],[],[],[],[],[],[],[],[],[]
dtm=xr.merge([height,slope,aspect],compat='override')
dtm=dtm.to_dataframe()
dtm=dtm.drop(columns='surface')
dtm.reset_index(inplace=True)
# dtm and soilgrids have only 1 timestep: shift date, change NaN to -99999, merge with sls, reorder df,forward-fill in new dtm-NaNs, change -99999 back to NaN and drop nans
day1=swvl_df['valid_time'].iloc[0]
sg_df_all['valid_time'] = sg_df_all['valid_time'].replace('2020-05-01',day1)
dtm['valid_time'] = dtm['valid_time'].replace('2011-07-01',day1)
sg_df_all = sg_df_all.replace(np.nan,-99999) 
dtm[['p3008','slor','anor']] = dtm[['p3008','slor','anor']].replace(np.nan,-99999) 
sg_df_all=sg_df_all.set_index(['latitude','longitude','valid_time'])
sg_df_all=sg_df_all.to_xarray()
dtm=dtm.set_index(['latitude','longitude','valid_time'])
dtm=dtm.to_xarray()
ds1=xr.merge([sl00,dtm,sg_df_all],compat='override')
sl00,dtm,sg=[],[],[]
df1=ds1.to_dataframe() # > 75G memory usage (17.5G + tää ajo)
ds1=[]
df1=df1.drop(columns=['surface','depthBelowLandLayer'])
df1 = df1.reorder_levels(['latitude','longitude','valid_time']).sort_index() 
#print(df1) # check order
df1[dtm_var+sg_var] = df1[dtm_var+sg_var].fillna(method='ffill') # note: row order important
df1[dtm_var+sg_var] = df1[dtm_var+sg_var].replace(-99999,np.nan)
df1=df1.dropna()
df1.reset_index(inplace=True)
#df1=df1[['valid_time','latitude','longitude']+sl_UTC00_var+sl_disacc_var+dtm_var]
df1[['latitude','longitude']]=df1[['latitude','longitude']].astype('float32')
df1.rename(columns = {'u10':'u10-00','v10':'v10-00','d2m':'td2-00','t2m':'t2-00','rsn':'rsn-00','sd':'sd-00','stl1':'stl1-00','p3008':'DTM_height','slor':'DTM_slope','anor':'DTM_aspect'}, inplace = True)
df2 = pd.merge(swvl_df,df1, on=['valid_time','latitude','longitude'])
df1,swvl_df=[],[]

# disacc
sl_disacc_var=['tp','e','slhf','sshf','ro','str','strd','ssr','ssrd','sf']
sldisacc=xr.open_dataset(sl_disacc, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))[sl_disacc_var]
sldacc=sldisacc.to_dataframe()
sldisacc=[]
sldacc.reset_index(inplace=True)
sldacc=sldacc[['valid_time','latitude','longitude']+sl_disacc_var]
sldacc[['latitude','longitude']]=sldacc[['latitude','longitude']].astype('float32')
sldacc.rename(columns={'e':'evap'},inplace=True)
df_new=pd.merge(df2,sldacc,on=['valid_time','latitude','longitude'])
df2,sldacc=[],[]

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
df3=pd.merge(df_new,runsum_df, on=['valid_time','latitude','longitude'])
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
# shift dates
day1=str(day1)
mons=(int(day1[0:4])-2020)*12
laidf['valid_time'] = pd.DatetimeIndex( laidf['valid_time'] ) + pd.DateOffset(months = mons)
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
preds=['evap','evap15d','laihv-00','lailv-00','ro','ro15d','rsn-00','sd-00'
       ,'sf','slhf','sshf','ssr','ssrd','stl1-00','str','strd','swvl2-00',
       't2-00','td2-00','tp','tp15d','u10-00','v10-00',
       'TH_LAT','TH_LONG','DTM_height','DTM_slope','DTM_aspect',
       'clay_0-5cm','clay_100-200cm','clay_15-30cm','clay_30-60cm','clay_5-15cm','clay_60-100cm',
       'sand_0-5cm','sand_100-200cm','sand_15-30cm','sand_30-60cm','sand_5-15cm','sand_60-100cm',
       'silt_0-5cm','silt_100-200cm','silt_15-30cm','silt_30-60cm','silt_5-15cm','silt_60-100cm',
       'soc_0-5cm','soc_100-200cm','soc_15-30cm','soc_30-60cm','soc_5-15cm','soc_60-100cm',
       'dayOfYear']
df_preds = df[preds]
df=df[swicols]

### Predict with XGBoost fitted model 
mdl_name='mdl_swi2_2015-2022_10000points-7.txt'
fitted_mdl=xgb.XGBRegressor()
fitted_mdl.load_model(mdl_name)

print('start fit')
result=fitted_mdl.predict(df_preds)
print('end fit')

# result df to ds, and nc file as output
df['swi2']=result.tolist()
df.rename(columns = {'TH_LAT':'latitude','TH_LONG':'longitude'}, inplace = True)
df=df.set_index(['valid_time', 'latitude','longitude'])
#print(df)
result=df_grid.fillna(df)
#print(result)
ds=result.to_xarray()
#print(ds)
nc=ds.to_netcdf(outfile)

executionTime=(time.time()-startTime)
print('Fitting execution time per member in minutes: %.2f'%(executionTime/60))
