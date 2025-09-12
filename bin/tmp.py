
ecsf_sl_vars = ['2t', '2d', '10u', '10v', '10fg','tp','e','rsn','mx2t24','mn2t24','msl','slhf','sshf','ssr','str','strd','tcc','tclw','tcwv']

preds=['lat', 'lon', 'ERA5_anor', 'ERA5_z', 'ERA5_lsm','ERA5_slor', 'ERA5_sdor',
       'DTM_height',# 'DTM_slope', 'DTM_aspect',
       ]+ecsf_sl_vars

print(preds)