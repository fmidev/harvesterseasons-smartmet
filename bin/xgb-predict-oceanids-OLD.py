import xarray as xr
import cfgrib,time,sys
import pandas as pd
import xgboost as xgb

#startTime=time.time()

def filter_points(df,lat,lon,nro,names):
    df0=df.copy()
    filter1 = df0['latitude'] == lat
    filter2 = df0['longitude'] == lon
    df0.where(filter1 & filter2, inplace=True)
    idx='-'+str(nro)
    headers=[s + idx for s in names]
    if 'lsm' not in names:
        df0 = df0.drop(columns=['lsm'], errors='ignore')
    df0.columns=headers
    df0=df0.dropna()
    return df0

mod_dir='/home/ubuntu/data/MLmodels/'

# read in input and output
instant = sys.argv[1] # ecsf 00 UTC data
dailysums = sys.argv[2] # ecsf disaccumulated data
outFile = sys.argv[3] # output csv filename
ensmem = sys.argv[4] # ensemble member
pred00=sys.argv[5].split(',') # list of predictors at 00 UTC
predDSUM = sys.argv[6].split(',') # list of predictors daily sums
cols_own = sys.argv[7].split(',') # list of col order
mdl_name = sys.argv[8]
predictand = sys.argv[9]

# 00 UTC
sl=xr.open_dataset(instant, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
#print(sl)
df_00=sl.to_dataframe()
df_00.reset_index(['latitude','longitude'],inplace=True)
df_00=df_00.drop(columns=['surface'])
lats=df_00['latitude'].head(4).tolist()
lons=df_00['longitude'].head(4).tolist()

# filter points
lat1,lon1,lat2,lon2,lat3,lon3,lat4,lon4=lats[0],lons[0],lats[1],lons[1],lats[2],lons[2],lats[3],lons[3]
#print(lat1,lon1,lat2,lon2,lat3,lon3,lat4,lon4) # check that match with fitting input
df1=filter_points(df_00,lat1,lon1,1,pred00)
df2=filter_points(df_00,lat2,lon2,2,pred00)
df3=filter_points(df_00,lat3,lon3,3,pred00)
df4=filter_points(df_00,lat4,lon4,4,pred00)
# merge dataframes
df_new1 = pd.concat([df1,df2,df3,df4],axis=1,sort=False).reset_index()
# df from datetime
df_result = df_new1[['valid_time','lat-1']]
df_new1 = df_new1.drop(['valid_time','lat-1','lon-1','lat-2','lon-2','lat-3','lon-3','lat-4','lon-4'], axis=1)

# DSUMS
sl=xr.open_dataset(dailysums, engine='cfgrib', 
                    backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''))
df_DSUM=sl.to_dataframe()
df_DSUM.reset_index(['latitude','longitude'],inplace=True)
df_DSUM=df_DSUM.drop(columns=['surface'])
# filter points
df1=filter_points(df_DSUM,lat1,lon1,1,predDSUM)
df2=filter_points(df_DSUM,lat2,lon2,2,predDSUM)
df3=filter_points(df_DSUM,lat3,lon3,3,predDSUM)
df4=filter_points(df_DSUM,lat4,lon4,4,predDSUM)

# merge dataframes
df_new2 = pd.concat([df1,df2,df3,df4],axis=1,sort=False).reset_index()
#df_new2 = df_new2.drop(['valid_time','lat-1','lon-1','lat-2','lon-2','lat-3','lon-3','lat-4','lon-4'], axis=1)
 
# merge 00 utc and dsums
df_fin= pd.concat([df_new1,df_new2],axis=1,sort=False).reset_index()
if 'index' in df_fin.columns:
    df_fin=df_fin.drop(columns=['index'])
df_fin.rename(columns={'tclw-1': 'tlwc-1','tclw-2': 'tlwc-2','tclw-3': 'tlwc-3','tclw-4': 'tlwc-4'}, inplace=True)
#df_fin=df_fin[cols_own] # check that column order same as in fitting
#print(df_fin.columns)


# XGBoost predict
fitted_mdl=xgb.XGBRegressor()
fitted_mdl.load_model(mod_dir+mdl_name)
# Ensure the DataFrame has the correct columns
required_columns = fitted_mdl.get_booster().feature_names
df_fin = df_fin[required_columns]
#print(df_fin)
# Make the prediction
result=fitted_mdl.predict(df_fin)
if int(ensmem)<10:
    ensname=predictand+'0'+ensmem
else:
    ensname=predictand+ensmem
df_result[ensname]=result.tolist()
df_result=df_result.drop(columns=['lat-1']) # dummy way because with only datetime df did not work and quick googling did not help
df_result.to_csv(outFile,index=False)

#executionTime=(time.time()-startTime)
#print('Fitting execution time per member in minutes: %.2f'%(executionTime/60))