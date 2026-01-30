import pandas as pd
import ast
import numpy as np
from math import radians, sin, cos, sqrt, atan2

file = '/home/ubuntu/data/latest_vettakengassa.csv'
data = pd.read_csv(file)

# ----------------------------
# Clean contestant names
# - lowercase
# - remove ALL whitespace
# - treat empty / "nan"/"none"/"null" as missing
# ----------------------------
data['contestantName_clean'] = (
    data['contestantName']
        .astype('string')
        .str.lower()
        .str.replace(r'\s+', '', regex=True)
        .replace({'': pd.NA, 'nan': pd.NA, 'none': pd.NA, 'null': pd.NA})
)

# ----------------------------
# Translate Finnish answer classes to English
# ----------------------------
data['answer'] = data['answer'].replace({
    "Erittäin märkä": "Extremely wet",
    "Märkä": "Wet",
    "Kostea": "Moist",
    "Kuiva": "Dry",
    "Erittäin kuiva": "Very dry"
})

# Normalized answer for analysis (lowercase + strip)
data['answer_clean'] = (
    data['answer']
        .astype('string')
        .str.lower()
        .str.strip()
        .replace({'': pd.NA, 'nan': pd.NA, 'none': pd.NA, 'null': pd.NA})
)

# ----------------------------
# Parse createdAt and extract date
# ----------------------------
data['createdAt_dt'] = pd.to_datetime(data['createdAt'], errors='coerce', utc=True)
data['date'] = data['createdAt_dt'].dt.date

# ----------------------------
# Parse geoLocation: "[lon, lat]" -> lon, lat columns
# ----------------------------
def parse_lon_lat(x):
    try:
        if pd.isna(x):
            return pd.Series({'lon': np.nan, 'lat': np.nan})
        lon, lat = ast.literal_eval(str(x))
        return pd.Series({'lon': float(lon), 'lat': float(lat)})
    except Exception:
        return pd.Series({'lon': np.nan, 'lat': np.nan})

coords = data['geoLocation'].apply(parse_lon_lat)
data = pd.concat([data, coords], axis=1)

# ----------------------------
# Basic per-contestant counts
# ----------------------------
print("Total rows:", len(data))
print("Total rows with contestantName:", data['contestantName_clean'].notna().sum())

counts = data['contestantName_clean'].dropna().value_counts()
print("\nObservations per contestant (top 10):")
print(counts.head(10))

if len(counts) > 0:
    top_contestant = counts.idxmax()
    top_count = counts.max()
    print("\nTop contestant:")
    print(f"{top_contestant}: {top_count} observations")

    if len(counts) > 1:
        second_best_contestant = counts.index[1]
        second_best_count = counts.iloc[1]
        print("\nSecond best:")
        print(f"{second_best_contestant}: {second_best_count} observations")

print(f"\nTotal observations: {len(data)}")
print(f"Total observations with contestantName: {data['contestantName_clean'].notna().sum()}")

# ----------------------------
# Diversity ranking: number of distinct answer classes per contestant
# ----------------------------
diversity = (
    data
    .dropna(subset=['contestantName_clean', 'answer_clean'])
    .groupby('contestantName_clean')['answer_clean']
    .nunique()
    .sort_values(ascending=False)
)

print("\nDiversity ranking (distinct answer classes per contestant) (top 10):")
print(diversity.head(10))

# ----------------------------
# Active days ranking: number of distinct dates per contestant
# ----------------------------
active_days = (
    data
    .dropna(subset=['contestantName_clean', 'date'])
    .groupby('contestantName_clean')['date']
    .nunique()
    .sort_values(ascending=False)
)

print("\nActive days per contestant (top 10):")
print(active_days.head(10))

# ----------------------------
# Movement ranking (max distance between any two observations per contestant)
# ----------------------------
def haversine(lon1, lat1, lon2, lat2):
    R = 6371.0  # km
    lon1, lat1, lon2, lat2 = map(radians, [lon1, lat1, lon2, lat2])
    dlon = lon2 - lon1
    dlat = lat2 - lat1
    a = sin(dlat / 2) ** 2 + cos(lat1) * cos(lat2) * sin(dlon / 2) ** 2
    c = 2 * atan2(sqrt(a), sqrt(1 - a))
    return R * c

def max_distance(group):
    pts = group[['lon', 'lat']].dropna().values
    if len(pts) < 2:
        return 0.0
    max_d = 0.0
    for i in range(len(pts)):
        for j in range(i + 1, len(pts)):
            d = haversine(pts[i][0], pts[i][1], pts[j][0], pts[j][1])
            if d > max_d:
                max_d = d
    return max_d

movement = (
    data
    .dropna(subset=['contestantName_clean'])
    .groupby('contestantName_clean')
    .apply(max_distance)
    .sort_values(ascending=False)
)

print("\nMovement ranking (max distance between any two observations, km) (top 10):")
print(movement.head(10))

# ----------------------------
# Combined ranking (diversity + movement + temporal coverage)
# ----------------------------
combined = pd.DataFrame({
    'observations': counts,
    'diversity_classes': diversity,
    'active_days': active_days,
    'max_distance_km': movement
}).fillna(0)

# Normalize to 0..1 for comparability
combined['diversity_norm'] = combined['diversity_classes'] / combined['diversity_classes'].max() if combined['diversity_classes'].max() > 0 else 0.0
combined['movement_norm'] = combined['max_distance_km'] / combined['max_distance_km'].max() if combined['max_distance_km'].max() > 0 else 0.0
combined['days_norm'] = combined['active_days'] / combined['active_days'].max() if combined['active_days'].max() > 0 else 0.0

# Unweighted score (equal importance)
combined['score'] = combined['diversity_norm'] + combined['movement_norm'] + combined['days_norm']

combined = combined.sort_values('score', ascending=False)

print("\nCombined ranking (diversity + movement + days) (top 10):")
print(combined[['observations', 'diversity_classes', 'active_days', 'max_distance_km', 'score']].head(10))
