import pandas as pd
import numpy as np

# Parameters
n_locations = 10
days = pd.date_range("2025-01-01", "2025-01-31", freq="D")  # Daily data for January 2025

# Generate random but fixed lat/lon coordinates for 10 locations
np.random.seed(42)  # For reproducibility
lats = np.random.uniform(60.0, 70.0, n_locations)   # Example: somewhere in northern latitudes
lons = np.random.uniform(20.0, 30.0, n_locations)

# Generate mock time series data
records = []
for i in range(n_locations):
    for day in days:
        temperature = np.random.normal(loc=-5 + 0.2 * day.day, scale=3)
        precipitation = np.random.gamma(shape=2, scale=3)
        wind_speed = np.random.uniform(1, 10)

        records.append({
            "date": day,
            "lat": round(lats[i], 4),
            "lon": round(lons[i], 4),
            "temperature_C": round(temperature, 1),
            "precipitation_mm": round(precipitation, 1),
            "wind_speed_mps": round(wind_speed, 1),
            "target":round(temperature + precipitation - wind_speed, 1)
        })

# Create DataFrame
df = pd.DataFrame(records)

# Preview
print(df.head(20))
