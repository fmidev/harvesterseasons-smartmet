import requests, json
import pandas as pd
from matplotlib import pyplot as plt
# Plot timeseries for seasonal forecast (SF) and observed total precipitation accumulation (AK 2025)
pd.set_option('mode.chained_assignment', None)  # turn off SettingWithCopyWarning 

def ensemble_dict(det_fmikey,pert_fmikey):
    pardict = {
    'lat':'latitude','lon':'longitude','ens0': det_fmikey, 'ens1': pert_fmikey + ':1', 'ens2': pert_fmikey + ':2', 'ens3': pert_fmikey + ':3',
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
    return pardict

# parameters
#'swi2-ecens':'SWI2:ECXENS:5072:1:0:0:0',
#'swi2-swi':'SWI2:SWI:5059:1:0:0',
#'swvl2-era5l':'SWVL2-M3M3:ERA5L:5022:9:1820:1',
#'swvl2-ecens':'SWVL2-M3M3:ECENS:5009:9:1820:1:0',
#'tp-ecens':'RR-M:ECENS:5009:1:0:1:0',
#'tp-era5l':'RR-M:ERA5L:5022:1:0:1:0'    

# tp-ecens
det_fmikey = 'RR-M:ECENS:5009:1:0:1:0'
pert_fmikey = 'RR-M:ECENS:5009:1:0:3'  #:ensnro
# swi2 ecxens
#det_fmikey = 'SWI2:ECXENS:5072:1:0:0:0'
#pert_fmikey = 'SWI2:ECXENS:5072:1:0:0'  #:ensnro
pardict=ensemble_dict(det_fmikey,pert_fmikey)

# Define the date range
start_date = '2025-02-25'
end_date = '2025-03-11'
date =start_date.replace('-', '')+'T120000Z-'+end_date.replace('-', '')+'T000000Z'  # sf date range

# source Smartmet-server
source = 'desm.harvesterseasons.com:8080'

# area
area = {
    "min_lat": 59.95867,
    "max_lat": 60.45867,
    "min_lon": 24.9459,
    "max_lon": 25.4459
}
bbox = f"{area['min_lon']},{area['min_lat']},{area['max_lon']},{area['max_lat']}"

# query
start = date[0:16]
origintime = start
query = 'http://' + source + '/timeseries?bbox=' + bbox + '&param=utctime,'
for par in pardict.values():
    query += par + ','
query = query[0:-1]
query += '&starttime=' + start + '&timesteps=15&hour=00,12&format=json&precision=full&tz=utc&timeformat=sql&origintime=' + origintime
print(query)
response = requests.get(url=query)
results_json=json.loads(response.content)
#print(results_json)
for i in range(len(results_json)):
    res1=results_json[i]
    for key,val in res1.items():
        if key!='utctime':   
            res1[key]=val.strip('[]').split()
df_ecens=pd.DataFrame(results_json)   
expl_cols=list(pardict.values())    
df_ecens=df_ecens.explode(expl_cols)
print(df_ecens)

df_ecens = df_ecens.explode(list(pardict.values()))
df_ecens['utctime'] = pd.to_datetime(df_ecens['utctime'])
df_ecens = df_ecens.set_index('utctime')

# Group by latitude and longitude
grouped = df_ecens.groupby(['latitude', 'longitude'])

# Plot each group's time series
i=0
for (lat, lon), group in grouped:
    i+=1
    group = group.drop(columns=['latitude', 'longitude'])
    group = group.apply(pd.to_numeric, errors='coerce')
    group.plot(figsize=(10, 5))
    plt.xlabel("Time")
    plt.ylabel("Value")
    plt.title(f"EC-ENS Timeseries for Point {str(i)})")
    plt.legend(loc='upper left', bbox_to_anchor=(1, 1))
    plt.grid(True)
    #plt.tight_layout()
    plt.savefig(f"ec_ens_timeseries_{str(i)}.png")
    plt.close()