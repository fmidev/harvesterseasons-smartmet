#!/usr/bin/env python3
# filepath: /home/ubuntu/bin/make-training-data.py

import xarray as xr
import cfgrib
import pandas as pd
import os
import sys
import numpy as np

# File path
ecsf_file = '/home/ubuntu/data/era5/ECSF_19950101T000000_1995-2024_sl-mon-era5-eu-fix.grib'
era5_file = '/home/ubuntu/data/era5/ERA5_19950101T000000_1995-2024_sl-mon-eu.grib'
output_dir = '/home/ubuntu/data/ml-training-data'

# ECSF parameters
ecsf_param_names = [
    #'10u',    # 10m u-component of wind
    #'10v',    # 10m v-component of wind
    #'10fg',   # 10m wind gust
    '2d',     # 2m dewpoint temperature
    '2t',     # 2m temperature
    'ewssra', # Eastward turbulent surface stress accumulated
    'erate',  # Evaporation rate
    'mx2t24', # Maximum 2m temperature in the past 24 hours
    'msl',    # Mean sea level pressure
    'mn2t24', # Minimum 2m temperature in the past 24 hours
    'nsssra', # Northward turbulent surface stress accumulated
    'mslhfl', # Mean sea level latent heat flux
    'msshfl', # Mean surface sensible heat flux
    'msnsrf', # Mean surface net solar radiation flux
    'msdsrf', # Mean surface downward solar radiation flux
    'msntrf', # Mean surface net thermal radiation flux
    'msdtrf', # Mean surface downward thermal radiation flux
    'mtnsrf', # Mean top net solar radiation flux
    'mtntrf', # Mean top net thermal radiation flux
    'tcc',    # Total cloud cover
    'tclw',   # Total column liquid water
    'tcwv',   # Total column water vapour
    'tprate'  # Total precipitation rate
]

# ERA5 parameters
era5_param_names = [
    '2d',    # 2m dewpoint temperature
    '2t',    # 2m temperature
    'msl',   # Mean sea level pressure
    'tp',    # Total precipitation
    'slhf',  # Surface latent heat flux
    'ssr',   # Surface net solar radiation
    'str',   # Surface net thermal radiation
    'sshf',  # Surface sensible heat flux
    'ssrd',  # Surface solar radiation downwards
    'strd',  # Surface thermal radiation downwards
    'tsr',   # Top net solar radiation
    'ttr',   # Top net thermal radiation
    'tcc',   # Total cloud cover
    'tclw',  # Total column liquid water
    'e',     # Evaporation
    'ewss',  # Eastward turbulent surface stress
    'nsss',  # Northward turbulent surface stress
    'z',     # Geopotential
    'kx',    # K index
    'tcwv',  # Total column water vapour
    'lsm'    # Land-sea mask
]

# Mapping ECSF parameters to ERA5 equivalents
ecsf_to_era5_mapping = {
    '2d': '2d',           # Direct match - 2m dewpoint temperature
    '2t': '2t',           # Direct match - 2m temperature
    'msl': 'msl',         # Direct match - Mean sea level pressure
    'ewssra': 'ewss',     # Accumulated vs instantaneous - Eastward turbulent surface stress
    'erate': 'e',         # Rate vs amount - Evaporation
    'nsssra': 'nsss',     # Accumulated vs instantaneous - Northward turbulent surface stress
    'mslhfl': 'slhf',     # Different naming - Surface latent heat flux
    'msshfl': 'sshf',     # Different naming - Surface sensible heat flux
    'msnsrf': 'ssr',      # Different naming - Surface net solar radiation
    'msdsrf': 'ssrd',     # Different naming - Surface downward solar radiation
    'msntrf': 'str',      # Different naming - Surface net thermal radiation
    'msdtrf': 'strd',     # Different naming - Surface downward thermal radiation
    'mtnsrf': 'tsr',      # Different naming - Top net solar radiation
    'mtntrf': 'ttr',      # Different naming - Top net thermal radiation
    'tcc': 'tcc',         # Direct match - Total cloud cover
    'tclw': 'tclw',       # Direct match - Total column liquid water
    'tcwv': 'tcwv',       # Direct match - Total column water vapor
    'tprate': 'tp',       # Rate vs amount - Precipitation
    
    # No direct ERA5 equivalents in the provided list
    'mx2t24': None,       # Maximum 2m temperature in the past 24 hours
    'mn2t24': None,       # Minimum 2m temperature in the past 24 hours
}

# ERA5 parameters with no ECSF equivalent
era5_unique_params = [param for param in era5_param_names if param not in ecsf_to_era5_mapping.values()]
# Will include: 'z', 'kx', 'lsm'

# Create a combined parameter list without duplicates
all_param_names = list(set(ecsf_param_names + era5_param_names))

ecsf=xr.open_dataset(ecsf_file, engine='cfgrib',
                     backend_kwargs=dict(filter_by_keys= {'typeOfLevel': 'surface'},time_dims=('valid_time','verifying_time'),indexpath=''))#[ecsf_param_names]

ecsf_df=ecsf.to_dataframe()
print(ecsf_df.columns.tolist())