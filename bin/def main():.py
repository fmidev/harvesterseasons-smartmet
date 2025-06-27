def main():
    # ...existing code...
    ds = xr.open_dataset(your_file_path)  # or however ds is loaded

    # Fix: Check for correct coordinate names (lat/lon vs. latitude/longitude)
    print("Available coordinates:", list(ds.coords))
    # Try common alternatives if 'lat' or 'lon' are missing
    lat_name = None
    lon_name = None
    for candidate in ['lat', 'latitude', 'y']:
        if candidate in ds.coords:
            lat_name = candidate
            break
    for candidate in ['lon', 'longitude', 'x']:
        if candidate in ds.coords:
            lon_name = candidate
            break
    if lat_name is None or lon_name is None:
        raise KeyError(f"Could not find latitude/longitude coordinates in dataset. Available: {list(ds.coords)}")

    # Use the found coordinate names for slicing
    ds = ds.sel(**{lat_name: slice(70.1, 58.8), lon_name: slice(19.0, 31.6)})

    # ...existing code...