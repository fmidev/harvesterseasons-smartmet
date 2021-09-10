# -*- coding: utf-8 -*-
"""
@author: Emmihenna Jääskeläinen
"""

import numpy as np
from sklearn.linear_model import LinearRegression

# ---------------------------------------------------------------------------
# function to calculate mean DEM, slope and aspect from 5x5 block of 2m resolution DEM
# ---------------------------------------------------------------------------
def calc_slope_and_aspect(dem0):
    dem_mean = np.nanmean(dem0)
    ind = 0
    tab = np.zeros([5*5,3])
    for i1 in range(0,np.shape(dem0)[0]):
        for j1 in range(0,np.shape(dem0)[1]):
            tab[ind,0] = i1
            tab[ind,1] = j1
            tab[ind,2] = dem0[i1,j1]
            ind += 1

    X = np.zeros([25,5])
    X[:,0] = tab[:,0]**2
    X[:,1] = tab[:,1]**2
    X[:,2] = tab[:,0]*tab[:,1]
    X[:,3] = tab[:,0]
    X[:,4] = tab[:,1]
    reg = LinearRegression().fit(X, tab[:,2])

    a = reg.coef_[0]
    b = reg.coef_[1]
    c = reg.coef_[2]
    d = reg.coef_[3]
    e = reg.coef_[4]
    dzdx = 2*a*2.5 + c*2.5 + d
    dzdy = 2*b*2.5 + c*2.5 + e

    slope0 = np.arctan(np.sqrt(dzdx**2 + dzdy**2))
    apu = -np.arctan2(dzdy, dzdx)*(180/np.pi)
    if apu > 180:
        apu = apu -360
    aspect0 = apu + 180

    return [dem_mean,slope0,aspect0]


'''
focused_sar: focused sar image


dems = np.full([np.shape(focused_sar)[0],np.shape(focused_sar)[1]],np.nan)
slopes = np.full([np.shape(focused_sar)[0],np.shape(focused_sar)[1]],np.nan)
aspects = np.full([np.shape(focused_sar)[0],np.shape(focused_sar)[1]],np.nan)

for ii in range(0,len(focused_sar)):
    for jj in range(0, np.shape(focused_sar)[1]):
        demt = dem[5*ii:5*ii+5,5*jj:5*jj+5]
        if demt.size == 25:
            [dems[ii,jj],slopes[ii,jj],aspects[ii,jj]] = calc_slope_and_aspect(demt)
'''


# ---------------------------------------------------------------------------
# azimuth direction correction
# ---------------------------------------------------------------------------

#filookm: azimuth angle of the morning orbit
#filooke: azimuth angle of the evening orbit
aspm = np.sin(-(aspects - filookm)*(np.pi/180))
aspe = np.sin(-(aspects - filooke)*(np.pi/180))
slo2 = np.tan(slopes)
slo2_aspe = slo2*aspe #azimuth direction correction evening
slo2_aspm = slo2*aspm #azimuth direction correction morning


# ---------------------------------------------------------------------------
# gradient corrections for each channel (IW1, IW2, IW3) and orbit (morning, evening)
# ---------------------------------------------------------------------------

#iw1_m: incidenceAngleFromEllipsoid_IW1_morning
#iw1_e: incidenceAngleFromEllipsoid_IW1_evening
#iw2_m: incidenceAngleFromEllipsoid_IW2_morning
#iw2_e: incidenceAngleFromEllipsoid_IW2_evening
#iw3_m: incidenceAngleFromEllipsoid_IW3_morning
#iw3_e: incidenceAngleFromEllipsoid_IW3_evening

coste1m = np.cos(iw1_m*(np.pi/180))
coste1e = np.cos(iw1_e*(np.pi/180))
coste2m = np.cos(iw2_m*(np.pi/180))
coste2e = np.cos(iw2_e*(np.pi/180))
coste3m = np.cos(iw3_m*(np.pi/180))
coste3e = np.cos(iw3_e*(np.pi/180))


cslom1 = np.cos(slopes-np.arccos(coste1m))*aspm
csloe1 = np.cos(slopes-np.arccos(coste1e))*aspe
cslom2 = np.cos(slopes-np.arccos(coste2m))*aspm
csloe2 = np.cos(slopes-np.arccos(coste2e))*aspe
cslom3 = np.cos(slopes-np.arccos(coste3m))*aspm
csloe3 = np.cos(slopes-np.arccos(coste3e))*aspe


# ---------------------------------------------------------------------------



