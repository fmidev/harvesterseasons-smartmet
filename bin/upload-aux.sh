#!/bin/bash
s3cmd -P -q sync $1.tif.aux.xml s3://copernicus/dsm/ &
s3cmd -P -q sync $1-dtm.tif.aux.xml s3://copernicus/dtm/ && rm $1-dtm.tif.aux.xml &
s3cmd -P -q sync $1-aspect.tif.aux.xml s3://copernicus/dtm/aspect/ && rm $1-aspect.tif.aux.xml &
s3cmd -P -q sync $1-filled.tif.aux.xml s3://copernicus/dtm/sink-filled-dem/ && rm $1-filled.tif.aux.xml &
s3cmd -P -q sync $1-burn.tif.aux.xml s3://copernicus/dtm/stream-burn/ && rm $1-burn.tif.aux.xml &
s3cmd -P -q sync $1-slope.tif.aux.xml s3://copernicus/dtm/slope/ && rm $1-slope.tif.aux.xml &
#s3cmd -P -q sync $1-stream.tif.aux.xml s3://copernicus/dtm/stream/ &
#s3cmd -P -q sync $1-flowdir.tif.aux.xml s3://copernicus/dtm/flow-dir/ &
s3cmd -P -q sync $1-flow.tif.aux.xml s3://copernicus/dtm/flow-acc/ && rm $1-flow.tif.aux.xml &
s3cmd -P -q sync $1-flow-width.tif.aux.xml s3://copernicus/dtm/flow-width/ && rm $1-flow-width.tif.aux.xml &
s3cmd -P -q sync $1-scarea.tif.aux.xml s3://copernicus/dtm/scarea/ && rm $1-scarea.tif.aux.xml &
s3cmd -P -q sync $1-twi.tif.aux.xml s3://copernicus/dtm/twi/
