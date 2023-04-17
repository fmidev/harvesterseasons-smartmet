import pandas as pd
import numpy as np
from dataclasses import dataclass
import geopandas as gpd
import matplotlib.pyplot as plt
#import contextily as cx
#import matplotlib as mpl
#from matplotlib.cm import ScalarMappable
#from matplotlib.colors import Normalize
#import matplotlib.colors as mcolors

def plot_map(df,name,n):
    df.plot(ax=countries.plot(),x="TH_LONG", y="TH_LAT", kind="scatter",color='red',s=1)
    plt.xlim(-25, 50)
    plt.ylim(30, 75) 
    plt.title(name+' '+str(n)+' sampled points')
    plt.savefig(ml_dir+name+'_points_map.png',dpi=200)


data_dir='/home/ubuntu/data/'
ml_dir=data_dir+'mlbias/'
lucas='LUCAS_2018_Copernicus_attr+additions.csv'

cols_own=['POINT_ID','NUTS0','TH_LAT','TH_LONG','CPRN_LC','LC1_LABEL','DTM_height','DTM_slope','DTM_aspect','TCD','WAW','CorineLC']
df=pd.read_csv(data_dir+lucas,usecols=cols_own)

# drop missing values
df=df[(df.DTM_slope !=-99999.000000) & (df.DTM_aspect !=-99999.000000) & (df.DTM_height !=-99999.000000)] 
df=df.reset_index()

AF_rep_nr=int(np.round((12+374+21+35+30+3+1503)/80,decimals=0))
B_rep_nr=int(np.round((12774+877+2435+767+2757+817+1148)/80,decimals=0))
C1_rep_nr=int(np.round(8481/80,decimals=0))
C2_rep_nr=int(np.round(5996/80,decimals=0))
C3_rep_nr=int(np.round(4484/80,decimals=0))
D_rep_nr=int(np.round((1308+1546)/80,decimals=0))
E_rep_nr=int(np.round((2078+13053+2608)/80,decimals=0))
G1_rep_nr=1
H1_rep_nr=2
summ=np.sum(AF_rep_nr+B_rep_nr+C1_rep_nr+C2_rep_nr+C3_rep_nr+D_rep_nr+E_rep_nr+H1_rep_nr)

AF_df=df.loc[(df['CPRN_LC']=='A1') | (df['CPRN_LC']=='A2') | (df['CPRN_LC']=='A3') | (df['CPRN_LC']=='F1') | (df['CPRN_LC']=='F2') | (df['CPRN_LC']=='F3') | (df['CPRN_LC']=='F4')].sample(n=AF_rep_nr)
B_df=df.loc[(df['CPRN_LC']=='B1') | (df['CPRN_LC']=='B2') | (df['CPRN_LC']=='B3') | (df['CPRN_LC']=='B4') | (df['CPRN_LC']=='B5') | (df['CPRN_LC']=='B7') | (df['CPRN_LC']=='B8')].sample(n=B_rep_nr)
C1_df=df.loc[(df['CPRN_LC']=='C1')].sample(n=C1_rep_nr)
C2_df=df.loc[(df['CPRN_LC']=='C2')].sample(n=C2_rep_nr)
C3_df=df.loc[(df['CPRN_LC']=='C3')].sample(n=C3_rep_nr)
D_df=df.loc[(df['CPRN_LC']=='D1') | (df['CPRN_LC']=='D2')].sample(n=D_rep_nr)
E_df=df.loc[(df['CPRN_LC']=='E1') | (df['CPRN_LC']=='E2') | (df['CPRN_LC']=='E3')].sample(n=E_rep_nr)
#G1_df=df.loc[(df['CPRN_LC']=='G1')].sample(n=G1_rep_nr) # no data for this point
H1_df=df.loc[(df['CPRN_LC']=='H1')].sample(n=H1_rep_nr)
df_all_rows = pd.concat([AF_df, B_df,C1_df,C2_df,C3_df,D_df,E_df,H1_df]).reset_index()

countries = gpd.read_file(data_dir+'NUTS_RG_20M_2021_4326.json')
#
plot_map(df_all_rows,'allA-H',summ)
#
plot_map(AF_df,'AF',AF_rep_nr)
#
plot_map(B_df,'B',B_rep_nr)
#
plot_map(C1_df,'C1',C1_rep_nr)
#
plot_map(C2_df,'C2',C2_rep_nr)
#
plot_map(C3_df,'C3',C3_rep_nr)
#
plot_map(D_df,'D',D_rep_nr)
#
plot_map(E_df,'E',E_rep_nr)
#
plot_map(H1_df,'H1',H1_rep_nr)

AF_df.to_csv(ml_dir+'AF_rep.csv',index=False)
B_df.to_csv(ml_dir+'B_rep.csv',index=False)
C1_df.to_csv(ml_dir+'C1_rep.csv',index=False)
C2_df.to_csv(ml_dir+'C2_rep.csv',index=False)
C3_df.to_csv(ml_dir+'C3_rep.csv',index=False)
D_df.to_csv(ml_dir+'D4_rep.csv',index=False)
E_df.to_csv(ml_dir+'E5_rep.csv',index=False)
H1_df.to_csv(ml_dir+'H1_rep.csv',index=False)
df_all_rows.to_csv(ml_dir+'allA-H_rep.csv',index=False)

