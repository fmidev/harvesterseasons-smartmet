#!/bin/bash
fch=/home/smartmet/data/UMD_FCH_2019.tif
tr=$(gdalinfo $1/$1-wbm.vrt | grep -Po 'Size = (.+)' | sed 's:Size = (::' | sed 's:,: :' | sed 's:)::' )
ul=$(gdalinfo $1/$1-wbm.vrt | grep -Po 'Upper Left (.*)' | sed 's:Upper Left  (::'| sed 's:) (.*::'|sed 's:,::' )
#| awk '{print int($1+0.5) " " int($2+0.5)}')
lr=$(gdalinfo $1/$1-wbm.vrt | grep -Po 'Lower Right (.*)' | sed 's:Lower Right (::'| sed 's:) (.*::'|sed 's:,::' )
#| awk '{print int($1+0.5) " " int($2+0.5)}')
echo "$1 -> $tr $ul $lr" 
gdal_translate -of VRT -tr $tr -projwin $ul $lr $fch $1-fch.vrt