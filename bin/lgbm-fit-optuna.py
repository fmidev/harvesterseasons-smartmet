import os,optuna,time,random,warnings
import sklearn.datasets
import sklearn.metrics
from sklearn.metrics import mean_squared_error, mean_absolute_error
import pandas as pd
import xgboost as xgb
from sklearn.model_selection import GridSearchCV
import numpy as np
warnings.filterwarnings("ignore")
### LightGBM with Optuna hyperparameter tuning
# note anni 12/04/2023 this is still cp xgb-training, lightgbm version here soon
startTime=time.time()

data_dir='/home/ubuntu/data/ml-training-data/' # training data
ml_dir='/home/ubuntu/data/mlbias/'
mod_dir=ml_dir+'models/' # saved mdl
res_dir=ml_dir+'results/'
os.chdir(ml_dir)
print(os.getcwd())
### optuna objective & xgboost
def objective(trial):
    # hyperparameters
    param = {
        "num_parallel_tree":trial.suggest_int("number_parallel_tree", 1, 10),
        "max_depth":trial.suggest_int("max_depth",3,18),
        "objective": "count:poisson",
        "subsample":trial.suggest_float("subsample",0.01,1),
        "learning_rate":trial.suggest_float("learning_rate",0.01,0.7),
        "colsample_bytree": trial.suggest_float("colsample_bytree", 0.01, 1.0),
        "n_estimators":trial.suggest_int("n_estimators",50,1000),
        "alpha":trial.suggest_float("alpha", 0.000000001, 1.0),
        "n_jobs":64,
        "random_state":99,
        #"early_stopping_rounds":50,
        "eval_metric":"rmse"
    }
    eval_set=[(valid_x,valid_y)]

    xgbr=xgb.XGBRegressor(**param)
    bst = xgbr.fit(train_x,train_y,eval_set=eval_set)
    preds = bst.predict(valid_x)
    pred_labels = np.rint(preds)
    accuracy = np.sqrt(mean_squared_error(valid_y,preds))
    print("accuracy: "+str(accuracy))
    return accuracy


### Read in training data, split to preds and vars
cols_own=['staid','utctime','t2m-K','td-K','msl-Pa','u10-ms','v10-ms','z-m','sdor-m','slor','anor-rad',
'tcc-0to1','sd-kgm2','rsn-kgm2','stl1-K','mx2t-K','mn2t-K',
'lsm-0to1','HGHT','LAT','LON','t850-K-00','t850-K-12','t700-K-00',
't700-K-12','t500-K-00','t500-K-12','q850-kgkg-00','q850-kgkg-12','q700-kgkg-00','q700-kgkg-12',
'q500-kgkg-00','q500-kgkg-12','u850-ms-00','u850-ms-12','u700-ms-00','u700-ms-12','u500-ms-00','u500-ms-12',
'v850-ms-00','v850-ms-12','v700-ms-00','v700-ms-12','v500-ms-00','v500-ms-12','z850-m-00','z850-m-12',
'z700-m-00','z700-m-12','z500-m-00','z500-m-12','kx-00','kx-12','tp-m','e-m','tsr-jm2','fg10-ms','slhf-Jm2',
'sshf-Jm2',
'ro-m','sf-m', 
'dtw',
#'slope','aspect','tpi','tri',
'dtr','dtl','dto','fch','dayOfYear',
'RR','STAID'
]
fname='era5-SL-PL-terrain-EOBS_1995-2020_all194.csv'
print(fname)
df=pd.read_csv(data_dir+fname,usecols=cols_own)

df['RR']=df['RR']/10000.0 # units from x0.1mm to m
# Fix E-OBS station rainfall observations (rain > 12 mm: x1.4, other x1.1)
#df.loc[ df['RR'] >= 0.012, 'RR'] = df['RR']*1.4 
#df.loc[ df['RR'] < 0.012, 'RR'] = df['RR']*1.1
        
df['utctime']=pd.to_datetime(df['utctime'])

# divide to train and test by years (from KFold with smallest rmse (k=5))
#test_y=[2000,2003,2005,2015]
test_y=[2003, 2009, 2011, 2015]
#train_y=[1995,1996,1997,1998,1999,2001,2002,2004,2006,2007,2008,2009,2010,2011,2012,2013,2014]
train_y=[2000, 2001, 2002, 2004, 2005, 2006, 2007, 2008, 2010, 2012, 2013, 2014, 2016, 2017, 2018, 2019, 2020, 2021]
print('test ',test_y,' train ',train_y)
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
print('test set dropped '+str(testnans1-testnans2)+' rows')
print('train set dropped '+str(trainnans1-trainnans2)+' rows')
train_stations=train_stations.drop(columns=['utctime','STAID','staid'])
test_stations=test_stations.drop(columns=['utctime','STAID','staid'])

# split data to predidctors (preds) and variable to be predicted (var)
preds=['tp-m','tcc-0to1','slor','msl-Pa','sdor-m','LAT','LON','anor-rad','kx-00','kx-12',
'q850-kgkg-00','q850-kgkg-12','q700-kgkg-00','q700-kgkg-12','q500-kgkg-00','q500-kgkg-12',
'u850-ms-00','u850-ms-12','u700-ms-00','u700-ms-12','u500-ms-00','u500-ms-12',
'z-m','z850-m-00','z850-m-12','z700-m-00','z700-m-12','z500-m-00','z500-m-12',
'v850-ms-00','v850-ms-12','v700-ms-00','v700-ms-12','v500-ms-00','v500-ms-12',
'lsm-0to1','HGHT','dtw','dtr','dtl','dto','fch',
'ro-m','sf-m',
'sshf-Jm2','slhf-Jm2','e-m','tsr-jm2','fg10-ms',
't2m-K','td-K','u10-ms','v10-ms','sd-kgm2','rsn-kgm2','stl1-K','mx2t-K','mn2t-K',
't850-K-00','t850-K-12','t700-K-00','t700-K-12','t500-K-00','t500-K-12','dayOfYear'#,
#'slope','aspect','tpi','tri'
]
var=['RR'] 
train_x=train_stations[preds] 
valid_x=test_stations[preds]
train_y=train_stations[var]
valid_y=test_stations[var]
    
### Optuna trials
study = optuna.create_study(storage="sqlite:///MLexperiments.sqlite3",study_name="xgb-precip-1",direction="minimize")
study.optimize(objective, n_trials=100, timeout=432000)

print("Number of finished trials: ", len(study.trials))
print("Best trial:")
trial = study.best_trial

print("  Value: {}".format(trial.value))
print("  Params: ")
for key, value in trial.params.items():
    print("    {}: {}".format(key, value))

executionTime=(time.time()-startTime)
print('Execution time in minutes: %.2f'%(executionTime/60))
