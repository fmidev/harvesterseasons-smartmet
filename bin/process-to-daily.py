import pandas as pd

# Read the CSV file
name = 'fmisid116891_2024'
hour = '6'
df = pd.read_csv(f'/home/ubuntu/data/synop/{name}_pra{hour}h.csv')

# Convert 'time' column to datetime
df['date'] = pd.to_datetime(df['time'])

# Resample the data by day and sum the 'PRA_PT1H_ACC' values
df_daily = df.resample('D', on='date')[f'PRA_PT{hour}H_ACC'].sum().reset_index()
df_daily = df_daily.rename(columns={f'PRA_PT{hour}H_ACC': 'PRA_PT24H_ACC'})

# Select the first occurrence of each day to get the additional columns
additional_columns = df.drop_duplicates(subset='date')[['date', 'lat', 'lon', 'fmisid', 'wmo']]

# Merge the additional columns into df_daily
df_daily = pd.merge(df_daily, additional_columns, on='date', how='left')

# Drop rows where 'fmisid' is missing
df_daily = df_daily.dropna(subset=['fmisid'])

# Reorder the columns to match the original CSV
df_daily = df_daily[['date', 'lat', 'lon', 'fmisid', 'wmo', 'PRA_PT24H_ACC']]

# Rename 'date' column back to 'time'
df_daily = df_daily.rename(columns={'date': 'time'})

# Round the 'PRA_PT24H_ACC' values to 2 decimal places
df_daily['PRA_PT24H_ACC'] = df_daily['PRA_PT24H_ACC'].round(2)

# Convert 'fmisid' and 'wmo' to integers
df_daily['fmisid'] = df_daily['fmisid'].astype(int)
df_daily['wmo'] = df_daily['wmo'].astype(int)

# Save the resulting DataFrame to a new CSV file
df_daily.to_csv(f'/home/ubuntu/data/synop/{name}_daily.csv', index=False)
