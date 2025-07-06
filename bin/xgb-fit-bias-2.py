#!/usr/bin/env python3
import xarray as xr
import cfgrib, sys, time
import pandas as pd
import xgboost as xgb
import numpy as np
from sklearn.metrics import mean_squared_error, mean_absolute_error
import matplotlib.pyplot as plt
import cartopy.crs as ccrs
import cartopy.feature as cfeature

startTime = time.time()

# Predictand to be fitted, from era5, with parameter ID
predictand_mappings = {
    't2m': 167,  # 2m temperature
}
predictand = 't2m'

# Paths
mod_dir = '/home/ubuntu/data/MLmodels/'
mod_name = f'xgb-bias_era5_ecsf_1995-2024_{predictand}.json'

data_dir = '/home/ubuntu/data/'
sf_data_dir = data_dir + 'xgb-bias/yearly-controls/'
era5_data_dir = data_dir + 'xgb-bias/era5-targets/'
xgb_dir= data_dir + 'xgb-bias/'

# ERA5 target
era5_target_file = era5_data_dir + 'ERA5_20200101T000000_20241231T000000_temperatures.grib'
print('Opening ERA5 data...')
era5_target = xr.open_dataset(
    era5_target_file, engine='cfgrib',
    backend_kwargs={
        'filter_by_keys': {'paramId': predictand_mappings[predictand]},
        'indexpath': '',
    }, decode_timedelta=True).rename({predictand: f'ERA5_{predictand}'})

# ERA5 static variables (features: lsm, z, slor, sdor, anor)
era5_static_file = era5_data_dir + 'ERA5_20200101T000000_20241231T000000_static.grib'
era5_static = xr.open_dataset(
    era5_static_file, engine='cfgrib', backend_kwargs={'indexpath': ''}, decode_timedelta=True
).rename_vars({'lsm': 'ERA5_lsm', 'z': 'ERA5_z', 'slor': 'ERA5_slor', 'sdor': 'ERA5_sdor', 'anor': 'ERA5_anor'})
print('ERA5 statics loaded.')

# DTM features
dtm_aspect = data_dir + 'grib/COPERNICUS_20000101T000000_20110701_anor-dtm-aspect-avg_eu-era5.grib'
dtm_slope = data_dir + 'grib/COPERNICUS_20000101T000000_20110701_slor-dtm-slope-avg_eu-era5.grib'
dtm_height = data_dir + 'grib/COPERNICUS_20000101T000000_20110701_h-dtm-height-avg_eu-era5.grib'
height = xr.open_dataset(dtm_height, engine='cfgrib', backend_kwargs={'indexpath': ''}, decode_timedelta=True).rename_vars({'h': 'DTM_height'})
#slope = xr.open_dataset(dtm_slope, engine='cfgrib', backend_kwargs={'indexpath': ''}, decode_timedelta=True).rename_vars({'slor': 'DTM_slope'})
#aspect = xr.open_dataset(dtm_aspect, engine='cfgrib', backend_kwargs={'indexpath': ''}, decode_timedelta=True).rename_vars({'anor': 'DTM_aspect'})

# Merge ERA5 target, static, and DTM
era5 = xr.merge([era5_target, era5_static, height], compat='override')
                 #, slope, aspect], compat='override')

# ECSF features (2020-2022 for now)
ecsf_sl_vars = ['t2m', 'd2m', 'u10', 'v10', 'fg10']
ecsf_list = []
for year in [2020, 2021, 2022]:
    ds_year = xr.open_dataset(sf_data_dir + f'ECSF_{year}_sfc.grib', engine='cfgrib',
                              backend_kwargs={'indexpath': ''}, decode_timedelta=True)[ecsf_sl_vars]
    ecsf_list.append(ds_year)
ecsf = xr.concat(ecsf_list, dim='time', compat='override', coords='minimal', join='override')

era5_df = era5.to_dataframe().reset_index()
ecsf_df = ecsf.to_dataframe().reset_index()
# drop column if exists
cols = ['number', 'time', 'surface','step','depthBelowLandLayer']
for col in cols:
    if col in era5_df.columns:
        era5_df.drop(columns=[col], inplace=True)
    if col in ecsf_df.columns:
        ecsf_df.drop(columns=[col], inplace=True)
#merge on valid_time, latitude, longitude
df_xgb = pd.merge(era5_df, ecsf_df, on=['valid_time', 'latitude', 'longitude'])
# Add utctime column as datetime version of valid_time
df_xgb['utctime'] = pd.to_datetime(df_xgb['valid_time'], errors='coerce')       
# Drop valid_time column
df_xgb.drop(columns=['valid_time'], inplace=True)
# add month as column
df_xgb['month'] = df_xgb['utctime'].dt.month

# check for working: Filter example for 2022-12-01 at latitude 75.0 and longitude -29.0
#filtered_df = df_xgb[(df_xgb['utctime'] == pd.Timestamp('2022-12-05')) & (df_xgb['latitude'] == 75.0) & (df_xgb['longitude'] == -29.0)]
#print(filtered_df)

### study NaNs in df_xgb
import seaborn as sns
# Count NaNs per column
nan_counts = df_xgb.isna().sum()
nan_counts = nan_counts[nan_counts > 0].sort_values(ascending=False)
# Print the counts
print("\nColumns with NaNs before drop (sorted):")
print(nan_counts)
# Plot
plt.figure(figsize=(10, 6))
sns.barplot(x=nan_counts.values, y=nan_counts.index, palette="viridis")
plt.xlabel("Number of NaNs")
plt.title("Missing Values per Column in df_xgb Before Drop")
plt.tight_layout()
plt.savefig(xgb_dir+'XGB-BIAS_missing_values_before_drop.png')
# Check for NaNs
nan_summary = df_xgb.isna().sum()
nan_summary = nan_summary[nan_summary > 0].sort_values(ascending=False)
print("\nColumns with NaNs before drop:")
print(nan_summary)

### drop NaN and -99999 values
s1=df_xgb.shape[0]
df_xgb=df_xgb.dropna(axis=0,how='any')
df_xgb=df_xgb[((df_xgb.DTM_height !=9999.000000) )]#& (df_xgb.DTM_aspect !=9999.000000) & (df_xgb.DTM_slope !=9999.000000))] # too many nans in aspect and slope datasets
s2=df_xgb.shape[0]
print('From '+str(s1)+' dropped '+str(s1-s2)+', apprx. '+str(round(100-s2/s1*100,1))+' %')

# Split to train and test by years, choose years, maybe another split here if 5 years data, like 20-80...)
test_y=[2021]
train_y=[2020, 2022]
print('test ',test_y,' train ',train_y)
train,test=pd.DataFrame(),pd.DataFrame()
for y in train_y:
        train=pd.concat([train,df_xgb[df_xgb['utctime'].dt.year == y]],ignore_index=True)
for y in test_y:
        test=pd.concat([test,df_xgb[df_xgb['utctime'].dt.year == y]],ignore_index=True)

train=train.drop(columns=['utctime'])
test=test.drop(columns=['utctime'])

# split data to features (preds) and target variable to be predicted (var)
preds=['latitude', 'longitude', 'ERA5_anor', 'ERA5_z', 'ERA5_lsm',
       'ERA5_slor', 'ERA5_sdor',
       'DTM_height',# 'DTM_slope', 'DTM_aspect',
       't2m', 'd2m', 'u10', 'v10', 'fg10', 'month']
var=['ERA5_'+predictand] 
preds_train=train[preds] 
preds_test=test[preds]
var_train=train[var]
var_test=test[var]

#print(preds_test,preds_train)
#print(var_test,var_train)

### XGBoost
# Define model hyperparameters 
nstm=500
lrte=0.1
max_depth=7
subsample=0.7
colsample_bytree=0.7
colsample_bynode=1
num_parallel_tree=10

# initialize and tune model
xgbr=xgb.XGBRegressor(
            objective= 'reg:squarederror',
            n_estimators=nstm,
            learning_rate=lrte,
            max_depth=max_depth,
            alpha=0.01,#gamma=0.01
            num_parallel_tree=num_parallel_tree,
            n_jobs=64,
            subsample=subsample,
            colsample_bytree=colsample_bytree,
            colsample_bynode=colsample_bynode,
            eval_metric='rmse',
            random_state=99,
            early_stopping_rounds=50
            )

# train model 
eval_set=[(preds_test,var_test)]
xgbr.fit(
        preds_train,var_train,
        eval_set=eval_set)
print(xgbr)

# predict var and compare with test
var_pred=xgbr.predict(preds_test)
mse=mean_squared_error(var_test,var_pred)
#varOut['RR-pred']=var_pred.tolist()
#varOut.to_csv(res_dir+'predicted_results_194sta.csv')

# save model 
xgbr.save_model(mod_dir+mod_name)

print("RMSE: %.5f" % (mse**(1/2.0)))

executionTime=(time.time()-startTime)
print('Execution time in minutes: %.2f'%(executionTime/60))

print("--- %s seconds ---" % (time.time() - startTime))
