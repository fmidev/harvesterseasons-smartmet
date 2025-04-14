import os,optuna,time,warnings,json,sys,commentjson
import sklearn.metrics
from sklearn.metrics import mean_squared_error,mean_absolute_error
import pandas as pd
import xgboost as xgb
import numpy as np
# XGBoost with Optuna hyperparameter tuning in OCEANIDS project for ERA5/ERA5D training data
# give the name of the harbor and predictand as cmd argument
# note: does not save trained mdl
# (AK 2025)
warnings.filterwarnings("ignore")

startTime = time.time()

# Give harbor name and predictand as cmd arguments
harbor_name=sys.argv[1]
pred=sys.argv[2]

# Custom loss function combining MSE with variance penalty
def custom_var_mse(y_true, y_pred, lambda_val=0.1):
    """
    Custom metric function that combines MSE with variance penalty.
    """
    # Convert to numpy arrays
    if hasattr(y_true, 'values'):
        y_true = y_true.values
    
    # Flatten arrays if needed
    if len(y_true.shape) > 1:
        y_true = y_true.flatten()
    if len(y_pred.shape) > 1:
        y_pred = y_pred.flatten()
    
    # Calculate MSE
    mse = np.mean((y_pred - y_true) ** 2)
    
    # Calculate variance penalty
    var_pred = np.var(y_pred)
    var_true = np.var(y_true)
    var_penalty = (var_pred - var_true) ** 2
    
    # Combined loss
    loss = mse + lambda_val * var_penalty
    
    return loss

# Custom XGBoost objective function (for training)
def custom_objective(y_pred, dtrain, lambda_val):
    y_true = dtrain.get_label()
    
    # Calculate gradient for MSE + variance penalty
    # For MSE part: gradient = 2(y_pred - y_true)/n
    n = len(y_true)
    mse_grad = 2 * (y_pred - y_true) / n
    
    # For variance penalty part
    # grad(λ·(Var(y_pred) - Var(y_true))²) with respect to y_pred
    var_pred = np.var(y_pred)
    var_true = np.var(y_true)
    
    # Derivative of variance term
    # 2λ·(Var(y_pred) - Var(y_true))·(2/n)·(y_pred - mean(y_pred))
    var_diff = var_pred - var_true
    mean_pred = np.mean(y_pred)
    var_grad = 2 * lambda_val * var_diff * (2/n) * (y_pred - mean_pred)
    
    # Combined gradient
    grad = mse_grad + var_grad
    
    # Hessian (second derivative) - simplified approximation
    # For MSE part: hess = 2/n
    # Using constant hessian approximation for variance part
    hess = np.ones_like(y_pred) * (2/n)
    
    return grad, hess

# Optuna objective
def objective(trial):
    # Add lambda as a hyperparameter
    lambda_val = trial.suggest_float("lambda_val", 0.01, 1.0)
    
    # Define a custom objective function with the current lambda value
    def objective_lambda(y_pred, dtrain):
        return custom_objective(y_pred, dtrain, lambda_val)
    
    # hyperparameters
    param = {
        "objective": objective_lambda,  # Use our custom objective
        "num_parallel_tree":1,
        "max_depth":trial.suggest_int("max_depth",3,18),
        "subsample":trial.suggest_float("subsample",0.01,1),
        "learning_rate":trial.suggest_float("learning_rate",0.01,0.7),
        "colsample_bytree": trial.suggest_float("colsample_bytree", 0.01, 1.0),
        "n_estimators":trial.suggest_int("n_estimators",50,1000),
        "min_child_weight":1,
        "n_jobs":64,
        "random_state":99,
        "early_stopping_rounds":50,
        "eval_metric":'mae'
    }
    eval_set=[(valid_x,valid_y)]

    xgbr=xgb.XGBRegressor(**param)
    bst = xgbr.fit(train_x,train_y,eval_set=eval_set)
    preds = bst.predict(valid_x)
    
    # Calculate custom loss with variance penalty
    custom_loss = custom_var_mse(valid_y, preds, lambda_val)
    print(f"Custom Loss (MSE + {lambda_val}·Var Penalty): {custom_loss}")
    
    return custom_loss

data_dir = f'/home/ubuntu/data/ML/training-data/OCEANIDS/{harbor_name}/'  # training data
mod_dir = f'/home/ubuntu/data/ML/models/OCEANIDS/{harbor_name}/'  # save hyperparameters
optuna_dir = '/home/ubuntu/data/ML/'  # optuna storage

fname=f'training_data_oceanids_{harbor_name}-sf-addpreds.csv'
hfname=f'hyperparameters_{harbor_name}_{pred}cl-test.json'
study=f'{harbor_name}_{pred}_cl-test-qe'

# Load train/validation years split config file
with open(f'{mod_dir}{harbor_name}_{pred}_best_split.json', 'r') as file3:
    yconfig = json.load(file3)
test_y=yconfig.get('test_years')
train_y=yconfig.get('train_years')

# predictand mappings from JSON file and determine qa (quantile_alpha) for the given pred
with open('predictand_mappings.json', 'r') as f:
    mappings = json.load(f)
predictand_mappings = { key: mappings[key]["parameter"] for key in mappings }
qa = mappings[pred]["quantile_alpha"]

selected_value = predictand_mappings[pred]
keys_to_drop = [key for key in predictand_mappings if key != pred]
values_to_drop = [val for key, val in predictand_mappings.items() if key != pred]

# Load training data config file
with open(f'training_data_config.json', 'r') as file:
    config = commentjson.load(file) # commentjson to allow comments syntax in json files
columns = config['training_columns']
print(columns)

# Filter the columns for predictor and related variables:
filtered_columns = []
for col in columns:
    drop = any(drop_key in col for drop_key in keys_to_drop)
    drop = drop or any(drop_val in col for drop_val in values_to_drop)
    if not drop:
        filtered_columns.append(col)

# Read in training data
df=pd.read_csv(data_dir+fname,usecols=filtered_columns)

# drop NaN values
df=df.dropna(axis=1, how='all')
s1=df.shape[0]
df=df.dropna(axis=0,how='any')
s2=df.shape[0]
print('From '+str(s1)+' rows dropped '+str(s1-s2)+', apprx. '+str(round(100-s2/s1*100,1))+' %')
df['utctime']= pd.to_datetime(df['utctime'])
headers=list(df) # list column headers
#print(df)

# Split to train and test by years, KFold for best split (k=5)
train_stations,test_stations=pd.DataFrame(),pd.DataFrame()
for y in train_y:
        train_stations=pd.concat([train_stations,df[df['utctime'].dt.year == y]],ignore_index=True)
for y in test_y:
        test_stations=pd.concat([test_stations,df[df['utctime'].dt.year == y]],ignore_index=True)

# Split to predictors (preds) and predictand (var) data
var_headers=list(df[[pred]])
preds_headers=list(df[headers].drop(['utctime','name','latitude', 'longitude',pred], axis=1))
train_x=train_stations[preds_headers] 
valid_x=test_stations[preds_headers]
train_y=train_stations[var_headers]
valid_y=test_stations[var_headers]
    
### Optuna trials

# move to correct dir for optuna study 
os.chdir(optuna_dir)
print(os.getcwd())

study = optuna.create_study(storage="sqlite:///MLexperiments.sqlite3",study_name=study,direction="minimize",load_if_exists=True)
study.optimize(objective, n_trials=100, timeout=432000)

print("Number of finished trials: ", len(study.trials))
print("Best trial:")
trial = study.best_trial

print("  Value: {}".format(trial.value))
print("  Params: ")
for key, value in trial.params.items():
    print("    {}: {}".format(key, value))

# Save best hyperparameters to json
best_params = {
    "best_custom_loss": trial.value,
    "max_depth": trial.params["max_depth"],
    "subsample": trial.params["subsample"],
    "learning_rate": trial.params["learning_rate"],
    "colsample_bytree": trial.params["colsample_bytree"],
    "n_estimators": trial.params["n_estimators"],
    "lambda_val": trial.params["lambda_val"],  # Save the lambda parameter
    "quantile_alpha":qa,
    "num_parallel_tree": 1
}
with open(mod_dir+hfname, 'w') as f:
    json.dump(best_params, f, indent=4)

executionTime=(time.time()-startTime)
print('Execution time in minutes: %.2f'%(executionTime/60))