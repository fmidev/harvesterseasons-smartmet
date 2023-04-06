import os, glob,requests,json,sys
import pandas as pd
import xarray as xr
#import xgboost as xgb

#eobs_path='/home/smartmet/data/eobs/blend' # copernicus-koneella
data_dir='/home/ubuntu/data/ml-training-data/data/' # training data

def smartmet_ts_query(start,end,tstep,lat,lon,pardict):
    ''' timeseries query to smartmet-server
    start date, end date, timestep, lat&lon, parameters as dictionary (colname:smartmet-fmikey)
    returns dataframe
    '''
    query='http://smdev.harvesterseasons.com/timeseries?latlon='+lat+','+lon+'&param=utctime,'
    for par in pardict.values():
        query+=par+','
    query=query[0:-1]
    query+='&starttime='+start+'&endtime='+end+'&timestep='+tstep+'&format=json&precision=full&tz=utc&timeformat=sql'
    print(query)
    response=requests.get(url=query)
    df=pd.DataFrame(json.loads(response.content))
    df.columns=['utctime']+list(pardict.keys()) # change headers to params.keys
    df['utctime']=pd.to_datetime(df['utctime'])
    return df

def smartmet_ts_query_multiplePoints(start,end,tstep,latlons,pardict,staids):
    ''' timeseries query to smartmet-server
    start date, end date, timestep, list of lats&lons, parameters as dictionary (colname:smartmet-fmikey)
    returns dataframe
    '''
    query='http://smdev.harvesterseasons.com:8080/timeseries?latlon='
    for nro in latlons:
        query+=nro+','
    query=query[0:-1]
    query+='&param=utctime,'
    for par in pardict.values():
        query+=par+','
    query=query[0:-1]
    query+='&starttime='+start+'&endtime='+end+'&timestep='+tstep+'&format=json&precision=full&tz=utc&timeformat=sql&grouplocations=1'
    print(query)
    response=requests.get(url=query)
    results_json=json.loads(response.content)
    #print(results_json)
    for i in range(len(results_json)):
        res1=results_json[i]
        for key,val in res1.items():
            if key!='utctime':   
                res1[key]=val.strip('[]').split()
    df=pd.DataFrame(results_json)   
    df.columns=['utctime']+list(pardict.keys()) # change headers to params.keys
    #df['utctime']=pd.to_datetime(df['utctime'])
    expl_cols=list(pardict.keys())
    df=df.explode(expl_cols)
    df['latlonsID'] = df.groupby(level=0).cumcount().add(1).astype(str).radd('')
    df=df.reset_index(drop=True)
    df['latlonsID'] = df['latlonsID'].astype('int')
    max=df['latlonsID'].max()
    df['latitude']=''
    df['longitude']=''
    df['staid']=''
    i=1
    j=0
    while i <= max:
        df.loc[df['latlonsID']==i,'latitude']=latlons[j]
        df.loc[df['latlonsID']==i,'longitude']=latlons[j+1]
        df.loc[df['latlonsID']==i,'staid']=staids[i-1]
        j+=2
        i+=1
    df=df.drop(columns='latlonsID')
    return df
'''    
def read_eobs_staids_latlons_elevs():
    # read ECA_blend_station_rr.txt file info into dictionary
    staInfo={}
    with open(eobs_path+'/ECA_blend_station_rr.txt','r') as stations:
            for _ in range(19): # skip description lines in file
                next(stations)
            for line in stations:
                line = line.rstrip()
                staid=line[0:5].strip()
                lat,lon=latlon2decimalDeg(line[50:59],line[60:70])
                elev=line[71:].strip()
                staInfo[staid]=[str('%.6f' % lat),str('%.6f' % lon),elev]
    return staInfo

def latlon2decimalDeg(lat,lon): 
    # lat,lon from deg:min:sec to decimal degrees
    newlat=float(lat[1:3])+float(lat[4:6])/60 + float(lat[7:])/(60*60)
    newlon=float(lon[1:4])+float(lon[5:7])/60 + float(lon[8:])/(60*60)
    if lat[0]=='-':
        newlat=-1*newlat
    elif lon[0]=='-':
        newlon=-1*newlon
    return newlat,newlon

def stations2dataFrame(staids,varList):
    # create DataFrame for era5-eobs data for staids 
    stations=pd.DataFrame()
    for staid in staids:
        fname=data_dir+'era5_eobs_2000-2022_'+staid+'.csv'
        if os.path.exists(fname):
            stations=pd.concat([stations,pd.read_csv(fname)],ignore_index=True)
    return stations[varList]

def splitTrainTest(staids,varList):
    # split to test/train by including/not including NaNs  
    # tää ei oikein toimi koska kaikissa ilmeisesti puuttuu jtn
    train_set,test_set=pd.DataFrame(),pd.DataFrame()
    for staid in staids:
        fname=data_dir+'era5_eobs_2000-2022_'+staid+'.csv'
        if os.path.exists(fname):
            df=pd.read_csv(fname)
            df=df[varList]
            if df.isnull().any().any(): # includes NaN values 
                test_set=pd.concat([test_set,df],ignore_index=True)
            else:
                train_set=pd.concat([train_set,df],ignore_index=True)
        else:
            print('File '+fname+' NOT found')
    return train_set,test_set

def splitTrainTestYears(staids,varList,test_years,train_years):
    # Split to test/train by years
    vars=['utctime']+varList
    train_set,test_set=pd.DataFrame(),pd.DataFrame()
    for staid in staids:
        fname=data_dir+'era5_eobs_2000-2022_'+staid+'.csv'
        if os.path.exists(fname):
            df=pd.read_csv(fname)
            df=df[vars]
            df['RR']=df['RR']/10.0 # units from x0.1mm to mm
            df['utctime']=pd.to_datetime(df['utctime'])
            for y in train_years:
                train_set=pd.concat([train_set,df[df['utctime'].dt.year == y]],ignore_index=True)
            for y in test_years:
                test_set=pd.concat([test_set,df[df['utctime'].dt.year == y]],ignore_index=True)
        else:
            print('File '+fname+' NOT found')
    return train_set,test_set
'''