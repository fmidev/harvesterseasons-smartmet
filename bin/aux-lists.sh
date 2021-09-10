#!/bin/bash
# make the lst files for virtual raster input for AUXFILES EDM, FLM, HEM and WBM products from the main DEM lst
# 24.5.2021 Mikko Strahlendorff
cat $1.lst | sed s:/DEM/:/AUXFILES/: | sed s:DEM\.tif:EDM\.tif: > $1-edm.lst
cat $1.lst | sed s:/DEM/:/AUXFILES/: | sed s:DEM\.tif:FLM\.tif: > $1-flm.lst
cat $1.lst | sed s:/DEM/:/AUXFILES/: | sed s:DEM\.tif:HEM\.tif: > $1-hem.lst
cat $1.lst | sed s:/DEM/:/AUXFILES/: | sed s:DEM\.tif:WBM\.tif: > $1-wbm.lst