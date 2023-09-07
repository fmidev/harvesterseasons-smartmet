import xarray as xr
import cfgrib,time,sys
import pandas as pd
import numpy as np
import xgboost as xgb
import datetime

# general testing python script for stuff... can be removed
startTime=time.time()
soilgrids='/home/ubuntu/data/SG_2020050101T000000_soilgrids-0-200cm-eu-era5l.grib' # sand ssfr, silt soilp, clay scfr, soc stf

soilg_ds=xr.open_dataset(soilgrids, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
print(soilg_ds)
executionTime=(time.time()-startTime)
print('Fitting execution time per member in minutes: %.2f'%(executionTime/60))
