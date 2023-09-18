import xarray as xr
import cfgrib,time,sys
import pandas as pd
import numpy as np
import xgboost as xgb
startTime=time.time()
# Prediction for swi2
pd.set_option('mode.chained_assignment', None) # turn off SettingWithCopyWarning 
path='/home/ubuntu/data/'

file1='grib/SWIC_20000101T000000_2020_2015-2022_swis-ydaymean-eu-9km-fix.grib'
file2='grib/SWIC_20000101T000000_2020_2015-2022_swis-ydaymean-eu-9km-2-fix.grib'
print('moi')
swi2clim1=xr.open_dataset(path+file1, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))['swi2']
swi2clim2=xr.open_dataset(path+file2, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))['swi2']

print('moikka')
swi2clim=xr.merge([swi2clim1,swi2clim2],compat='override')
print(swi2clim)
#ds_swic = swi2clim.sel(
#    valid_time=slice('2020-08-02', '2021-03-03'))
#swi2clim=[]
#print('ciao')
print(swi2clim.to_dataframe())

executionTime=(time.time()-startTime)
print('Fitting execution time per member in minutes: %.2f'%(executionTime/60))
