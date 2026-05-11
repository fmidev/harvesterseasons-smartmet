import xarray as xr
import cfgrib, time, sys, json
import pandas as pd
import xgboost as xgb
import os
import warnings

warnings.simplefilter(action='ignore', category=FutureWarning)

# Helper to open a GRIB file, select variables, and subset by region

# Robustly open each variable separately to avoid cfgrib DatasetBuildError
def open_grib_vars(filepath, var_map, lon_min=19.995536, lon_max=28.924, lat_min=54.066, lat_max=62.995536, backend_kwargs=None):
    datasets = []
    missing_vars = []
    # Baltic grid definition
    import numpy as np
    baltic_lon_start = 19.995536
    baltic_lon_inc = 0.008929
    baltic_lon_size = 1000
    baltic_lat_start = 62.995536
    baltic_lat_inc = -0.008929
    baltic_lat_size = 1000
    baltic_lons = np.round(baltic_lon_start + np.arange(baltic_lon_size) * baltic_lon_inc, 6)
    baltic_lats = np.round(baltic_lat_start + np.arange(baltic_lat_size) * baltic_lat_inc, 6)

    for out_var, grib_var in var_map.items():
        try:
            # Try paramId if grib_var is int, else shortName
            filter_key = {'shortName': grib_var} if isinstance(grib_var, str) else {'paramId': grib_var}
            ds = xr.open_dataset(
                filepath,
                engine='cfgrib',
                backend_kwargs={'filter_by_keys': filter_key}
            )
            # Rename to output variable name if needed
            if grib_var in ds.variables:
                ds = ds.rename({grib_var: out_var})
            # Get the data array - keep time dimension, only drop non-spatial/temporal dims
            da = ds[out_var]
            # Find non-lat/lon/time dims to drop (e.g., step, number, surface, etc.)
            reduce_dims = [d for d in da.dims if d not in ('lat', 'lon', 'latitude', 'longitude', 'time', 'valid_time')]
            for d in reduce_dims:
                da = da.isel({d: 0})
            # After reduction, check for lat/lon dims
            lat_dim = 'lat' if 'lat' in da.dims else 'latitude' if 'latitude' in da.dims else None
            lon_dim = 'lon' if 'lon' in da.dims else 'longitude' if 'longitude' in da.dims else None
            if lat_dim and lon_dim:
                # Rename to standard names for interpolation
                da = da.rename({lat_dim: 'lat', lon_dim: 'lon'})
                # Interpolate to Baltic grid
                try:
                    da_interp = da.interp(lon=baltic_lons, lat=baltic_lats)
                    datasets.append(da_interp.to_dataset(name=out_var))
                except Exception as e:
                    print(f"Warning: Could not interpolate variable '{out_var}' to Baltic grid: {e}")
                    missing_vars.append(out_var)
            else:
                print(f"Warning: Variable '{out_var}' could not be reduced to 2D lat/lon, skipping. Dims: {da.dims}")
                missing_vars.append(out_var)
        except Exception as e:
            print(f"Warning: Could not load variable '{grib_var}' from {filepath}: {e}")
            missing_vars.append(out_var)
    if not datasets:
        print(f"Warning: None of the expected variables {list(var_map.values())} found in {filepath}")
        return None
    # Merge all loaded datasets
    try:
        merged = xr.merge(datasets, compat='override')
    except Exception as e:
        print(f"Error merging variables from {filepath}: {e}")
        return None
    if missing_vars:
        print(f"Warning: The following variables could not be loaded or regridded from {filepath}: {missing_vars}")
    return merged


# Track failed variable loads
failed_vars = []

def try_open_grib_vars(label, *args, **kwargs):
    try:
        ds = open_grib_vars(*args, **kwargs)
        if ds is None or (hasattr(ds, 'variables') and len(ds.variables) == 0):
            failed_vars.append(label)
        return ds
    except Exception as e:
        print(f"Error loading {label}: {e}")
        failed_vars.append(label)
        return None

# 1. rad+heat
radheat_vars = {
    'slhf': 'slhf',
    'ssr': 'ssr',
    'str': 'str',
    'sshf': 'sshf',
    'ssrd': 'ssrd',
    'strd': 'strd'
}
radheat = try_open_grib_vars('radheat', '/home/ubuntu/data/grib/ERA5L_20000101T000000_202412_rad+heat.grib', radheat_vars)

# 2. evaporation-runoff
evaprunoff_vars = {
    'ro': 'ro',
    'ssro': 'ssro',
    'sro': 'sro',
    'e': 'e'
}
evaprunoff = try_open_grib_vars('evaprunoff', '/home/ubuntu/data/grib/ERA5L_20000101T000000_202412_evaporation-runoff.grib', evaprunoff_vars)

# 3. snow
def open_snow_vars():
    try:
        snow_sf = xr.open_dataset(
            '/home/ubuntu/data/grib/ERA5L_20000101T000000_202412_snow.grib',
            engine='cfgrib',
            backend_kwargs={'filter_by_keys': {'paramId': 33}}
        )
        snow_sd = xr.open_dataset(
            '/home/ubuntu/data/grib/ERA5L_20000101T000000_202412_snow.grib',
            engine='cfgrib',
            backend_kwargs={'filter_by_keys': {'paramId': 141}}
        )
        snow_rsn = xr.open_dataset(
            '/home/ubuntu/data/grib/ERA5L_20000101T000000_202412_snow.grib',
            engine='cfgrib',
            backend_kwargs={'filter_by_keys': {'paramId': 144}}
        )
        snow_sf = snow_sf.rename({'rsn': 'sf'}) if 'rsn' in snow_sf.variables else snow_sf
        snow_sd = snow_sd.rename({'sd': 'sd'}) if 'sd' in snow_sd.variables else snow_sd
        snow_rsn = snow_rsn.rename({'sf': 'rsn'}) if 'sf' in snow_rsn.variables else snow_rsn
        return xr.merge([snow_sf, snow_sd, snow_rsn], compat='override')
    except Exception as e:
        print(f"Error loading snow: {e}")
        failed_vars.append('snow')
        return None
snow = open_snow_vars()

# 4. soilwater
soilwater_vars = {
    'swvl1': 'swvl1',
}
soilwater = try_open_grib_vars('soilwater', '/home/ubuntu/data/grib/ERA5L_20000101T000000_202412_soilwater.grib', soilwater_vars)


# 5. temperatures (updated variable mapping)
temp_vars = {
    't2m': '2t',
    'd2m': '2d',
    'skt': 'skt',
    'stl1': 'stl1',
}
temperatures = try_open_grib_vars('temperatures', '/home/ubuntu/data/grib/ERA5L_20000101T000000_2024_temperatures.grib', temp_vars)

# 6. vegetation
veg_vars = {
    'lai_hv': 'lai_hv',
    'lai_lv': 'lai_lv',
}
vegetation = try_open_grib_vars('vegetation', '/home/ubuntu/data/grib/ERA5L_20000101T000000_2024_vegetation.grib', veg_vars)

# 4. wind-pressure-precipitation (updated to match GRIB file shortNames)
windpress_vars = {
    'u10': '10u',
    'v10': '10v',
    'sp': 'sp',
    'tp': 'tp'
}
windpress = try_open_grib_vars('windpress', '/home/ubuntu/data/grib/ERA5L_20000101T000000_2024_wind-pressure-precipitation.grib', windpress_vars)

# 8. daily max/min temperature
try:
    tmax = xr.open_dataset('/home/ubuntu/data/grib/ERA5LD_20250101T000000_202412_2m_temperature-daily_maximum.grib', engine='cfgrib')
    if 'lon' in tmax.dims and 'lat' in tmax.dims:
        tmax = tmax.sel(lon=slice(19.995536, 28.924), lat=slice(62.995536, 54.066)).rename({'mn2t24': 'tmax'})
except Exception as e:
    print(f"Error loading tmax: {e}")
    failed_vars.append('tmax')
    tmax = None
try:
    tmin = xr.open_dataset('/home/ubuntu/data/grib/ERA5LD_20250101T000000_202412_2m_temperature-daily_minimum.grib', engine='cfgrib')
    if 'lon' in tmin.dims and 'lat' in tmin.dims:
        tmin = tmin.sel(lon=slice(19.995536, 28.924), lat=slice(62.995536, 54.066)).rename({'mx2t24': 'tmin'})
except Exception as e:
    print(f"Error loading tmin: {e}")
    failed_vars.append('tmin')
    tmin = None
# 9. pressure level variables
def open_pl_var(filepath, varname, levels, label):
    try:
        ds = xr.open_dataset(filepath, engine='cfgrib')
        if varname not in ds.variables:
            print(f"Warning: '{varname}' not found in {filepath}. Available: {list(ds.variables.keys())}")
            failed_vars.append(label)
            return None
        arrs = []
        import numpy as np
        baltic_lon_start = 19.995536
        baltic_lon_inc = 0.008929
        baltic_lon_size = 1000
        baltic_lat_start = 62.995536
        baltic_lat_inc = -0.008929
        baltic_lat_size = 1000
        baltic_lons = np.round(baltic_lon_start + np.arange(baltic_lon_size) * baltic_lon_inc, 6)
        baltic_lats = np.round(baltic_lat_start + np.arange(baltic_lat_size) * baltic_lat_inc, 6)
        for lev in levels:
            try:
                arr = ds[varname].sel(isobaricInhPa=lev)
                arr.name = f"{varname}{lev}"
                # Drop non-spatial/temporal dims but keep time
                for d in arr.dims:
                    if d not in ('lat', 'lon', 'latitude', 'longitude', 'time', 'valid_time'):
                        arr = arr.isel({d: 0})
                lat_dim = 'lat' if 'lat' in arr.dims else 'latitude' if 'latitude' in arr.dims else None
                lon_dim = 'lon' if 'lon' in arr.dims else 'longitude' if 'longitude' in arr.dims else None
                if lat_dim and lon_dim:
                    arr = arr.rename({lat_dim: 'lat', lon_dim: 'lon'})
                    arr_interp = arr.interp(lon=baltic_lons, lat=baltic_lats)
                    arrs.append(arr_interp.to_dataset(name=arr.name))
                else:
                    print(f"Warning: Pressure-level variable '{varname}{lev}' could not be reduced to 2D lat/lon, skipping. Dims: {arr.dims}")
            except Exception as e:
                print(f"Could not extract {varname} at {lev} hPa: {e}")
        if arrs:
            return xr.merge(arrs, compat='override')
        else:
            failed_vars.append(label)
            return None
    except Exception as e:
        print(f"Error loading {label}: {e}")
        failed_vars.append(label)
        return None

pl_temp = open_pl_var('/home/ubuntu/data/grib/ERA5_20000101T000000_20241231T120000_pl_temperature_12h.grib', 't', [500, 700, 850], 'pl_temp')
pl_v = open_pl_var('/home/ubuntu/data/grib/ERA5_20000101T000000_20241231T120000_pl_v_component_of_wind_12h.grib', 'v', [500, 700, 850], 'pl_v')
pl_u = open_pl_var('/home/ubuntu/data/grib/ERA5_20000101T000000_20241231T120000_pl_u_component_of_wind_12h.grib', 'u', [500, 700, 850], 'pl_u')
pl_q = open_pl_var('/home/ubuntu/data/grib/ERA5_20000101T000000_20241231T120000_pl_specific_humidity_12h.grib', 'q', [500, 700, 850], 'pl_q')

# 13. static fields
def subset_static(ds):
    if 'lon' in ds.dims and 'lat' in ds.dims:
        return ds.sel(lon=slice(19.995536, 28.924), lat=slice(62.995536, 54.066))
    return ds

def try_open_static_var(label, filepath, wanted, rename_to):
    try:
        ds = xr.open_dataset(filepath, engine='cfgrib')
        print(f"Static file {filepath} variables: {list(ds.variables.keys())}")
        if wanted not in ds.variables:
            print(f"Warning: '{wanted}' not found in {filepath}. Available: {list(ds.variables.keys())}")
            failed_vars.append(label)
            return None
        da = ds[wanted]
        # Drop non-spatial dims but keep time if it exists (static fields may not have time)
        for d in da.dims:
            if d not in ('lat', 'lon', 'latitude', 'longitude', 'time', 'valid_time'):
                da = da.isel({d: 0})
        # Interpolate to Baltic grid
        import numpy as np
        baltic_lon_start = 19.995536
        baltic_lon_inc = 0.008929
        baltic_lon_size = 1000
        baltic_lat_start = 62.995536
        baltic_lat_inc = -0.008929
        baltic_lat_size = 1000
        baltic_lons = np.round(baltic_lon_start + np.arange(baltic_lon_size) * baltic_lon_inc, 6)
        baltic_lats = np.round(baltic_lat_start + np.arange(baltic_lat_size) * baltic_lat_inc, 6)
        lat_dim = 'lat' if 'lat' in da.dims else 'latitude' if 'latitude' in da.dims else None
        lon_dim = 'lon' if 'lon' in da.dims else 'longitude' if 'longitude' in da.dims else None
        if lat_dim and lon_dim:
            da = da.rename({lat_dim: 'lat', lon_dim: 'lon'})
            da_interp = da.interp(lon=baltic_lons, lat=baltic_lats)
            return da_interp.to_dataset(name=rename_to)
        else:
            print(f"Warning: Static variable '{wanted}' could not be reduced to 2D lat/lon, skipping. Dims: {da.dims}")
            failed_vars.append(label)
            return None
    except Exception as e:
        print(f"Error loading {label}: {e}")
        failed_vars.append(label)
        return None

cl = try_open_static_var('cl', '/home/ubuntu/data/grib/ECC_20000101T000000_ilwaterc-frac-eu-fix.grib', 'cl', 'cl')
cur = try_open_static_var('cur', '/home/ubuntu/data/grib/ECC_20000101T000000_urbancov-eu-fix.grib', 'cur', 'cur')
cvn = try_open_static_var('cvn', '/home/ubuntu/data/grib/ECC_20000101T000000_hveg-frac-eu-fix.grib', 'cvh', 'cvh')
cvl = try_open_static_var('cvl', '/home/ubuntu/data/grib/ECC_20000101T000000_lveg-frac-eu-fix.grib', 'cvl', 'cvl')
dl = try_open_static_var('dl', '/home/ubuntu/data/grib/ECC_20000101T000000_ilwater-depth-eu-fix.grib', 'dl', 'dl')
lc = try_open_static_var('lc', '/home/ubuntu/data/grib/ECC_20000101T000000_lc-frac-eu-fix.grib', 'lsm', 'lc')
soilt = try_open_static_var('soilt', '/home/ubuntu/data/grib/ECC_20000101T000000_soiltype-eu-fix.grib', 'slt', 'soilt')
tvh = try_open_static_var('tvh', '/home/ubuntu/data/grib/ECC_20000101T000000_hveg-type-eu-fix.grib', 'tvh', 'tvh')
tvl = try_open_static_var('tvl', '/home/ubuntu/data/grib/ECC_20000101T000000_lveg-type-eu-fix.grib', 'tvl', 'tvl')
z = try_open_static_var('z', '/home/ubuntu/data/grib/ECC_20000101T000000_sfc-gp-eu.grib', 'z', 'z')
hl = try_open_static_var('hl', '/home/ubuntu/data/grib/UMD_20190701T000000_h-fch-avg_eu-de.grb', 'h', 'hl')
laihv_ecc = try_open_static_var('laihv_ecc', '/home/ubuntu/data/grib/ECC_20000101T000000_2020-21_laihv-eu-swi-day.grib', 'lai_hv', 'laihv_ecc')
lailv_ecc = try_open_static_var('lailv_ecc', '/home/ubuntu/data/grib/ECC_20000101T000000_2020-21_lailv-eu-swi-day.grib', 'lai_lv', 'lailv_ecc')

# Now you have all variables loaded as xarray Datasets or DataArrays.

# --- XGBoost Prediction Section ---
# 1. Load the XGBoost model
model = xgb.Booster()
model.load_model('/home/ubuntu/data/aurora/model_skt_combined.json')

# 2. Prepare the input features for prediction
# Example: concatenate all variables into a single DataFrame
# (You may need to adjust the feature order and selection to match model training)

# Collect all DataArrays into a list


# Find reference grid (lat/lon/time) from the first available dataset

# Try to find reference grid from loaded data, else use Baltic-1km-grid metadata
ref = None
for da in [radheat, evaprunoff, snow, soilwater, temperatures, vegetation, windpress]:
    if da is not None and hasattr(da, 'lat') and hasattr(da, 'lon'):
        ref = da
        break
if ref is None:
    # Fallback: create reference grid from Baltic-1km-grid metadata
    import numpy as np
    lon_start = 19.995536
    lon_inc = 0.008929
    lon_size = 1000
    lat_start = 62.995536
    lat_inc = -0.008929
    lat_size = 1000
    lons = np.round(lon_start + np.arange(lon_size) * lon_inc, 6)
    lats = np.round(lat_start + np.arange(lat_size) * lat_inc, 6)
    ref_lat = xr.DataArray(lats, dims='lat', name='lat')
    ref_lon = xr.DataArray(lons, dims='lon', name='lon')
    ref_time = None
else:
    ref_lat = ref['lat'] if 'lat' in ref.coords else ref['latitude']
    ref_lon = ref['lon'] if 'lon' in ref.coords else ref['longitude']
    ref_time = ref['time'] if 'time' in ref.coords else None

def align_to_ref(ds):
    # Align lat/lon/time if present
    sel = {}
    if 'lat' in ds.coords:
        sel['lat'] = ref_lat
    elif 'latitude' in ds.coords:
        sel['latitude'] = ref_lat
    if 'lon' in ds.coords:
        sel['lon'] = ref_lon
    elif 'longitude' in ds.coords:
        sel['longitude'] = ref_lon
    if ref_time is not None and 'time' in ds.coords:
        sel['time'] = ref_time
    try:
        return ds.sel(**sel)
    except Exception:
        return ds  # fallback: return as is



# Align and collect all DataArrays, print their shapes for debugging
data_arrays = []
for idx, da in enumerate([radheat, evaprunoff, snow, soilwater, temperatures, vegetation, windpress, tmax, tmin, pl_temp, pl_v, pl_u, pl_q, cl, cur, cvn, cvl, dl, lc, soilt, tvh, tvl, z, hl, laihv_ecc, lailv_ecc]):
    if da is not None:
        aligned = align_to_ref(da)
        # Print shape and variable names for debugging
        if isinstance(aligned, xr.Dataset):
            dims = list(aligned.dims)
            shape = tuple(aligned.dims[d] for d in dims)
            print(f"DataArray {idx}: Dataset variables: {list(aligned.variables.keys())}, dims: {dict(aligned.dims)}")
            # Only add if shape is (1000, 1000) for lat/lon or lon/lat
            if (('lat' in aligned.dims and 'lon' in aligned.dims and aligned.dims['lat'] == 1000 and aligned.dims['lon'] == 1000) or
                ('lon' in aligned.dims and 'lat' in aligned.dims and aligned.dims['lon'] == 1000 and aligned.dims['lat'] == 1000)):
                data_arrays.append(aligned)
            else:
                print(f"Warning: Skipping DataArray {idx} due to shape {shape} (dims: {dims})")
        else:
            print(f"DataArray {idx}: DataArray name: {aligned.name}, shape: {aligned.shape}, dims: {aligned.dims}")
            # Only add if shape is (1000, 1000)
            if aligned.shape == (1000, 1000):
                data_arrays.append(aligned)
            else:
                print(f"Warning: Skipping DataArray {idx} due to shape {aligned.shape}")

# Merge all DataArrays into a single xarray.Dataset
merged = xr.merge([da if isinstance(da, xr.Dataset) else da.to_dataset() for da in data_arrays], compat='override')

# Flatten the grid to a DataFrame: (n_points * n_times, n_features)
df = merged.to_dataframe().reset_index()

# Store grid structure for reshaping predictions later
if 'time' in df.columns:
    grid_coords = df[['time', 'lat', 'lon']].copy()
else:
    grid_coords = df[['lat', 'lon']].copy()

# Drop non-feature columns and non-numeric columns
non_feature_cols = ['lat', 'lon', 'time', 'step', 'valid_time']
feature_cols = [col for col in df.columns if col not in non_feature_cols]
X = df[feature_cols]
X = X.select_dtypes(include=[int, float, bool])

# Rename columns to match model's expected features
rename_map = {
    't2m': 't2',
    'd2m': 'td2',
    'lai_hv': 'laihv',
    'lai_lv': 'lailv',
    'mx2t24': 'tmax',
    'mn2t24': 'tmin',
    # Add more mappings as needed
}
X = X.rename(columns=rename_map)

# Model's expected features (from error message)
expected_features = [
    'latitude', 'longitude', 'closest_hour', 'dayofyear', 'month', 'laihv', 'lailv', 'rsn', 'sd', 'sp', 'stl1', 'swvl1', 'swvl2', 'swvl3', 'swvl4', 't2', 'td2', 'u10', 'v10', 'q500', 'q700', 'q850', 't500', 't700', 't850', 'u500', 'u700', 'u850', 'v500', 'v700', 'v850', 'z500', 'z700', 'z850', 'e', 'ro', 'sf', 'slhf', 'sro', 'sshf', 'ssr', 'ssrd', 'ssro', 'str', 'strd', 'tp', 'tmax', 'tmin', 'cl', 'cur', 'cvn', 'cvl', 'dl', 'lc', 'soilt', 'tvh', 'tvl', 'z', 'hl', 'day', 'laihv_ecc'
]

# Add missing columns as NaN, drop extra columns
for col in expected_features:
    if col not in X.columns:
        X[col] = float('nan')
X = X[expected_features]

# 3. Make predictions
dtest = xgb.DMatrix(X)
preds = model.predict(dtest)

# 4. Attach predictions back to grid coordinates
grid_coords['prediction'] = preds

# 5. Reshape predictions back to grid with time dimension if present
if 'time' in grid_coords.columns:
    grid_coords = grid_coords.set_index(['time', 'lat', 'lon'])
    result = grid_coords.to_xarray()
    prediction_grid = result['prediction']
else:
    grid_coords = grid_coords.set_index(['lat', 'lon'])
    result = grid_coords.to_xarray()
    prediction_grid = result['prediction']



# Save prediction as NetCDF (intermediate step) in /home/ubuntu/
prediction_grid.name = 'skt'
prediction_grid = prediction_grid.to_dataset()
netcdf_path = '/home/ubuntu/AURORA_20000101T000000_202412_skt_bl.nc'
grib_path = '/home/ubuntu/AURORA_20000101T000000_202412_skt_bl.grib'
prediction_grid.to_netcdf(netcdf_path)

# To convert to GRIB, run the following command in the shell (requires cdo):
# cdo -f grb copy /home/ubuntu/data/grib/AURORA_20000101T000000_202412_skt_bl.nc /home/ubuntu/data/grib/AURORA_20000101T000000_202412_skt_bl.grib

# Optionally, automate with os.system if cdo is available:
# os.system(f'cdo -f grb copy {netcdf_path} {grib_path}')
