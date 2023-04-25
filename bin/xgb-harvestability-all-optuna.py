import os,optuna,time,random,warnings
import pandas as pd
import xgboost as xgb
from sklearn.model_selection import GridSearchCV
import numpy as np
from sklearn.model_selection import train_test_split
np.random.seed(42)
from sklearn.metrics import confusion_matrix, classification_report
from sklearn.metrics import balanced_accuracy_score, accuracy_score, precision_score, recall_score, f1_score
from sklearn.utils.class_weight import compute_sample_weight
warnings.filterwarnings("ignore")
### XGBoost with Optuna hyperparameter tuning
# note: does not save trained mdl
startTime=time.time()

data_dir='/home/ubuntu/data/ml-harvestability-data' # training data
#data_dir="C:\\Users\prakasam\Downloads\harvester\data"
ml_dir='/home/ubuntu/data/ml-harvestability-data'
#ml_dir="C:\\Users\prakasam\Downloads\harvester\data"
mod_dir=os.path.join(ml_dir,'models') # saved mdl
res_dir=os.path.join(ml_dir,'results')
os.chdir(ml_dir)
print(os.getcwd())
### optuna objective & xgboost
def objective(trial):
    # hyperparameters
    param = {
        "num_parallel_tree":trial.suggest_int("number_parallel_tree", 10, 1000),
        "max_depth":trial.suggest_int("max_depth",3,18),
        "objective": "multi:softmax",
        "subsample":trial.suggest_float("subsample",0.01,1),
        "learning_rate":trial.suggest_float("learning_rate",0.01,0.7),
        "colsample_bytree": trial.suggest_float("colsample_bytree", 0.01, 1.0),
        "colsample_bynode":trial.suggest_float("colsample_bynode", 0.01, 1.0),
        "n_estimators":trial.suggest_int("n_estimators",50,500),
        "alpha":trial.suggest_float("alpha", 0.000000001, 1.0),
        "n_jobs":24,
        "random_state":42,
        "num_class":6,
        "early_stopping_rounds":10,
        "eval_metric":"mlogloss"
    }
    eval_set=[(X_test,y_test)]

    xgb_cl=xgb.XGBClassifier(**param)
    bst = xgb_cl.fit(X_train,y_train,eval_set=eval_set)
    y_pred = bst.predict(X_test)
    accuracy=accuracy_score(y_test, y_pred)
    print("accuracy: "+str(accuracy))
    return accuracy
lucas_fname="LUCAS_2018_Copernicus_harvestability_FIN.csv"
sample_fname="all_locs_harvestability_FIN.csv"
cols_own= ["DTM_height","DTM_slope","DTM_aspect","TCD","WAW","CorineLC","TWI","harvestability"]
train_data = pd.read_csv(os.path.join(data_dir,sample_fname),usecols=cols_own)
test_data = pd.read_csv(os.path.join(data_dir,lucas_fname),usecols=cols_own)

#removing blank harvestibility classes
train_clean_data = train_data.loc[~train_data["harvestability"].isin(["",254,0,np.nan])]
test_clean_data = test_data.loc[~test_data["harvestability"].isin(["",254,0,np.nan])]

#order columns
train_clean_data = train_clean_data[cols_own]
test_clean_data = test_clean_data[cols_own]

#grouping samples
train_samples = train_clean_data.groupby("harvestability").sample(n=1000, random_state=42)
test_samples = test_clean_data.groupby("harvestability").sample(n=54, random_state=42)

#XGBoost accepts target values only starting from '0', so deducting 1 from each class
X_train = train_samples.drop(["harvestability"],axis=1)
X_test = test_samples.drop(["harvestability"],axis=1)
y_train = train_samples.harvestability.copy()-1
y_test = test_samples.harvestability.copy()-1

### Optuna trials
study = optuna.create_study(storage="sqlite:///MLexperiments.sqlite3",study_name="harvestability-sampling-1",direction="maximize")
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
