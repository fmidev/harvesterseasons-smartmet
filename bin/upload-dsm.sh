#!/bin/bash
s3cmd -P -q sync $1-aspect.tif s3://copernicus/dsm/aspect/ &
s3cmd -P -q sync $1-filled.tif s3://copernicus/dsm/sink-filled-dem/ &
s3cmd -P -q sync $1-slope.tif s3://copernicus/dsm/slope/ &
s3cmd -P -q sync $1-flow.tif s3://copernicus/dsm/flow-acc/ &
s3cmd -P -q sync $1-flow-width.tif s3://copernicus/dsm/flow-width/ &
s3cmd -P -q sync $1-scarea.tif s3://copernicus/dsm/scarea/ &
s3cmd -P -q sync $1-twi.tif s3://copernicus/dsm/twi/
