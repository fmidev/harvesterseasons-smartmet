#!/usr/bin/env python3
import xarray as xr
import sys, time, shap
import pandas as pd
import xgboost as xgb
import numpy as np
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score
import matplotlib.pyplot as plt
import cartopy.crs as ccrs
import cartopy.feature as cfeature
# Nordic domain for now

startTime = time.time()

# target to be fitted, from era5 or era5d, with parameter ID
target_mappings = {
    '2t': 167,  # 2m temperature (6h instantaneous)
    'tp': 228,  # total precipitation (24h aggregation)
    '10fg': 49  # 10m wind gust since previous post-processing (24h aggregation)
}
target = '10fg'  # change this to sys.argv[1]
if target not in target_mappings:
    print(f"Target {target} not recognized. Available targets: {list(target_mappings.keys())}")
    sys.exit(1)

# Paths
mod_dir = '/home/ubuntu/data/ML/xgb-bias-models/'
data_dir = '/home/ubuntu/data/xgb-bias/'
sf_data_dir = data_dir + 'reduced-fin/'
era5_data_dir = data_dir + 'era5-targets/'
dtm_data_dir = data_dir + 'dtm/'

# output model name
mod_name = f'xgb-bias_era5_ecsf_2020-2024_{target}-V2.json'

# ERA5 target
if target == '2t':
    era5_target_file = era5_data_dir + 'ERA5_20200101T000000_20241231T000000_temperatures-nd.nc'
elif target == 'tp':
    era5_target_file = era5_data_dir + 'ERA5D_2020-2024_tp-nd-fix.nc'
elif target == '10fg':
    era5_target_file = era5_data_dir + 'ERA5D_2020-2024_10fg-nd-fix.nc' # onko tää nyt sitten daily mean vai max?? who knows...
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

# ECSF
years1 = [2017,2018,2019,2020,2021]
years2 = [2022,2023,2024]

# ECSF surface features 2017-2024
ecsf_sl_vars = ['10u','10v','10fg','2d','2t','rsn','sd','stl1','tcc']
ensmems = list(range(51))  # 0–50
ds_list = []

for nro in ensmems:
    print('Loading ECSF surface data for ensemble member', nro)
    ds = xr.open_dataset(
        f'{sf_data_dir}ecsf-era5_2017-2021_3days-sfc-eu_{nro}.nc'
    )[ecsf_sl_vars]
    ds = ds.rename({var: f"{var}_{nro}" for var in ds.data_vars})
    ds_list.append(ds)
ds_merged_sfc = xr.merge(ds_list)
df = ds_merged_sfc.to_dataframe().reset_index()
print(df)

# ECSF disaccumulated features 
'''
# ECSF features
years = [2020,2021,2022,2023,2024]

# ECSF disacc and surface features 
ecsf_sl_vars = ['10u','10v','10fg','2d','2t','rsn','sd','stl1','tcc']
#ecsf_sl_vars = ['10u','10v','10fg','2d','2t','tcc']

ds_list = []

for y in years:
    print(f'Loading ECSF surface {y} data...')
    ds = xr.open_dataset(
        f'{sf_data_dir}ECSF_{y}_sfc-era5-nd.nc' # smaller grid
    )[ecsf_sl_vars]
    print(f'ECSF surface {y} data loaded.')
    ds_list.append(ds)

print('Merging ECSF surface datasets...')
#df_ecsf_sfc = ds_merged_sfc.to_dataframe().reset_index()

ecsf_disacc_vars=['ewss','e','nsss','ro','sf','slhf','ssr','str','sshf','ssrd','strd','tsr','ttr','tp']
#ecsf_disacc_vars=['e','tp']
ds_list = []
for y in years:
    print(f'Loading ECSF disacc {y} data...')
    ds = xr.open_dataset(
        f'{sf_data_dir}ECSF_{y}_disacc-era5-nd.nc' # smaller grid
    )[ecsf_disacc_vars]
    print(f'ECSF disacc {y} data loaded.')
    ds_list.append(ds)

print('Merging ECSF disacc datasets...')
ds_merged_disacc = xr.concat(ds_list, dim='time')

# ECSF pressure level features
ecsf_pl_vars = ['t','u','v','q','z']
ds_list = []
# 850 hPa level
for y in years:
    print(f'Loading ECSF {y} 850 hPa pressure level data...')
    ds = xr.open_dataset(
        f'{sf_data_dir}ECSF_{y}_pl-era5-nd-fix.nc' # only 00 utc timesteps
    ).sel(plev=85000)[ecsf_pl_vars]
    ds = ds.rename({var: f"{var}850" for var in ds.data_vars if var not in ["time", "lat", "lon"]})
    print(f'ECSF {y} 850 hPa pressure level data loaded.')
    ds_list.append(ds)
print('Merging ECSF 850 hPa pressure level datasets...')
ds_merged_pl = xr.concat(ds_list, dim='time')

ds_list = []
# 925 hPa level
for y in years:
    print(f'Loading ECSF {y} 925 hPa pressure level data...')
    ds = xr.open_dataset(
        f'{sf_data_dir}ECSF_{y}_925pl-era5-nd-fixfix.nc' # only 00 utc timesteps
    ).sel(plev=92500)[ecsf_pl_vars]
    ds = ds.rename({var: f"{var}925" for var in ds.data_vars if var not in ["time", "lat", "lon"]})
    print(f'ECSF {y} 925 hPa pressure level data loaded.')
    ds_list.append(ds)
print('Merging ECSF 925 hPa pressure level datasets...') # probably can me merged as datasets ecsf data!!! since same timesteps and grid
ds_merged_925pl = xr.concat(ds_list, dim='time')

print(ds_merged_925pl.to_dataframe().reset_index())
print(ds_merged_disacc.to_dataframe().reset_index())
print(ds_merged_pl.to_dataframe().reset_index())
print(ds_merged_sfc.to_dataframe().reset_index())

print('Merging ECSF datasets...')
ds_ecsf = xr.merge([ds_merged_sfc, ds_merged_disacc, ds_merged_pl, ds_merged_925pl], compat="override", join="override")

# add lapse rate in K/km
g = 9.80665 # to convert geopotential in m2/s2 to m
ds_ecsf['lrate'] = (ds_ecsf['t850'] - ds_ecsf['t925']) / (ds_ecsf['z850']/g - ds_ecsf['z925']/g) * 1000

df_ecsf=ds_ecsf.to_dataframe().reset_index()
print('ECSF pl and sfc data merged.')

print(df_ecsf)

df_xgb = df_ecsf.merge(df_era5, on=['lat', 'lon', 'time'], how='left')
print('ECSF and ERA5 data merged.')
print(df_xgb)

# Example filtering to verify data (keeps duplicate dates from sf)
print("Example filter for specific lat/lon and time:")
example_filter = df_xgb[
    (df_xgb['time'] == '2023-02-24') & 
    (df_xgb['lat'] == 66.0) & 
    (df_xgb['lon'] == 25.5)
]
print(example_filter[['lat', 'lon','ERA5_'+target,'tp']])

# time column as datetime version of time
df_xgb['time'] = pd.to_datetime(df_xgb['time'], errors='coerce')       
# add month as column
df_xgb['month'] = df_xgb['time'].dt.month
# add season as column (DJF=1, MAM=2, JJA=3, SON=4)
season_map = {
    12: 1, 1: 1, 2: 1,   # DJF
    3: 2, 4: 2, 5: 2,    # MAM
    6: 3, 7: 3, 8: 3,    # JJA
    9: 4, 10: 4, 11: 4   # SON
}
df_xgb["season"] = df_xgb["month"].map(season_map)
print(df_xgb)

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
preds=['lat', 'lon', 'ERA5_anor', 'ERA5_z', 'ERA5_lsm','ERA5_slor', 'ERA5_sdor', 'month', 'lrate', 'season',
       #'DTM_height',# 'DTM_slope', 'DTM_aspect',
       ]+ecsf_sl_vars+ecsf_disacc_vars+[f"{var}850" for var in ecsf_pl_vars] + [f"{var}925" for var in ecsf_pl_vars]
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
nstm=500
lrte=0.1
max_depth=7
subsample=0.7
colsample_bytree = 0.8
colsample_bylevel = 1.0
colsample_bynode = 0.9
num_parallel_tree=10
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
            colsample_bylevel=colsample_bylevel,
            eval_metric='mae',
            random_state=99,
            early_stopping_rounds=50
            )

# train model 
eval_set=[(preds_test,var_test)]
xgbr.fit(
    preds_train, var_train,
    eval_set=eval_set
)
print(xgbr)
# predict var and compare with test
var_pred=xgbr.predict(preds_test)
mse=mean_squared_error(var_test,var_pred)

# save model 
xgbr.save_model(mod_dir+mod_name)

# Plot feature importance by weight, gain, and cover
plt.figure(figsize=(12, 20))
xgb.plot_importance(xgbr, importance_type='weight')
plt.title('Feature Importance (Weight)')
plt.tight_layout()
plt.savefig(mod_dir + f'feature_importance_weight_{target}.png', dpi=300)
plt.close()

plt.figure(figsize=(12, 20))
xgb.plot_importance(xgbr, importance_type='gain')
plt.title('Feature Importance (Gain)')
plt.tight_layout()
plt.savefig(mod_dir + f'feature_importance_gain_{target}.png', dpi=300)
plt.close()

plt.figure(figsize=(12, 20))
xgb.plot_importance(xgbr, importance_type='cover')
plt.title('Feature Importance (Cover)')
plt.tight_layout()
plt.savefig(mod_dir + f'feature_importance_cover_{target}.png', dpi=300)
plt.close()

print("RMSE: %.5f" % (mse**(1/2.0)))
print("MAE: %.5f" % (mean_absolute_error(var_test, var_pred)))
print("R2: %.5f" % r2_score(var_test, var_pred))

# SHAP (Not tested yet!!)
explainer = shap.TreeExplainer(xgbr, model_output="raw", feature_perturbation="tree_path_dependent")
shap_values = explainer.shap_values(preds_test, approximate=True)
if shap_values.shape[1] == preds_test.shape[1] + 1:
    shap_values = shap_values[:, :-1]
mean_abs_shap = np.abs(shap_values).mean(axis=0)
sorted_idx = np.argsort(mean_abs_shap)

plt.figure(figsize=(12, 20))
plt.barh(np.array(preds)[sorted_idx], mean_abs_shap[sorted_idx])
plt.title("SHAP Feature Importance (mean |SHAP|)")
plt.xlabel("Mean |SHAP value|")
plt.tight_layout()
plt.savefig(mod_dir + f"shap_feature_importance_{target}.png", dpi=300)
plt.close()

executionTime=(time.time()-startTime)
print('Execution time in minutes: %.2f'%(executionTime/60))
'''