import cdsapi
import sys

yyyy = sys.argv[1]
mm = sys.argv[2]

dataset = "satellite-cloud-properties"
request = {
    "product_family": "clara_a3",
    "origin": "eumetsat",
    "variable": ["cloud_fraction"],
    "climate_data_record_type": "thematic_climate_data_record",
    "time_aggregation": "daily_mean",
    "year": yyyy,
    "month": mm,
    "day": [
        "01", "02", "03",
        "04", "05", "06",
        "07", "08", "09",
        "10", "11", "12",
        "13", "14", "15",
        "16", "17", "18",
        "19", "20", "21",
        "22", "23", "24",
        "25", "26", "27",
        "28", "29", "30",
        "31"
    ],
    "area": [75, -30, 25, 50],
    "data_format": "grib"
}

client = cdsapi.Client()
client.retrieve(dataset, request),
f'/home/smartmet/data/grib/C3S_200001010000_%s-%sclara-clr.grib'%(yyyy,mm).download()
