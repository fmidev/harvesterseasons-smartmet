#!/usr/bin/env python3
# filepath: /home/ubuntu/bin/xgb-predict-oceanids-grib.py

import xarray as xr
import cfgrib
import pandas as pd
import os
import sys
import numpy as np
import time

startTime = time.time()

# File paths
ecsf_file = '/home/ubuntu/data/era5/ECSF_19950101T000000_1995-2024_sl-mon-era5-eu-fix.grib'
era5_file = '/home/ubuntu/data/era5/ERA5_19950101T000000_1995-2024_sl-mon-eu.grib'

# ECSF parameters grouped by type
ecsf_temp_params = ['d2m', 't2m', 'mx2t24', 'mn2t24']
ecsf_stress_params = ['ewssra', 'nsssra']
ecsf_flux_params = ['mslhfl', 'msshfl', 'msnsrf', 'msdsrf', 'msntrf', 'msdtrf', 'mtnsrf', 'mtntrf']
ecsf_pressure_params = ['msl']
ecsf_water_params = ['tcc', 'tclw', 'tcwv', 'tprate', 'erate']

# ERA5 parameters grouped by type
era5_temp_params = ['2d', '2t']
era5_flux_params = ['slhf', 'sshf', 'ssr', 'str', 'ssrd', 'strd', 'tsr', 'ttr']
era5_pressure_params = ['msl', 'z']
era5_water_params = ['tcc', 'tclw', 'tcwv', 'tp', 'e']
era5_wind_params = ['ewss', 'nsss', 'kx']
era5_surface_params = ['lsm']

print("Loading ECSF data using multiple dataset approach...")
ecsf_datasets = []

# Try loading different parameter groups separately
try:
    ecsf_temp = xr.open_dataset(ecsf_file, engine='cfgrib',
                          backend_kwargs={
                              'filter_by_keys': {'typeOfLevel': 'surface'},
                              'indexpath': '',
                              'time_dims': ('valid_time', 'verifying_time')
                          })[ecsf_temp_params]
    ecsf_datasets.append(ecsf_temp)
except Exception as e:
    print(f"Error loading ECSF temperature parameters: {e}")

try:
    ecsf_stress = xr.open_dataset(ecsf_file, engine='cfgrib',
                          backend_kwargs={
                              'filter_by_keys': {'typeOfLevel': 'surface'},
                              'indexpath': '',
                              'time_dims': ('valid_time', 'verifying_time')
                          })[ecsf_stress_params]
    ecsf_datasets.append(ecsf_stress)
except Exception as e:
    print(f"Error loading ECSF stress parameters: {e}")

try:
    ecsf_flux = xr.open_dataset(ecsf_file, engine='cfgrib',
                          backend_kwargs={
                              'filter_by_keys': {'typeOfLevel': 'surface'},
                              'indexpath': '',
                              'time_dims': ('valid_time', 'verifying_time')
                          })[ecsf_flux_params]
    ecsf_datasets.append(ecsf_flux)
except Exception as e:
    print(f"Error loading ECSF flux parameters: {e}")

try:
    ecsf_pressure = xr.open_dataset(ecsf_file, engine='cfgrib',
                          backend_kwargs={
                              'filter_by_keys': {'typeOfLevel': 'surface'},
                              'indexpath': '',
                              'time_dims': ('valid_time', 'verifying_time')
                          })[ecsf_pressure_params]
    ecsf_datasets.append(ecsf_pressure)
except Exception as e:
    print(f"Error loading ECSF pressure parameters: {e}")

try:
    ecsf_water = xr.open_dataset(ecsf_file, engine='cfgrib',
                          backend_kwargs={
                              'filter_by_keys': {'typeOfLevel': 'surface'},
                              'indexpath': '',
                              'time_dims': ('valid_time', 'verifying_time')
                          })[ecsf_water_params]
    ecsf_datasets.append(ecsf_water)
except Exception as e:
    print(f"Error loading ECSF water parameters: {e}")

# Merge all ECSF datasets
if ecsf_datasets:
    ecsf_ds = xr.merge(ecsf_datasets, compat='override')
    print(f"ECSF datasets merged with variables: {list(ecsf_ds.data_vars)}")
else:
    ecsf_ds = None
    print("No ECSF datasets could be loaded")

print("Loading ERA5 data using multiple dataset approach...")
era5_datasets = []

# Try loading different parameter groups separately
try:
    era5_temp = xr.open_dataset(era5_file, engine='cfgrib',
                          backend_kwargs={
                              'filter_by_keys': {'typeOfLevel': 'surface'},
                              'indexpath': '',
                              'time_dims': ('valid_time', 'verifying_time')
                          })[era5_temp_params]
    era5_datasets.append(era5_temp)
except Exception as e:
    print(f"Error loading ERA5 temperature parameters: {e}")

try:
    era5_flux = xr.open_dataset(era5_file, engine='cfgrib',
                          backend_kwargs={
                              'filter_by_keys': {'typeOfLevel': 'surface'},
                              'indexpath': '',
                              'time_dims': ('valid_time', 'verifying_time')
                          })[era5_flux_params]
    era5_datasets.append(era5_flux)
except Exception as e:
    print(f"Error loading ERA5 flux parameters: {e}")

try:
    era5_pressure = xr.open_dataset(era5_file, engine='cfgrib',
                          backend_kwargs={
                              'filter_by_keys': {'typeOfLevel': 'surface'},
                              'indexpath': '',
                              'time_dims': ('valid_time', 'verifying_time')
                          })[era5_pressure_params]
    era5_datasets.append(era5_pressure)
except Exception as e:
    print(f"Error loading ERA5 pressure parameters: {e}")

try:
    era5_water = xr.open_dataset(era5_file, engine='cfgrib',
                          backend_kwargs={
                              'filter_by_keys': {'typeOfLevel': 'surface'},
                              'indexpath': '',
                              'time_dims': ('valid_time', 'verifying_time')
                          })[era5_water_params]
    era5_datasets.append(era5_water)
except Exception as e:
    print(f"Error loading ERA5 water parameters: {e}")

try:
    era5_wind = xr.open_dataset(era5_file, engine='cfgrib',
                          backend_kwargs={
                              'filter_by_keys': {'typeOfLevel': 'surface'},
                              'indexpath': '',
                              'time_dims': ('valid_time', 'verifying_time')
                          })[era5_wind_params]
    era5_datasets.append(era5_wind)
except Exception as e:
    print(f"Error loading ERA5 wind parameters: {e}")

try:
    era5_surface = xr.open_dataset(era5_file, engine='cfgrib',
                          backend_kwargs={
                              'filter_by_keys': {'typeOfLevel': 'surface'},
                              'indexpath': '',
                              'time_dims': ('valid_time', 'verifying_time')
                          })[era5_surface_params]
    era5_datasets.append(era5_surface)
except Exception as e:
    print(f"Error loading ERA5 surface parameters: {e}")

# Merge all ERA5 datasets
if era5_datasets:
    era5_ds = xr.merge(era5_datasets, compat='override')
    print(f"ERA5 datasets merged with variables: {list(era5_ds.data_vars)}")
else:
    era5_ds = None
    print("No ERA5 datasets could be loaded")

# Convert datasets to DataFrames
print("Converting to DataFrames...")
if ecsf_ds is not None:
    ecsf_df = ecsf_ds.to_dataframe()
    ecsf_df = ecsf_df.reset_index()
    print(f"ECSF DataFrame shape: {ecsf_df.shape}")
    print("\nECSF DataFrame head:")
    print(ecsf_df.head())

if era5_ds is not None:
    era5_df = era5_ds.to_dataframe()
    era5_df = era5_df.reset_index()
    print(f"\nERA5 DataFrame shape: {era5_df.shape}")
    print("\nERA5 DataFrame head:")
    print(era5_df.head())

# Optionally merge DataFrames if both exist
if ecsf_ds is not None and era5_ds is not None:
    print("\nCreating merged DataFrame...")
    
    # Define mapping between ECSF and ERA5 parameter names
    ecsf_to_era5_mapping = {
        'd2m': '2d',           # Direct match - 2m dewpoint temperature
        't2m': '2t',           # Direct match - 2m temperature
        'msl': 'msl',          # Direct match - Mean sea level pressure
        'ewssra': 'ewss',      # Accumulated vs instantaneous - Eastward turbulent surface stress
        'erate': 'e',          # Rate vs amount - Evaporation
        'nsssra': 'nsss',      # Accumulated vs instantaneous - Northward turbulent surface stress
        'mslhfl': 'slhf',      # Different naming - Surface latent heat flux
        'msshfl': 'sshf',      # Different naming - Surface sensible heat flux
        'msnsrf': 'ssr',       # Different naming - Surface net solar radiation
        'msdsrf': 'ssrd',      # Different naming - Surface downward solar radiation
        'msntrf': 'str',       # Different naming - Surface net thermal radiation
        'msdtrf': 'strd',      # Different naming - Surface downward thermal radiation
        'mtnsrf': 'tsr',       # Different naming - Top net solar radiation
        'mtntrf': 'ttr',       # Different naming - Top net thermal radiation
        'tcc': 'tcc',          # Direct match - Total cloud cover
        'tclw': 'tclw',        # Direct match - Total column liquid water
        'tcwv': 'tcwv',        # Direct match - Total column water vapor
        'tprate': 'tp',        # Rate vs amount - Precipitation
    }
    
    # Create a common index across both datasets
    merged_df = pd.merge(
        ecsf_df, 
        era5_df,
        on=['latitude', 'longitude', 'valid_time'],
        how='inner',
        suffixes=('_ecsf', '_era5')
    )
    
    print(f"\nMerged DataFrame shape: {merged_df.shape}")
    print("\nMerged DataFrame head:")
    print(merged_df.head())

executionTime = (time.time() - startTime)
print(f'\nExecution time in minutes: {executionTime/60:.2f}')

