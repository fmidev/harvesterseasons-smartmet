import xarray as xr
import cfgrib,pandas,time,sys
import xgboost as xgb
startTime=time.time()

mod_dir='/home/ubuntu/mlbias/models/'

# cmd: ensemble member pl, sl, era5 orography input gribs, outfile-name
tp_ecsf = sys.argv[1] # ecsf disaccumulated precipitation data
pl_ecsf = sys.argv[2] # ecsf pressure level data
sl_ecsf = sys.argv[3] # ecsf single-level data
oro_era5 = sys.argv[4] # era5 orography 
outFile = sys.argv[5] # result output

cols=['tp','e','t2m','t850','t700','t500','d2m','msl','kx',
        'q850','q700','q500','u10','u850','u700','u500','v10','v850',
        'v700','v500','z','z850','z700','z500','sdor','slor','anor','tsr',
        'fg10','slhf', 'sshf','tcc','ro','sd','sf','rsn','stl1',
        'lsm','lat','lon'] 
'''
preds=['tp-m', 'e-m', 't2m-K', 't850-K', 't700-K', 't500-K', 'td-K', 
        'msl-Pa', 'kx', 'q850-kgkg', 'q700-kgkg', 'q500-kgkg', 'u10-ms', 
        'u850-ms', 'u700-ms', 'u500-ms', 'v10-ms', 'v850-ms', 'v700-ms', 
        'v500-ms', 'z-m', 'z850-m', 'z700-m', 'z500-m', 'sdor-m', 'slor', 
        'anor-rad', 'tsr-jm2', 'ffg-ms', 'slhf-Jm2', 'sshf-Jm2', 'tcc-0to1', 
        'ro-m', 'sd-kgm2', 'sf-kgm2', 'rsn-kgm2', 'stl1-K', 
        'lsm-0to1', 'LAT', 'LON']
        '''

# parameters for fitting
tp_var = ['tp']
pl_var = ['z','q','t','u','v','kx']
sl_var = ['u10','v10','fg10','d2m','t2m','e','msl',
        'ro','rsn','sd','sf','stl1','slhf','sshf','tsr','tcc'] 
oro_var = ['sdor','slor','anor','z','lsm']
names500 = {'z':'z500','q':'q500','t':'t500','u':'u500','v':'v500'}
names700 = {'z':'z700','q':'q700','t':'t700','u':'u700','v':'v700'}
names850 = {'z':'z850','q':'q850','t':'t850','u':'u850','v':'v850','kx':'kx'}

pl850 = xr.open_dataset(pl_ecsf, engine='cfgrib',
                    backend_kwargs=dict(filter_by_keys= {'typeOfLevel': 'isobaricInhPa','level':850},time_dims=('time','verifying_time'),indexpath=''))[pl_var].rename_vars(names850)
pl700 = xr.open_dataset(pl_ecsf, engine='cfgrib',
                    backend_kwargs=dict(filter_by_keys= {'typeOfLevel': 'isobaricInhPa','level':700},time_dims=('time','verifying_time'),indexpath=''))[pl_var[:-1]].rename_vars(names700)
pl500 = xr.open_dataset(pl_ecsf, engine='cfgrib',
                    backend_kwargs=dict(filter_by_keys= {'typeOfLevel': 'isobaricInhPa','level':500},time_dims=('time','verifying_time'),indexpath=''))[pl_var[:-1]].rename_vars(names500)
sl=xr.open_dataset(sl_ecsf, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('time','verifying_time'),indexpath=''))#[sl_var]
oro = xr.open_dataset(oro_era5, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('time','verifying_time'),indexpath=''))[oro_var]
tp=xr.open_dataset(tp_ecsf, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('time','verifying_time'),indexpath=''))[tp_var]

ecsf=xr.merge([tp,sl,pl850,pl700,pl500,oro],compat='override')
ecsf_df=ecsf.to_dataframe()
ecsf_df['lat'] = ecsf_df.index.get_level_values('latitude')
ecsf_df['lon'] = ecsf_df.index.get_level_values('longitude')
ecsf_df[['sdor', 'slor', 'anor','z','lsm']] = ecsf_df[['sdor', 'slor', 'anor','z','lsm']].fillna(method='ffill') # fill in NaNs for forecast months
ecsf_df = ecsf_df.dropna()[cols]
#print(ecsf_df)

### Predict with XGBoost fitted model 
mdl_name='bestmdl_100sta_2000-2020_ecsfparams+_poisson_RRweight.txt'
fitted_mdl=xgb.XGBRegressor()
fitted_mdl.load_model(grbmod_dir+mdl_name)

print('start fit')
result=fitted_mdl.predict(ecsf_df)
print('end fit')

ecsf_df['rain']=result.tolist()
ecsf_df=ecsf_df.drop(columns=cols)
ecsf_ds=ecsf_df.to_xarray().rename_vars({'rain':'tp'})
##outFile='result.nc'
ecsf_nc=ecsf_ds.to_netcdf(outFile)
##ecsf_grib=cfgrib.xarray_to_grib(ecsf_ds,outFile)

#executionTime=(time.time()-startTime)
##print('Fitting execution time per member in minutes: %.2f'%(executionTime/60))