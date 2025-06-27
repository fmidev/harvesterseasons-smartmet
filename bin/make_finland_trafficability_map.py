#!/usr/bin/env python3
import argparse, os, sys
import numpy as np
import xarray as xr
import rioxarray
import earthkit.data as ekdata
import rasterio

def main():
    parser = argparse.ArgumentParser(
        description="Generate Finland trafficability map from EC-ENS output")
    parser.add_argument("date", help="YYYY-MM-DD")
    parser.add_argument("offset_day", nargs="?", type=int, default=0,
                        help="Offset days (0–14)")
    parser.add_argument("outdir", nargs="?", default="maps",
                        help="Output directory")
    args = parser.parse_args()

    if not (1 <= args.offset_day <= 14):
        sys.exit("Error: offset_day must be between 1 and 14")

    base_data = "/home/smartmet/data"
    os.makedirs(args.outdir, exist_ok=True)

    grib_file = os.path.join(base_data,
        f"grib/ECXENS_{args.date.replace('-','')}T000000_swi2-era5l-nd.grib")
    if not os.path.isfile(grib_file):
        sys.exit(f"Error: EC-ENS GRIB file not found: {grib_file}")

    # compute forecast date
    from datetime import datetime, timedelta
    forecast = (datetime.strptime(args.date, "%Y-%m-%d") +
                timedelta(days=args.offset_day)).strftime("%Y-%m-%d")

    # Load ENS soil water index using earthkit-data
    grib_data = ekdata.from_source("file", grib_file)

    # Load to xarray
    ds = grib_data.to_xarray(time_dim_mode='valid_time')

    # Select the specific forecast lead before area subsetting
    ds = ds.sel(valid_time=forecast)

    # Handle coordinate naming variations in earthkit output
    lat_coord = 'latitude' if 'latitude' in ds.coords else 'lat'
    lon_coord = 'longitude' if 'longitude' in ds.coords else 'lon'
    
    # Print coordinate ranges to help with debugging
    print(f"Latitude range: {ds[lat_coord].min().item()} to {ds[lat_coord].max().item()}")
    print(f"Longitude range: {ds[lon_coord].min().item()} to {ds[lon_coord].max().item()}")
    
    # Determine if coordinates are ascending or descending
    lat_ascending = ds[lat_coord][0].item() < ds[lat_coord][-1].item()
    
    # Subset to Finland area
    if lat_ascending:
        ds = ds.sel(**{lat_coord: slice(58.8, 70.1), lon_coord: slice(19.0, 31.6)})
    else:
        ds = ds.sel(**{lat_coord: slice(70.1, 58.8), lon_coord: slice(19.0, 31.6)})
    
    
    # Check for ensemble dimension naming
    ens_dim = 'number'

    # Get the data variable name (may vary depending on GRIB content)
    data_var = list(ds.data_vars)[0] if ds.data_vars else 'unknown'
        
    # Compute statistics on the ensemble dimension
    p90 = ds[data_var].reduce(np.nanpercentile, q=90, dim=ens_dim)
    p10 = ds[data_var].reduce(np.nanpercentile, q=10, dim=ens_dim)
    
    # Create datasets with proper naming
    p90 = p90.to_dataset(name="swi2_p90")
    p10 = p10.to_dataset(name="swi2_p10")
    
    # Try to handle projection issues - first set the CRS properly
    try:
        p90 = p90.rio.write_crs("EPSG:4326")
        p10 = p10.rio.write_crs("EPSG:4326")
    except Exception as e:
        print(f"Warning: Could not set CRS: {e}")
    
    # load original trafficability map
    try:
        orig = rioxarray.open_rasterio(
            "/vsicurl/https://pta.data.lit.fmi.fi/geo/harvestability/KKL_SMK_Suomi_2021_06_01.tif"
        )
        print(f"Original raster loaded, shape: {orig.shape}")
        
        # Explicitly set the CRS for the original raster to EPSG:3067 (Finnish coordinate system)
        orig = orig.rio.write_crs("EPSG:3067")
        print("Set original raster CRS to EPSG:3067 (Finnish national coordinate system)")
    except Exception as e:
        print(f"Static trafficability load error: {e}")
    
    # Try reprojection with robust error handling
    try:
        # Attempt standard reprojection
        p90r = p90["swi2_p90"].rio.reproject_match(orig)
        p10r = p10["swi2_p10"].rio.reproject_match(orig)
        print("Standard reprojection successful")
    except Exception as e:
        print(f"Reprojection error: {e}")
    
    # embed the colormap into the output file
    cmap = {}
    cmap_file = os.path.join(args.outdir, "trafficability_colormap.txt")
    with open(cmap_file) as f:
        for line in f:
            idx, r, g, b, a = map(int, line.split())
            cmap[idx] = (r, g, b, a)

    # apply classification logic
    A = orig[0]   # assume single band
    B = p90r
    C = p10r
    out = xr.where((B>=65)&((A==3)|(A==5)), 6,
            xr.where((C<65)&((A>1)&(A<6)), 1, A))
    out = out.astype(np.uint8)
    print(f"Output raster, shape: {out.shape}")

    # write result as COG-like GeoTIFF
    out.rio.set_spatial_dims(x_dim="x", y_dim="y", inplace=True)
    out.rio.write_crs("EPSG:3067", inplace=True)  # Explicitly set Finnish coordinate system
    out.rio.set_nodata(0, inplace=True)  # Set nodata value to 0
    out_path = os.path.join(args.outdir, f"trafficability_modified_{forecast}_{args.date.replace('-','')}.tif")
    out.rio.to_raster(
        out_path,
        driver="GTiff", compress="deflate",
        predictor=2, tiled=True, BIGTIFF="IF_SAFER"
    )

    with rasterio.open(out_path, "r+") as dst:
        dst.write_colormap(1, cmap)

    print("Done. Next, you can apply further masking as needed.")

if __name__ == "__main__":
    main()
