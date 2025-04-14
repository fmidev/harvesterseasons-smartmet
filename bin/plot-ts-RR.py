import requests, json
import pandas as pd
from matplotlib import pyplot as plt
# Plot timeseries for seasonal forecast (SF) and observed total precipitation accumulation (AK 2025)
pd.set_option('mode.chained_assignment', None)  # turn off SettingWithCopyWarning 

# Define the SF date range
start_date = '2024-04-02' 
end_date = '2024-11-02'
date =start_date.replace('-', '')+'T000000Z-'+end_date.replace('-', '')+'T000000Z'  # sf date range

# Load and preprocess observation data
obs_dir = '/home/ubuntu/data/synop/'
obs_file = 'fmisid116859_2024_pra6h.csv'
df_obs = pd.read_csv(obs_dir + obs_file)
print(df_obs)
df_obs.loc[ df_obs['PRA_PT6H_ACC'] >= 0.012, 'WeightRR'] = df_obs['PRA_PT6H_ACC']*1.4 
df_obs.loc[ df_obs['PRA_PT6H_ACC'] < 0.012, 'WeightRR'] = df_obs['PRA_PT6H_ACC']*1.1
print(df_obs)
fmisid = str(df_obs['fmisid'].iloc[0])
lat = str(df_obs['lat'].iloc[0])
lon = str(df_obs['lon'].iloc[0])
df_obs['time'] = pd.to_datetime(df_obs['time'])
df_obs['date'] = df_obs['time'].dt.date
daily_sums = df_obs.groupby('date')['WeightRR'].sum().reset_index()
daily_sums.columns = ['date', 'daily_sum']
daily_sums['date'] = pd.to_datetime(daily_sums['date'])
filtered_df = daily_sums[(daily_sums['date'] >= start_date) & (daily_sums['date'] <= end_date)]
filtered_df['accumulated_sum'] = filtered_df['daily_sum'].cumsum()/1000
filtered_df['daily_sum'] = filtered_df['daily_sum']/1000

# Timeseries query and preprocess SF data
det_fmikey = 'RR-M:ECXQSF:5054:1:0:1:0'
pert_fmikey = 'RR-M:ECXQSF:5054:1:0:3'  #:ensnro
pardict = {
    'ens0': det_fmikey, 'ens1': pert_fmikey + ':1', 'ens2': pert_fmikey + ':2', 'ens3': pert_fmikey + ':3',
    'ens4': pert_fmikey + ':4', 'ens5': pert_fmikey + ':5', 'ens6': pert_fmikey + ':6', 'ens7': pert_fmikey + ':7',
    'ens8': pert_fmikey + ':8', 'ens9': pert_fmikey + ':9', 'ens10': pert_fmikey + ':10', 'ens11': pert_fmikey + ':11',
    'ens12': pert_fmikey + ':12', 'ens13': pert_fmikey + ':13', 'ens14': pert_fmikey + ':14', 'ens15': pert_fmikey + ':15',
    'ens16': pert_fmikey + ':16', 'ens17': pert_fmikey + ':17', 'ens18': pert_fmikey + ':18', 'ens19': pert_fmikey + ':19',
    'ens20': pert_fmikey + ':20', 'ens21': pert_fmikey + ':21', 'ens22': pert_fmikey + ':22', 'ens23': pert_fmikey + ':23',
    'ens24': pert_fmikey + ':24', 'ens25': pert_fmikey + ':25', 'ens26': pert_fmikey + ':26', 'ens27': pert_fmikey + ':27',
    'ens28': pert_fmikey + ':28', 'ens29': pert_fmikey + ':29', 'ens30': pert_fmikey + ':30', 'ens31': pert_fmikey + ':31',
    'ens32': pert_fmikey + ':32', 'ens33': pert_fmikey + ':33', 'ens34': pert_fmikey + ':34', 'ens35': pert_fmikey + ':35',
    'ens36': pert_fmikey + ':36', 'ens37': pert_fmikey + ':37', 'ens38': pert_fmikey + ':38', 'ens39': pert_fmikey + ':39',
    'ens40': pert_fmikey + ':40', 'ens41': pert_fmikey + ':41', 'ens42': pert_fmikey + ':42', 'ens43': pert_fmikey + ':43',
    'ens44': pert_fmikey + ':44', 'ens45': pert_fmikey + ':45', 'ens46': pert_fmikey + ':46', 'ens47': pert_fmikey + ':47',
    'ens48': pert_fmikey + ':48', 'ens49': pert_fmikey + ':49', 'ens50': pert_fmikey + ':50'
}
source = 'desm.harvesterseasons.com:8080'
start = date[0:16]
origintime = date[:7] + '1' + date[8:16]
query = 'http://' + source + '/timeseries?latlon=' + lat + ',' + lon + '&param=utctime,'
for par in pardict.values():
    query += par + ','
query = query[0:-1]
query += '&starttime=' + start + '&timesteps=215&hour=00&format=json&precision=full&tz=utc&timeformat=sql&origintime=' + origintime
print(query)
response = requests.get(url=query)
df_ecxsf = pd.DataFrame(json.loads(response.content))
df_ecxsf.columns = ['utctime'] + [*pardict]  # change headers to params.keys
df_ecxsf['utctime'] = pd.to_datetime(df_ecxsf['utctime'])
df_ecxsf = df_ecxsf.set_index('utctime')
df_ecxsf.index = pd.to_datetime(df_ecxsf.index)

# Merge the observation and forecast dataframes
merged_df = pd.merge(
    df_ecxsf, filtered_df,
    left_index=True, right_on='date',
    how='inner'  # Use 'inner' to include only matching rows, or 'left' for all from df1
)
merged_df.set_index('date', inplace=True)
#merged_df.drop(columns=['daily_sum'], inplace=True)
merged_df.drop(columns=['accumulated_sum'], inplace=True)

# disaccumulate ecsf
merged_df = merged_df.fillna(0.0)
ensemble_columns = [col for col in merged_df.columns if col.startswith('ens')]
df_disaccumulated_1 = merged_df.copy()  # Create a copy to avoid modifying the original dataframe
df_disaccumulated_1[ensemble_columns] = merged_df[ensemble_columns].diff()
df_disaccumulated_1.loc[df_disaccumulated_1.index[0], ensemble_columns] = merged_df.loc[merged_df.index[0], ensemble_columns]

print(merged_df)

# Plot the ensemble forecast and observed total precipitation
plt.figure(figsize=(12, 6))
ens_columns = [col for col in df_disaccumulated_1.columns if 'ens' in col]  # List all columns that contain 'ens'
for col in ens_columns:
    plt.plot(df_disaccumulated_1.index, df_disaccumulated_1[col], label=col, color='blue', alpha=0.7)
plt.plot(df_disaccumulated_1.index, df_disaccumulated_1['daily_sum'], label='obs', color='red', linewidth=2)
plt.title('Seasonal forecast (XGB) and observed total precipitation for FMISID '+fmisid+' ('+start_date+')', fontsize=16)
plt.xlabel('Time (UTC)', fontsize=14)
plt.ylabel('Total precipitation (m)', fontsize=14)
plt.ylim(0,0.1)
plt.legend(loc='upper left', ncol=2, fontsize=10, bbox_to_anchor=(1.05, 1), borderaxespad=0.)
plt.grid(True, linestyle='--', alpha=0.6)
plt.tight_layout()

# Save the plot as PNG and PDF files
plt.savefig(fmisid+'_ensemble_plot-QE-dsum.png', dpi=300, bbox_inches='tight')  # Save as PNG with high resolution
plt.savefig(fmisid+'_ensemble_plot-QE-dsum.pdf', bbox_inches='tight')  # Save as PDF

plt.close()

# Plot ECSF for comparison
det_fmikey = 'RR-M:ECSF:5014:1:0:1:0'
pert_fmikey = 'RR-M:ECSF:5014:1:0:3'  #:ensnro
pardict = {
    'ens0': det_fmikey, 'ens1': pert_fmikey + ':1', 'ens2': pert_fmikey + ':2', 'ens3': pert_fmikey + ':3',
    'ens4': pert_fmikey + ':4', 'ens5': pert_fmikey + ':5', 'ens6': pert_fmikey + ':6', 'ens7': pert_fmikey + ':7',
    'ens8': pert_fmikey + ':8', 'ens9': pert_fmikey + ':9', 'ens10': pert_fmikey + ':10', 'ens11': pert_fmikey + ':11',
    'ens12': pert_fmikey + ':12', 'ens13': pert_fmikey + ':13', 'ens14': pert_fmikey + ':14', 'ens15': pert_fmikey + ':15',
    'ens16': pert_fmikey + ':16', 'ens17': pert_fmikey + ':17', 'ens18': pert_fmikey + ':18', 'ens19': pert_fmikey + ':19',
    'ens20': pert_fmikey + ':20', 'ens21': pert_fmikey + ':21', 'ens22': pert_fmikey + ':22', 'ens23': pert_fmikey + ':23',
    'ens24': pert_fmikey + ':24', 'ens25': pert_fmikey + ':25', 'ens26': pert_fmikey + ':26', 'ens27': pert_fmikey + ':27',
    'ens28': pert_fmikey + ':28', 'ens29': pert_fmikey + ':29', 'ens30': pert_fmikey + ':30', 'ens31': pert_fmikey + ':31',
    'ens32': pert_fmikey + ':32', 'ens33': pert_fmikey + ':33', 'ens34': pert_fmikey + ':34', 'ens35': pert_fmikey + ':35',
    'ens36': pert_fmikey + ':36', 'ens37': pert_fmikey + ':37', 'ens38': pert_fmikey + ':38', 'ens39': pert_fmikey + ':39',
    'ens40': pert_fmikey + ':40', 'ens41': pert_fmikey + ':41', 'ens42': pert_fmikey + ':42', 'ens43': pert_fmikey + ':43',
    'ens44': pert_fmikey + ':44', 'ens45': pert_fmikey + ':45', 'ens46': pert_fmikey + ':46', 'ens47': pert_fmikey + ':47',
    'ens48': pert_fmikey + ':48', 'ens49': pert_fmikey + ':49', 'ens50': pert_fmikey + ':50'
}
query = 'http://' + source + '/timeseries?latlon=' + lat + ',' + lon + '&param=utctime,'
for par in pardict.values():
    query += par + ','
query = query[0:-1]
query += '&starttime=' + start + '&timesteps=215&hour=00&format=json&precision=full&tz=utc&timeformat=sql&origintime=' + origintime
print(query)
response = requests.get(url=query)
df_ecsf = pd.DataFrame(json.loads(response.content))
df_ecsf.columns = ['utctime'] + [*pardict]  # change headers to params.keys
df_ecsf['utctime'] = pd.to_datetime(df_ecsf['utctime'])
df_ecsf = df_ecsf.set_index('utctime')
df_ecsf.index = pd.to_datetime(df_ecsf.index)
print(df_ecsf)

# Merge the observation and forecast dataframes
merged_df_2 = pd.merge(
    df_ecsf, filtered_df,
    left_index=True, right_on='date',
    how='inner'  # Use 'inner' to include only matching rows, or 'left' for all from df1
)
merged_df_2.set_index('date', inplace=True)
#merged_df_2.drop(columns=['daily_sum'], inplace=True)
merged_df_2.drop(columns=['accumulated_sum'], inplace=True)
# disaccumulate ecsf
merged_df_2 = merged_df_2.fillna(0.0)
ensemble_columns = [col for col in merged_df_2.columns if col.startswith('ens')]
df_disaccumulated = merged_df_2.copy()  # Create a copy to avoid modifying the original dataframe
df_disaccumulated[ensemble_columns] = merged_df_2[ensemble_columns].diff()
df_disaccumulated.loc[df_disaccumulated.index[0], ensemble_columns] = merged_df_2.loc[merged_df_2.index[0], ensemble_columns]

#print(df_disaccumulated)
#print(merged_df_2)
#print(merged_df)

# Plot the ensemble forecast and observed total precipitation
plt.figure(figsize=(12, 6))
ens_columns = [col for col in df_disaccumulated.columns if 'ens' in col]  # List all columns that contain 'ens'
for col in ens_columns:
    plt.plot(df_disaccumulated.index, df_disaccumulated[col], label=col, color='blue', alpha=0.7)
plt.plot(df_disaccumulated.index, df_disaccumulated['daily_sum'], label='obs', color='red', linewidth=2)
plt.title('Seasonal forecast (ECSF) and observed total precipitation for FMISID '+fmisid+' ('+start_date+')', fontsize=16)
plt.xlabel('Time (UTC)', fontsize=14)
plt.ylabel('Total precipitation (m)', fontsize=14)
plt.ylim(0,0.1)
plt.legend(loc='upper left', ncol=2, fontsize=10, bbox_to_anchor=(1.05, 1), borderaxespad=0.)
plt.grid(True, linestyle='--', alpha=0.6)
plt.tight_layout()

# Save the plot as PNG and PDF files
plt.savefig(fmisid+'_ensemble_plot-ecsf-dsum.png', dpi=300, bbox_inches='tight')  # Save as PNG with high resolution
plt.savefig(fmisid+'_ensemble_plot-ecsf-dsum.pdf', bbox_inches='tight')  # Save as PDF
