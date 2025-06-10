#!/usr/bin/env python3
"""
Script to calculate seasonal mean differences between ECXSF and SWI observations
Using earthkit-data and earthkit-meteo instead of CDO commands
"""
import sys
import argparse
from datetime import datetime, timedelta
import earthkit.data as ekdata
import earthkit.meteo as ekmeteo
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
import numpy as np
import os

def parse_arguments():
    parser = argparse.ArgumentParser(description='Calculate seasonal mean differences between ECXSF and SWI observations')
    parser.add_argument('var', help='Variable name')
    parser.add_argument('stmon', help='Start month in format YYYYMM or YYYYMMDD')
    parser.add_argument('i', type=int, help='Lead time month (0=first month, 1=second month, etc.)')
    return parser.parse_args()

def calculate_dates(stmon, lead_month):
    """
    Calculate target dates based on start month and lead time
    
    Parameters:
    - stmon: Start month in YYYYMM or YYYYMMDD format
    - lead_month: Lead time month (0=first month, 1=second month, etc.)
    
    Returns:
    - target_month: Month number (1-12) of the target forecast month
    - start_date_str: First day of the target month as YYYY-MM-DD
    - end_date_str: Last day of the target month as YYYY-MM-DD
    """
    try:
        # First try YYYYMMDD format
        start_date = datetime.strptime(stmon, '%Y%m%d')
    except ValueError:
        try:
            # Fall back to YYYYMM format
            start_date = datetime.strptime(stmon, '%Y%m')
        except ValueError:
            raise ValueError(f"Invalid date format for stmon: {stmon}. Expected YYYYMMDD or YYYYMM")
    
    # Get the first day of the start month
    first_day_of_start_month = datetime(start_date.year, start_date.month, 1)
    
    # Calculate first day of target month
    target_month_start = first_day_of_start_month
    for _ in range(lead_month):
        # Move to next month
        if target_month_start.month == 12:
            target_month_start = datetime(target_month_start.year + 1, 1, 1)
        else:
            target_month_start = datetime(target_month_start.year, target_month_start.month + 1, 1)
    
    # Calculate last day of target month
    if target_month_start.month == 12:
        target_month_end = datetime(target_month_start.year + 1, 1, 1) - timedelta(days=1)
    else:
        target_month_end = datetime(target_month_start.year, target_month_start.month + 1, 1) - timedelta(days=1)
    
    # Extract month number of the target month
    target_month = target_month_start.month
    
    # Format dates as required
    start_date_str = target_month_start.strftime('%Y-%m-%d')
    end_date_str = target_month_end.strftime('%Y-%m-%d')
    
    print(f"Lead time {lead_month} corresponds to {target_month_start.strftime('%B %Y')}")
    
    return target_month, start_date_str, end_date_str

def main():
    args = parse_arguments()
    var = args.var
    stmon = args.stmon
    i = args.i
    
    # Calculate dates
    smon, sdate, edate = calculate_dates(stmon, i)
    
    # Define paths and variables
    pred = 'ecxsf'
    obs = 'swi'
    
    # Load SWI observations - using proper earthkit-data filtering methods
    swi_pattern = f"grib/SWI_20000101T000000_202[345]*"
    swi_files = ekdata.from_source("file", swi_pattern)
    
    # Debug: Print attributes of first field to inspect structure
    if len(swi_files) > 0:
        print(f"Available keys in first field: {swi_files[0].metadata().keys()}")
        
    # Filter by variable name using paramId or shortName (depends on version)
    try:
        # First try filtering with param
        swi_data = [field for field in swi_files if field.metadata().get('param') == var]
        if len(swi_data) == 0:
            # Try with paramId
            swi_data = [field for field in swi_files if field.metadata().get('paramId') == var]
        if len(swi_data) == 0:
            # Finally try with shortName if it's a string
            if isinstance(var, str):
                swi_data = [field for field in swi_files if str(field.metadata().get('shortName', '')).lower() == var.lower()]
    except Exception as e:
        print(f"Error filtering SWI data: {e}")
        print(f"Attempting alternative approach...")
        # Alternative approach using metadata() method
        swi_data = []
        for field in swi_files:
            meta = field.metadata()
            # Print first field's metadata for debugging
            if len(swi_data) == 0:
                print(f"Sample metadata: {meta}")
            # Look for the variable in various metadata fields
            if (str(meta.get('param', '')).lower() == var.lower() or 
                str(meta.get('shortName', '')).lower() == var.lower() or 
                str(meta.get('paramId', '')).lower() == var.lower()):
                swi_data.append(field)
    
    # Further filter by date
    start_date = datetime.strptime(sdate, '%Y-%m-%d')
    end_date = datetime.strptime(edate, '%Y-%m-%d')
    swi_data = [field for field in swi_data if start_date <= field.valid_date <= end_date]
    
    if len(swi_data) == 0:
        print(f"Warning: No SWI data found for date range {sdate} to {edate}")
        sys.exit(1)
    
    # Convert list back to a GribFieldList
    swi_data = ekdata.FieldList(swi_data)
    
    # Remap to era5l grid
    era5l_grid = ekdata.from_source("file", "era5l-eu-grid")
    swi_remapped = ekmeteo.regrid(swi_data, era5l_grid, method="nearest")
    
    # Load ECXSF forecasts
    ecxsf_pattern = f"grib/ECXSF_{stmon}*{var}*"
    ecxsf_files = ekdata.from_source("file", ecxsf_pattern)
    
    # Filter ECXSF data by variable - using same approach as for SWI data
    try:
        # First try filtering with param
        ecxsf_data = [field for field in ecxsf_files if field.metadata().get('param') == var]
        if len(ecxsf_data) == 0:
            # Try with paramId
            ecxsf_data = [field for field in ecxsf_files if field.metadata().get('paramId') == var]
        if len(ecxsf_data) == 0:
            # Finally try with shortName if it's a string
            if isinstance(var, str):
                ecxsf_data = [field for field in ecxsf_files if str(field.metadata().get('shortName', '')).lower() == var.lower()]
    except Exception as e:
        print(f"Error filtering ECXSF data: {e}")
        print(f"Attempting alternative approach...")
        # Alternative approach
        ecxsf_data = []
        for field in ecxsf_files:
            meta = field.metadata()
            if (str(meta.get('param', '')).lower() == var.lower() or 
                str(meta.get('shortName', '')).lower() == var.lower() or 
                str(meta.get('paramId', '')).lower() == var.lower()):
                ecxsf_data.append(field)
    
    # Further filter by month
    ecxsf_data = [field for field in ecxsf_data if field.valid_date.month == smon]
    
    if len(ecxsf_data) == 0:
        print(f"Warning: No ECXSF data found for month {smon}")
        sys.exit(1)
    
    # Convert list back to a GribFieldList
    ecxsf_data = ekdata.FieldList(ecxsf_data)
    
    # Invert latitude and calculate ensemble mean
    ecxsf_flipped = ekmeteo.flip_latitude(ecxsf_data)
    ecxsf_mean = ekmeteo.ensemble_mean(ecxsf_flipped)
    
    # Calculate difference and monthly mean
    diff = ekmeteo.subtract(swi_remapped, ecxsf_mean)
    monthly_mean = ekmeteo.monthly_mean(diff)
    
    # Save to GRIB file
    output_grib = f"{var}-diff-{obs}-{pred}-{stmon}+{i}.grib"
    monthly_mean.save(output_grib)
    
    # Create visualization
    plt.figure(figsize=(10, 8))
    
    # Set up colormap similar to the CDO shaded command
    colors = ['violet', 'blue', 'cyan', 'green', 'yellow', 'red', 'purple']
    cmap = mcolors.LinearSegmentedColormap.from_list('custom_cmap', colors)
    
    # Plot data
    lons = monthly_mean.longitude
    lats = monthly_mean.latitude
    data = monthly_mean.values
    
    plt.contourf(lons, lats, data, levels=np.linspace(-35, 45, 21), cmap=cmap, extend='both')
    plt.colorbar(label=f'{var} Difference')
    plt.xlim(-15, 45)
    plt.ylim(35, 72)
    plt.title(f'Difference between {obs.upper()} and {pred.upper()} for {var} ({stmon}+{i})')
    plt.xlabel('Longitude')
    plt.ylabel('Latitude')
    
    # Save figure
    output_img = f"{var}-diff-img-{stmon}+{i}.png"
    plt.savefig(output_img, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"Processed {var} for {stmon}+{i}")
    print(f"Output files: {output_grib} and {output_img}")

if __name__ == "__main__":
    main()
