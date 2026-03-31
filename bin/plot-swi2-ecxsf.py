import requests, json, sys
import pandas as pd
from matplotlib import pyplot as plt
import cartopy.crs as ccrs
import cartopy.feature as cfeature

def make_ensdict(sf, sf_control):
    ensdict={}
    ensdict['ens0']=sf_control
    for i in range(1, 51):
        ensdict[f'ens{i}']=sf+f':{i}'
    return ensdict

points = {
    "Finland":  (63.05, 29.85),
    "Sweden":   (57.10, 14.70),
    "Germany":  (52.85, 13.25),
    "France":   (44.20, -0.80),
    "Spain":    (41.95, -3.90),
    "Poland":   (53.80, 17.60),
    "Ukraine":  (51.20, 28.70),
    "Greece":   (40.05, 21.05),
    "Latvia":   (57.15, 25.30),
    "Slovenia": (46.30, 14.90),
    "Estonia":  (58.70, 25.80),
    "Czech":    (49.60, 15.30),
    "Denmark":  (56.20, 10.20),
}
country=sys.argv[1]
lat, lon = points[country]

# ECXSF XGBoost SWI2 seasonal forecasts
sf_control='SWI2:ECXSF:5062:1:0:1:0'
sf='SWI2:ECXSF:5062:1:0:3'#:ensnro
xsfdict=make_ensdict(sf, sf_control)
# make xsfdict string for query
xsf_params=''
for par in xsfdict.values():
    xsf_params+=par+','
xsf_params=xsf_params[0:-1] # remove last comma
# ensemble mean
emean=f'AVG{{{sf_control};{sf}:1-50}}'

# SWI SWI2 satellite-based observations
#swi='SWI2:SWI:5059:1:0:0'
swi='SWI2:SWI:5022:1:0:0' # ERA5L grid that is also in ECXSF

# SWI2CLIM climatology
swi2clim='SWI2:SWIC:5022:1:0:0' # ERA5L grid that is also in ECXSF

# ts queries
source='smartmet.xyz:8080'
start='20250410T000000Z'
origintime='20250401T000000Z'
ts='205' # number of timesteps

# ECXSF forecasts query
query=f'http://{source}/timeseries?latlon={lat},{lon}&param=utctime,{xsf_params},{emean}&starttime={start}&hour=0&timesteps={ts}&format=json&precision=full&tz=utc&timeformat=sql&origintime={origintime}'
print(query)
response=requests.get(url=query)
df=pd.DataFrame(json.loads(response.content))
df.columns=['utctime']+list(xsfdict.keys())+['ensmean'] # change headers to params.keys
df['utctime']=pd.to_datetime(df['utctime'])
df=df.set_index('utctime') # vsw
print(df)
    
# SWI2 observations query
hour='12' # swi2
query=f'http://{source}/timeseries?latlon={lat},{lon}&param=utctime,{swi}&starttime={start}&timesteps={ts}&hour={hour}&format=json&precision=full&tz=utc&timeformat=sql'
print(query)
response=requests.get(url=query)
df2=pd.DataFrame(json.loads(response.content))
df2.columns=['utctime','swi2']  
df2['utctime']=pd.to_datetime(df2['utctime']).dt.date 
df2['utctime']=pd.to_datetime(df2['utctime'])
df2=df2.set_index('utctime') # vsw
print(df2)

# SWI2 climatology query
origintime='20000101T000000'
hour='00' # swi2clim
query=f'http://{source}/timeseries?latlon={lat},{lon}&param=utctime,{swi2clim}&starttime={start}&timesteps={ts}&hour={hour}&format=json&precision=full&tz=utc&timeformat=sql&origintime={origintime}'
print(query)
response=requests.get(url=query)
df3=pd.DataFrame(json.loads(response.content))
df3.columns=['utctime','swi2clim']  
df3['utctime']=pd.to_datetime(df3['utctime']).dt.date 
df3['utctime']=pd.to_datetime(df3['utctime'])
df3=df3.set_index('utctime') # vsw
print(df3)

# merge ECXSF and SWI2 dataframes
df_fin=df.merge(df2, how='left', left_index=True, right_index=True)
df_fin=df_fin.merge(df3, how='left', left_index=True, right_index=True) 
print(df_fin)

# Plot ECXSF forecasts and SWI2 observations
colorsdict={}
for i in range(0, 51):
    colorsdict[f'ens{i}']='blue'
colorsdict['ensmean']='yellow'
colorsdict['swi2']='red'
colorsdict['swi2clim']='black'

# plot figure with colorsdict
mytitle=f'2025 April {country}, ({lat}, {lon})'
plot = df_fin.plot(figsize=(15,10),color=colorsdict, title=mytitle, legend=False)
fig = plot.get_figure()
from matplotlib.lines import Line2D

custom_legend = [
    Line2D([0], [0], color='blue', lw=1, label='ECXSF 51 ensemble members'),
    Line2D([0], [0], color='yellow', lw=2, label='ECXSF ensemble mean'),
    Line2D([0], [0], color='red', lw=2, label='SWI2 observation'),
    Line2D([0], [0], color='black', lw=2, label='SWI2 climatology'),
]

plot.legend(
    handles=custom_legend,
    loc='upper left',
    bbox_to_anchor=(0.75, 1.13),
    frameon=False
)

fig.savefig(f'/home/ubuntu/data/swi2valid/ECXSF_SWI2_202504_{country}.png')
fig.savefig(f'/home/ubuntu/data/swi2valid/ECXSF_SWI2_202504_{country}.svg', format='svg')

# Plot locations to map 
extent = (-12, 45, 34, 72) # Europe

fig = plt.figure(figsize=(10, 8))
ax = plt.axes(projection=ccrs.PlateCarree())
ax.set_extent(extent, crs=ccrs.PlateCarree())

# Base map: land/ocean + borders
ax.add_feature(cfeature.OCEAN)
ax.add_feature(cfeature.LAND, edgecolor="none")
ax.add_feature(cfeature.BORDERS, linewidth=0.8)
ax.add_feature(cfeature.COASTLINE, linewidth=0.8)

# Optional: admin-1 boundaries if you want more detail
# ax.add_feature(cfeature.STATES, linewidth=0.3)  # works mainly for some datasets/regions

# Plot points
lats = [lat for (lat, lon) in points.values()]
lons = [lon for (lat, lon) in points.values()]
ax.scatter(
    lons, lats,
    s=80, marker="o",
    color="red",
    transform=ccrs.PlateCarree(),
    zorder=5,
)

# Labels (slight offset so they don't overlap the dot)
for name, (lat, lon) in points.items():
    ax.text(
        lon + 0.5, lat + 0.3, name,
        transform=ccrs.PlateCarree(),
        fontsize=9,
        zorder=6,
        bbox=dict(boxstyle="round,pad=0.2", fc="white", ec="none", alpha=0.7),
    )

ax.set_title("Selected locations in Europe", fontsize=14)
plt.tight_layout()
plt.savefig("/home/ubuntu/data/swi2valid/Europe_forest_points_map.svg", format="svg")
plt.savefig("/home/ubuntu/data/swi2valid/Europe_forest_points_map.png", dpi=300)