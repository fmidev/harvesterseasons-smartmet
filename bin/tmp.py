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
laihv=path+'grib/ECC_20000101T000000_laihv-eu-day.grib' 
lailv=path+'grib/ECC_20000101T000000_lailv-eu-day.grib' 
swi2c=path+'grib/SWIC_20000101T000000_2020_2015-2022_swis-ydaymean-eu-9km-fixed.grib' # swi2 climate
swvls_ecsf=path+'ens/ec-sf_era5l_202308_swvls-24h-eu-5-fixLevs.grib'
soilgrids=path+'grib/SG_20200501T000000_soilgrids-0-200cm-eu-era5l.grib' # sand ssfr, silt soilp, clay scfr, soc stf

soilg_ds=xr.open_dataset(soilgrids, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
soilg_ds=xr.open_dataset(soilgrids, engine='cfgrib', 
                    backend_kwargs=dict(filter_by_keys= {'typeOfLevel': 'depthBelowLand','level':0.15},time_dims=('valid_time','verifying_time'),indexpath=''))

print(soilg_ds)
sg_df=soilg_ds.to_dataframe()
soilg_ds=[]
sg_df.reset_index(inplace=True)
sg_df=sg_df[['valid_time','depthBelowLand','latitude','longitude','scfr','ssfr','soilp','stf']]
sg_df['depthBelowLand']=sg_df['depthBelowLand'].round(2)
sg_df1 = sg_df[sg_df.depthBelowLand == 0.05]
sg_df2 = sg_df[sg_df.depthBelowLand == 0.15]
sg_df3 = sg_df[sg_df.depthBelowLand == 0.3]
sg_df1 = sg_df1.drop(columns='depthBelowLand')
sg_df2 = sg_df2.drop(columns='depthBelowLand')
sg_df3 = sg_df3.drop(columns='depthBelowLand')
sg_df1.rename(columns = {'scfr':'clay_0-5cm','ssfr':'sand_0-5cm','soilp':'silt_0-5cm','stf':'soc_0-5cm'}, inplace = True)
sg_df2.rename(columns = {'scfr':'clay_5-15cm','ssfr':'sand_5-15cm','soilp':'silt_5-15cm','stf':'soc_5-15cm'}, inplace = True)
sg_df3.rename(columns = {'scfr':'clay_15-30cm','ssfr':'sand_15-30cm','soilp':'silt_15-30cm','stf':'soc_15-30cm'}, inplace = True)
m1=pd.merge(sg_df1,sg_df2, on=['valid_time','latitude','longitude'])
sg_df_all=pd.merge(m1,sg_df3, on=['valid_time','latitude','longitude'])
print(sg_df_all)


executionTime=(time.time()-startTime)
print('Fitting execution time per member in minutes: %.2f'%(executionTime/60))
