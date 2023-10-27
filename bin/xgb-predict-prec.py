import xarray as xr
import cfgrib,pandas,time,sys
import xgboost as xgb
startTime=time.time()

'''
test with
python3 /home/ubuntu/bin/xgb-predict-prec.py ens/ec-sf-${grid}_$year${month}_disacc-$abr-5.grib ens/ec-sf-${grid}_$year${month}_pl-pp-12h-$abr-5.grib ens/ec-sf-${grid}_$year${month}_all-24h-$abr-5.grib ens/$grid-orography-$year${month}-$abr.grib ens/ECX${bsf}_$year${month}_tp-$abr-disacc-5.nc
'''

mod_dir='/home/ubuntu/data/MLmodels/'

# cmd: ensemble member pl, sl, era5 orography input gribs, outfile-name
disacc_ecsf = sys.argv[1] # ecsf disaccumulated data
pl_ecsf = sys.argv[2] # ecsf pressure level data at 00
sl_ecsf = sys.argv[3] # ecsf single-level data at 00
oro_era5 = sys.argv[4] # era5 orography 
outFile = sys.argv[5] # result output

cols=['latitude','longitude', 'anor','e','kx','lsm','mn2t24','msl',
        'mx2t24', 'q500','q700','q850','ro','rsn','sd','sdor',
        'sf', 'slhf','slor','sshf','ssr','ssrd','strd', 't2m','t500',
        't700','t850','tcc','d2m','tp', 'tsr','ttr','u10',
        'u500','u700','u850','v10', 'v500', 'v850','z',
        'z700','z850', 'dayOfYear']
'''
preds=['latitude','longitude', 'anor','evap','kx-00','lsm','mn2t-00','msl-00',
        'mx2t-00', 'q500-00','q700-00','q850-00','ro','rsn-00','sd-00','sdor',
        'sf', 'slhf','slor','sshf','ssr','ssrd','strd', 't2m-00','t500-00',
        't700-00','t850-00','tcc-00','td2m-00','tp', 'tsr','ttr','u10-00',
        'u500-00','u700-00','u850-00','v10-00', 'v500-00', 'v850-00','z',
        'z700-00','z850-00', 'dayOfYear'
]
'''

# parameters for fitting
disacc_var=['tp','e','slhf','sshf','ro','strd','ssr','ssrd','sf','tsr','ttr']
pl_var = ['z','q','t','u','v','kx']
sl_var = ['u10','v10','d2m','t2m','msl','rsn','sd','tcc','mx2t24','mn2t24'] 
oro_var = ['sdor','slor','anor','z','lsm']
names500 = {'z':'z500','q':'q500','t':'t500','u':'u500','v':'v500'}
names700 = {'z':'z700','q':'q700','t':'t700','u':'u700','v':'v700'}
names850 = {'z':'z850','q':'q850','t':'t850','u':'u850','v':'v850','kx':'kx'}

pl850 = xr.open_dataset(pl_ecsf, engine='cfgrib',
                    backend_kwargs=dict(filter_by_keys= {'typeOfLevel': 'isobaricInhPa','level':850},time_dims=('valid_time','verifying_time'),indexpath=''))[pl_var].rename_vars(names850)
pl700 = xr.open_dataset(pl_ecsf, engine='cfgrib',
                    backend_kwargs=dict(filter_by_keys= {'typeOfLevel': 'isobaricInhPa','level':700},time_dims=('valid_time','verifying_time'),indexpath=''))[pl_var[:-1]].rename_vars(names700)
pl500 = xr.open_dataset(pl_ecsf, engine='cfgrib',
                    backend_kwargs=dict(filter_by_keys= {'typeOfLevel': 'isobaricInhPa','level':500},time_dims=('valid_time','verifying_time'),indexpath=''))[pl_var[:-1]].rename_vars(names500)
sl=xr.open_dataset(sl_ecsf, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))#[sl_var]
oro = xr.open_dataset(oro_era5, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))[oro_var]
disacc=xr.open_dataset(disacc_ecsf, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))[disacc_var]

ecsf=xr.merge([disacc,sl,pl850,pl700,pl500,oro],compat='override')
ecsf['dayOfYear']=ecsf.valid_time.dt.dayofyear        
ecsf_df=ecsf.to_dataframe()
ecsf_df=ecsf_df.reset_index() 
ecsf_df[['sdor', 'slor', 'anor','z','lsm']] = ecsf_df[['sdor', 'slor', 'anor','z','lsm']].ffill() # fill in NaNs for forecast months
rescols=['valid_time','latitude','longitude']
df=ecsf_df.dropna()[rescols]
ecsf_df = ecsf_df.dropna()[cols]

### Predict with XGBoost fitted model 
mdl_name='mdl_RRweight_5441sta_2000-2020-5.txt'
fitted_mdl=xgb.XGBRegressor()
fitted_mdl.load_model(mod_dir+mdl_name)

print('start fit')
result=fitted_mdl.predict(ecsf_df)
print('end fit')

df['tp']=result.tolist()
# laita että jos alle 0.1mm sadetta niin on 0m df['tp']=df['tp']
df.loc[ df['tp'] < 0.0001, 'tp'] = 0.0 

df=df.set_index(['valid_time', 'latitude','longitude'])
#print(df[df['tp']>0])
print(df)
ds=df.to_xarray()
#print(ds)
##outFile='result.nc'
nc=ds.to_netcdf(outFile)
##ecsf_grib=cfgrib.xarray_to_grib(ecsf_ds,outFile)

executionTime=(time.time()-startTime)
print('Fitting execution time per member in minutes: %.2f'%(executionTime/60))