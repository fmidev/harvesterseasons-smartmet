import matplotlib.pyplot as plt
import geopandas as gpd
from shapely.geometry import box

# Load world map
world = gpd.read_file(gpd.datasets.get_path("naturalearth_lowres"))

# Define bounding boxes as shapely polygons
bbox1 = box(0, 51, 42, 74)   # surface grid
bbox2 = box(3, 53, 33, 73)   # pressure grid

# Create GeoDataFrames
gdf1 = gpd.GeoDataFrame({"grid": ["Surface grid"], "geometry": [bbox1]}, crs="EPSG:4326")
gdf2 = gpd.GeoDataFrame({"grid": ["Pressure grid"], "geometry": [bbox2]}, crs="EPSG:4326")

# Plot
fig, ax = plt.subplots(figsize=(8, 8))
world.boundary.plot(ax=ax, linewidth=1, color="black")
gdf1.boundary.plot(ax=ax, color="red", linewidth=2, label="Surface grid")
gdf2.boundary.plot(ax=ax, color="blue", linewidth=2, label="Pressure grid")

ax.set_xlim(-5, 50)
ax.set_ylim(45, 80)
ax.legend()
plt.title("Bounding boxes of grids")
plt.savefig('tmp.png', dpi=300)