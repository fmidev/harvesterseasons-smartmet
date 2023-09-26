import xarray as xr
import cfgrib,time,sys
import pandas as pd
import numpy as np
import xgboost as xgb
startTime=time.time()
# Prediction for swi2
pd.set_option('mode.chained_assignment', None) # turn off SettingWithCopyWarning 

#mod_dir='/home/ubuntu/data/ML/models/soilwater/' # saved mdl
#data_dir='/home/ubuntu/data/ens/'

# input files 
swvls_ecsf=sys.argv[1] # vsw (swvl layers)
sl00_ecsf=sys.argv[2] # u10,v10,d2m,t2m,rsn,sd,stl1
sl_runsum=sys.argv[3] # 15-day runnins sums for disaccumulated tp,e,ro
sl_disacc=sys.argv[4] # disaccumulated tp,e,slhf,sshf,ro,str,strd,ssr,ssrd,sf 
laihv='grib/ECC_20000101T000000_laihv-eu-day.grib' 
lailv='grib/ECC_20000101T000000_lailv-eu-day.grib' 
dtm_aspect='grib/COPERNICUS_20000101T000000_20110701T000000_anor-dtm-aspect-avg_eu-era5l.grb' 
dtm_slope='grib/COPERNICUS_20000101T000000_20110701T000000_slor-dtm-slope-avg_eu-era5l.grb'
dtm_height='grib/COPERNICUS_20000101T000000_20110701T000000_h-dtm-height-avg_eu-era5l.grb'
soilgrids='grib/SG_20200501T000000_soilgrids-0-200cm-eu-era5l.grib' # sand ssfr, silt soilp, clay scfr, soc stf
lakecov='grib/ECC_20000101T000000_ilwaterc-frac-eu-9km-fix.grib' # lake cover
urbancov='grib/ECC_20000101T000000_urbanc-frac-eu-9km-fix.grib' # urban cover
highveg='grib/ECC_20000101T000000_hveg-frac-eu-9km-fix.grib' # high vegetation cover
lowveg='grib/ECC_20000101T000000_lveg-frac-eu-9km-fix.grib' # low vegetation cover 
lakedepth='grib/ECC_20000101T000000_ilwater-depth-eu-9km-fix.grib' # lake depth
landcov='grib/ECC_20000101T000000_lc-frac-eu-9km-fix.grib' # land cover
soiltype='grib/ECC_20000101T000000_soiltype-eu-9km-fix.grib' # soil type
typehv='grib/ECC_20000101T000000_hveg-type-eu-9km-fix.grib' # type of high vegetation
typelv='grib/ECC_20000101T000000_lveg-type-eu-9km-fix.grib' # type of low vegetation 
swi2c='grib/SWIC_20000101T000000_2020_2015-2022_swis-ydaymean-eu-9km-fixed.grib' # swi2 climate
outfile=sys.argv[5]

# read in swvl2 
swvls=xr.open_dataset(swvls_ecsf, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
swvl_df=swvls.to_dataframe()
swvls=[]
swvl_df.reset_index(inplace=True)
swvl_df=swvl_df[['valid_time','depthBelowLandLayer','latitude','longitude','vsw']]
swvl_df[['depthBelowLandLayer','latitude','longitude']]=swvl_df[['depthBelowLandLayer','latitude','longitude']].astype('float32')
swvl_df['depthBelowLandLayer']=swvl_df['depthBelowLandLayer'].round(2)
swvl_df = swvl_df[swvl_df.depthBelowLandLayer == 0.07]
swvl_df.rename(columns = {'vsw':'swvl2-00'}, inplace = True)
swvl_df=swvl_df[['valid_time','latitude','longitude','swvl2-00']]
#print(swvl_df)

# sl, dtm, soilgrids, eccs
sl_UTC00_var = [#'u10','v10',
        'd2m','t2m',
        'rsn','sd','stl1'] # sde instead of sd?? FIX
dtm_var=['p3008','slor','anor']
sg_var=['clay_0-5cm','sand_0-5cm','silt_0-5cm','soc_0-5cm',
     'clay_5-15cm','sand_5-15cm','silt_5-15cm','soc_5-15cm',
     'clay_15-30cm','sand_15-30cm','silt_15-30cm','soc_15-30cm'
]
ecc_var=['cl','cvh','cvl','dl','lsm','slt','tvh','tvl','cur']
sl00=xr.open_dataset(sl00_ecsf, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))[sl_UTC00_var]
height=xr.open_dataset(dtm_height, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
slope=xr.open_dataset(dtm_slope, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
aspect=xr.open_dataset(dtm_aspect, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
soilg_ds=xr.open_dataset(soilgrids, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
lakecov_ds=xr.open_dataset(lakecov, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
hvc_ds=xr.open_dataset(highveg, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
hlc_ds=xr.open_dataset(lowveg, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
lakedepth_ds=xr.open_dataset(lakedepth, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
landcov_ds=xr.open_dataset(landcov, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
soilty_ds=xr.open_dataset(soiltype, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
tvh_ds=xr.open_dataset(typehv, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
tvl_ds=xr.open_dataset(typelv, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
ecc_ucov=xr.open_dataset(urbancov, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
# sg
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
m1,sg_df1,sg_df2,sg_df3=[],[],[],[]
# dtm
dtm=xr.merge([height,slope,aspect],compat='override')
dtm=dtm.to_dataframe()
dtm=dtm.drop(columns='surface')
dtm.reset_index(inplace=True)
# ecc
ecc1996=xr.merge([tvh_ds,tvl_ds],compat='override')
tvh_ds,tvl_ds=[],[]
ecc2011=xr.merge([lakecov_ds,hvc_ds,hlc_ds,lakedepth_ds,landcov_ds,soilty_ds],compat='override')
lakecov_ds,hvc_ds,hlc_ds,lakedepth_ds,landcov_ds,soilty_ds=[],[],[],[],[],[]
ecc1996=ecc1996.to_dataframe()
ecc1996=ecc1996.drop(columns='surface')
ecc2011=ecc2011.to_dataframe()
ecc2011=ecc2011.drop(columns='surface')
ecc_ucov=ecc_ucov.to_dataframe()
ecc_ucov=ecc_ucov.drop(columns='surface')
ecc1996.reset_index(inplace=True)
ecc2011.reset_index(inplace=True)
ecc_ucov.reset_index(inplace=True)
# ecc, dtm and soilgrids have only 1 timestep: shift date, change NaN to -99999, merge with sls, reorder df,forward-fill in new dtm-NaNs, change -99999 back to NaN and drop nans
day1=swvl_df['valid_time'].iloc[0]
sg_df_all['valid_time'] = sg_df_all['valid_time'].replace('2020-05-01',day1)
dtm['valid_time'] = dtm['valid_time'].replace('2011-07-01',day1)
ecc1996['valid_time'] = ecc1996['valid_time'].replace('1996-01-01',day1)
ecc2011['valid_time'] = ecc2011['valid_time'].replace('2011-01-31',day1)
ecc_ucov['valid_time'] = ecc_ucov['valid_time'].replace('2020-06-15',day1)
ecc1=pd.merge(ecc1996,ecc2011, on=['valid_time','latitude','longitude'])
ecc=pd.merge(ecc1,ecc_ucov, on=['valid_time','latitude','longitude'])
#ecc.rename(columns = {}, inplace = True)
ecc1,ecc1996,ecc2011,ecc_ucov=[],[],[],[]
ecc=ecc.replace(np.nan,-99999)
sg_df_all = sg_df_all.replace(np.nan,-99999) 
dtm[['p3008','slor','anor']] = dtm[['p3008','slor','anor']].replace(np.nan,-99999) 
ecc=ecc.set_index(['latitude','longitude','valid_time'])
ecc=ecc.to_xarray()
sg_df_all=sg_df_all.set_index(['latitude','longitude','valid_time'])
sg_df_all=sg_df_all.to_xarray()
dtm=dtm.set_index(['latitude','longitude','valid_time'])
dtm=dtm.to_xarray()
ds1=xr.merge([sl00,dtm,sg_df_all,ecc],compat='override')
sl00,dtm,sg,ecc=[],[],[],[]
df1=ds1.to_dataframe() # > 69G memory usage (19.3G + tää ajo)
ds1=[]
df1=df1.drop(columns=['surface','depthBelowLandLayer'])
df1 = df1.reorder_levels(['latitude','longitude','valid_time']).sort_index() 
#print(df1) # check order
df1[dtm_var+sg_var+ecc_var] = df1[dtm_var+sg_var+ecc_var].fillna(method='ffill') # note: row order important
df1[dtm_var+sg_var+ecc_var] = df1[dtm_var+sg_var+ecc_var].replace(-99999,np.nan)
df1=df1.dropna()
df1.reset_index(inplace=True)
df1[['latitude','longitude']]=df1[['latitude','longitude']].astype('float32')
df1.rename(columns = {'d2m':'td2-00','t2m':'t2-00','rsn':'rsn-00','sd':'sd-00','stl1':'stl1-00','p3008':'DTM_height','slor':'DTM_slope','anor':'DTM_aspect','cl':'lake_cover','dl':'lake_depth','lsm':'land_cover','slt':'soiltype','cur':'urban_cover'}, inplace = True)
df2 = pd.merge(swvl_df,df1, on=['valid_time','latitude','longitude'])
df1,swvl_df=[],[]
#print(df2)


# disacc
sl_disacc_var=['tp','e','slhf','sshf','ro','str',#'strd',
               'ssr','ssrd'#,'sf'
               ]
sldisacc=xr.open_dataset(sl_disacc, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))[sl_disacc_var]
sldacc=sldisacc.to_dataframe()
sldisacc=[]
sldacc.reset_index(inplace=True)
sldacc=sldacc[['valid_time','latitude','longitude']+sl_disacc_var]
sldacc[['latitude','longitude']]=sldacc[['latitude','longitude']].astype('float32')
sldacc.rename(columns={'e':'evap'},inplace=True)
df_new=pd.merge(df2,sldacc,on=['valid_time','latitude','longitude'])
df2,sldacc=[],[]
#print(df_new)

### Read in runsums
sl_runsum_var=['tp','e','ro']
slrunsum=xr.open_dataset(sl_runsum, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))[sl_runsum_var]
runsum_df=slrunsum.to_dataframe()
slrunsum=[]
runsum_df.reset_index(inplace=True)
runsum_df=runsum_df[['valid_time','latitude','longitude']+sl_runsum_var]
runsum_df[['latitude','longitude']]=runsum_df[['latitude','longitude']].astype('float32')
runsum_df.rename(columns = {'ro':'ro15d','e':'evap15d','tp':'tp15d'}, inplace = True)
df3=pd.merge(df_new,runsum_df, on=['valid_time','latitude','longitude'])
# store grid for final result
df_grid=runsum_df[['valid_time','latitude','longitude']]
df_grid['swi2'] = np.nan
df_grid=df_grid.set_index(['valid_time', 'latitude','longitude'])
runsum_df,df_new=[],[]
#print(df3)

### Read in laihv lailv (12 utc) swi2clim (00 utc)
# mem use ~80G 
laihv_ds=xr.open_dataset(laihv, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
lailv_ds=xr.open_dataset(lailv, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
swi2clim=xr.open_dataset(swi2c, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))['swi2']
laids=xr.merge([laihv_ds,lailv_ds],compat='override')
laihv_ds,lailv_ds=[],[]
laidf=laids.to_dataframe()
swi2cs=swi2clim.to_dataframe()
swi2clim=[]
laidf.reset_index(inplace=True)
swi2cs.reset_index(inplace=True)
laidf['valid_time']=pd.to_datetime(laidf['valid_time'])
swi2cs['valid_time']=pd.to_datetime(swi2cs['valid_time'])
laidf['valid_time']=laidf['valid_time'].dt.date
laidf['valid_time']=pd.to_datetime(laidf['valid_time'])
df4=pd.merge(laidf,swi2cs, on=['valid_time','latitude','longitude'])
laidf,swi2cs=[],[]
df4=df4[['valid_time','latitude','longitude','lai_hv','lai_lv','swi2']]
df4[['latitude','longitude']]=df4[['latitude','longitude']].astype('float32')
# shift dates
day1=str(day1)
mons=(int(day1[0:4])-2020)*12
df4['valid_time'] = pd.DatetimeIndex( df4['valid_time'] ) + pd.DateOffset(months = mons)
df4.rename(columns = {'lai_lv':'lailv-00','lai_hv':'laihv-00','swi2':'swi2clim'}, inplace = True)
df=pd.merge(df3,df4, on=['valid_time','latitude','longitude'])
df3,df4=[],[]

df['valid_time']=pd.to_datetime(df['valid_time'])
df['dayOfYear'] = df['valid_time'].dt.dayofyear
df.rename(columns = {'latitude':'TH_LAT', 'longitude':'TH_LONG'}, inplace = True)

df=df.dropna()
#print(df)
swicols=['valid_time','TH_LAT','TH_LONG']
preds=['evap','evap15d',
        'laihv-00','lailv-00',
        'ro','ro15d','rsn-00','sd-00',
        'slhf','sshf','ssr','ssrd',
        'stl1-00','str','swvl2-00','t2-00','td2-00',
        'tp','tp15d',
        'swi2clim',
        'lake_cover','cvh','cvl','lake_depth','land_cover','soiltype','urban_cover','tvh','tvl',
        'TH_LAT','TH_LONG','DTM_height','DTM_slope','DTM_aspect',
        'clay_0-5cm','clay_15-30cm','clay_5-15cm',
        'sand_0-5cm','sand_15-30cm','sand_5-15cm',
        'silt_0-5cm','silt_15-30cm','silt_5-15cm',
        'soc_0-5cm','soc_15-30cm','soc_5-15cm',
        'dayOfYear']
df_preds = df[preds]
df=df[swicols]

### Predict with XGBoost fitted model 
mdl_name='MLmodels/mdl_swi2_2015-2022_10000points-13.txt'
fitted_mdl=xgb.XGBRegressor()
fitted_mdl.load_model(mdl_name)

print('start fit')
result=fitted_mdl.predict(df_preds)
print('end fit')

# result df to ds, and nc file as output
df['swi2']=result.tolist()
df.rename(columns = {'TH_LAT':'latitude','TH_LONG':'longitude'}, inplace = True)
df=df.set_index(['valid_time', 'latitude','longitude'])
print(df)
result=df_grid.fillna(df)
#print(result)
ds=result.to_xarray()
#print(ds)
nc=ds.to_netcdf(outfile)

executionTime=(time.time()-startTime)
print('Fitting execution time per member in minutes: %.2f'%(executionTime/60))
