import xarray as xr
import cfgrib,time,sys
import pandas as pd
import numpy as np
import xgboost as xgb

file='/home/ubuntu/data/xgb-bias/yearly-controls/ECSF_2023_sfc-era5.grib'
ds=xr.open_dataset(file, engine='cfgrib',
                   backend_kwargs={'indexpath': ''}, decode_timedelta=True)

print(ds)
df=ds.to_dataframe()
print(df)
