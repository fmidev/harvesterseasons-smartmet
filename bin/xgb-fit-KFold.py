import os, time, datetime, random
import numpy as np
import pandas as pd
import xgboost as xgb
from sklearn.model_selection import KFold 
from sklearn.metrics import mean_squared_error, mean_absolute_error
### XGBoost with KFold
# note: need to be modified if want to use at desm
startTime=time.time()

data_dir='/home/ubuntu/data/ml-training-data/data/' # training data
mod_dir='/home/ubuntu/mlbias/models/' # saved mdl
res_dir='/home/ubuntu/mlbias/results/'

print('KFold, 200 prf-staids, 1995-2015')
cols_own=['utctime', 'tp-m', 'e-m', 't2m-K', 't850-K', 't700-K', 't500-K', 'td-K', 'msl-Pa', 'kx', 'q850-kgkg', 'q700-kgkg', 'q500-kgkg', 'u10-ms', 'u850-ms', 'u700-ms', 'u500-ms', 'v10-ms', 'v850-ms', 'v700-ms', 'v500-ms', 'z-m', 'z850-m', 'z700-m', 'z500-m', 'sdor-m', 'slor', 'anor-rad', 'tsr-jm2', 'ffg-ms', 'slhf-Jm2', 'sshf-Jm2', 'tcc-0to1', 'ro-m', 'sd-kgm2', 'sf-kgm2', 'rsn-kgm2', 'stl1-K', 'strc-Jm2', 'lsm-0to1', 'HGHT', 'LAT', 'LON', 'dtw', 'RR']
df=pd.read_csv('/lustre/tmp/strahlen/mlbias/data/era5+_eobs_dtw_1995-2015_all200_RRweight.csv',usecols=cols_own)
df['RR']=df['RR']/10.0 # units from x0.1mm to mm
df['tp-m']=df['tp-m']*1000 # units from m to mm
df['e-m']=df['e-m']*1000
#df['pev-m']=df['pev-m']*1000 # not in ecsf 
df['utctime']=pd.to_datetime(df['utctime'])
print(df)

# Read predictor (preds) and predictand (var) data
preds=['utctime','tp-m', 'e-m', 't2m-K', 't850-K', 't700-K', 't500-K', 'td-K', 'msl-Pa', 'kx', 'q850-kgkg', 'q700-kgkg', 'q500-kgkg', 'u10-ms', 'u850-ms', 'u700-ms', 'u500-ms', 'v10-ms', 'v850-ms', 'v700-ms', 'v500-ms', 'z-m', 'z850-m', 'z700-m', 'z500-m', 'sdor-m', 'slor', 'anor-rad', 'tsr-jm2', 'ffg-ms', 'slhf-Jm2', 'sshf-Jm2', 'tcc-0to1', 'ro-m', 'sd-kgm2', 'sf-kgm2', 'rsn-kgm2', 'stl1-K', 'strc-Jm2', 'lsm-0to1', 'HGHT', 'LAT', 'LON', 'dtw']
var=['utctime','RR'] # variable to be predicted

# Define XGBRegressor model parameters (from gridSearchCV)
nstm=500
lrte=0.1 
max_depth=7
subsample=0.7
colsample_bytree=0.7
colsample_bynode=1
num_parallel_tree=10

# KFold cross-validation; splitting to train/test sets by years
allyears=np.arange(1995,2016).astype(int)
#allyears=np.aragne(2000,2021).astype(int)

kf=KFold(5,shuffle=True,random_state=20)
fold=0
mdls=[]
for train_idx, test_idx in kf.split(allyears):
        fold+=1
        train_years=allyears[train_idx]
        test_years=allyears[test_idx]
        train_idx=np.isin(df['utctime'].dt.year,train_years)
        test_idx=np.isin(df['utctime'].dt.year,test_years)
        train_set=df[train_idx].reset_index(drop=True)
        test_set=df[test_idx].reset_index(drop=True)
        
        # Drop NaN rows (XGBoost dies)
        train_set=train_set.dropna(axis=0,how='any')
        test_set=test_set.dropna(axis=0,how='any')

        #varOut=test_set[['utctime','STAID','tp-mm','RR']].copy()

        # Split to predictors and target variable
        preds_train=train_set[preds].drop(columns=['utctime'])
        preds_test=test_set[preds].drop(columns=['utctime'])
        var_train=train_set[var].drop(columns=['utctime'])
        var_test=test_set[var].drop(columns=['utctime'])

        # Define the model without...
        eval_met='rmse'
        
        xgbr=xgb.XGBRegressor(
                objective= 'count:poisson', #'reg:squarederror'
                n_estimators=nstm,
                learning_rate=lrte,
                max_depth=max_depth,
                gamma=0.01, #alpha=0.01
                num_parallel_tree=num_parallel_tree,
                n_jobs=24,
                subsample=subsample,
                colsample_bytree=colsample_bytree,
                colsample_bynode=colsample_bynode,
                random_state=99,
                eval_metric=eval_met,
                early_stopping_rounds=50
                )
        
        # Train the model
        eval_set=[(preds_test,var_test)]
        fitted_mdl=xgbr.fit(
                preds_train,var_train,
                eval_set=eval_set,
                verbose=False #True
        )

        # Predict var and compare with test
        var_pred=fitted_mdl.predict(preds_test)
        mse=mean_squared_error(var_test,var_pred)
        #varOut['RR-pred']=var_pred.tolist()
        #varOut.to_csv('RR-results_fold'+str(fold)+'_1000stat.txt')
        print("Fold: %s RMSE: %.2f" % (fold,mse**(1/2.0)))
        print('Train: ',train_years,'Test: ',test_years)
        mdls.append(fitted_mdl)

# Save GB models
for i,mdl in enumerate(mdls):
        mdl.save_model(grbmod_dir+'model_200repStations_RRweight_1995-2015_nro'+str(i+1)+'.txt')

executionTime=(time.time()-startTime)
print('Execution time in minutes: %.2f'%(executionTime/60))