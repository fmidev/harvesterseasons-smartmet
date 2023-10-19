import xarray as xr
import cfgrib,time,sys
import pandas as pd
import dask.distributed
import numpy as np
import xgboost as xgb
startTime=time.time()
# Prediction for swi2
pd.set_option('mode.chained_assignment', None) # turn off SettingWithCopyWarning 
if __name__ == "__main__":
        cluster=dask.distributed.LocalCluster()
        client=dask.distributed.Client(cluster)
        #mod_dir='/home/ubuntu/data/ML/models/soilwater/' # saved mdl
        #data_dir='/home/ubuntu/data/ens/'

        # input files 
        swvls_ecsf=sys.argv[1] # vsw (swvl layers)
        sl00_ecsf=sys.argv[2] # u10,v10,d2m,t2m,rsn,sd,stl1
        sl_runsum=sys.argv[3] # 15-day runnins sums for disaccumulated tp,e,ro
        sl_disacc=sys.argv[4] # disaccumulated tp,e,slhf,sshf,ro,str,strd,ssr,ssrd,sf 
        laihv=sys.argv[5]
        lailv=sys.argv[6]
        swi2c=sys.argv[7] # swi2clim
        dtm_aspect='grib/COPERNICUS_20000101T000000_20110701_anor-dtm-aspect-avg_eu-swi.grb' 
        dtm_slope='grib/COPERNICUS_20000101T000000_20110701_slor-dtm-slope-avg_eu-swi.grb'
        dtm_height='grib/COPERNICUS_20000101T000000_20110701_h-dtm-height-avg_eu-swi.grb'
        #soilgrids='grib/SG_20200501T000000_soilgrids-0-200cm-eu-era5l.grib' # sand ssfr, silt soilp, clay scfr, soc stf
        lakecov='grib/ECC_20000101T000000_ilwaterc-frac-eu.grib' # lake cover
        urbancov='grib/ECC_20000101T000000_urbancov-eu-fix.grib' # urban cover
        highveg='grib/ECC_20000101T000000_hveg-frac-eu.grib' # high vegetation cover
        lowveg='grib/ECC_20000101T000000_lveg-frac-eu.grib' # low vegetation cover 
        lakedepth='grib/ECC_20000101T000000_ilwater-depth-eu.grib' # lake depth
        landcov='grib/ECC_20000101T000000_lc-frac-eu.grib' # land cover
        soiltype='grib/ECC_20000101T000000_soiltype-eu.grib' # soil type
        typehv='grib/ECC_20000101T000000_hveg-type-eu.grib' # type of high vegetation
        typelv='grib/ECC_20000101T000000_lveg-type-eu.grib' # type of low vegetation 
        # output file
        outfile=sys.argv[8]

        # read in swvl2 
        sl_UTC00_var = ['d2m','t2m','rsn','sd','stl1'] # sde instead of sd?? FIX
        names00UTC={'d2m':'td2-00','t2m':'t2-00','rsn':'rsn-00','sd':'sd-00','stl1':'stl1-00'}
        dtm_var=['h','slor','anor']
        sg_var=['clay_0-5cm','sand_0-5cm','silt_0-5cm','soc_0-5cm',
        'clay_5-15cm','sand_5-15cm','silt_5-15cm','soc_5-15cm',
        'clay_15-30cm','sand_15-30cm','silt_15-30cm','soc_15-30cm'
        ]
        sl_disacc_var=['tp','e','slhf','sshf','ro','str','ssr','ssrd'
                ]
        sl_runsum_var=['tp','e','ro']
        namesRS={'tp':'tp15d','e':'evap15d','ro':'ro15d'}
        #sand ssfr, silt soilp, clay scfr, soc stf
        namesSG5={'scfr':'clay_0-5cm','ssfr':'sand_0-5cm','soilp':'silt_0-5cm','stf':'soc_0-5cm'}
        namesSG15={'scfr':'clay_5-15cm','ssfr':'sand_5-15cm','soilp':'silt_5-15cm','stf':'soc_5-15cm'}
        namesSG30={'scfr':'clay_15-30cm','ssfr':'sand_15-30cm','soilp':'silt_15-30cm','stf':'soc_15-30cm'}
        ecc_var=['cl','cvh','cvl','dl','lsm','slt','tvh','tvl','cur']
        print('moi0')
        swvls=xr.open_dataset(swvls_ecsf, engine='cfgrib', chunks={'valid_time':1},
                        backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
        print('read swvls')
        executionTime=(time.time()-startTime)
        print('time %.2f'%(executionTime/60))
        sl00=xr.open_dataset(sl00_ecsf, engine='cfgrib',  chunks={'valid_time':1},
                        backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))[sl_UTC00_var].rename_vars(names00UTC)
        print('read sl00')
        executionTime=(time.time()-startTime)
        print('time %.2f'%(executionTime/60))
        height=xr.open_dataset(dtm_height, engine='cfgrib', chunks={'valid_time':100}, 
                        backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath='')).rename_vars({'h':'DTM_height'})
        print('read height')
        executionTime=(time.time()-startTime)
        print('time %.2f'%(executionTime/60))
        slope=xr.open_dataset(dtm_slope, engine='cfgrib',  chunks={'valid_time':100},
                        backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath='')).rename_vars({'slor':'DTM_slope'})
        print('read slope')
        executionTime=(time.time()-startTime)
        print('time %.2f'%(executionTime/60))
        aspect=xr.open_dataset(dtm_aspect, engine='cfgrib',  chunks={'valid_time':100},
                        backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath='')).rename_vars({'anor':'DTM_aspect'})
        print('read aspect')
        executionTime=(time.time()-startTime)
        print('time %.2f'%(executionTime/60))
        # soilg_ds=xr.open_dataset(soilgrids, engine='cfgrib',  chunks={'valid_time':100},
        #                 backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
        lakecov_ds=xr.open_dataset(lakecov, engine='cfgrib',  chunks={'valid_time':100},
                        backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath='')).rename_vars({'cl':'lake_cover'})
        executionTime=(time.time()-startTime)
        print('time %.2f'%(executionTime/60))
        hvc_ds=xr.open_dataset(highveg, engine='cfgrib',  chunks={'valid_time':100},
                        backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
        executionTime=(time.time()-startTime)
        print('time %.2f'%(executionTime/60))
        hlc_ds=xr.open_dataset(lowveg, engine='cfgrib',  chunks={'valid_time':100},
                        backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
        executionTime=(time.time()-startTime)
        print('time %.2f'%(executionTime/60))
        lakedepth_ds=xr.open_dataset(lakedepth, engine='cfgrib',  chunks={'valid_time':100},
                        backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath='')).rename_vars({'dl':'lake_depth'})
        executionTime=(time.time()-startTime)
        print('time %.2f'%(executionTime/60))
        landcov_ds=xr.open_dataset(landcov, engine='cfgrib',  chunks={'valid_time':100},
                        backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath='')).rename_vars({'lsm':'land_cover'})
        executionTime=(time.time()-startTime)
        print('time %.2f'%(executionTime/60))
        soilty_ds=xr.open_dataset(soiltype, engine='cfgrib',  chunks={'valid_time':100},
                        backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath='')).rename_vars({'slt':'soiltype'})
        executionTime=(time.time()-startTime)
        print('time %.2f'%(executionTime/60))
        tvh_ds=xr.open_dataset(typehv, engine='cfgrib',  chunks={'valid_time':100},
                        backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
        executionTime=(time.time()-startTime)
        print('time %.2f'%(executionTime/60))
        tvl_ds=xr.open_dataset(typelv, engine='cfgrib',  chunks={'valid_time':100},
                        backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
        executionTime=(time.time()-startTime)
        print('time %.2f'%(executionTime/60))
        ecc_ucov=xr.open_dataset(urbancov, engine='cfgrib',  chunks={'valid_time':100},
                        backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath='')).rename_vars({'cur':'urban_cover'})
        executionTime=(time.time()-startTime)
        print('time %.2f'%(executionTime/60))
        print('read ecc')
        sldisacc=xr.open_dataset(sl_disacc, engine='cfgrib', chunks={'valid_time':100},
                        backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))[sl_disacc_var].rename_vars({'e':'evap'})
        executionTime=(time.time()-startTime)
        print('time %.2f'%(executionTime/60))
        slrunsum=xr.open_dataset(sl_runsum, engine='cfgrib', chunks={'valid_time':100},
                        backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))[sl_runsum_var].rename_vars(namesRS)
        executionTime=(time.time()-startTime)
        print('time %.2f'%(executionTime/60))
        laihv_ds=xr.open_dataset(laihv, engine='cfgrib', chunks={'valid_time':100},
                        backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath='')).rename_vars({'lai_hv':'laihv-00'})
        executionTime=(time.time()-startTime)
        print('time %.2f'%(executionTime/60))
        lailv_ds=xr.open_dataset(lailv, engine='cfgrib', chunks={'valid_time':100},
                        backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath='')).rename_vars({'lai_lv':'lailv-00'})
        executionTime=(time.time()-startTime)
        print('time %.2f'%(executionTime/60))
        swi2clim=xr.open_dataset(swi2c, engine='cfgrib', chunks={'valid_time':100},
                        backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))['swi2'].to_dataset().rename_vars({'swi2':'swi2clim'})
        executionTime=(time.time()-startTime)
        print('time %.2f'%(executionTime/60))
        
        print('moi1')
        date_first=str(swvls.valid_time[0].data)[:10]
        date_last=str(swvls.valid_time[-1].data)[:10]   
        print(date_first, date_last)     
        swi2clim=swi2clim.sel(valid_time=slice(date_first,date_last))
        laihv_ds=laihv_ds.sel(valid_time=slice(date_first,date_last))
        lailv_ds=lailv_ds.sel(valid_time=slice(date_first,date_last))
        swvls=swvls.where((swvls.depthBelowLandLayer<=0.20) & (swvls.depthBelowLandLayer>=0.06), drop=True).rename_vars({'vsw':'swvl2-00'}).squeeze(["depthBelowLandLayer"], drop=True) # use layer 0.07 m for swvl2
        swvls['dayOfYear']=swvls.valid_time.dt.dayofyear
        #soilg_ds5=soilg_ds.where((soilg_ds.depthBelowLand<=0.10), drop=True).rename_vars(namesSG5).squeeze(["depthBelowLand"], drop=True) # use layers 0-30cm for swvl2
        #soilg_ds15=soilg_ds.where((soilg_ds.depthBelowLand<=0.20) & (soilg_ds.depthBelowLand>=0.10), drop=True).rename_vars(namesSG15).squeeze(["depthBelowLand"], drop=True) # use layers 0-30cm for swvl2
        #soilg_ds30=soilg_ds.where((soilg_ds.depthBelowLand<=0.40) & (soilg_ds.depthBelowLand>=0.20), drop=True).rename_vars(namesSG30).squeeze(["depthBelowLand"], drop=True) # use layers 0-30cm for swvl2
        print('merge')
        ds1=xr.merge([swvls,sl00,height,slope,aspect,#soilg_ds5,soilg_ds15,soilg_ds30,
                      lakecov_ds,hvc_ds,hlc_ds,lakedepth_ds,landcov_ds,soilty_ds,tvh_ds,tvl_ds,ecc_ucov,
                      sldisacc,slrunsum,laihv_ds,lailv_ds,swi2clim
                      ],compat='override')
        ds1=ds1.drop_vars(['number','surface','depthBelowLandLayer'])
        ds1=ds1.sel(valid_time=slice(date_first,date_last))
        print('ds1 print')
        print(ds1)
        print('start df')
        df=ds1.to_dataframe()
        print('end df')
        print(df)

        preds=['evap','evap15d',
        'laihv-00','lailv-00',
        'ro','ro15d','rsn-00','sd-00',
        'slhf','sshf','ssr','ssrd',
        'stl1-00','str','swvl2-00','t2-00','td2-00',
        'tp','tp15d',
        'swi2clim',
        'lake_cover','cvh','cvl','lake_depth','land_cover','soiltype','urban_cover','tvh','tvl',
        'latitude','longitude','DTM_height','DTM_slope','DTM_aspect',
        'clay_0-5cm','clay_15-30cm','clay_5-15cm',
        'sand_0-5cm','sand_15-30cm','sand_5-15cm',
        'silt_0-5cm','silt_15-30cm','silt_5-15cm',
        'soc_0-5cm','soc_15-30cm','soc_5-15cm',
        'dayOfYear']
        '''
        #df=ds1.to_dataframe()[preds] # pandas
        ds1=ds1.unify_chunks() # dask
        df=ds1.to_dask_dataframe()[preds] #dask
        #print(df)
        #df=df.reset_index() # pandas
        #print(df[df.valid_time == '2024-02-29'])
        df=df.dropna()
        #print(df.compute()) # dask
        #df=df.drop(columns=['latitude','longitude']) # pandsas
        #print(df)
        '''
        '''
        # store grid for final result
        df_grid=runsum_df[['valid_time','latitude','longitude']]
        df_grid['swi2'] = np.nan
        df_grid=df_grid.set_index(['valid_time', 'latitude','longitude'])

        swicols=['valid_time','TH_LAT','TH_LONG']
        df_preds = df[preds]
        df=df[swicols]
        '''
        '''

        ### Predict with XGBoost fitted model 
        mdl_name='MLmodels/mdl_swi2_2015-2022_10000points-13.txt'
        #fitted_mdl=xgb.XGBRegressor() # pandas
        fitted_mdl=xgb.Booster() # dask
        fitted_mdl.load_model(mdl_name)

        print('start fit')
        #result=fitted_mdl.predict(df_preds) # pandas
        result = xgb.dask.predict(client, fitted_mdl, df) # dask
        print('end fit')

        print(result)
        # result df to ds, and nc file as output
        #df['swi2']=result.tolist()
        #df.rename(columns = {'TH_LAT':'latitude','TH_LONG':'longitude'}, inplace = True)
        #df=df.set_index(['valid_time', 'latitude','longitude'])
        #print(df)
        #result=df_grid.fillna(df)
        #print(result)
        #ds=result.to_xarray()
        #print(ds)
        #nc=ds.to_netcdf(outfile)
        '''
        executionTime=(time.time()-startTime)
        print('Fitting execution time per member in minutes: %.2f'%(executionTime/60))
