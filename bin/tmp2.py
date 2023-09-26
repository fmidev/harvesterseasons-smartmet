import xarray as xr
import cfgrib,time,sys
import pandas as pd
import dask.dataframe as dd
import numpy as np
import xgboost as xgb
startTime=time.time()
# Prediction for swi2
pd.set_option('mode.chained_assignment', None) # turn off SettingWithCopyWarning 
path='/home/ubuntu/data/'

file=path+'ec-sf-202309-all-24h-eu.grib'
lakecov_ds=xr.open_dataset(file, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
print(lakecov_ds)
executionTime=(time.time()-startTime)
print('Fitting execution time per member in minutes: %.2f'%(executionTime/60))
