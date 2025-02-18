#!/usr/bin/env python
import requests
import sys
import pandas as pd
from datetime import datetime

elements = sys.argv[1] # for example ask for this on cmd line: getmetno-py 'sum(precipitation_amount P1D)'
sources = sys.argv[2] # for example ask for this on cmd line: getmetno-py 'SN*'
prefix = sys.argv[3] # for example ask for this on cmd line: getmetno-py '-2' to add to the filename
referencetime = '2000-01-01/2024-12-31'

def get_precipitation_data():
    # API endpoint
    endpoint = 'https://frost.met.no/observations/v0.jsonld'
        
    # Parameters for the API request
    parameters = {
        'sources': sources, #'SN*',  # All stations in Norway
        'elements': elements, #'sum(precipitation_amount P1D)',  # Daily precipitation sum
        'levels': 5,  # 2 meters above ground
        'referencetime': referencetime,
    #   'fields': 'sourceId,referenceTime,geometry,elementID,value',
    }
    
    # Make the request
    r = requests.get(endpoint, parameters)
    
    if r.status_code == 200:
        data = r.json()
        
        # Convert to DataFrame
        rows = []
        for item in data['data']:
            row = {
                'date': item['referenceTime'],
                'latitude': item['geometry']['coordinates'][1],
                'longitude': item['geometry']['coordinates'][0],
                'station': item['sourceId'],
                elements: item['observations'][0]['value']
            }
            rows.append(row)
        
        df = pd.DataFrame(rows)
        
        # Save to CSV
        filename = f'metno_{referencetime.replace('/', '-')}_{elements}{prefix}.csv'
        df.to_csv(filename, index=False)
        print(f'Data saved to {filename}')
        
    else:
        print('Error:', r.status_code)
        print(r.text)

if __name__ == '__main__':
    get_precipitation_data()