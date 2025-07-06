#!/usr/bin/env python3
import xarray as xr
import numpy as np

data_dir = '/home/ubuntu/data/grib/'

files = {
    'DTM_aspect': data_dir + 'COPERNICUS_20000101T000000_20110701_anor-dtm-aspect-avg_eu-era5.grib',
    'DTM_slope': data_dir + 'COPERNICUS_20000101T000000_20110701_slor-dtm-slope-avg_eu-era5.grib',
    'DTM_height': data_dir + 'COPERNICUS_20000101T000000_20110701_h-dtm-height-avg_eu-era5.grib',
}

for name, filepath in files.items():
    print(f'\n{name} - {filepath}')
    ds = xr.open_dataset(filepath, engine='cfgrib', backend_kwargs={'indexpath': ''})
    varname = list(ds.data_vars)[0]  # yleensä yksi muuttuja per tiedosto
    da = ds[varname]
    
    missing_val = da.encoding.get('_FillValue', None)
    if missing_val is None:
        # Jos _FillValue ei ole määritelty, katso grib missingValue attribuutti
        missing_val = da.attrs.get('missing_value') or da.attrs.get('GRIB_missingValue')
    
    print(f'Missing value (fill value): {missing_val}')
    
    # Tarkistetaan onko missarvoa datassa
    has_missing_val = np.any(da.values == missing_val) if missing_val is not None else False
    print(f'Contains missing value ({missing_val}): {has_missing_val}')
    
    # Tarkistetaan NaN-arvot
    n_nans = np.count_nonzero(np.isnan(da.values))
    print(f'Number of NaNs: {n_nans}')
    
    print(f'Min: {np.nanmin(da.values)}, Max: {np.nanmax(da.values)}')
