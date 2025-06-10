import xarray as xr
import cfgrib, time, sys, json
import pandas as pd
import xgboost as xgb
import os,warnings

warnings.filterwarnings("ignore") # ignore settingWithCopyWarning

def filter_points(df,lat,lon,nro):
    df0=df.copy()
    filter1 = df0['lat'] == lat
    filter2 = df0['lon'] == lon
    df0.where(filter1 & filter2, inplace=True)
    idx='-'+str(nro)
    headers=df0.columns.tolist()
    headers_new=[s + idx for s in headers]
    df0.columns=headers_new
    df0=df0.dropna()
    return df0

mod_dir='/home/ubuntu/data/MLmodels/OCEANIDS/' # fitted XGB models
data_dir='/home/ubuntu/data/OCEANIDS/' # climatology data

# read in input and output
sl=sys.argv[1] # sl data
pl=sys.argv[2] # pl data (850 hPa)
ensmem = sys.argv[3] # ensemble member
predictand = sys.argv[4] # predictand in fitting
harbor=sys.argv[5]
outFile = sys.argv[6] # output csv filename

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
if not os.path.exists(data_dir + clim_data):
    sys.exit("Error: Climatology file not found: " + data_dir + clim_data)

# feature names from ecmwf acronyms
namesSL = {'tcc':'tcc-00','d2m':'td2-00','t2m':'t2-00','msl':'msl-00','u10':'u10-00','v10':'v10-00','mn2t24':'mn2t','mx2t24':'mx2t','r':'rh'}
namesPL850 = {'z':'z850-00','q':'q850-00','t':'t850-00','u':'u850-00','v':'v850-00','kx':'kx-00'}

# single level data
sl_ds=xr.open_dataset(sl, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath='')).rename_vars(namesSL)
df_sl = sl_ds.to_dataframe().reset_index(['latitude','longitude']).rename(columns={'latitude':'lat','longitude':'lon'}).drop(columns=['surface'])

# get lat/lon points for filtering
lats=df_sl['lat'].head(4).tolist()
lons=df_sl['lon'].head(4).tolist()
lat1,lon1,lat2,lon2,lat3,lon3,lat4,lon4=lats[0],lons[0],lats[1],lons[1],lats[2],lons[2],lats[3],lons[3]
#print(lat1,lon1,lat2,lon2,lat3,lon3,lat4,lon4) # check that match with fitting input

# filter points
df1=filter_points(df_sl,lat1,lon1,1)
df2=filter_points(df_sl,lat2,lon2,2)
df3=filter_points(df_sl,lat3,lon3,3)
df4=filter_points(df_sl,lat4,lon4,4)
df_new1 = pd.concat([df1,df2,df3,df4],axis=1,sort=False).reset_index()
df_result = df_new1[['valid_time','lat-1']] # df from datetime to save the results

# pressure level data
pl_ds=xr.open_dataset(pl, engine='cfgrib',
                   backend_kwargs=dict(filter_by_keys= {'typeOfLevel': 'isobaricInhPa','level':850},time_dims=('valid_time','verifying_time'),indexpath='')).rename_vars(namesPL850)
df_pl = pl_ds.to_dataframe().reset_index(['latitude','longitude']).rename(columns={'latitude':'lat','longitude':'lon'}).drop(columns=['isobaricInhPa'])

# filter points
df1=filter_points(df_pl,lat1,lon1,1)
df2=filter_points(df_pl,lat2,lon2,2)
df3=filter_points(df_pl,lat3,lon3,3)
df4=filter_points(df_pl,lat4,lon4,4)
df_new2 = pd.concat([df1,df2,df3,df4],axis=1,sort=False).reset_index()

# merge pl to sl
df_fin= pd.concat([df_new1,df_new2],axis=1,sort=False).reset_index()
df_fin = df_fin.loc[:, ~df_fin.columns.duplicated()]

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

# add pressure change from previous day to predictors
for i in range(1, 5):  # For columns 1 to 4
    df_fin[f'Dmsl-00-{i}'] = df_fin[f'msl-00-{i}'].diff()

# XGBoost predict
fitted_mdl=xgb.XGBRegressor()
fitted_mdl.load_model(mod_dir+mdl_name)

# Ensure the DataFrame has the correct columns
required_columns = fitted_mdl.get_booster().feature_names
df_fin = df_fin[required_columns]

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

# save to csv
df_result.to_csv(outFile,index=False)
