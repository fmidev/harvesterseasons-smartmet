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
from sklearn.cluster import KMeans
from sklearn.preprocessing import MinMaxScaler
from sklearn.decomposition import PCA
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
    
        "max_depth":trial.suggest_int("max_depth",15,30),
        "objective": "multi:softmax",
        "subsample":trial.suggest_float("subsample",0.01,1),
        "learning_rate":trial.suggest_float("learning_rate",0.1,0.3),
        "n_estimators":trial.suggest_int("n_estimators",100,200),
        "random_state":42,
        "num_class":6,
        "early_stopping_rounds":10,
        "eval_metric":"merror"
    }
    eval_set=[(X_valid,y_valid)]

    xgb_cl=xgb.XGBClassifier(**param)
    bst = xgb_cl.fit(X_train,y_train,eval_set=eval_set)
    y_pred = bst.predict(X_test)
    accuracy=accuracy_score(y_test, y_pred)
    print('\n------------------ Confusion Matrix -----------------\n')
    print(confusion_matrix(y_test, y_pred))

    print('\n-------------------- Key Metrics --------------------')
    print('\nAccuracy: {:.2f}'.format(accuracy_score(y_test, y_pred)))
    print('Balanced Accuracy: {:.2f}\n'.format(balanced_accuracy_score(y_test, y_pred)))

    print('Micro Precision: {:.2f}'.format(precision_score(y_test, y_pred, average='micro')))
    print('Micro Recall: {:.2f}'.format(recall_score(y_test, y_pred, average='micro')))
    print('Micro F1-score: {:.2f}\n'.format(f1_score(y_test, y_pred, average='micro')))

    print('Macro Precision: {:.2f}'.format(precision_score(y_test, y_pred, average='macro')))
    print('Macro Recall: {:.2f}'.format(recall_score(y_test, y_pred, average='macro')))
    print('Macro F1-score: {:.2f}\n'.format(f1_score(y_test, y_pred, average='macro')))

    print('Weighted Precision: {:.2f}'.format(precision_score(y_test, y_pred, average='weighted')))
    print('Weighted Recall: {:.2f}'.format(recall_score(y_test, y_pred, average='weighted')))
    print('Weighted F1-score: {:.2f}'.format(f1_score(y_test, y_pred, average='weighted')))

    print('\n--------------- Classification Report ---------------\n')
    print(classification_report(y_test, y_pred))
    print("\n-----------Test LUCAS---------------------\n")
    pred_all = bst.predict(X_valid)
    print('\nAccuracy: {}'.format(accuracy_score(y_valid, pred_all)))
    print('\n------------------ Confusion Matrix -----------------\n')
    print(confusion_matrix(y_valid, pred_all))
    print('\n--------------- Classification Report ---------------\n')
    print(classification_report(y_valid, pred_all))
    return accuracy

lucas_fname="LUCAS_2018_Copernicus_harvestability_FIN.csv"
sample_fname="all_locs_harvestability_FIN.csv"
cols_own= ["DTM_height","DTM_slope","DTM_aspect","TCD","WAW","CorineLC","TWI","TWI16","harvestability"]
train_data = pd.read_csv(os.path.join(data_dir,sample_fname),usecols=cols_own)
test_data = pd.read_csv(os.path.join(data_dir,lucas_fname),usecols=cols_own)

#removing blank harvestibility classes
train_clean_data = train_data.loc[~train_data["harvestability"].isin(["",254,0,np.nan])]
test_clean_data = test_data.loc[~test_data["harvestability"].isin(["",254,0,np.nan])]

#order columns
train_clean_data = train_clean_data[cols_own]
test_clean_data = test_clean_data[cols_own]

all_data = pd.concat([train_clean_data,test_clean_data])

# scaling

scaler = MinMaxScaler()
continuous_df= all_data[["DTM_height","DTM_slope","DTM_aspect","TWI","TWI16"]]

df_scaled = scaler.fit_transform(continuous_df)

df_scaled = pd.DataFrame(df_scaled, columns=["DTM_height","DTM_slope","DTM_aspect","TWI","TWI16"])

# append categorical values back

data = pd.concat([df_scaled, all_data[["TCD","WAW","CorineLC","harvestability"]].reset_index()],axis=1)

#drop target value from prdictors
predictors=data.drop(["harvestability"],axis=1)

for each_col in predictors.columns:
    predictors[each_col] = predictors[each_col].astype("float64")

pca = PCA(n_components=2, random_state=42,).fit(predictors)

pca_pred = pca.transform(predictors)

all_data["pca1"] = pca_pred[:,0]
all_data["pca2"] = pca_pred[:,1]

kmeans = KMeans(n_clusters=6, random_state=42,).fit(predictors)

kmeans_pred = kmeans.predict(predictors)
all_data["k_cluster"] = kmeans_pred


# keep lucas as validation set validation 
validation_set = all_data.iloc[len(train_clean_data):]
y_valid = validation_set.harvestability.copy()-1
X_valid = validation_set.drop(["harvestability"],axis=1)

# all_harvestability = all_data.harvestability.copy()-1
# all_predictors = all_data.drop(["harvestability"],axis=1)

# sampled_data = all_data.groupby("harvestability").sample(n=1000, random_state=42)

# there are more samples for some classes , remove a fraction from it
# all_data = all_data.drop(all_data[all_data['harvestability'] == 6].sample(frac=0.95,random_state=42).index)
# all_data = all_data.drop(all_data[all_data['harvestability'] == 2].sample(frac=0.80,random_state=42).index)
# all_data = all_data.drop(all_data[all_data['harvestability'] == 5].sample(frac=0.70,random_state=42).index)
# all_data = all_data.drop(all_data[all_data['harvestability'] == 3].sample(frac=0.50,random_state=42).index)
# all_data = all_data.drop(all_data[all_data['harvestability'] == 1].sample(frac=0.40,random_state=42).index)

# print(all_data.harvestability.value_counts())


#XGBoost accepts target values only starting from '0', so deducting 1 from each class
harvestibility = all_data.harvestability.copy()-1

#drop target value from prdictors
predictors=all_data.drop(["harvestability"],axis=1)

X_train, X_test, y_train, y_test = train_test_split(predictors, harvestibility, test_size=0.2, random_state=42)

### Optuna trials
study = optuna.create_study(storage="sqlite:///MLexperiments.sqlite3",study_name="harvestability-features-5",direction="maximize")
study.optimize(objective, n_trials=5, timeout=432000)

print("Number of finished trials: ", len(study.trials))
print("Best trial:")
trial = study.best_trial

print("  Value: {}".format(trial.value))
print("  Params: ")
for key, value in trial.params.items():
    print("    {}: {}".format(key, value))

executionTime=(time.time()-startTime)
print('Execution time in minutes: %.2f'%(executionTime/60))
