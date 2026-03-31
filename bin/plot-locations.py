import matplotlib.pyplot as plt
import cartopy.crs as ccrs
import cartopy.feature as cfeature

# (lat, lon)
points = {
    "Finland":  (63.05, 29.85),
    "Sweden":   (57.10, 14.70),
    "Germany":  (52.85, 13.25),
    "France":   (44.20, -0.80),
    "Spain":    (41.95, -3.90),
    "Poland":   (53.80, 17.60),
    "Ukraine":  (51.20, 28.70),
    "Greece":   (40.05, 21.05),
    "Latvia":   (57.15, 25.30),
    "Slovenia": (46.30, 14.90),
    "Estonia":  (58.70, 25.80),
    "Czech":    (49.60, 15.30),
    "Denmark":  (56.20, 10.20),
}

# Europe-ish extent (lon_min, lon_max, lat_min, lat_max)
extent = (-12, 45, 34, 72)

fig = plt.figure(figsize=(10, 8))
ax = plt.axes(projection=ccrs.PlateCarree())
ax.set_extent(extent, crs=ccrs.PlateCarree())

# Base map: land/ocean + borders
ax.add_feature(cfeature.OCEAN)
ax.add_feature(cfeature.LAND, edgecolor="none")
ax.add_feature(cfeature.BORDERS, linewidth=0.8)
ax.add_feature(cfeature.COASTLINE, linewidth=0.8)

# Optional: admin-1 boundaries if you want more detail
# ax.add_feature(cfeature.STATES, linewidth=0.3)  # works mainly for some datasets/regions

# Plot points
lats = [lat for (lat, lon) in points.values()]
lons = [lon for (lat, lon) in points.values()]
ax.scatter(
    lons, lats,
    s=80, marker="o",
    color="red",
    transform=ccrs.PlateCarree(),
    zorder=5,
)

# Labels (slight offset so they don't overlap the dot)
for name, (lat, lon) in points.items():
    ax.text(
        lon + 0.5, lat + 0.3, name,
        transform=ccrs.PlateCarree(),
        fontsize=9,
        zorder=6,
        bbox=dict(boxstyle="round,pad=0.2", fc="white", ec="none", alpha=0.7),
    )

ax.set_title("Selected locations in Europe", fontsize=14)
plt.tight_layout()
plt.savefig("/home/ubuntu/data/swi2valid/Europe_forest_points_map.svg", format="svg")
plt.savefig("/home/ubuntu/data/swi2valid/Europe_forest_points_map.png", dpi=300)