import xarray as xr

data_dir = '/home/ubuntu/data/xgb-bias/training_data_fin/'
file1 = data_dir + 'ECSF_2020_pl-era5-nd.nc'
file2 = data_dir + 'ECSF_2021_pl-era5-nd.nc'
file3 = data_dir + 'ECSF_2022_pl-era5-nd.nc'
file4 = data_dir + 'ECSF_2023_pl-era5-nd.nc'
file5 = data_dir + 'ECSF_2024_pl-era5-nd.nc'

ds_list=[]

pl=['t','u']

ds1 = xr.open_dataset(file1).sel(plev=85000)[pl]

print(ds1)
ds2 = xr.open_dataset(file2).sel(plev=85000)
ds3 = xr.open_dataset(file3).sel(plev=85000)
ds4 = xr.open_dataset(file4).sel(plev=85000)
ds5 = xr.open_dataset(file5).sel(plev=85000)

ds_list.append(ds1)
ds_list.append(ds2)
ds_list.append(ds3)
ds_list.append(ds4)
ds_list.append(ds5)

ds_merged = xr.concat(ds_list, dim='time')
df = ds_merged.to_dataframe().reset_index()


# Example filtering to verify data (keeps duplicate dates from sf)
print("Example filter for specific lat/lon and time:")
example_filter = df[
    (df['time'] == '2021-02-24') & 
    (df['lat'] == 66.0) & 
    (df['lon'] == 25.5)
]
print(example_filter[['lat', 'lon','t','z']])

print("2022 Example filter for specific lat/lon and time:")
example_filter = df[
    (df['time'] == '2022-09-24') & 
    (df['lat'] == 66.0) & 
    (df['lon'] == 25.5)
]
print(example_filter[['lat', 'lon','t','z']])
print("Example filter for specific lat/lon and time:")
example_filter = df[
    (df['time'] == '2023-02-24') & 
    (df['lat'] == 66.0) & 
    (df['lon'] == 25.5)
]
print(example_filter[['lat', 'lon','t','z']])
print("Example filter for specific lat/lon and time:")
example_filter = df[
    (df['time'] == '2024-02-24') & 
    (df['lat'] == 66.0) & 
    (df['lon'] == 25.5)
]
print(example_filter[['lat', 'lon','t','z']])

print("Example filter for specific lat/lon and time:")
example_filter = df[
    (df['time'] == '2024-09-24') & 
    (df['lat'] == 66.0) & 
    (df['lon'] == 25.5)
]
print(example_filter[['lat', 'lon','t','z']])

