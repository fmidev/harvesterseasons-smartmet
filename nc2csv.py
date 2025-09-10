import pandas as pd
import numpy as np
import sys
import xarray as xr
from datetime import datetime, timedelta

def netcdf_to_csv(netcdf_file, csv_file):
    # Open the NetCDF file
    ds = xr.open_dataset(netcdf_file)
    
    # Print available dimensions for debugging
    print("Available dimensions:", list(ds.dims))
    
    # Find all variables ending with _grid2x2
    grid_vars = [var for var in ds.variables if var.endswith('_grid2x2')]
    
    if not grid_vars:
        print("No variables with _grid2x2 found in the dataset.")
        sys.exit(1)
    
    # Group variables by their base name (prefix)
    # Expecting names like sfcWind_2010_grid2x2, tasmin_2012_grid2x2, etc.
    var_groups = {}
    for var in grid_vars:
        parts = var.split('_')
        if len(parts) < 3:
            continue
        prefix = parts[0]
        year = parts[1]
        var_groups.setdefault(prefix, []).append((var, year))
    
    processed = {}
    for prefix, items in var_groups.items():
        # Sort the list by year for correct time order
        items_sorted = sorted(items, key=lambda x: int(x[1]))
        da_list = []
        for var, year in items_sorted:
            da = ds[var]
            # Create new time axis starting from January 1st of the extracted year
            num_times = len(da.time)
            start_date = f"{year}-01-01"
            new_times = pd.date_range(start=start_date, periods=num_times, freq='D')
            da = da.assign_coords(time=new_times)
            # Rename the variable to its prefix
            da = da.rename(prefix)
            da_list.append(da)
        # Concatenate arrays along the time dimension and sort
        combined = xr.concat(da_list, dim='time')
        combined = combined.sortby('time')
        processed[prefix] = combined
    
    # Merge all processed DataArrays into one Dataset
    merged_ds = xr.merge(list(processed.values()))
    
    # Convert the Dataset to a DataFrame
    df = merged_ds.to_dataframe().reset_index()
    
    # Create a unique identifier for each grid point
    df['grid_point'] = df['latitude'].astype(str) + '_' + df['longitude'].astype(str)
    
    # Check for duplicate time values per grid point
    duplicates = df.groupby(['time', 'grid_point']).size()
    if (duplicates > 1).any():
        print("Warning: Found duplicate time values for some grid points")
        # Keep first occurrence of each time-gridpoint combination
        df = df.drop_duplicates(subset=['time', 'grid_point'])
    
    # Drop the temporary grid_point column and sort the DataFrame
    df = df.drop('grid_point', axis=1)
    df = df.sort_values(['time', 'latitude', 'longitude']).reset_index(drop=True)
    
    # Save the DataFrame to CSV
    df.to_csv(csv_file, index=False)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python nc2csv.py <input_netCDF_file> <output_csv_file>")
        sys.exit(1)
    
    netcdf_file = sys.argv[1]
    csv_file = sys.argv[2]
    
    netcdf_to_csv(netcdf_file, csv_file)
    print(f"Converted {netcdf_file} to {csv_file}")
