import xarray as xr
import numpy as np
import pandas as pd
import os
import argparse
import warnings
from datetime import datetime

try:
    import psutil
except ImportError:
    psutil = None

def _human(n):
    for u in ["B","KB","MB","GB","TB"]:
        if n < 1024:
            return f"{n:0.2f}{u}"
        n /= 1024
    return f"{n:0.2f}PB"

def _mem_status():
    if psutil is None:
        return None
    p = psutil.Process(os.getpid())
    rss = p.memory_info().rss
    vm = psutil.virtual_memory()
    return {
        "rss": rss,
        "rss_pct_total": rss / vm.total,
        "sys_used_pct": vm.percent,
        "total": vm.total
    }

def _check_memory(stage, threshold):
    st = _mem_status()
    if st is None:
        print(f"[mem] psutil not installed; skipping check at {stage}")
        return
    print(f"[mem] {stage}: RSS={_human(st['rss'])} ({st['rss_pct_total']*100:0.2f}% of {_human(st['total'])}), system used={st['sys_used_pct']:0.2f}%")
    if st["rss_pct_total"] > threshold:
        raise MemoryError(f"Aborting at {stage}: RSS exceeds threshold ({st['rss_pct_total']*100:0.2f}% > {threshold*100:.1f}%)")

def _write_month_dataset(
    df,
    out_file,
    scale_factor,
    add_offset,
    bits,
    attrs_base,
    mem_threshold
):
    if df.empty:
        return
    _check_memory(f"month build before xarray ({os.path.basename(out_file)})", mem_threshold)
    df = df.set_index(["time","latitude","longitude"]).sort_index()
    ds = df.to_xarray()
    # Attach attrs
    ds["skt"].attrs.update({
        "description": "SKT redistributed with per-gridpoint STSKTD offset; packed uint16",
        "packing_bits": bits,
        "original_min": attrs_base["original_min"],
        "original_max": attrs_base["original_max"]
    })
    ds.attrs.update({
        "title": f"Combined SKT data (time-distributed) month {out_file[-13:-5]}",
        "created": datetime.utcnow().isoformat()
    })
    encoding = {
        "skt": {
            "dtype": "uint16",
            "scale_factor": scale_factor,
            "add_offset": add_offset,
            "zlib": True,
            "complevel": 4,
            "_FillValue": np.uint16(65535)
        }
    }
    _check_memory(f"before to_netcdf ({os.path.basename(out_file)})", mem_threshold)
    ds.to_netcdf(out_file, encoding=encoding)
    _check_memory(f"after to_netcdf ({os.path.basename(out_file)})", mem_threshold)
    print(f"[write] {out_file} rows={ds.sizes.get('time',0)} unique-times")

# --- New helper to robustly construct a proper time dimension ---
def _normalize_time_dataarray(ds: xr.Dataset, var_name: str):
    """
    Return DataArray with a proper 'time' dimension (time, lat, lon).
    Handles common GRIB patterns:
      1. Already has 'time' in dims.
      2. Has ('time','step') -> combine into single time axis.
      3. Has only 'step' as dim + scalar 'time' coordinate.
      4. Has 'valid_time' dimension -> rename to 'time'.
    """
    if var_name not in ds:
        # Fallback to first data var
        cand = next(iter(ds.data_vars))
        print(f"[warn] Variable '{var_name}' not found; using '{cand}' instead.")
        var_name = cand
    da = ds[var_name]

    # Case: already has time
    if "time" in da.dims:
        return da

    # Case: has valid_time
    if "valid_time" in da.dims:
        print("[info] Using 'valid_time' as time dimension.")
        return da.rename({"valid_time": "time"})

    # Case: has step plus a scalar or length-1 time coord
    has_step = "step" in da.dims
    ds_time = ds.coords.get("time")
    if has_step and "time" in ds.coords and "time" not in da.dims:
        base_times = ds_time.values  # may be scalar or length T
        steps = ds["step"].values  # timedeltas
        if np.ndim(base_times) == 0:
            base_times = base_times.reshape(1)
        # produce all valid times
        valid_times = (base_times.reshape(-1, 1) + steps.reshape(1, -1)).reshape(-1)
        print(f"[info] Expanding scalar/base time + step -> {valid_times.size} time points.")
        # reshape data
        lat_name = "latitude" if "latitude" in da.dims else ("lat" if "lat" in da.dims else None)
        lon_name = "longitude" if "longitude" in da.dims else ("lon" if "lon" in da.dims else None)
        if lat_name is None or lon_name is None:
            raise ValueError(f"Cannot identify latitude/longitude dims in {da.dims}")
        # Determine ordering for reshape
        # Accept (step, lat, lon) or (something, step, lat, lon)
        step_axis = da.dims.index("step")
        # Move step to position 0 then reshape
        da_re = da.transpose("step", ...).values if step_axis != 0 else da.values
        data_reshaped = da_re.reshape(valid_times.size, da.sizes[lat_name], da.sizes[lon_name])
        new_da = xr.DataArray(
            data_reshaped,
            dims=("time", lat_name, lon_name),
            coords={
                "time": valid_times,
                lat_name: da.coords[lat_name],
                lon_name: da.coords[lon_name]
            },
            name=da.name
        )
        return new_da

    # Case: has both time and step as dims (forecast grid)
    if has_step and "time" in da.dims:
        # Combine cartesian product
        t_vals = ds["time"].values
        s_vals = ds["step"].values
        valid_times = (t_vals.reshape(-1, 1) + s_vals.reshape(1, -1)).reshape(-1)
        print(f"[info] Collapsing (time, step) -> single time axis of length {valid_times.size}.")
        lat_name = "latitude" if "latitude" in da.dims else ("lat" if "lat" in da.dims else None)
        lon_name = "longitude" if "longitude" in da.dims else ("lon" if "lon" in da.dims else None)
        if lat_name is None or lon_name is None:
            raise ValueError(f"Cannot identify latitude/longitude dims in {da.dims}")
        # Ensure order (time, step, lat, lon) if both present
        order = []
        for d in ["time", "step", lat_name, lon_name]:
            if d in da.dims:
                order.append(d)
        da_ord = da.transpose(*order)
        arr = da_ord.values.reshape(valid_times.size, da.sizes[lat_name], da.sizes[lon_name])
        new_da = xr.DataArray(
            arr,
            dims=("time", lat_name, lon_name),
            coords={
                "time": valid_times,
                lat_name: da.coords[lat_name],
                lon_name: da.coords[lon_name]
            },
            name=da.name
        )
        return new_da

    # No acceptable time pattern found
    raise ValueError(
        "Cannot derive a time dimension for variable '{var}'. "
        "Dims: {dims}. Available coords: {coords}".format(
            var=var_name, dims=da.dims, coords=list(ds.coords))
    )

def process_monthly(
    skt_file="data/grib/CCI_20000101T000000_2020_skt-12h.grib",
    stsktd_file="data/grib/CCI_20000101T000000_2020_stsktd-eu.grib",
    out_dir="data/monthly",
    mem_threshold=0.85,
    bits=12,
    route_by_shifted_time=True,
    var_name="skt",
    truncate_shifted_to_hour=True  # NEW
):
    os.makedirs(out_dir, exist_ok=True)
    _check_memory("start", mem_threshold)

    print("[open] GRIB datasets")
    skt_ds = xr.open_dataset(skt_file, engine="cfgrib")
    stsktd_ds = xr.open_dataset(stsktd_file, engine="cfgrib")
    _check_memory("after open_dataset", mem_threshold)

    # UPDATED: robust variable/time extraction
    skt_var = _normalize_time_dataarray(skt_ds, var_name)
    stsktd_var = stsktd_ds.get("stsktd", next(iter(stsktd_ds.data_vars.values())))  # seconds

    if "time" not in skt_var.dims:
        raise ValueError(f"SKT variable still has no time dimension after normalization. Dims={skt_var.dims}")

    # Offsets (seconds) -> int32 to save memory
    offsets = stsktd_var.values
    if offsets.dtype != np.int32:
        offsets = offsets.astype(np.int32)

    lat_vals = skt_var.coords["latitude"].values if "latitude" in skt_var.coords else skt_var.coords["lat"].values
    lon_vals = skt_var.coords["longitude"].values if "longitude" in skt_var.coords else skt_var.coords["lon"].values
    nlat = lat_vals.size
    nlon = lon_vals.size

    # Pre-build flattened lat/lon arrays (avoid repeating each time)
    flat_lats = np.repeat(lat_vals, nlon).astype(np.float32)
    flat_lons = np.tile(lon_vals, nlat).astype(np.float32)
    flat_offsets = offsets.reshape(-1)  # seconds per grid point

    time_index = pd.to_datetime(skt_var.time.values)
    periods = time_index.to_period("M")
    unique_months = periods.unique()

    print(f"[info] Months to process: {len(unique_months)}")

    written_files = []

    for per in unique_months:
        month_mask = (periods == per)
        month_times = time_index[month_mask]
        if month_times.empty:
            continue

        print(f"[month] {per} times={len(month_times)}")
        # Slice SKT for the month
        skt_month = skt_var.isel(time=np.where(month_mask)[0])
        # Quantize within month
        raw = skt_month.values  # shape (T, nlat, nlon)
        data_min = float(np.nanmin(raw))
        data_max = float(np.nanmax(raw))
        if not np.isfinite(data_min) or not np.isfinite(data_max):
            print(f"[warn] All NaN month {per}, skipping.")
            continue
        scale_factor = (data_max - data_min)/(2**bits - 1) if data_max != data_min else 1.0
        add_offset = data_min
        q = np.rint((raw - add_offset)/scale_factor).astype(np.uint16)
        del raw
        _check_memory(f"{per} after quantize", mem_threshold)

        # Accumulate rows for all time steps in this month
        # To reduce peak memory, process time steps and append DataFrames intermittently
        chunk_rows = []
        row_count = 0

        def flush_chunk(chunk):
            nonlocal row_count, month_df_list
            if not chunk:
                return
            dfc = pd.concat(chunk, ignore_index=True)
            month_df_list.append(dfc)
            row_count += len(dfc)
            chunk.clear()

        month_df_list = []
        for ti, tstamp in enumerate(month_times):
            field = q[ti].reshape(-1)  # flattened uint16
            # Shift time per grid point
            shifted_times = tstamp + pd.to_timedelta(flat_offsets, unit="s")
            if truncate_shifted_to_hour:  # NEW
                # Floor to the hour (remove minutes/seconds)
                shifted_times = pd.to_datetime(shifted_times).floor("H").values
            else:
                shifted_times = shifted_times.astype("datetime64[ns]")
            if route_by_shifted_time:
                # we will later separate by shifted month if needed (optional)
                pass
            df_step = pd.DataFrame({
                "time": shifted_times,
                "latitude": flat_lats,
                "longitude": flat_lons,
                "skt": field
            })
            chunk_rows.append(df_step)
            # Flush every few steps to keep memory low
            if len(chunk_rows) >= 4:  # adjust flush frequency if needed
                flush_chunk(chunk_rows)
            if ti % 10 == 0:
                _check_memory(f"{per} after step {ti}", mem_threshold)

        flush_chunk(chunk_rows)
        month_df = pd.concat(month_df_list, ignore_index=True)
        del month_df_list
        _check_memory(f"{per} after DataFrame build", mem_threshold)

        if route_by_shifted_time:
            # Split rows by shifted (actual) year-month (post offset)
            month_df["ym"] = pd.to_datetime(month_df["time"]).dt.to_period("M")
            for ym, sub in month_df.groupby("ym"):
                ym_str = f"{ym.year:04d}{ym.month:02d}"
                out_file = os.path.join(out_dir, f"combined_skt_distributed_{ym_str}.nc")
                attrs_base = {
                    "original_min": data_min,
                    "original_max": data_max
                }
                # Build per-group dataset
                _write_month_dataset(
                    sub.drop(columns=["ym"]),
                    out_file,
                    scale_factor,
                    add_offset,
                    bits,
                    attrs_base,
                    mem_threshold
                )
                if out_file not in written_files:
                    written_files.append(out_file)
        else:
            ym_str = f"{per.year:04d}{per.month:02d}"
            out_file = os.path.join(out_dir, f"combined_skt_distributed_{ym_str}.nc")
            attrs_base = {
                "original_min": data_min,
                "original_max": data_max
            }
            _write_month_dataset(
                month_df,
                out_file,
                scale_factor,
                add_offset,
                bits,
                attrs_base,
                mem_threshold
            )
            if out_file not in written_files:
                written_files.append(out_file)

        # Cleanup
        del month_df, q
        _check_memory(f"{per} end", mem_threshold)

    print("[done] Files written:")
    for f in written_files:
        print("  ", f)
    return written_files

def _parse():
    ap = argparse.ArgumentParser()
    ap.add_argument("--skt", default="data/grib/CCI_20000101T000000_2020_skt-12h.grib")
    ap.add_argument("--stsktd", default="data/grib/CCI_20000101T000000_2020_stsktd-eu.grib")
    ap.add_argument("--out-dir", default="data/monthly",
                    help="Directory to write monthly NetCDF files.")
    ap.add_argument("--mem-threshold", type=float, default=0.85,
                    help="Abort if RSS exceeds this fraction of total RAM.")
    ap.add_argument("--bits", type=int, default=12,
                    help="Effective quantization bits (<=16).")
    ap.add_argument("--route-by-shifted-time", action="store_true",
                    help="Route rows to output file based on shifted time (default splits by original month).")
    ap.add_argument("--var-name", default="skt",
                    help="Name of SKT variable in GRIB (default 'skt').")
    ap.add_argument("--truncate-shifted-to-hour", action="store_true",
                    help="Floor shifted times to the hour (drop minutes/seconds).")  # NEW
    return ap.parse_args()

if __name__ == "__main__":
    args = _parse()
    try:
        if not (1 <= args.bits <= 16):
            raise ValueError("--bits must be 1..16")
        process_monthly(
            skt_file=args.skt,
            stsktd_file=args.stsktd,
            out_dir=args.out_dir,
            mem_threshold=args.mem_threshold,
            bits=args.bits,
            route_by_shifted_time=args.route_by_shifted_time,
            var_name=args.var_name,
            truncate_shifted_to_hour=args.truncate_shifted_to_hour  # NEW
        )
    except MemoryError as e:
        print(f"[error] {e}")
        print("Suggestion: lower --mem-threshold, reduce flush interval, or spatially subset.")
    except Exception as e:
        print(f"[error] {e}")