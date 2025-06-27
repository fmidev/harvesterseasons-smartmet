#!/usr/bin/env python3
import xarray as xr
import cfgrib
import pandas as pd
import numpy as np
from scipy.spatial import cKDTree
import time

start_time = time.time()

# CONFIG
predictand = 't2m'
predictand_mappings = {'t2m': 167}
data_dir = '/home/ubuntu/data/xgb-bias/'
sf_data_dir = f'{data_dir}yearly-controls/'
era5_data_dir = f'{data_dir}era5-targets/'
era5_file = f'{era5_data_dir}ERA5_20200101T000000_20241231T120000_temperatures.grib'

# Load ERA5
print("Loading ERA5...")
era5 = xr.open_dataset(era5_file, engine='cfgrib',
    backend_kwargs={'filter_by_keys': {'paramId': predictand_mappings[predictand]}, 'indexpath': ''},
    decode_timedelta=True)
era5 = era5.rename({predictand: f'era5_{predictand}'})
print("ERA5 data loaded.")
df_era5 = era5.to_dataframe().reset_index()
df_era5['utctime'] = pd.to_datetime(df_era5['time'])
df_era5['latlon'] = list(zip(df_era5['latitude'].round(2), df_era5['longitude'].round(2)))

# Load ECSF
print("Loading ECSF...")
years = [2020, 2021, 2022]
ecsf_vars = ['t2m', 'd2m', 'u10', 'v10', 'fg10']
ecsf = xr.concat([
    xr.open_dataset(f'{sf_data_dir}/ECSF_{y}_sfc.grib', engine='cfgrib',
                    backend_kwargs={'indexpath': ''}, decode_timedelta=True)[ecsf_vars]
    for y in years
], dim='time', compat='override', coords='minimal', join='override')
print("ECSF data loaded.")
df_ecsf = ecsf.to_dataframe().reset_index()
df_ecsf['utctime'] = pd.to_datetime(df_ecsf['valid_time'])
df_ecsf['latlon'] = list(zip(df_ecsf['latitude'].round(2), df_ecsf['longitude'].round(2)))

# Common time window
tmin = max(df_era5['utctime'].min(), df_ecsf['utctime'].min())
tmax = min(df_era5['utctime'].max(), df_ecsf['utctime'].max())
df_era5 = df_era5[(df_era5['utctime'] >= tmin) & (df_era5['utctime'] <= tmax)]
df_ecsf = df_ecsf[(df_ecsf['utctime'] >= tmin) & (df_ecsf['utctime'] <= tmax)]

# KD-tree search
print("Building KD-tree...")
ecsf_coords = np.array(list({tuple(x) for x in df_ecsf['latlon']}))
era5_coords = np.array(list({tuple(x) for x in df_era5['latlon']}))
tree = cKDTree(ecsf_coords)
dists, indices = tree.query(era5_coords, k=9)
era5_neighbors = {tuple(era5_coords[i]): ecsf_coords[indices[i]] for i in range(len(era5_coords))}

# Match each ERA5 point & time with its ECSF neighbors
print("Matching points...")
records = []
era5_grouped = df_era5.groupby(['latlon', 'utctime'])

for (latlon, utctime), era5_row in era5_grouped:
    neighbors = era5_neighbors.get(latlon, [])
    if len(neighbors) < 9:
        continue
    era5_val = era5_row[f'era5_{predictand}'].values[0]
    row = {'latitude': latlon[0], 'longitude': latlon[1], 'utctime': utctime, f'era5_{predictand}': era5_val}
    
    ecsf_sub = df_ecsf[(df_ecsf['utctime'] == utctime) & (df_ecsf['latlon'].isin(map(tuple, neighbors.round(2))))]
    
    for i, (nlat, nlon) in enumerate(neighbors):
        match = ecsf_sub[(ecsf_sub['latitude'].round(2) == nlat) & (ecsf_sub['longitude'].round(2) == nlon)]
        if not match.empty:
            for var in ecsf_vars:
                row[f'{var}_n{i}'] = match.iloc[0][var]
    if len(row) == 1 + 1 + 1 + 1 + len(ecsf_vars) * 9:  # lat, lon, time, era5 + 9x5 vars
        records.append(row)

print("Finalizing dataframe...")
final_df = pd.DataFrame(records)
final_df['month'] = pd.to_datetime(final_df['utctime']).dt.month

# Save
final_df.to_csv(f'{data_dir}xgb_data_ckdtree.csv', index=False)

print(f"✅ Done in {round(time.time() - start_time, 1)} s. Output rows: {len(final_df)}")
