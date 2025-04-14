#!/usr/bin/env python

harbor='Vuosaari'
FMISID='151028'
lat=60.20867
lon=25.1959
pred_correl_map = {'WG_PT24H_MAX': 'fg10','TX_PT24H_MAX': '','TN_PT24H_MIN': '','TP_PT24H_SUM': 'tp'}
predictand='WG_PT24H_MAX'
correl_pred='fg10'
mdl_name=f'mdl_{predictand}_2000-2023_sf_{harbor}_quantileerror-fe.txt'
predictors00='10u,10v,2d,2t,10fg,msl,tcc,tclw' # grib file
predictorsDSUM='ewss,nsss,slhf,sshf,ssr,ssrd,strd,tp,e,str' # grib file
#cols_own='e-1','e-2','e-3','e-4','ewss-1','ewss-2','ewss-3','ewss-4','fg10-1','fg10-2','fg10-3','fg10-4','lsm-1','lsm-2','lsm-3','lsm-4','msl-1','msl-2','msl-3','msl-4','nsss-1','nsss-2','nsss-3','nsss-4','slhf-1','slhf-2','slhf-3','slhf-4','sshf-1','sshf-2','sshf-3','sshf-4','ssr-1','ssr-2','ssr-3','ssr-4','ssrd-1','ssrd-2','ssrd-3','ssrd-4','str-1','str-2','str-3','str-4','strd-1','strd-2','strd-3','strd-4','t2-1','t2-2','t2-3','t2-4','tcc-1','tcc-2','tcc-3','tcc-4','td2-1','td2-2','td2-3','td2-4','tlwc-1','tlwc-2','tlwc-3','tlwc-4','tp-1','tp-2','tp-3','tp-4','u10-1','u10-2','u10-3','u10-4','v10-1','v10-2','v10-3','v10-4',f'{correl_pred}_sum',f'{correl_pred}_sum_mean',f'{correl_pred}_sum_min',f'{correl_pred}_sum_max',f'{predictand}_mean',f'{predictand}_min',f'{predictand}_max'#,f'{correl_pred}_{predictand}_diff_mean',f'{correl_pred}_{predictand}_diff_min',f'{correl_pred}_{predictand}_diff_max'
f1=f'obs-oceanids-20240101T000000Z-20240803T000000Z-all-{harbor}-daymean-daymax.csv' # observations 
threshold_values = [33.55, 30.78, 24.84, 18.33, 8.71, 17.0, 12.58, 16.77, 18.67, 30.97, 31.33, 35.16]
th_wind=15