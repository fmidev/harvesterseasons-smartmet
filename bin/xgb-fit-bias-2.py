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

data_dir = '/home/ubuntu/data/xgb-bias/'
sf_data_dir = data_dir + 'yearly-controls/'
era5_data_dir = data_dir + 'era5-targets/'

era5_file = era5_data_dir + 'ERA5_20200101T000000_20241231T120000_temperatures.grib'
print('Opening ERA5 data...')
era5 = xr.open_dataset(
    era5_file,
    engine='cfgrib',
    backend_kwargs={
        'filter_by_keys': {'paramId': predictand_mappings[predictand]},
        'indexpath': '',
    },
    decode_timedelta=True)
print('ERA5 data opened.')
df_era5 = era5.to_dataframe().reset_index()
df_era5['utctime'] = pd.to_datetime(df_era5['time'])

# Open ECSF data (years manually)
ecsf_sl_vars = ['t2m', 'd2m', 'u10', 'v10', 'fg10']
ecsf_sl = xr.concat([
    xr.open_dataset(sf_data_dir + f'ECSF_{year}_sfc.grib', engine='cfgrib',
                    backend_kwargs={'indexpath': ''}, decode_timedelta=True)[ecsf_sl_vars]
    for year in [2020, 2021, 2022]
], dim="time", compat="override", coords="minimal", join="override")
df_ecsf = ecsf_sl.to_dataframe().reset_index()
df_ecsf['utctime'] = pd.to_datetime(df_ecsf['valid_time'])

# Filter to common time range
start_time = max(df_era5['utctime'].min(), df_ecsf['utctime'].min())
end_time = min(df_era5['utctime'].max(), df_ecsf['utctime'].max())
df_era5 = df_era5[(df_era5['utctime'] >= start_time) & (df_era5['utctime'] <= end_time)]
df_ecsf = df_ecsf[(df_ecsf['utctime'] >= start_time) & (df_ecsf['utctime'] <= end_time)]
print(f'Filtered to common time range: {start_time} to {end_time}')

# Prepare for merging
print('Creating full xarray dataset...')
df_era5 = df_era5[['utctime', 'latitude', 'longitude', predictand]]
df_era5 = df_era5.rename(columns={predictand: f'era5_{predictand}'})

# Create initial dataset
dsx = xr.Dataset()
for var in ecsf_sl_vars:
    dsx[var] = ecsf_sl[var]
dsx[f'era5_{predictand}'] = era5[predictand].rename(f'era5_{predictand}')

# Shift directions for neighbors
directions = {
    'o': (0, 0), 'n': (1, 0), 'ne': (1, 1), 'e': (0, 1), 'se': (-1, 1),
    's': (-1, 0), 'sw': (-1, -1), 'w': (0, -1), 'nw': (1, -1)
}

new_ds = xr.Dataset()

# Shift ECSF variables
for var in ecsf_sl_vars:
    for dir, (lat_shift, lon_shift) in directions.items():
        name = f'{var}_{dir}'
        if lat_shift == 0 and lon_shift == 0:
            new_ds[name] = dsx[var]
        else:
            new_ds[name] = dsx[var].shift(latitude=lat_shift, longitude=lon_shift)

# Add ERA5 only at center
era5_var = f'era5_{predictand}'
new_ds[era5_var] = dsx[era5_var]  # Only center

# Broadcast coordinates to 2D
lat2d, lon2d = xr.broadcast(dsx['latitude'], dsx['longitude'])

# Shift coordinates
for dir, (lat_shift, lon_shift) in directions.items():
    lat_name = f'lat_{dir}'
    lon_name = f'lon_{dir}'
    if lat_shift == 0 and lon_shift == 0:
        new_ds[lat_name] = lat2d
        new_ds[lon_name] = lon2d
    else:
        new_ds[lat_name] = lat2d.shift(latitude=lat_shift, longitude=lon_shift)
        new_ds[lon_name] = lon2d.shift(latitude=lat_shift, longitude=lon_shift)

# Final dataframe
xgb_df = new_ds.to_dataframe().dropna(how='any').reset_index()
xgb_df['month'] = xgb_df['valid_time'].dt.month

print(xgb_df.head())
print(xgb_df)
print(xgb_df.columns)

df_ecsf.to_csv(data_dir + 'ecsf_data.csv', index=False)
xgb_df.to_csv(data_dir + 'xgb_data.csv', index=False)
df_era5.to_csv(data_dir + 'era5_data.csv', index=False)

print("--- %s seconds ---" % (time.time() - startTime))
