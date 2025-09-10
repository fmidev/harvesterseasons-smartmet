import matplotlib.pyplot as plt
import cartopy.crs as ccrs
import cartopy.feature as cfeature

# bounding boxes: (lon_min, lon_max, lat_min, lat_max)
bbox1 = [0, 42, 51, 74]   # first grid
bbox2 = [3, 33, 53, 73]   # second grid

# Luo projektiolla varustettu kartta
fig = plt.figure(figsize=(10, 8))
ax = plt.axes(projection=ccrs.PlateCarree())
ax.set_extent([-5, 50, 45, 80], crs=ccrs.PlateCarree())

# Lisää taustaelementtejä
ax.add_feature(cfeature.BORDERS, linewidth=1)
ax.add_feature(cfeature.COASTLINE, linewidth=1)
ax.add_feature(cfeature.LAND, facecolor="lightgray")

# Piirrä bounding boxit
rect1 = plt.Rectangle((bbox1[0], bbox1[2]),
                      bbox1[1]-bbox1[0],
                      bbox1[3]-bbox1[2],
                      linewidth=2, edgecolor="red", facecolor="none",
                      transform=ccrs.PlateCarree(), label="Surface grid")
ax.add_patch(rect1)

rect2 = plt.Rectangle((bbox2[0], bbox2[2]),
                      bbox2[1]-bbox2[0],
                      bbox2[3]-bbox2[2],
                      linewidth=2, edgecolor="blue", facecolor="none",
                      transform=ccrs.PlateCarree(), label="Pressure grid")
ax.add_patch(rect2)

plt.legend()
plt.title("Bounding boxes of grids on real map (Cartopy)")

plt.savefig('tmp.png', dpi=300)