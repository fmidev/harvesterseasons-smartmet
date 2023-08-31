import xarray as xr
import cfgrib,time,sys
import pandas as pd
import numpy as np
import xgboost as xgb

file='/home/ubuntu/data/grib/SWI_20000101T000000_SWI_202007261200_swis.grib'
swi_ds=xr.open_dataset(file, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
print(swi_ds)
swi_df=swi_ds.to_dataframe()
#print(swi_df)

file='/home/ubuntu/data/ens/ec-sf_era5l_202308_sl00utc-24h-eu-23.grib'
sl_UTC00_var = ['u10'] 
sl00=xr.open_dataset(file, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))[sl_UTC00_var]
print(sl00)
