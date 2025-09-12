import xarray as xr
import dask.distributed

if __name__ == "__main__":
    cluster=dask.distributed.LocalCluster()
    client=dask.distributed.Client(cluster)
    file='/home/ubuntu/data/xgb-bias/yearly-controls/ECSF_2023_sfc-era5.grib'
    ds=xr.open_dataset(file, engine='cfgrib', chunks={'valid_time':1},
                   backend_kwargs=dict(time_dims=('valid_time','verifying_time'),indexpath=''), decode_timedelta=True)

    print(ds)
    df=ds.to_dataframe()
    print(df)
