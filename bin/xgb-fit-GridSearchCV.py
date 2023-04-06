#!/usr/bin/env python3
import os,time,random
import pandas as pd
import xgboost as xgb
from sklearn.model_selection import GridSearchCV
from sklearn.metrics import mean_squared_error, mean_absolute_error
# Search for best XGBoost hyperparameters with gridSearchCV
# note: this needs to be modified if want to run here at desm
startTime=time.time()

data_dir='/home/ubuntu/data/ml-training-data/data/' # training data
mod_dir='/home/ubuntu/mlbias/models/' # saved mdl
res_dir='/home/ubuntu/mlbias/results/'

### Split to train set and test set

# Select train and test set split years (from KFold with smallest rmse (k=5))
test_y=[2003, 2009, 2011, 2015]
train_y=[2000, 2001, 2002, 2004, 2005, 2006, 2007, 2008, 2010, 2012, 2013, 2014, 2016, 2017, 2018, 2019, 2020, 2021]
print('test ',test_y,' train ',train_y)

### Select predictors and variable to be predicted
df=pd.read_csv('/lustre/tmp/strahlen/mlbias/data/era5+_eobs_dtw_2000-2020_all-100.csv')
allvars=list(df)
# delete NaN etc columns
delete=['DATE','cape-Jkg','ssrc-jm2','cin-Jkg','cbh-m','RR',
        'i10fg-ms', 'hcc-0to1', 'lcc-0to1', 'mcc-0to1','cp-m', 
        'skt-K', 'swvl1-m3m3','swvl2-m3m3', 'swvl3-m3m3', 'swvl4-m3m3',
        'mx2t-K', 'mn2t-K', 'stl2-K', 'stl3-K', 'stl4-K','u100-ms', 'v100-ms', 'mcpr-kgm2s', 'mer-kgm2s', 'mlspr-kgm2s', 'mror-kgm2s', 'mslhf-Wm2',
        'msr-kgm2s', 'msror-kgm2s', 'msshf-Wm2', 'mssror-kgm2s', 'mtpr-kgm2s',
        'sro-m', 'ssro-m',  'pev-m', 'cl-0to1',
        'cvh-n', 'cvl-n', 'dl-m', 'laihv-m2m2', 'lailv-m2m2',
        'lshf', 'slt', 'tvh-n', 'tvl-n'
]
for val in delete:
    allvars.remove(val)
allvars=allvars+['RR']
print(allvars)
df=df[allvars]
#print(df)
df['RR']=df['RR']/10.0 # units from x0.1mm to mm
df['tp-m']=df['tp-m']*1000 # units from m to mm
df['e-m']=df['e-m']*1000
#df['pev-m']=df['pev-m']*1000 # not in ecsf 
df['utctime']=pd.to_datetime(df['utctime'])

train_stations,test_stations=pd.DataFrame(),pd.DataFrame()
for y in train_y:
        train_stations=pd.concat([train_stations,df[df['utctime'].dt.year == y]],ignore_index=True)
for y in test_y:
        test_stations=pd.concat([test_stations,df[df['utctime'].dt.year == y]],ignore_index=True)

# drop rows with any NaN (XGBoost dies) 
testnans1=test_stations.shape[0] # just checking how many rows were dropped due to NaNs
trainnans1=train_stations.shape[0]
test_stations=test_stations.dropna(axis=0,how='any')
train_stations=train_stations.dropna(axis=0,how='any')
testnans2=test_stations.shape[0]
trainnans2=train_stations.shape[0]
varOut=test_stations[['utctime','STAID','RR','tp-m']].copy()
#test_stations.to_csv('test_set_1000_prod.txt')
#train_stations.to_csv('train_set_1000_prod.txt')
print('test set dropped '+str(testnans1-testnans2)+' rows')
print('train set dropped '+str(trainnans1-trainnans2)+' rows')
train_stations=train_stations.drop(columns=['utctime','STAID'])
test_stations=test_stations.drop(columns=['utctime','STAID'])
allvars.remove('STAID') 

# split test,train data to predictors (preds) and predictand (var)
preds_train=train_stations[allvars[1:-1]] 
preds_test=test_stations[allvars[1:-1]]
var_train=train_stations[allvars[-1]]
var_test=test_stations[allvars[-1]]
    
### GRADIENT BOOSTING
# tuning params with GridSearchCV 

xgbparams={
        'num_parallel_tree': [10],
        'objective': ['reg:squarederror'],# ['count:poisson'], 
        'max_depth':[7], # max depth per tree
        'subsample':[0.7], # frac of obs to be sampled for each tree
        'colsample_bytree':[0.7], # frac of cols to be randomly sampled for each tree
        'colsample_bynode':[1], 
        'n_estimators': [500], # nro of trees in ensemble
        'learning_rate': [0.1], 
        'alpha':[0.01],#'gamma':[0.01],  
        'n_jobs':[24],
        'random_state':[99],
        'early_stopping_rounds':[50]
        }    

# initialize and tune model
model=xgb.XGBRegressor(
        eval_metric='rmse',
)
xgbr=GridSearchCV(
            model,
            xgbparams,
            cv=2#,
            #verbose=10
            )

# train model 
eval_set=[(preds_test,var_test)]
xgbr.fit(
        preds_train,var_train,
        eval_set=eval_set)

print(xgbr.best_params_) # print best tuned gb-model parameters
best_mdl = xgbr.best_estimator_ # save best gridsearchcv model

# predict var and compare with test
var_pred=xgbr.predict(preds_test)
mse=mean_squared_error(var_test,var_pred)
varOut['RR-pred']=var_pred.tolist()
varOut.to_csv('predicted_results_RR_100_ecsfparams+_dtw.csv')
print("RMSE: %.2f" % (mse**(1/2.0)))

# save model
best_mdl.save_model('models/bestmdl_100sta_ecsfparams+_dtw_squarederror.txt')

executionTime=(time.time()-startTime)
print('Execution time in minutes: %.2f'%(executionTime/60))