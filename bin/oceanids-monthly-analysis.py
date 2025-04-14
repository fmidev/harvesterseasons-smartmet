import sys
import pandas as pd
import calendar
#from Vuosaari_151028_XGBoost import *
#from Raahe_101785_XGBoost import *
#from Rauma_101061_XGBoost import *
#from Malaga_000231_XGBoost  import *
from Vuosaari_config import *
pd.set_option('mode.chained_assignment', None) # turn off SettingWithCopyWarning 

# ECXSF and observations
yearmon=sys.argv[1]

data_dir='/home/ubuntu/data/OCEANIDS/'

cols1=['utctime',predictand]
# ECXSF_202501_WG_PT24H_MAX_Vuosaari_151028.csv
f2 = f'ECXSF_{yearmon}_{predictand}_{harbor}_{FMISID}.csv' # sf XGBoost result file
df=pd.read_csv(data_dir+f2)
df.rename(columns={'valid_time': 'utctime'},inplace=True)
df=df.set_index('utctime')
df.index = pd.to_datetime(df.index)

# Monthly thresholds for each month (January to December)
monthly_thresholds = {month: threshold for month, threshold in enumerate(threshold_values, start=1)}

over_th = df.iloc[:, 1:] >= th_wind
count_over_th = over_th.sum(axis=1)
df['percent_over_threshold'] = (count_over_th / 51) * 100
print(df)

# Apply monthly thresholds to identify rows exceeding each month's threshold
monthly_results = []
for month, threshold in monthly_thresholds.items():
    # Filter data for the specific month
    df_month = df[df.index.month == month]
    
    # Filter by the monthly threshold
    df_max = df_month[df_month['percent_over_threshold'] >= threshold]
    
    # Save results for the month
    monthly_results.append(df_max)
    
# Combine results for all months
df_max_all = pd.concat(monthly_results)

# Group by month for summary
dfg_ecxsf = df_max_all.groupby(df_max_all.index.month).size().reset_index(name='counts')
dfg_ecxsf['utctime'] = dfg_ecxsf['utctime'].map(dict(zip(range(1, 13), calendar.month_name[1:])))

print(harbor +' ECXSF by month for '+str(th_wind)+' m/s wind threshold (sf '+yearmon+'):')
print(dfg_ecxsf)

