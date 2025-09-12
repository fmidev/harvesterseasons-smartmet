#!/usr/bin/env python3
import xarray as xr
import cfgrib, sys, time
import pandas as pd
import xgboost as xgb
import numpy as np
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score
import matplotlib.pyplot as plt
import cartopy.crs as ccrs
import cartopy.feature as cfeature

data_dir = '/home/ubuntu/data/xgb-bias/ensstats/'
d1 = '/home/ubuntu/data/xgb-bias/og_files'
sf=data_dir + 'ECSF_202001_all-ensmean-eu.grib'
ds = xr.open_dataset(f'{sf}',engine='cfgrib',backend_kwargs={'indexpath':''})
print(ds)
df=ds.to_dataframe().reset_index()
print(df)

sf=d1 + 'ECSF_20200101T000000_all-24h-eu.grib'
ds = xr.open_dataset(f'{sf}',engine='cfgrib',backend_kwargs={'indexpath':''})
ds = ds.sel(number=0)
print(ds)
df=ds.to_dataframe().reset_index()
print(df)