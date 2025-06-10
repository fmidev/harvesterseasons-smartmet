import xarray as xr
import time,sys
import numpy as np
import xgboost as xgb
import warnings
import pandas as pd
warnings.filterwarnings("ignore")
# SWI2 prediction with XGBoost for ECENS (ECXENS)
#startTime=time.time()

# input files
input1=sys.argv[1] # sl data
input2=sys.argv[2] # disaccumulated data
laihv=sys.argv[3] # laihv
lailv=sys.argv[4] # lailv
swi2clim=sys.argv[5] # swi2clim
dtm_aspect='ec-ens/COPERNICUS_20000101T000000_20110701_anor-dtm-aspect-avg_nd-era5l-fix.grib' # DTM ASPECT
dtm_slope='ec-ens/COPERNICUS_20000101T000000_20110701_slor-dtm-slope-avg_nd-era5l-fix.grib' # DTM SLOPE
dtm_height='ec-ens/COPERNICUS_20000101T000000_20110701_h-dtm-height-avg_nd-era5l-fix.grib' # DTM HEIGHT
soilgrids='ec-ens/SG_20200501T000000_soilgrids-0-200cm-nd-era5l-fix.grib' # sand ssfr, silt soilp, clay scfr, soc stf
lakecov='ec-ens/ECC_20000101T000000_ilwaterc-frac-nd-9km.grib' # lake cover
urbancov='ec-ens/ECC_20000101T000000_urbanc-frac-nd-9km.grib' # urban cover
highveg='ec-ens/ECC_20000101T000000_hveg-frac-nd-9km.grib' # high vegetation cover
lowveg='ec-ens/ECC_20000101T000000_lveg-frac-nd-9km.grib' # low vegetation cover 
lakedepth='ec-ens/ECC_20000101T000000_ilwater-depth-nd-9km.grib' # lake depth
landcov='ec-ens/ECC_20000101T000000_lc-frac-nd-9km.grib' # land cover
soiltype='ec-ens/ECC_20000101T000000_soiltype-nd-9km.grib' # soil type
typehv='ec-ens/ECC_20000101T000000_hveg-type-nd-9km.grib' # type of high vegetation
typelv='ec-ens/ECC_20000101T000000_lveg-type-nd-9km.grib' # type of low vegetation 
            
output=sys.argv[6] # output file

mdl_name='MLmodels/mdl_swi2_2015-2022_10000points-noRunsums.txt'

# Read in data
sl_vars={'d2m':'td2-00','t2m':'t2-00','rsn':'rsn-00','sde':'sd-00'}
sl_sfc = xr.open_dataset(input1,engine='cfgrib',
    backend_kwargs={
        'time_dims': ('valid_time', 'verifying_time'),
        'indexpath': '',
        'filter_by_keys': {'typeOfLevel': 'surface'}
    })[sl_vars.keys()].rename_vars(sl_vars)
sl_sfc = sl_sfc.where(sl_sfc.valid_time.dt.strftime("%H:%M:%S") != "12:00:00", drop=True)

# stl1
stl1_var = {'stl1':'stl1-00'}
sl_stl1 = xr.open_dataset(input1,engine='cfgrib',
    backend_kwargs={
        'time_dims': ('valid_time', 'verifying_time'),
        'indexpath': '',    
        'filter_by_keys': {
            'shortName': 'stl1'
        }
    })[stl1_var.keys()].rename_vars(stl1_var)
sl_stl1 = sl_stl1.where(sl_stl1.valid_time.dt.strftime("%H:%M:%S") != "12:00:00", drop=True)

# swvl2
swvl2_var = {'swvl2':'swvl2-00'}
# swvl2
sl_swvl2 = xr.open_dataset(input1, engine='cfgrib', backend_kwargs={
    'time_dims': ('valid_time', 'verifying_time'),
    'indexpath': '',
    'filter_by_keys': {
        'shortName': 'swvl2'
    }
})[swvl2_var.keys()].rename_vars(swvl2_var)
sl_swvl2 = sl_swvl2.where(sl_swvl2.valid_time.dt.strftime("%H:%M:%S") != "12:00:00", drop=True)
sl_swvl2['dayOfYear']=sl_swvl2.valid_time.dt.dayofyear

# disaccumulated
sl_disacc_vars=['tp','e','slhf','sshf','ro','str','ssr','ssrd']
sl_disacc=xr.open_dataset(input2,engine='cfgrib',
    backend_kwargs={
        'time_dims': ('valid_time', 'verifying_time'),
        'indexpath': '',
        'filter_by_keys': {'typeOfLevel': 'surface'}
    })[sl_disacc_vars].rename_vars({'e':'evap'})
sl_disacc = sl_disacc.where(sl_disacc.valid_time.dt.strftime("%H:%M:%S") != "12:00:00", drop=True)
sl_disacc = sl_disacc.assign_coords(valid_time=sl_disacc.valid_time - pd.Timedelta(days=1)) # shift disaccumulated data to correct dates (24h accumulations)

# laihv
laihv_ds=xr.open_dataset(laihv, engine='cfgrib',
    backend_kwargs={
        'time_dims': ('valid_time','verifying_time'),
        'indexpath': ''
        }).rename_vars({'lai_hv':'laihv-00'})

# lailv
lailv_ds=xr.open_dataset(lailv, engine='cfgrib',
    backend_kwargs={
        'time_dims': ('valid_time','verifying_time'),
        'indexpath': ''
        }).rename_vars({'lai_lv':'lailv-00'})

# swi2clim
swi2clim=xr.open_dataset(swi2clim, engine='cfgrib',
    backend_kwargs={
        'time_dims': ('valid_time','verifying_time'),
        'indexpath': ''
        })['swi2'].to_dataset().rename_vars({'swi2':'swi2clim'})

# dtm
height=xr.open_dataset(dtm_height, engine='cfgrib',
    backend_kwargs={
        'time_dims': ('valid_time','verifying_time'),
        'indexpath': ''
        }).rename_vars({'h':'DTM_height'})
slope=xr.open_dataset(dtm_slope, engine='cfgrib',
    backend_kwargs={
        'time_dims': ('valid_time','verifying_time'),
        'indexpath': ''
        }).rename_vars({'slor':'DTM_slope'})
aspect=xr.open_dataset(dtm_aspect, engine='cfgrib',
    backend_kwargs={
        'time_dims': ('valid_time','verifying_time'),
        'indexpath': ''
        }).rename_vars({'anor':'DTM_aspect'})

# soilgrids
namesSG5={'scfr':'clay_0-5cm','ssfr':'sand_0-5cm','soilp':'silt_0-5cm','stf':'soc_0-5cm'}
namesSG15={'scfr':'clay_5-15cm','ssfr':'sand_5-15cm','soilp':'silt_5-15cm','stf':'soc_5-15cm'}
namesSG30={'scfr':'clay_15-30cm','ssfr':'sand_15-30cm','soilp':'silt_15-30cm','stf':'soc_15-30cm'}
soilg_ds=xr.open_dataset(soilgrids, engine='cfgrib',
    backend_kwargs={
        'time_dims': ('valid_time','verifying_time'),
        'indexpath': ''
        })
soilg_ds5=soilg_ds.where((soilg_ds.depthBelowLand<=0.10), drop=True).rename_vars(namesSG5).squeeze(["depthBelowLand"], drop=True) # use layers 0-30cm for swvl2
soilg_ds15=soilg_ds.where((soilg_ds.depthBelowLand<=0.20) & (soilg_ds.depthBelowLand>=0.10), drop=True).rename_vars(namesSG15).squeeze(["depthBelowLand"], drop=True) # use layers 0-30cm for swvl2
soilg_ds30=soilg_ds.where((soilg_ds.depthBelowLand<=0.40) & (soilg_ds.depthBelowLand>=0.20), drop=True).rename_vars(namesSG30).squeeze(["depthBelowLand"], drop=True) # use layers 0-30cm for swvl2

# ecc
lakecov_ds=xr.open_dataset(lakecov, engine='cfgrib',
    backend_kwargs={
        'time_dims': ('valid_time','verifying_time'),
        'indexpath': ''
        }).rename_vars({'cl':'lake_cover'})
hvc_ds=xr.open_dataset(highveg, engine='cfgrib',
    backend_kwargs={
        'time_dims': ('valid_time','verifying_time'),
        'indexpath': ''
        })
hlc_ds=xr.open_dataset(lowveg, engine='cfgrib',
    backend_kwargs={
        'time_dims': ('valid_time','verifying_time'),
        'indexpath': ''
        })
lakedepth_ds=xr.open_dataset(lakedepth, engine='cfgrib',
    backend_kwargs={
        'time_dims': ('valid_time','verifying_time'),
        'indexpath': ''
        }).rename_vars({'dl':'lake_depth'})
landcov_ds=xr.open_dataset(landcov, engine='cfgrib',
    backend_kwargs={
        'time_dims': ('valid_time','verifying_time'),
        'indexpath': ''
        }).rename_vars({'lsm':'land_cover'})
soilty_ds=xr.open_dataset(soiltype, engine='cfgrib',
    backend_kwargs={
        'time_dims': ('valid_time','verifying_time'),
        'indexpath': ''
        }).rename_vars({'slt':'soiltype'})
tvh_ds=xr.open_dataset(typehv, engine='cfgrib',
    backend_kwargs={
        'time_dims': ('valid_time','verifying_time'),
        'indexpath': ''
        })
tvl_ds=xr.open_dataset(typelv, engine='cfgrib',    
    backend_kwargs={
        'time_dims': ('valid_time','verifying_time'),
        'indexpath': ''
        })
ecc_ucov=xr.open_dataset(urbancov, engine='cfgrib',
    backend_kwargs={
        'time_dims': ('valid_time','verifying_time'),
        'indexpath': ''
        }).rename_vars({'cur':'urban_cover'})

ds=xr.merge([sl_sfc,sl_stl1,sl_swvl2,sl_disacc,
    height,slope,aspect,
    soilg_ds5,soilg_ds15,soilg_ds30,
    lakecov_ds,hvc_ds,hlc_ds,lakedepth_ds,landcov_ds,soilty_ds,tvh_ds,tvl_ds,ecc_ucov,
    laihv_ds,lailv_ds,swi2clim
    ],compat='override')
ds=ds.drop_vars(['number','surface','depthBelowLandLayer'])
#print(ds)
df=ds.to_dataframe() 
df=df.reset_index() 
df.rename(columns={'latitude': 'TH_LAT', 'longitude': 'TH_LONG'}, inplace=True)
#print(df.dropna())

# store grid for final result
df_grid=df[['valid_time','TH_LAT','TH_LONG']]
df_grid.rename(columns={'TH_LAT': 'latitude', 'TH_LONG': 'longitude'}, inplace=True)
df_grid['swi2'] = np.nan
df_grid=df_grid.set_index(['valid_time', 'latitude','longitude'])
        
df=df.dropna()
preds=['evap',
    'laihv-00','lailv-00','ro',
    'rsn-00','sd-00',
    'slhf','sshf','ssr','ssrd','stl1-00','str','swvl2-00','t2-00','td2-00',
    'tp',
    'swi2clim',
    'lake_cover','cvh','cvl','lake_depth','land_cover','soiltype','urban_cover','tvh','tvl',
    'TH_LAT','TH_LONG','DTM_height','DTM_slope','DTM_aspect',
    'clay_0-5cm','clay_15-30cm','clay_5-15cm',
    'sand_0-5cm','sand_15-30cm','sand_5-15cm',
    'silt_0-5cm','silt_15-30cm','silt_5-15cm',
    'soc_0-5cm','soc_15-30cm','soc_5-15cm',
    'dayOfYear']
df_preds = df[preds]
swicols=['valid_time','TH_LAT','TH_LONG']
df=df[swicols]
#print(df)
  
# Predict with XGBoost fitted model 
fitted_mdl=xgb.XGBRegressor() 
fitted_mdl.load_model(mdl_name)

result=fitted_mdl.predict(df_preds) 
df_preds=[]

df['swi2']=result.tolist()
df.rename(columns={'TH_LAT': 'latitude', 'TH_LONG': 'longitude'}, inplace=True)
df.set_index(['valid_time', 'latitude', 'longitude'], inplace=True)
#print(df)
result=df_grid.fillna(df)
#print(result)#.dropna())
#print(result)
ds=result.to_xarray()
#print(ds)
nc=ds.to_netcdf(output)
#print(result.dropna())
#executionTime=(time.time()-startTime)
#print('Fitting execution time per member in minutes: %.2f'%(executionTime/60))