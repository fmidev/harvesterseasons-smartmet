import xarray as xr
import numpy as np
import pandas as pd

# --- 1. Read GRIB files (single-variable GRIB assumed) ---
era5_file = "era5_temperature.grib"
sf_file = "seasonal_forecast_control.grib"

# Open GRIB files using cfgrib
era5 = xr.open_dataset(era5_file, engine="cfgrib")
sf = xr.open_dataset(sf_file, engine="cfgrib")

# Ensure lat/lon naming consistency
era5 = era5.rename({'latitude': 'lat', 'longitude': 'lon'})
sf = sf.rename({'latitude': 'lat', 'longitude': 'lon'})

# Check variable name (you may need to adjust these!)
era5_var = list(era5.data_vars)[0]  # e.g. 't2m'
sf_var = list(sf.data_vars)[0]      # e.g. 't2m'

# --- 2. Select a few sample ERA5 grid points (or loop all with care) ---
# Example: Select 4 grid points (small patch for test)
era5_sample = era5.isel(lat=slice(20, 22), lon=slice(20, 22))
era5_points = [(float(lat), float(lon)) for lat in era5_sample.lat.values for lon in era5_sample.lon.values]

# --- 3. Helper: Get 3x3 surrounding grid points (with tie-breaking) ---
def get_surrounding_sf_timeseries(sf_ds, varname, era_lat, era_lon):
    sf_lats = sf_ds.lat.values
    sf_lons = sf_ds.lon.values

    lat_diff = np.abs(sf_lats - era_lat)
    lon_diff = np.abs(sf_lons - era_lon)
    lat_idx = np.argmin(lat_diff)
    lon_idx = np.argmin(lon_diff)

    # Tie-breaker logic: prefer lower index (north/left) if ambiguous
    if np.count_nonzero(lat_diff == lat_diff[lat_idx]) > 1 and era_lat < sf_lats[lat_idx]:
        lat_idx -= 1
    if np.count_nonzero(lon_diff == lon_diff[lon_idx]) > 1 and era_lon < sf_lons[lon_idx]:
        lon_idx -= 1

    lat_idx = np.clip(lat_idx, 0, len(sf_lats) - 1)
    lon_idx = np.clip(lon_idx, 0, len(sf_lons) - 1)

    lat_inds = np.clip([lat_idx - 1, lat_idx, lat_idx + 1], 0, len(sf_lats) - 1)
    lon_inds = np.clip([lon_idx - 1, lon_idx, lon_idx + 1], 0, len(sf_lons) - 1)

    result = {}
    k = 0
    for i in lat_inds:
        for j in lon_inds:
            lat_val = float(sf_lats[i])
            lon_val = float(sf_lons[j])
            timeseries = sf_ds[varname].sel(lat=lat_val, lon=lon_val, method="nearest").values
            result[f"sf_{k}_lat"] = lat_val
            result[f"sf_{k}_lon"] = lon_val
            for t, val in enumerate(timeseries):
                result[f"sf_{k}_t{t}"] = val
            k += 1
    return result

# --- 4. Loop over ERA5 points and collect data ---
records = []
for era_lat, era_lon in era5_points:
    row = {
        "era_lat": era_lat,
        "era_lon": era_lon
    }
    sf_data = get_surrounding_sf_timeseries(sf, sf_var, era_lat, era_lon)
    row.update(sf_data)
    records.append(row)

# --- 5. Convert to DataFrame ---
df = pd.DataFrame(records)

# --- 6. Preview or save ---
print(df.head())
# df.to_csv("era5_sf_9point_series.csv", index=False)
