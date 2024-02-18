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
        sl00_ecsf=sys.argv[2] # d2m,t2m,rsn,sde,stl1

        sl_disacc=sys.argv[3] # disaccumulated tp,e,slhf,sshf,ro,str,strd,ssr,ssrd,skt
        sktn=sys.argv[4] # sktn

        laihv=sys.argv[5]
        lailv=sys.argv[6]
        stl2=sys.argv[7]
        skt_amsrc=sys.argv[8]

        dtm_aspect='/home/ubuntu/data/grib/COPERNICUS_20000101T000000_aspect-eu-edte.grib' # aspect
        dtm_slope='/home/ubuntu/data/grib/COPERNICUS_20000101T000000_slope-eu-edte.grib' # slope
        dtm_height='/home/ubuntu/data/grib/COPERNICUS_20000101T000000_dtm-eu-edte.grib' # height

        # output file
        outfile=sys.argv[9]

        # read in data
        sl_UTC00_var = ['u10','v10','d2m','t2m','rsn','sde','stl1'] 
        names00UTC={'u10':'u10-00','v10':'v10-00','d2m':'td2-00',
                    't2m':'t2-00','rsn':'rsn-00',
                    'sde':'sd-00','stl1':'stl1-00'}
        dtm_var=['h','slor','anor']
        sl_disacc_var=['tp','e','slhf','sshf','ro','str','strd','ssr','ssrd','skt']
        
        namesRS={'tp':'tp-00',
                 'e':'evapp',
                 'slhf':'slhf',
                 'sshf':'sshf',
                 'ro':'ro',
                 'str': 'str',
                 'strd':'strd',
                 'ssr':'ssr',
                 'ssrd':'ssrd',
                 'skt':'skt-00'}
 
        swvls=xr.open_dataset(swvls_ecsf, engine='cfgrib', chunks={'valid_time':1},
                        backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath='')).rename_vars({'swvl2':'swvl2-00'})
        sl00=xr.open_dataset(sl00_ecsf, engine='cfgrib',  chunks={'valid_time':1},
                        backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))[sl_UTC00_var].rename_vars(names00UTC)
        sldisacc=xr.open_dataset(sl_disacc, engine='cfgrib', chunks={'valid_time':1},
                        backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))[sl_disacc_var].rename_vars(namesRS)
        sktn_ds=xr.open_dataset(sktn, engine='cfgrib', chunks={'valid_time':1},
                        backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath='')).rename_vars({'skt':'sktn'})
        height=xr.open_dataset(dtm_height, engine='cfgrib', chunks={'valid_time':1}, 
                        backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath='')).rename_vars({'h':'DTM_height'})
        slope=xr.open_dataset(dtm_slope, engine='cfgrib',  chunks={'valid_time':1},
                        backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath='')).rename_vars({'slor':'DTM_slope'})
        aspect=xr.open_dataset(dtm_aspect, engine='cfgrib',  chunks={'valid_time':1},
                        backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath='')).rename_vars({'anor':'DTM_aspect'})
        laihv_ds=xr.open_dataset(laihv, engine='cfgrib', chunks={'valid_time':1},
                        backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath='')).rename_vars({'lai_hv':'laihv-00'})
        lailv_ds=xr.open_dataset(lailv, engine='cfgrib', chunks={'valid_time':1},
                        backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath='')).rename_vars({'lai_lv':'lailv-00'})
        stl2_ds=xr.open_dataset(stl2, engine='cfgrib', chunks={'valid_time':1},
                        backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath='')).rename_vars({'stl2':'stl2-00'})
        skt_ds=xr.open_dataset(skt_amsrc, engine='cfgrib', chunks={'valid_time':1},
                               backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))

        date_first=str(swvls.valid_time[0].data)[:10]
        date_last=str(swvls.valid_time[-1].data)[:10]
        laihv_ds=laihv_ds.sel(valid_time=slice(date_first,date_last))
        lailv_ds=lailv_ds.sel(valid_time=slice(date_first,date_last))        
        sktn_ds=sktn_ds.sel(valid_time=slice(date_first,date_last))
        skt_ds=skt_ds.sel(valid_time=slice(date_first,date_last))
 
        #swvls=swvls.where((swvls.depthBelowLandLayer<=0.20) & (swvls.depthBelowLandLayer>=0.06), drop=True).rename_vars({'vsw':'swvl2-00'}).squeeze(["depthBelowLandLayer"], drop=True) # use layer 0.07 m for swvl2
        swvls['dayOfYear']=swvls.valid_time.dt.dayofyear
 
        ds1=xr.merge([swvls,sl00,
                      sldisacc,
                      height,slope,aspect,sktn_ds,laihv_ds,lailv_ds,stl2_ds,skt_ds
                      ],compat='override')
        ds1=ds1.drop_vars(['surface','depthBelowLandLayer'])
        ds1=ds1.sel(valid_time=slice(date_first,date_last)) 
        
        df=ds1.to_dataframe() # pandas
        #ds1=ds1.unify_chunks() # dask
        #df=ds1.to_dask_dataframe()[preds] #dask
        #print(df)
        df=df.reset_index() # pandas
        
        # store grid for final result
        df_grid=df[['valid_time','latitude','longitude']]
        df_grid['clim_ts_value'] = np.nan
        df_grid=df_grid.set_index(['valid_time', 'latitude','longitude'])
        
        df=df.dropna()
        preds=["slhf","sshf",
        "ssrd","strd","str","ssr","skt","skt-00",
        "sktn","laihv-00",
        "lailv-00",
        "sd-00","rsn-00",
        "stl1-00","stl2-00","swvl2-00",
        "t2-00","td2-00","u10-00",
        "v10-00","ro","evapp","DTM_height","DTM_slope",
        "DTM_aspect",'dayOfYear']

        df_preds = df[preds]
        climcols=['valid_time','latitude','longitude']
        df=df[climcols]
        
        #print(df.compute()) # dask
        
        ### Predict with XGBoost fitted model 
        mdl_name='/home/ubuntu/data/MLmodels/xgbmodel_soiltemp_latest_02122024092131.json'
        fitted_mdl=xgb.XGBRegressor() # pandas
        #fitted_mdl=xgb.Booster() # dask
        fitted_mdl.load_model(mdl_name)

        #print('start fit')
        result=fitted_mdl.predict(df_preds) # pandas
        #result = xgb.dask.predict(client, fitted_mdl, df) # dask, super slow! don't even know how long to execute
        #print('end fit')
        df_preds=[]

        # result df to ds, and nc file as output
        df['clim_ts_value']=result.tolist()
        df=df.set_index(['valid_time', 'latitude','longitude'])
        #print(df)
        result=df_grid.fillna(df)

        #print(result)
        ds=result.to_xarray()
        #print(ds)
        nc=ds.to_netcdf(outfile)
        
        executionTime=(time.time()-startTime)
        print('Fitting execution time per member in minutes: %.2f'%(executionTime/60))
