#!/usr/bin/env python3
import xarray as xr
import cfgrib,sys
import pandas as pd
import xgboost as xgb
import numpy as np
from sklearn.metrics import mean_squared_error, mean_absolute_error
import matplotlib.pyplot as plt

### Prepare datasets

# Predictand to be fitted, from era5, with parameter ID
predictand_mappings={
    't2m': 167, # 2m temperature
    }
predictand='t2m' #sys.argv[1] # predictand to be fitted

# File paths
ecsf_file = '/home/ubuntu/data/era5/ECSF_19950101T000000_1995-2024_sl-mon-era5-eu-fix.grib'
era5_file = '/home/ubuntu/data/era5/ERA5_19950101T000000_1995-2024_sl-mon-eu.grib'
mod_dir = '/home/ubuntu/data/MLmodels/'
mod_name = f'xgb-bias_era5_ecsf_1995-2024_{predictand}.json' # model name

# ECSF parameters 21 in total 
# alla olevat ja t ja z pl-tiedostosta painepinnoille 925hPa ja 850hPa
ecsf_param_names = [
    'u10',    # 10m u-component of wind
    'v10',    # 10m v-component of wind
    'fg10',   # 10m wind gust
    'd2m',     # 2m dewpoint temperature
    't2m',     # 2m temperature
    'ewssra', # Eastward turbulent surface stress accumulated
    'erate',  # Evaporation rate
    'mx2t24', # Maximum 2m temperature in the past 24 hours
    'msl',    # Mean sea level pressure
    'mn2t24', # Minimum 2m temperature in the past 24 hours
    'nsssra', # Northward turbulent surface stress accumulated
    'mslhfl', # Mean sea level latent heat flux
    'msshfl', # Mean surface sensible heat flux
    #'msnsrf', # Mean surface net solar radiation flux
    #'msdsrf', # Mean surface downward solar radiation flux
    #'msntrf', # Mean surface net thermal radiation flux
    #'msdtrf', # Mean surface downward thermal radiation flux
    #'mtnsrf', # Mean top net solar radiation flux
    #'mtntrf', # Mean top net thermal radiation flux
    'tcc',    # Total cloud cover
    'tclw',   # Total column liquid water
    'tcwv',   # Total column water vapour
    'tprate'  # Total precipitation rate
]
# lisäksi ECSF z, lsm, lai staattisina tai kuukausi muuttujina
ecsf=xr.open_dataset(ecsf_file, engine='cfgrib',
                    backend_kwargs=dict(filter_by_keys= {'typeOfLevel': 'surface'},time_dims=('valid_time','verifying_time'),indexpath=''))[ecsf_param_names]

# avoid errors by filtering parameters by paramId
era5_predictand = xr.open_dataset(era5_file, engine='cfgrib',
                          backend_kwargs={
                              'filter_by_keys': {'typeOfLevel': 'surface','edition':1,'paramId': predictand_mappings[predictand]},
                                'indexpath': '',
                                'time_dims': ('valid_time', 'verifying_time')
                            }).rename({predictand: f"era5_{predictand}"})
era5_lsm = xr.open_dataset(era5_file, engine='cfgrib',
                          backend_kwargs={
                              'filter_by_keys': {'typeOfLevel': 'surface','edition':1,'paramId': 172},
                              'indexpath': '',
                              'time_dims': ('valid_time', 'verifying_time')
                          })
era5_z = xr.open_dataset(era5_file, engine='cfgrib',
                          backend_kwargs={
                              'filter_by_keys': {'typeOfLevel': 'surface','edition':1,'paramId': 129},
                              'indexpath': '',
                              'time_dims': ('valid_time', 'verifying_time')
                          })
xgb_ds = xr.merge([era5_lsm, era5_z, ecsf,era5_predictand], compat='override')
xgb_df = xgb_ds.to_dataframe()
xgb_df.reset_index(['latitude','longitude'],inplace=True)
xgb_df=xgb_df.drop(columns=['surface','number'])
xgb_df['month'] = xgb_df.index.get_level_values('valid_time').month
print(xgb_df)

# drop NaN values
xgb_df=xgb_df.dropna(axis=1, how='all')
s1=xgb_df.shape[0]
xgb_df=xgb_df.dropna(axis=0,how='any')
s2=xgb_df.shape[0]
print('From '+str(s1)+' rows dropped '+str(s1-s2)+', apprx. '+str(round(100-s2/s1*100,1))+' %')

# random split
xgb_df.reset_index(inplace=True)
train_y = [1995, 1997, 1998, 2000, 2001, 2002, 2003, 2004, 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2014, 2015, 2016, 2018, 2019, 2020, 2021, 2022, 2024]
test_y = [1996, 1999, 2005, 2013, 2017, 2023]
train_set,test_set=pd.DataFrame(),pd.DataFrame()
for y in train_y:
        train_set=pd.concat([train_set,xgb_df[xgb_df['valid_time'].dt.year == y]],ignore_index=True)
for y in test_y:
        test_set=pd.concat([test_set,xgb_df[xgb_df['valid_time'].dt.year == y]],ignore_index=True)

# Split to predictand and predictors
predictand_column = f"era5_{predictand}"
train_predictand = train_set[predictand_column]#.drop(columns=['valid_time'])
train_predictors = train_set.drop(columns=[predictand_column,'valid_time'])
test_predictand = test_set[predictand_column]#.drop(columns=['valid_time'])
test_predictors = test_set.drop(columns=[predictand_column,'valid_time'])

# convert to DMatrix for XGBoost
dtrain = xgb.DMatrix(train_predictors, label=train_predictand)
dtest = xgb.DMatrix(test_predictors, label=test_predictand)

# Custom objective function
def custom_objective(y_pred, dtrain):
    y_true = dtrain.get_label()

    # Calculate gradient for MSE + variance penalty
    # For MSE part: gradient = 2(y_pred - y_true)
    mse_grad = 2 * (y_pred - y_true)

    # For variance penalty part
    # grad(λ·(Var(y_pred) - Var(y_true))²) with respect to y_pred
    var_pred = np.var(y_pred)
    var_true = np.var(y_true)

    # Derivative of variance term
    # 2λ·(Var(y_pred) - Var(y_true))·2·(y_pred - mean(y_pred))
    var_diff = var_pred - var_true
    mean_pred = np.mean(y_pred)
    var_grad = 2 * lambda_val * var_diff * 2 * (y_pred - mean_pred)
    
    # Combined gradient
    grad = mse_grad + var_grad
    
    # Hessian (second derivative) - simplified approximation
    # Using constant hessian approximation for variance part
    hess = np.ones_like(y_pred) * 2

    # Debug prints (when script is OK, comment out/remove)
    print("y_true[:5]:", y_true[:5])
    print("y_pred[:5]:", y_pred[:5])
    print("grad[:5]:", grad[:5])
    print("hess[:5]:", hess[:5])
    print("var_pred:", var_pred)
    print("var_true:", var_true)
    print("var_diff:", var_diff)
    return grad, hess

# Custom eval metric
def custom_eval_metric(y_pred, dtrain):
    y_true = dtrain.get_label()

    # Calulate MSE
    mse = np.mean((y_pred - y_true) ** 2)

    # Calculate variance penalty
    var_pred = np.var(y_pred)
    var_true = np.var(y_true)
    var_penalty = (var_pred - var_true) ** 2

    # Combined loss
    loss = mse + lambda_val * var_penalty
    return 'custom_eval_metric', float(loss)

# Hyperparameters
lambda_val = 0.01
params = {
    'max_depth': 10,
    'eta': 0.02,
    'subsample': 0.29,
    'colsample_bytree': 0.56,
    'alpha': 0.54,
    'num_parallel_tree': 10,
    'tree_method': 'hist',
    'nthread': 64,
    'objective': 'reg:squarederror',  # dummy value, overridden by custom
    'eval_metric': 'rmse',            # optional fallback
    'seed':99                         # model reproducibility
}

# Train the model
num_boost_round = 1000
early_stopping_rounds = 50
evals = [(dtest, 'validation_0')]

model = xgb.train(
    params,
    dtrain,
    num_boost_round=num_boost_round,
    evals=evals,
    early_stopping_rounds=early_stopping_rounds,
    obj=custom_objective,
    custom_metric=custom_eval_metric,
    verbose_eval=True
)

# Validation set predictions and metrics
predictand_pred = model.predict(dtest)
mse = mean_squared_error(test_predictand, predictand_pred)
mae = mean_absolute_error(test_predictand, predictand_pred)
print("RMSE: %.5f" % (mse ** 0.5))
print("MAE: %.5f" % mae)

# Save the model
model.save_model(f'{mod_dir}{mod_name}')

# Get feature importances
importance = model.get_score(importance_type='gain')
importance_df = pd.DataFrame({
    'feature': list(importance.keys()),
    'importance': list(importance.values())
})
importance_df = importance_df.sort_values('importance', ascending=False) 

# Plot
plt.figure(figsize=(8, 12))
plt.barh(importance_df['feature'], importance_df['importance'], color='skyblue')
plt.xlabel('Gain Importance')
plt.title('XGBoost Feature Importance')
plt.tight_layout()
plt.savefig(f'{mod_dir}{mod_name}_XGBfeature_importance.png')  # Save as PNG
plt.show()
