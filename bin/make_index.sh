#!/bin/bash
# list files in cloud storage and produce folder index.html file
# run in data/copernicus folder and give top folder as input
# Mikko Strahlendorff 7.6.2021
fld=$1
rclone lsf -R --files-only lit:copernicus/$fld/ |sed 's:\(.*\):<li><a href="/'$fld'/\1">\1</a></li>:' > $fld-list.html
cat $fld-header.html $fld-list.html footer.html > $fld.html 
s3cmd -P put $fld.html s3://copernicus/$fld/index.html