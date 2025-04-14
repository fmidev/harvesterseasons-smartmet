import xarray as xr
import cfgrib,time,sys
import pandas as pd
import xgboost as xgb

#startTime=time.time()

def filter_points(df,lat,lon,nro,names):
    df0=df.copy()
    filter1 = df0['latitude'] == lat
    filter2 = df0['longitude'] == lon
    df0.where(filter1 & filter2, inplace=True)
    idx='-'+str(nro)
    headers=[s + idx for s in names]
    df0.columns=headers
    df0=df0.dropna()
    return df0

mod_dir='/home/ubuntu/data/MLmodels/' # fitted XGB models
data_dir='/home/ubuntu/data/OCEANIDS/' # climatology data

# read in input and output
instant = sys.argv[1] # ecsf 00 UTC data
dailysums = sys.argv[2] # ecsf disaccumulated data
lsm=sys.argv[3] # land sea mas
ensmem = sys.argv[4] # ensemble member
predictand = sys.argv[5] # predictand in fitting
correl_pred= sys.argv[6] # correlated predictor in fitting
harbor=sys.argv[7]
outFile = sys.argv[8] # output csv filename

mdl_name=f'mdl_{predictand}_2013-2024_sf_{harbor}_quantileerror-fe.txt'

pred00=['lat','lon','u10','v10','fg10','td2','t2','msl','tcc','tclw']
predDSUM=['lat','lon','ewss','nsss','slhf','ssr','sshf','ssrd','strd','tp','e','str']
landsm=['lat','lon','lsm']

# 00 UTC
sl=xr.open_dataset(instant, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
#print(sl)
df_00=sl.to_dataframe()
df_00.reset_index(['latitude','longitude'],inplace=True)
df_00=df_00.drop(columns=['surface'])
lats=df_00['latitude'].head(4).tolist()
lons=df_00['longitude'].head(4).tolist()

# filter points
lat1,lon1,lat2,lon2,lat3,lon3,lat4,lon4=lats[0],lons[0],lats[1],lons[1],lats[2],lons[2],lats[3],lons[3]
#print(lat1,lon1,lat2,lon2,lat3,lon3,lat4,lon4) # check that match with fitting input
df1=filter_points(df_00,lat1,lon1,1,pred00)
df2=filter_points(df_00,lat2,lon2,2,pred00)
df3=filter_points(df_00,lat3,lon3,3,pred00)
df4=filter_points(df_00,lat4,lon4,4,pred00)
df_new1 = pd.concat([df1,df2,df3,df4],axis=1,sort=False).reset_index()
# df from datetime to save the results
df_result = df_new1[['valid_time','lat-1']]
df_new1 = df_new1.drop(['valid_time','lat-1','lon-1','lat-2','lon-2','lat-3','lon-3','lat-4','lon-4'], axis=1)

# daily sums
sl=xr.open_dataset(dailysums, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
df_DSUM=sl.to_dataframe()
df_DSUM.reset_index(['latitude','longitude'],inplace=True)
df_DSUM=df_DSUM.drop(columns=['surface'])
# filter points
df1=filter_points(df_DSUM,lat1,lon1,1,predDSUM)
df2=filter_points(df_DSUM,lat2,lon2,2,predDSUM)
df3=filter_points(df_DSUM,lat3,lon3,3,predDSUM)
df4=filter_points(df_DSUM,lat4,lon4,4,predDSUM)
df_new2 = pd.concat([df1,df2,df3,df4],axis=1,sort=False).reset_index()

# merge 00 utc and dsums
df_apu= pd.concat([df_new1,df_new2],axis=1,sort=False).reset_index()
if 'index' in df_apu.columns:
    df_apu=df_apu.drop(columns=['index'])
df_apu.rename(columns={'tclw-1': 'tlwc-1','tclw-2': 'tlwc-2','tclw-3': 'tlwc-3','tclw-4': 'tlwc-4'}, inplace=True)

# lsm
lsm_ds=xr.open_dataset(lsm, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
df_lsm=lsm_ds.to_dataframe()
df_lsm.reset_index(['latitude','longitude'],inplace=True)
df_lsm=df_lsm.drop(columns=['surface'])
# filter points
df1=filter_points(df_lsm,lat1,lon1,1,landsm)
df2=filter_points(df_lsm,lat2,lon2,2,landsm)
df3=filter_points(df_lsm,lat3,lon3,3,landsm)
df4=filter_points(df_lsm,lat4,lon4,4,landsm)
# merge dataframes
df_new3 = pd.concat([df1,df2,df3,df4],axis=1,sort=False).reset_index()

# merge lsm to others
df_fin= pd.concat([df_apu,df_new3],axis=1,sort=False).reset_index()
if 'index' in df_fin.columns:
    df_fin=df_fin.drop(columns=['index'])
df_fin = df_fin.loc[:, ~df_fin.columns.duplicated()]
df_fin = df_fin[['valid_time'] + [col for col in df_fin.columns if col != 'valid_time']]
#df_fin=df_fin[cols_own] # check that column order same as in fitting
#print(df_fin.columns)

# Calculate additional predictors

# Convert 'utctime' to datetime and extract year and month
df_fin['valid_time'] = pd.to_datetime(df_fin['valid_time'])
df_fin['year'] = df_fin['valid_time'].dt.year
df_fin['month'] = df_fin['valid_time'].dt.month

# Sum the values for columns for correl_pred 1-4 into a single column
df_fin[f'{correl_pred}_sum'] = df_fin[[f'{correl_pred}-1', f'{correl_pred}-2', f'{correl_pred}-3', f'{correl_pred}-4']].sum(axis=1) / 4

# Group by 'month' and calculate mean, max, and min for above sum
monthly_stats = df_fin.groupby('month')[f'{correl_pred}_sum'].agg(['mean', 'max', 'min']).reset_index()
monthly_stats.rename(columns={'mean': f'{correl_pred}_sum_monthly_mean', 
                              'max': f'{correl_pred}_sum_monthly_max', 
                              'min': f'{correl_pred}_sum_monthly_min'}, inplace=True)
# Merge the monthly statistics back to the original DataFrame
df_fin = df_fin.merge(monthly_stats, on='month', how='left')

# read in climatological data for the predictand, rename cols and merge
clim=pd.read_csv(data_dir+f'training_data_oceanids_{harbor}-sf_2014-{predictand}-clim.csv')
clim['utctime'] = pd.to_datetime(clim['utctime'])
clim['month'] = clim['utctime'].dt.month
clim['day'] = clim['utctime'].dt.day
df_fin['valid_time'] = pd.to_datetime(df_fin['valid_time'])
df_fin['month'] = df_fin['valid_time'].dt.month
df_fin['day'] = df_fin['valid_time'].dt.day
df_fin = df_fin.merge(
    clim[['month', 'day', f'{predictand}_mean_climatology', f'{predictand}_max_climatology', f'{predictand}_min_climatology']],
    on=['month', 'day'],
    how='left'
)
df_fin.drop(columns=['month', 'day'], inplace=True)

df_fin.rename(columns={f'{predictand}_mean_climatology':f'{predictand}_mean', f'{predictand}_max_climatology':f'{predictand}_max', f'{predictand}_min_climatology':f'{predictand}_min'}, inplace=True)
df_fin.rename(columns={f'{correl_pred}_sum_monthly_mean':f'{correl_pred}_sum_mean', f'{correl_pred}_sum_monthly_max':f'{correl_pred}_sum_max', f'{correl_pred}_sum_monthly_min':f'{correl_pred}_sum_min'}, inplace=True)

# add day of year to predictors
df_fin['valid_time']=pd.to_datetime(df_fin['valid_time'])
df_fin['dayOfYear'] = df_fin['valid_time'].dt.dayofyear

# XGBoost predict
fitted_mdl=xgb.XGBRegressor()
fitted_mdl.load_model(mod_dir+mdl_name)
# Ensure the DataFrame has the correct columns
required_columns = fitted_mdl.get_booster().feature_names
df_fin = df_fin[required_columns]
#print(df_fin)

# Make the prediction
result=fitted_mdl.predict(df_fin)
if int(ensmem)<10:
    ensname=predictand+'_0'+ensmem
else:
    ensname=predictand+'_'+ensmem
df_result[ensname]=result.tolist()
df_result=df_result.drop(columns=['lat-1']) # dummy way because with only datetime df did not work and quick googling did not help
df_result.to_csv(outFile,index=False)
#print(df_result)

#executionTime=(time.time()-startTime)
#print('Fitting execution time per member in minutes: %.2f'%(executionTime/60))