#!/usr/bin/env python3
import xarray as xr
import sys, time
import pandas as pd
import xgboost as xgb
import numpy as np
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score
import matplotlib.pyplot as plt
import cartopy.crs as ccrs
import cartopy.feature as cfeature
# Nordic domain for now

startTime = time.time()

# target to be fitted, from era5, with parameter ID
target_mappings = {
    '2t': 167,  # 2m temperature
}
target = '2t'  # change this to sys.argv[1]
if target not in target_mappings:
    print(f"Target {target} not recognized. Available targets: {list(target_mappings.keys())}")
    sys.exit(1)

# Paths
mod_dir = '/home/ubuntu/data/MLmodels/'
data_dir = '/home/ubuntu/data/xgb-bias/'
sf_data_dir = data_dir + 'training_data_fin/'
era5_data_dir = data_dir + 'era5-targets/'
dtm_data_dir = data_dir + 'dtm/'

# output model name
mod_name = f'xgb-bias_era5_ecsf_2020-2024_{target}.json'

# ERA5 target
era5_target_file = era5_data_dir + 'ERA5_20200101T000000_20241231T000000_temperatures-nd.nc'
print('Opening ERA5 data...')
era5_target = xr.open_dataset(era5_target_file).rename({target: f'ERA5_{target}'})

# ERA5 static variables (features: lsm, z, slor, sdor, anor)
era5_static_file = era5_data_dir + 'ERA5_20200101T000000_20241231T000000_static-nd.nc'
era5_static = xr.open_dataset(era5_static_file).rename_vars({'lsm': 'ERA5_lsm', 'z': 'ERA5_z', 'slor': 'ERA5_slor', 'sdor': 'ERA5_sdor', 'anor': 'ERA5_anor'})

# DTM features
dtm_aspect = dtm_data_dir + 'COPERNICUS_20000101T000000_20110701_anor-dtm-aspect-avg_nd-era5-fix.nc'
dtm_slope = dtm_data_dir + 'COPERNICUS_20000101T000000_20110701_slor-dtm-slope-avg_nd-era5-fix.nc'
dtm_height = dtm_data_dir + 'COPERNICUS_20000101T000000_20110701_h-dtm-height-avg_nd-era5-fix.nc'
height = xr.open_dataset(dtm_height).rename_vars({'h': 'DTM_height'})
#slope = xr.open_dataset(dtm_slope).rename_vars({'slor': 'DTM_slope'})
#aspect = xr.open_dataset(dtm_aspect).rename_vars({'anor': 'DTM_aspect'})

# Merge ERA5 target, static, dtm
era5_dtm_vars=[f'ERA5_{target}','DTM_height','ERA5_lsm','ERA5_z','ERA5_slor','ERA5_sdor','ERA5_anor']
era5 = xr.merge([era5_target, era5_static, height], compat='override')[era5_dtm_vars]
era5_16 = era5.astype(np.float16)
df_era5 = era5_16.to_dataframe().reset_index()
print('ERA5 data loaded.')

# ECSF features
years = [2020]

# ECSF surface features 
ecsf_sl_vars = ['2t', '2d', '10u', '10v', '10fg','tp','e','rsn','mx2t24','mn2t24','msl','slhf','sshf','ssr','str','strd','tcc']
ds_list = []

for y in years:
    print(f'Loading ECSF surface {y} data...')
    ds = xr.open_dataset(
        f'{sf_data_dir}ECSF_{y}_sfc-era5-nd.nc' # smaller grid
    )[ecsf_sl_vars]
    print(f'ECSF surface {y} data loaded.')

    #ds_list.append(ds)

print('Merging ECSF surface datasets...')
#ds_merged_sfc = xr.concat(ds_list, dim='time')
ds_merged_sfc = ds
#df_ecsf_sfc = ds_merged_sfc.to_dataframe().reset_index()
print(ds)
# ECSF pressure level features
ecsf_pl_vars = ['t','u','v','q','z']
ds_list = []
for y in years:
    print(f'Loading ECSF {y} 850 hPa pressure level data...')
    ds = xr.open_dataset(
        f'{sf_data_dir}ECSF_{y}_pl-era5-nd-fix.nc' # only 00 utc timesteps
    ).sel(plev=85000)[ecsf_pl_vars]
    ds = ds.rename({var: f"{var}-850" for var in ds.data_vars if var not in ["time", "lat", "lon"]})
    print(f'ECSF {y} 850 hPa pressure level data loaded.')
    if y == 2022: 
        ds = ds.isel(time=slice(0, -1))
        print(ds)

    #ds_list.append(ds)

#ds_merged_pl = xr.concat(ds_list, dim='time')
ds_merged_pl = ds
print(ds)
ds_list = []
for y in years:
    print(f'Loading ECSF {y} 925 hPa pressure level data...')
    ds = xr.open_dataset(
        f'{sf_data_dir}ECSF_{y}_925pl-era5-nd-fixfix.nc' # only 00 utc timesteps
    ).sel(plev=92500)[ecsf_pl_vars]
    ds = ds.rename({var: f"{var}-925" for var in ds.data_vars if var not in ["time", "lat", "lon"]})
    print(f'ECSF {y} 925 hPa pressure level data loaded.')

    #ds_list.append(ds)

#ds_merged_pl = xr.concat(ds_list, dim='time')
ds_merged_925pl = ds
print(ds)

print(ds_merged_pl.to_dataframe().reset_index())
print(ds_merged_925pl.to_dataframe().reset_index())
print(ds_merged_sfc.to_dataframe().reset_index())

#df_ecsf = df_ecsf_sfc.merge(df_ecsf_pl, on=['lat', 'lon', 'time'], how='left')

print('Merging ECSF datasets...')
#ds_ecsf=xr.merge([ds_merged_sfc,ds_merged_pl],compat='override')
ds_ecsf = xr.merge([ds_merged_sfc, ds_merged_pl, ds_merged_925pl], compat="override", join="override")
df_ecsf=ds_ecsf.to_dataframe().reset_index()
print('ECSF pl and sfc data merged.')

print(df_ecsf)

#ds_xgb=xr.merge([ds_ecsf,era5],compat='override',join='override')
#print(ds_xgb.to_dataframe().reset_index())

df_xgb = df_ecsf.merge(df_era5, on=['lat', 'lon', 'time'], how='left')
print('ECSF and ERA5 data merged.')
print(df_xgb)

# Example filtering to verify data (keeps duplicate dates from sf)
print("Example filter for specific lat/lon and time:")
example_filter = df_xgb[
    (df_xgb['time'] == '2021-02-24') & 
    (df_xgb['lat'] == 66.0) & 
    (df_xgb['lon'] == 25.5)
]
print(example_filter[['lat', 'lon','ERA5_2t','t-925','2t','DTM_height']])
'''
# time column as datetime version of time
df_xgb['time'] = pd.to_datetime(df_xgb['time'], errors='coerce')       
# add month as column
df_xgb['month'] = df_xgb['time'].dt.month

print("Plotting unique lat/lon points before filtering...")
unique_points = df_xgb[['lat', 'lon']].drop_duplicates()
plt.figure(figsize=(10, 10))
ax = plt.axes(projection=ccrs.PlateCarree())
ax.set_extent([0, 36, 50, 76], crs=ccrs.PlateCarree())
ax.coastlines(resolution='10m')
ax.add_feature(cfeature.BORDERS, linestyle=':')
ax.add_feature(cfeature.LAND, facecolor='lightgray')
ax.add_feature(cfeature.OCEAN, facecolor='lightblue')
ax.scatter(unique_points['lon'], unique_points['lat'], s=1, color='red', alpha=0.5, transform=ccrs.PlateCarree())
plt.title('Unique Grid Points (lat/lon) Before Filtering')
plt.savefig(mod_dir + 'latlon_coverage-nd-era5.png', dpi=300)
plt.close()

# study nro of nans
nan_counts = df_xgb.isna().sum()
nan_counts = nan_counts[nan_counts > 0].sort_values(ascending=False)
print("\nColumns with NaNs before drop or ocean-mask (sorted):")
print(nan_counts)

# mask dtm nans to 0 (water bodies)
df_xgb['DTM_height'] = df_xgb['DTM_height'].fillna(0)

### drop NaN and -99999 values
s1=df_xgb.shape[0]
df_xgb=df_xgb.dropna(axis=0,how='any')
#df_xgb = df_xgb[~(df_xgb == 9999.0).any(axis=1)]
s2=df_xgb.shape[0]
print('From '+str(s1)+' dropped '+str(s1-s2)+', apprx. '+str(round(100-s2/s1*100,1))+' %')

# Split to train and test by years, choose years, maybe another split here if 5 years data, like 20-80...)
test_y=[2021]
train_y=[2020,2022,2023,2024]
print('test ',test_y,' train ',train_y)
train,test=pd.DataFrame(),pd.DataFrame()
for y in train_y:
        train=pd.concat([train,df_xgb[df_xgb['time'].dt.year == y]],ignore_index=True)
for y in test_y:
        test=pd.concat([test,df_xgb[df_xgb['time'].dt.year == y]],ignore_index=True)

train=train.drop(columns=['time'])
test=test.drop(columns=['time'])

# split data to features (preds) and target variable to be predicted (var)
preds=['lat', 'lon', 'ERA5_anor', 'ERA5_z', 'ERA5_lsm','ERA5_slor', 'ERA5_sdor',
       'DTM_height',# 'DTM_slope', 'DTM_aspect',
       ]+ecsf_sl_vars
print("Selected predictors:")
print(preds)
print("Target variable:")
var=['ERA5_'+target] 
print(var)
preds_train=train[preds] 
preds_test=test[preds]
var_train=train[var]
var_test=test[var]

#print(preds_test,preds_train)
#print(var_test,var_train)

print('Start training XGBoost model...')

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
            eval_metric='mae',
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

# save model 
xgbr.save_model(mod_dir+mod_name)

print("Feature importance:")
print(xgbr.feature_importances_)
# Plot feature importance
xgb.plot_importance(xgbr, max_num_features=10, importance_type='weight')
plt.title('Feature Importance')
plt.xlabel('F score')
plt.ylabel('Features')
plt.savefig(mod_dir + 'feature_importance-nd-era5.png', dpi=300)
plt.close()

# Plot predictions vs actual values
plt.figure(figsize=(10, 6))
plt.scatter(var_test, var_pred, alpha=0.5)
plt.plot([var_test.min(), var_test.max()], [var_test.min(), var_test.max()], 'r--', lw=2)
plt.title('Predicted vs Actual Values')
plt.xlabel('Actual Values')
plt.ylabel('Predicted Values')
plt.xlim(var_test.min(), var_test.max())
plt.ylim(var_test.min(), var_test.max())
plt.grid()
plt.savefig(mod_dir + 'predicted_vs_actual.png', dpi=300)
plt.close()

print("RMSE: %.5f" % (mse**(1/2.0)))
print("MAE: %.5f" % (mean_absolute_error(var_test, var_pred)))
print("R2: %.5f" % r2_score(var_test, var_pred))

'''
executionTime=(time.time()-startTime)
print('Execution time in minutes: %.2f'%(executionTime/60))
