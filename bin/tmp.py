import xarray as xr
import cfgrib,time,sys
import pandas as pd
import numpy as np
import xgboost as xgb
startTime=time.time()
# Prediction for swi2
pd.set_option('mode.chained_assignment', None) # turn off SettingWithCopyWarning 
path='/home/ubuntu/data/'

file='grib/SWIC_20000101T000000_2020_2015-2022_swis-ydaymean.grib'

print('moi')
swi2clim=xr.open_dataset(path+file, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))['swi2']
print('moikka')
print(swi2clim)
ds_swic = swi2clim.sel(
    valid_time=slice('2020-08-02', '2021-03-03'))
swi2clim=[]
print('ciao')
print(ds_swic.to_dataframe())

executionTime=(time.time()-startTime)
print('Fitting execution time per member in minutes: %.2f'%(executionTime/60))
