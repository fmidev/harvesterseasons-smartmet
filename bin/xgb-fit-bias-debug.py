#!/usr/bin/env python3
import time
import numpy as np
import pandas as pd
import xgboost as xgb
from sklearn.metrics import mean_squared_error
import matplotlib.pyplot as plt
import seaborn as sns
import earthkit.data as ek  # use Earthkit to open grib files

startTime = time.time()

predictand = '2t'  # 2m temperature

# Paths
mod_dir = '/home/ubuntu/data/MLmodels/'
data_dir = '/home/ubuntu/data/xgb-bias/'
sf_data_dir = data_dir + 'yearly-controls/'
era5_data_dir = data_dir + 'era5-targets/'
dtm_data_dir = data_dir + 'dtm/'
mod_name = f'xgb-bias_era5_ecsf_2020-2024_{predictand}.json'

# Load ERA5 target and static variables from GRIB
print('Opening ERA5 GRIB data...')
era5_target = ek.from_source("file", era5_data_dir + 'ERA5_20200101T000000_20241231T000000_temperatures-nd.grib')
era5_target_df = era5_target.to_xarray().rename({predictand: f'ERA5_{predictand}'})

era5_static = ek.from_source("file", era5_data_dir + 'ERA5_20200101T000000_20241231T000000_static-nd.grib')
era5_static_df = era5_static.to_xarray().rename_vars({
    'lsm': 'ERA5_lsm',
    'z': 'ERA5_z',
    'slor': 'ERA5_slor',
    'sdor': 'ERA5_sdor',
    'anor': 'ERA5_anor'
})

# DTM features
dtm_height = dtm_data_dir + 'COPERNICUS_20000101T000000_20110701_h-dtm-height-avg_nd-era5-fix.grib'
height = ek.from_source("file", dtm_height).to_xarray().rename_vars({'h': 'DTM_height'})

# Merge ERA5 target, static, dtm
era5_dtm_vars = [f'ERA5_{predictand}', 'DTM_height', 'ERA5_lsm', 'ERA5_z', 'ERA5_slor', 'ERA5_sdor', 'ERA5_anor']
era5 = era5_target_df.merge(era5_static_df).merge(height, compat='override')[era5_dtm_vars]
era5_16 = era5.astype(np.float16)
df_era5 = era5_16.to_dataframe().reset_index()
print('ERA5 data loaded.')

# ECSF forecast features (read multiple GRIBs)
ecsf_sl_vars = ['2t', '2d', '10u', '10v', '10fg']
years = [2020, 2021, 2022, 2023, 2024]
df_ecsf_list = []

for y in years:
    print(f'Loading ECSF {y} GRIB data...')
    ds = ek.from_source("file", f'{sf_data_dir}ECSF_{y}_sfc-era5-nd-fix.grib')
    xds = ds.to_xarray()[ecsf_sl_vars]
    df = xds.to_dataframe().reset_index()
    df_ecsf_list.append(df)
    print(f'ECSF {y} data loaded.')

df_ecsf = pd.concat(df_ecsf_list, axis=0)

# Merge ECSF with ERA5
df_xgb = df_ecsf.merge(df_era5, on=['lat', 'lon', 'time'], how='left')

# Clean up and prepare features
df_xgb['utctime'] = pd.to_datetime(df_xgb['time'], errors='coerce')
df_xgb.drop(columns=['time'], inplace=True)
df_xgb['month'] = df_xgb['utctime'].dt.month

# Check example
filtered_df = df_xgb[(df_xgb['utctime'] == pd.Timestamp('2022-12-05')) & (df_xgb['lat'] == 75.0) & (df_xgb['lon'] == -29.0)]
print(filtered_df)

# Plot missing values
nan_counts = df_xgb.isna().sum()
nan_counts = nan_counts[nan_counts > 0].sort_values(ascending=False)
print("\nColumns with NaNs before drop (sorted):")
print(nan_counts)

plt.figure(figsize=(10, 6))
sns.barplot(x=nan_counts.values, y=nan_counts.index, palette="viridis")
plt.xlabel("Number of NaNs")
plt.title("Missing Values per Column in df_xgb Before Drop")
plt.tight_layout()
plt.savefig(mod_dir + 'XGB-BIAS_missing_values_before_drop.png')

# Drop NaNs and invalid values
s1 = df_xgb.shape[0]
df_xgb = df_xgb.dropna()
df_xgb = df_xgb[(df_xgb.DTM_height != 9999.0)]
s2 = df_xgb.shape[0]
print('From {} dropped {}, approx. {:.1f} %'.format(s1, s1 - s2, 100 * (s1 - s2) / s1))

# Split to train and test
test_y = [2021]
train_y = [2020, 2022, 2023]
train = pd.concat([df_xgb[df_xgb['utctime'].dt.year == y] for y in train_y])
test = pd.concat([df_xgb[df_xgb['utctime'].dt.year == y] for y in test_y])
train = train.drop(columns=['utctime'])
test = test.drop(columns=['utctime'])

# Features and target
preds = ['lat', 'lon', 'ERA5_anor', 'ERA5_z', 'ERA5_lsm', 'ERA5_slor', 'ERA5_sdor',
         'DTM_height', '2t', '2d', '10u', '10v', '10fg', 'month']
var = [f'ERA5_{predictand}']

preds_train = train[preds]
preds_test = test[preds]
var_train = train[var]
var_test = test[var]

# Train XGBoost
print('Start training XGBoost model...')
xgbr = xgb.XGBRegressor(
    objective='reg:squarederror',
    n_estimators=500,
    learning_rate=0.1,
    max_depth=7,
    alpha=0.01,
    num_parallel_tree=10,
    n_jobs=64,
    subsample=0.7,
    colsample_bytree=0.7,
    colsample_bynode=1,
    eval_metric='rmse',
    random_state=99,
    early_stopping_rounds=50
)

eval_set = [(preds_test, var_test)]
xgbr.fit(preds_train, var_train, eval_set=eval_set)
print(xgbr)

# Save model
xgbr.save_model(mod_dir + mod_name)

# Evaluate
var_pred = xgbr.predict(preds_test)
mse = mean_squared_error(var_test, var_pred)
print("RMSE: %.5f" % (mse ** 0.5))

executionTime = time.time() - startTime
print('Execution time in minutes: %.2f' % (executionTime / 60))
