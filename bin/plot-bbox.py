import matplotlib.pyplot as plt
import cartopy.crs as ccrs
import cartopy.feature as cfeature
from shapely.geometry import box
import cartopy.io.shapereader as shpreader

# Bounding box
latlons = {
    'min_lon': 23.604126,
    'min_lat': 59.642764,
    'max_lon': 26.251831,
    'max_lat': 60.777937        
}

# Create map
fig, ax = plt.subplots(figsize=(10, 8),
                       subplot_kw={'projection': ccrs.PlateCarree()})

# Set extent to Europe (rough bounds)
ax.set_extent([-15, 40, 35, 72], crs=ccrs.PlateCarree())

# Add countries
ax.add_feature(cfeature.BORDERS, linewidth=0.8)
ax.add_feature(cfeature.COASTLINE, linewidth=0.8)
ax.add_feature(cfeature.LAND, facecolor='lightgrey')
ax.add_feature(cfeature.OCEAN, facecolor='lightblue')

# Draw bounding box
rect = plt.Rectangle(
    (latlons['min_lon'], latlons['min_lat']),   # lower-left corner
    latlons['max_lon'] - latlons['min_lon'],    # width
    latlons['max_lat'] - latlons['min_lat'],    # height
    linewidth=2, edgecolor='red', facecolor='none', transform=ccrs.PlateCarree()
)
ax.add_patch(rect)

# Title
plt.title("Bounding Box over Europe", fontsize=14)
plt.savefig("/home/ubuntu/data/mapplots/Europe_bounding_box_map.png", dpi=300)
