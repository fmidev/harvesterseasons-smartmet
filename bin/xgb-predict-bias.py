import xarray as xr
import cfgrib, time, sys, json
import pandas as pd
import xgboost as xgb
import os,warnings
import numpy as np

warnings.filterwarnings("ignore") # ignore settingWithCopyWarning

i1=sys.argv[1] # input grib file
i2=sys.argv[2] # input grib file
i3=sys.argv[3] # input grib file
#ensmem = sys.argv[4] # ensemble member
target = sys.argv[4] # target variable in model
output = sys.argv[5] # output nc file

# import model
mod_dir='/home/ubuntu/data/MLmodels/xgb-bias/' # saved mdl
modname=mod_dir + 'xgb-bias_era5_ecsf_2020-2024_2t.json'
mdl=xgb.XGBRegressor()
mdl.load_model(modname)
required_columns = mdl.get_booster().feature_names
#print(f'Features in model {modname}: {required_columns}')
#print(f'Predicting {target} for ensemble member {ensmem}')

# Open and rename input data
# single level
sl = xr.open_dataset(i1, engine='cfgrib',
    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
vars_to_rename = ['t2m', 'd2m', 'u10', 'v10', 'fg10']
new_names = ['2t', '2d', '10u', '10v', '10fg']
sl = sl.rename(dict(zip(vars_to_rename, new_names)))

# pressure level 850 hPa
pl850 = xr.open_dataset(i2, engine='cfgrib',
    backend_kwargs=dict(filter_by_keys= {'typeOfLevel': 'isobaricInhPa','level':850},time_dims=('valid_time','verifying_time'),indexpath=''))
pl850 = pl850.rename({var: f"{var}850" for var in pl850.data_vars})
# pressure level 925 hPa
pl925 = xr.open_dataset(i2, engine='cfgrib',
    backend_kwargs=dict(filter_by_keys= {'typeOfLevel': 'isobaricInhPa','level':925},time_dims=('valid_time','verifying_time'),indexpath=''))
pl925 = pl925.rename({var: f"{var}925" for var in pl925.data_vars})
# era5 static orography
oro = xr.open_dataset(i3, engine='cfgrib',
    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
oro = oro.rename({var: f"ERA5_{var}" for var in oro.data_vars})
if 'valid_time' not in oro.dims:
    oro = oro.expand_dims(valid_time=[sl.valid_time[0]])
oro_expanded = oro.reindex(valid_time=sl.valid_time, method='ffill')

ecsf = xr.merge([sl, pl850, pl925, oro_expanded], compat='override')
# add lapse rate in K/km
g = 9.80665 # to convert geopotential in m2/s2 to m
ecsf['lrate'] = (ecsf['t850'] - ecsf['t925']) / (ecsf['z850']/g - ecsf['z925']/g) * 1000
# add month
ecsf = ecsf.assign_coords(month=ecsf.valid_time.dt.month)
# add season
season_map = xr.DataArray(
    [1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4],  # DJF=1, MAM=2, JJA=3, SON=4
    dims="month_index",
    coords={"month_index": np.arange(1,13)}
)
ecsf = ecsf.assign(season=season_map.sel(month_index=ecsf.month))

ecsf=ecsf.to_dataframe().reset_index()

# result is stored in df with shape as input
rescols=['valid_time','latitude','longitude']
df=ecsf.dropna()[rescols]

ecsf = ecsf.rename(columns={
    'latitude': 'lat',
    'longitude': 'lon',
})

df_fin = ecsf[required_columns]
#print(df_fin)

target_prediction = mdl.predict(df_fin)
df[target]=target_prediction.tolist()
df=df.set_index(['valid_time', 'latitude','longitude'])
#print(df)
ds=df.to_xarray()
ds = ds.sortby('latitude', ascending=False)
nc=ds.to_netcdf(output)


