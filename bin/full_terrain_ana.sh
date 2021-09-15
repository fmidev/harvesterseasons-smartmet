#!/bin/bash
dtm=${1:3:-4}
# Calculate channel network and drainage basins from DTM 
#[ ! -f $dtm-channel.sdat ] && /usr/bin/saga_cmd ta_channels 5 -ELEV $dtm.tif -FILLED $dtm-filled -MINSLOPE 0.01
# Calculate Saga WI as an option (it turned out to need a very long processing time for large areas!) NOT USED!
#saga_cmd ta_hydrology 15 -DEM $dtm.tif -TWI $dtm-swi -AREA $dtm-area -SLOPE $dtm-slope -SLOPE_TYPE 0 -SLOPE_MIN 0.01 -AREA_TYPE 2
/usr/bin/saga_cmd ta_compound 0 -ELEVATION $1 -SHADE $dtm-shade -SLOPE $dtm-slope -ASPECT $dtm-aspect -HCURV $dtm-hcurv -VCURV $dtm-vcurv -CONVERGENCE $dtm-conv -SINKS $dtm-sinks -FLOW $dtm-flow -WETNESS $dtm-twi -LSFACTOR $dtm-lsfactor -CHANNELS $dtm-channels -BASINS $dtm-basins -CHNL_BASE $dtm-chnl-base -CHNL_DIST $dtm-chnl-dist -VALL_DEPTH $dtm-valley-depth -RSP $dtm-rsp