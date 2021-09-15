#!/bin/bash
s3cmd -P -q sync $1.tif s3://copernicus/dsm/ &
s3cmd -P -q sync $1-dtm.tif s3://copernicus/dtm/ && rm $1-dtm.tif &
s3cmd -P -q sync $1-aspect.tif s3://copernicus/dtm/aspect/ && rm $1-aspect.tif &
s3cmd -P -q sync $1-filled.tif s3://copernicus/dtm/sink-filled-dem/ && rm $1-filled.tif &
s3cmd -P -q sync $1-burn.tif s3://copernicus/dtm/stream-burn/ && rm $1-burn.tif &
s3cmd -P -q sync $1-slope.tif s3://copernicus/dtm/slope/ #&& rm $1-slope.tif &
#s3cmd -P -q sync $1-stream.tif s3://copernicus/dtm/stream/ &
#s3cmd -P -q sync $1-flowdir.tif s3://copernicus/dtm/flow-dir/ &
s3cmd -P -q sync $1-flow.tif s3://copernicus/dtm/flow-acc/ && rm $1-flow.tif &
s3cmd -P -q sync $1-flow-width.tif s3://copernicus/dtm/flow-width/ && rm $1-flow-width.tif &
s3cmd -P -q sync $1-scarea.tif s3://copernicus/dtm/scarea/ #&& rm $1-scarea.tif &
s3cmd -P -q sync $1-twi.tif s3://copernicus/dtm/twi/
