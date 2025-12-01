import cdsapi
import sys

y1=str(sys.argv[1])

dataset = "seasonal-original-pressure-levels"
request = {
    "originating_centre": "ecmwf",
    "system": "51",
    "variable": [
        "geopotential",
        "specific_humidity",
        "temperature",
        "u_component_of_wind",
        "v_component_of_wind"
    ],
    "pressure_level": [
        "500", "700", "850",
        "925"
    ],
    "year": [y1],
    "month": [
        "01", "02", "03",
        "04", "05", "06",
        "07", "08", "09",
        "10", "11", "12"
    ],
    "day": ["01"],
    "leadtime_hour": [
        "24",
        "48",
        "72"
    ],
    "data_format": "grib",
    "area": [75, -30, 25, 50]
}

client = cdsapi.Client()
output_file = f"/home/ubuntu/data/ecsf-{y1}-pl-eu.grib"
client.retrieve(dataset, request).download(output_file)
