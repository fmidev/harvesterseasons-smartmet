import xarray as xr
import cfgrib, time, sys, json
import pandas as pd
import xgboost as xgb
import os

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

mod_dir='/home/ubuntu/data/MLmodels/OCEANIDS/' # fitted XGB models
data_dir='/home/ubuntu/data/OCEANIDS/' # climatology data

# read in input and output
pressure=sys.argv[1] # pl850 data
instant = sys.argv[2] # ecsf 00 UTC data
dailysums = sys.argv[3] # ecsf disaccumulated data
unbound = sys.argv[4] # unbound data
unbdisacc = sys.argv[5] # unbound disaccumulated data
mx2t = sys.argv[6] # maximum temperature
mn2t = sys.argv[7] # minimum temperature
bound = sys.argv[8] # unbound data
#lsm=sys.argv[4] # land sea mask omitted from predictors
ensmem = sys.argv[9] # ensemble member
predictand = sys.argv[10] # predictand in fitting
harbor=sys.argv[11]
outFile = sys.argv[12] # output csv filename

# Define the predictand mappings
predictand_mappings={
    'WG_PT24H_MAX': 'fg10',
    'WS_PT24H_AVG': 'ws',
    'RH_PT24H_AVG': 'rh',
    'TA_PT24H_MAX': 'mx2t',
    'TA_PT24H_MIN': 'mn2t',
    'TP_PT24H_ACC': 'tp'
    }
correl_pred=predictand_mappings[predictand]

mdl_name=f'mdl_{harbor}_{predictand}_xgb_era5_oceanids-QE.json'
clim_data=f'training_data_oceanids_{harbor}-sf_2020-clim.csv.gz'

if not os.path.exists(mod_dir + mdl_name):
    sys.exit("Error: Model file not found: " + mod_dir + mdl_name)

# read in fitting data
pred00= ["lat", "lon", "fg10", "tcc-00"]
predUB= ["lat", "lon", "td2-00", "t2-00", "msl-00", "tclw", "tcwv", "u10-00", "v10-00"]
predUBD= ["lat", "lon","ewss", "nsss", "sshf", "slhf","strd", "str"]
predDSUM= ["lat", "lon", "ssr", "ssrd", "tp", "e", "ttr"]
predPL= ["lat", "lon", "t850-00", "q850-00", "z850-00", "u850-00", "v850-00", "kx-00"]
predMX2T= ["lat", "lon", "mx2t"]
predMN2T= ["lat", "lon", "mn2t"]

#json_file = f'{mod_dir}{predictand}_training_preds.json'
'''json_file = f'{mod_dir}training_preds.json'
with open(json_file, 'r') as f:
    data = json.load(f)
pred00 = data.get('pred00')
predUB = data.get('predUB')
predUBD = data.get('predUBD')
predDSUM = data.get('predDSUM')
predPL = data.get('predPL')
#landsm = data.get('landsm')
'''

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
#df_apu.rename(columns={'tclw-1': 'tlwc-1','tclw-2': 'tlwc-2','tclw-3': 'tlwc-3','tclw-4': 'tlwc-4'}, inplace=True)

# pressure level 850hPa
names850 = {'z':'z850-00','q':'q850-00','t':'t850-00','u':'u850-00','v':'v850-00','kx':'kx-00'}

pl=xr.open_dataset(pressure, engine='cfgrib',
                   backend_kwargs=dict(filter_by_keys= {'typeOfLevel': 'isobaricInhPa','level':850},time_dims=('valid_time','verifying_time'),indexpath='')).rename_vars(names850)
df_pl=pl.to_dataframe()
df_pl=df_pl.drop(columns=['isobaricInhPa'])
df_pl.reset_index(['latitude','longitude'],inplace=True)
#df_pl=df_pl[predPL]
# filter points
df1=filter_points(df_pl,lat1,lon1,1,predPL)
df2=filter_points(df_pl,lat2,lon2,2,predPL)
df3=filter_points(df_pl,lat3,lon3,3,predPL)
df4=filter_points(df_pl,lat4,lon4,4,predPL)
df_new3 = pd.concat([df1,df2,df3,df4],axis=1,sort=False).reset_index()
# merge pl to others
df_apu2= pd.concat([df_apu,df_new3],axis=1,sort=False).reset_index()

# unbound
ub=xr.open_dataset(unbound, engine='cfgrib',
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
df_unbound=ub.to_dataframe()
df_unbound.reset_index(['latitude','longitude'],inplace=True)
df_unbound=df_unbound.drop(columns=['surface'])
# filter points
df1=filter_points(df_unbound,lat1,lon1,1,predUB)
df2=filter_points(df_unbound,lat2,lon2,2,predUB)
df3=filter_points(df_unbound,lat3,lon3,3,predUB)
df4=filter_points(df_unbound,lat4,lon4,4,predUB)
df_new4 = pd.concat([df1,df2,df3,df4],axis=1,sort=False).reset_index()
# merge all
df_apu3= pd.concat([df_apu2,df_new4],axis=1,sort=False).reset_index()
if 'level_0' in df_apu3.columns:
    df_apu3=df_apu3.drop(columns=['level_0'])

# unbound disaccumulated
ubd=xr.open_dataset(unbdisacc, engine='cfgrib',
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
df_unboundd=ubd.to_dataframe()
df_unboundd.reset_index(['latitude','longitude'],inplace=True)
df_unboundd=df_unboundd.drop(columns=['surface'])
# filter points
df1=filter_points(df_unboundd,lat1,lon1,1,predUBD)
df2=filter_points(df_unboundd,lat2,lon2,2,predUBD)
df3=filter_points(df_unboundd,lat3,lon3,3,predUBD)
df4=filter_points(df_unboundd,lat4,lon4,4,predUBD)
df_new5 = pd.concat([df1,df2,df3,df4],axis=1,sort=False).reset_index()
# merge all
df_apu4= pd.concat([df_apu3,df_new5],axis=1,sort=False).reset_index()
if 'level_0' in df_apu4.columns:
    df_apu4=df_apu4.drop(columns=['level_0'])

# maximum temperature
mx2t_ds=xr.open_dataset(mx2t, engine='cfgrib',
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
df_mx2t=mx2t_ds.to_dataframe()
df_mx2t.reset_index(['latitude','longitude'],inplace=True)
df_mx2t=df_mx2t.drop(columns=['surface'])
# filter points
df1=filter_points(df_mx2t,lat1,lon1,1,predMX2T)
df2=filter_points(df_mx2t,lat2,lon2,2,predMX2T)
df3=filter_points(df_mx2t,lat3,lon3,3,predMX2T)
df4=filter_points(df_mx2t,lat4,lon4,4,predMX2T)
df_new6 = pd.concat([df1,df2,df3,df4],axis=1,sort=False).reset_index()
# merge mx2t to others
df_apu5= pd.concat([df_apu4,df_new6],axis=1,sort=False).reset_index()
if 'level_0' in df_apu5.columns:
    df_apu5=df_apu5.drop(columns=['level_0'])

# minimum temperature
mn2t_ds=xr.open_dataset(mn2t, engine='cfgrib',
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
df_mn2t=mn2t_ds.to_dataframe()
df_mn2t.reset_index(['latitude','longitude'],inplace=True)
df_mn2t=df_mn2t.drop(columns=['surface'])
# filter points
df1=filter_points(df_mn2t,lat1,lon1,1,predMN2T)
df2=filter_points(df_mn2t,lat2,lon2,2,predMN2T)
df3=filter_points(df_mn2t,lat3,lon3,3,predMN2T)
df4=filter_points(df_mn2t,lat4,lon4,4,predMN2T)
df_new7 = pd.concat([df1,df2,df3,df4],axis=1,sort=False).reset_index()
# merge mn2t to others
df_fin= pd.concat([df_apu5,df_new7],axis=1,sort=False).reset_index()

'''# lsm
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
'''

if 'index' in df_fin.columns:
    df_fin=df_fin.drop(columns=['index'])

df_fin = df_fin.loc[:, ~df_fin.columns.duplicated()]
df_fin = df_fin[['valid_time'] + [col for col in df_fin.columns if col != 'valid_time']]
#df_fin=df_fin[cols_own] # check that column order same as in fitting
#print(df_fin.columns.tolist())

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
clim=pd.read_csv(data_dir+clim_data)
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
#print(list(df_fin.columns))

# add pressure change from previous day to predictors
for i in range(1, 5):  # For columns 1 to 4
    df_fin[f'Dmsl-00-{i}'] = df_fin[f'msl-00-{i}'].diff()

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
df_result['valid_time'] = pd.to_datetime(df_result['valid_time']).dt.floor('D') - pd.Timedelta(days=1)
df_result['valid_time'] = df_result['valid_time'].dt.strftime('%Y-%m-%d 12:00:00')
df_result.rename(columns={'valid_time': 'utctime'}, inplace=True)

# Reorder df_result columns
wg_columns = sorted([col for col in df_result.columns if col.startswith('WG')], key=lambda x: int(x.split('_')[-1].zfill(2)))
other_columns = [col for col in df_result.columns if not col.startswith('WG')]
df_result = df_result[other_columns + wg_columns]

df_result.to_csv(outFile,index=False)
#print(df_result)

#executionTime=(time.time()-startTime)
#print('Fitting execution time per member in minutes: %.2f'%(executionTime/60))
