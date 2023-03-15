#!/usr/bin/env python3
#The following line imports the HDA python library 

from hda import Client
import cdsapi
import sys
import datetime

sdate= sys.argv[1]
edate= sys.argv[2]
c = Client(debug=True)

#The following line contains the descriptor query looking for V10 Synergy product
query = {
  "datasetId": "EO:ESA:DAT:SENTINEL-3:SYNERGY",
  "dateRangeSelectValues": [
    {
      "name": "position",
      "start": "{:0>8}T00:00:00.000Z".format(sdate),
      "end": "{:0>8}T00:00:00.000Z".format(edate)
    }
  ],
  "stringChoiceValues": [
    {
      "name": "productType",
      "value": "SY_2_V10___"
    }
  ]
}
#print(query)
# The following line runs the query
matches = c.search(query)

# The following line prints the products returned by the query
print(matches)

#The download starts. All the products found in the query are downloaded consecutively
matches.download()