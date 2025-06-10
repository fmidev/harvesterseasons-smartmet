#!/usr/bin/env python3
import xarray as xr
import cfgrib,sys,time
import pandas as pd
import xgboost as xgb
import numpy as np
from sklearn.metrics import mean_squared_error, mean_absolute_error
import matplotlib.pyplot as plt

startTime=time.time()

# Predictand to be fitted, from era5, with parameter ID
predictand_mappings={
    't2m': 167, # 2m temperature
    }
predictand='t2m' #sys.argv[1] # predictand to be fitted

# Data directory for control runs for XGB bias training
data_dir = '/home/ubuntu/data/xgb-bias/yearly-controls/'

# ECSF files 20200101-20241201
# control runs with files for each year
# Anni/Rasmus... fiksaa vielä kun sieltä puuttuu ainakin 2022 03 ja taisi puuttua 2023 joku myös
# löytyy siis /data/xgb-bias/control ja sitten sinne kun saa puuttuvat niin cat ECSF_2020*all* > ECSF_2020_all.grib etc per vuosi ja all/pl
sf_sl_2020 = data_dir + 'ECSF_2020_all.grib'
sf_sl_2021 = data_dir + 'ECSF_2021_all.grib'
sf_sl_2022 = data_dir + 'ECSF_2022_all.grib'
sf_sl_2023 = data_dir + 'ECSF_2023_all.grib'
sf_sl_2024 = data_dir + 'ECSF_2024_all.grib'
sf_pl_2020 = data_dir + 'ECSF_2020_pl.grib'
sf_pl_2021 = data_dir + 'ECSF_2021_pl.grib'
sf_pl_2022 = data_dir + 'ECSF_2022_pl.grib'
sf_pl_2023 = data_dir + 'ECSF_2023_pl.grib'
sf_pl_2024 = data_dir + 'ECSF_2024_pl.grib'

# ERA5(L?) dataa 2020-2024
#era5_file = '/home/ubuntu/data/era5/ERA5_19950101T000000_1995-2024_sl-mon-eu.grib' # ei käytetä monthly dataa

mod_dir = '/home/ubuntu/data/MLmodels/'
mod_name = f'xgb-bias_era5_ecsf_1995-2024_{predictand}.json' # model name

# ECSF parameters 
ecsf_sl=['t2m']#,'d2m','u10','v10','fg10'] # single level features (add)
ecsf_pl = ['t','z'] # pressure level features

ecsf_1 = xr.open_dataset(
    sf_sl_2020,
    engine='cfgrib',
    backend_kwargs=dict(
        #filter_by_keys={'number': 0},
        #time_dims=('valid_time', 'verifying_time'),
        indexpath=''
        )
)[ecsf_sl]

print(ecsf_1)
sf=ecsf_1.to_dataframe()

df_flat = sf.reset_index()
df_flat['utctime'] = df_flat['valid_time']
df_final = df_flat[['utctime', 't2m', 'latitude', 'longitude']].copy()
df_final.reset_index(drop=True, inplace=True)
print(sf)
print(df_final)

df_final['utctime'] = pd.to_datetime(df_final['utctime'])

# Filter rows with utctime == 2020-05-14
rows_on_date = df_final[
    (df_final['utctime'] == '2020-05-14') &
    (df_final['latitude'] == 75) &
    (df_final['longitude'] == -30)
]
print(rows_on_date)

'''
# lisäksi ECSF z, lsm, lai staattisina tai kuukausi muuttujina
ecsf=xr.open_dataset(ecsf202312_sl, engine='cfgrib',
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

# Define the directions and their corresponding shifts
directions = {
    'o': (0, 0),    # original (no shift)
    'n': (1, 0),    # north
    'ne': (1, 1),   # northeast
    'e': (0, 1),    # east
    'se': (-1, 1),  # southeast
    's': (-1, 0),    # south
    'sw': (-1, -1), # southwest
    'w': (0, -1),   # west
    'nw': (1, -1)   # northwest
}

# Create a new dataset with all the shifted variables
new_ds = xr.Dataset()
for var_name in list(xgb_ds.data_vars):
    # Skip certain variables if needed
    if var_name in ['surface', 'number']:
        continue
    
    for direction, (lat_shift, lon_shift) in directions.items():
        if lat_shift == 0 and lon_shift == 0:
            # No shift for original point
            new_ds[f"{var_name}_{direction}"] = xgb_ds[var_name]
        else:
            # Create shifted version
            new_ds[f"{var_name}_{direction}"] = xgb_ds[var_name].shift(latitude=lat_shift, longitude=lon_shift)

# Convert to dataframe (using new_ds instead of xgb_ds)
xgb_df = new_ds.to_dataframe()
xgb_df.reset_index(['latitude','longitude'],inplace=True)
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
'''

elapsed = time.time() - startTime

if elapsed < 60:
    print(f"Script completed in {elapsed:.2f} seconds.")
elif elapsed < 3600:
    minutes = int(elapsed // 60)
    seconds = elapsed % 60
    print(f"Script completed in {minutes} minutes {seconds:.2f} seconds.")
else:
    hours = int(elapsed // 3600)
    minutes = int((elapsed % 3600) // 60)
    seconds = elapsed % 60
    print(f"Script completed in {hours} hours {minutes} minutes {seconds:.2f} seconds.")