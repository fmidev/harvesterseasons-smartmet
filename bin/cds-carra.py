import cdsapi

dataset = "reanalysis-carra-means"
request = {
    "domain": "west_domain",
    "time_aggregation": "daily",
    "level_type": "soil_levels",
    "level_location": ["1"],
    "variable": ["volumetric_soil_moisture"],
    "product_type": "analysis_based",
    "year": ["2025"],
    "month": ["08"],
    "day": ["06", "26"],
    "data_format": "grib"
}

client = cdsapi.Client()
client.retrieve(dataset, request).download('/home/ubuntu/data/CARRA_202508_test.grib')