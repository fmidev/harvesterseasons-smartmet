from datetime import datetime as dt, timedelta
import json
import os
import sys
from pathlib import Path
from typing import List

import pandas as pd
from requests import request

client_id = "RdDpoIEgrf5Fi0QmFgNVB"
client_secret = "74sIBp9aajwIOdWZM23UBWDwv5ass6QASYkO8SU7"

def aeris_api_dataframe(location: str, custom_fields: List[str] = None, start_date: dt = None, end_date: dt = None) -> pd.DataFrame:
    formatted_fields = []

    if custom_fields is not None:
        formatted_fields = ','.join(custom_fields)

    print(f"retrieving data for {location} from {start_date.strftime('%Y-%m-%d')} to {end_date.strftime('%Y-%m-%d')}...")
    res = request(
        method="GET",
        url=f"https://api.aerisapi.com/conditions/{location}",
        params={
            "client_id": client_id,
            "client_secret": client_secret,
            "fields": formatted_fields,
            "from": start_date,
            "to": end_date,
            "limit": 1000  # Adjust limit as needed
        }
    )
    
    if res.status_code != 200:
        raise Exception(f"status code was not 200: {res.status_code}")
          
    api_response_body = json.loads(res.text)

    try:
        df_pre_period = pd.json_normalize(api_response_body['response'][0]).drop("periods", axis=1)
        df_periods = pd.json_normalize(api_response_body['response'][0], "periods", record_prefix="periods.")
        df_combined = df_pre_period.join(df_periods, how="cross")
        df_combined['latitude'] = df_combined['loc.lat']
        df_combined['longitude'] = df_combined['loc.long']
        return df_combined
    except IndexError:
        print(f"API Response did not contain periods. Verify request parameters are correct.\n\nRequest:\n{res.url}\n\nResponse:\n{api_response_body}")

def fetch_data_in_parts(location: str, custom_fields: List[str], start_date: dt, end_date: dt, part_days: int = 365):
    current_start_date = start_date
    all_dataframes = []

    while current_start_date < end_date:
        current_end_date = min(current_start_date + timedelta(days=part_days), end_date)
        df_part = aeris_api_dataframe(location=location, custom_fields=custom_fields, start_date=current_start_date, end_date=current_end_date)
        all_dataframes.append(df_part)
        current_start_date = current_end_date + timedelta(days=1)

    return pd.concat(all_dataframes, ignore_index=True)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python fetch_historical_conditions.py <location> <country>")
        sys.exit(1)

    location = f"{sys.argv[1]},{sys.argv[2]}"
    start_date = dt(2012, 1, 1)
    end_date = dt(2024, 12, 31)

    request_fields = [
        'periods.dateTimeISO',
        'place.name',
        'place.country',
        'loc.lat',
        'loc.long',
        'periods.tempC',
        'periods.windGustMPS',
        'periods.windSpeedMPS',
        'periods.windDirDEG',
        'periods.precipMM',
        'periods.humidity',
    ]

    df = fetch_data_in_parts(location=location, custom_fields=request_fields, start_date=start_date, end_date=end_date)
    output_dir = Path('csv_output')
    output_dir.mkdir(exist_ok=True)
    location_name = location.replace(",", "_").replace(" ", "_")
    filename = f"{location_name}-{start_date.strftime('%Y%m%d')}-to-{end_date.strftime('%Y%m%d')}.csv"
    df.to_csv(output_dir / filename, encoding="utf-8")
    print(f"csv saved as {output_dir / filename}")
