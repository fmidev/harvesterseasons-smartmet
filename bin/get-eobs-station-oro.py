#!/usr/bin/env python
import pandas as pd
import numpy as np
#import re
import subprocess as sp
#from osgeo import gdal

def dms2dd(dms):
    degstr, min, sec = dms.split(":")
    degs=degstr.lstrip("+-0")
    if degs == '':
        return degstr
    elif degstr[0:1]=="-":
        deg = -1 * float(degs)
    else:
        deg=degs
    dd=float(deg) + float(min)/60 + float(sec)/3600
    return dd
def locinfo(lon, lat, url):
    return sp.getoutput('gdallocationinfo -wgs84 -valonly %s %s %s 2>/dev/null' % (url,lon,lat))

stationsfile="/home/smartmet/data/eobs/stations_rr.txt"
stations=pd.read_csv(stationsfile,skiprows=19,names=["STAID","STANAME","CN","LAT","LON","HGHT"],index_col="STAID",
    dtype={"STANAME":str, "LAT":str, "LON":str,"CN":str,"HGHT":np.int16})
#print(stations)

dtwurl="/vsicurl/https://copernicus.ceph.lit.fmi.fi/dtm/dtw/Europe-wbm-dtw-m.tif"
dtlurl="/vsicurl/https://copernicus.ceph.lit.fmi.fi/dtm/dtl/Europe-wbm-dtl-m.tif"
dtrurl="/vsicurl/https://copernicus.ceph.lit.fmi.fi/dtm/dtr/Europe-wbm-dtr-m.tif"
dtourl="/vsicurl/https://copernicus.ceph.lit.fmi.fi/dtm/dto/Europe-wbm-dto-m.tif"
stations["DDLAT"] = stations["LAT"].apply(dms2dd)
stations["DDLON"] = stations["LON"].apply(dms2dd)

stations["DTW"]=stations.apply(lambda x: locinfo(x["DDLON"], x["DDLAT"],dtwurl),axis=1)
stations["DTL"]=stations.apply(lambda x: locinfo(x["DDLON"], x["DDLAT"],dtlurl),axis=1)
stations["DTR"]=stations.apply(lambda x: locinfo(x["DDLON"], x["DDLAT"],dtrurl),axis=1)
stations["DTO"]=stations.apply(lambda x: locinfo(x["DDLON"], x["DDLAT"],dtourl),axis=1)
outfile="/home/smartmet/data/eobs/stations+_rr.txt"
stations.to_csv(outfile)