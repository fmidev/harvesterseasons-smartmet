import cdsapi

dataset = "satellite-surface-radiation-budget"
request = {
    "product_family": "clara_a3",
    "origin": "eumetsat",
    "variable": ["surface_downwelling_shortwave_flux"],
    "climate_data_record_type": "thematic_climate_data_record",
    "time_aggregation": "daily_mean",
    "year": [
        "2000", "2001", "2002",
        "2003", "2004", "2005",
        "2006", "2007", "2008",
        "2009", "2010", "2011",
        "2012", "2013", "2014",
        "2015", "2016", "2017",
        "2018", "2019", "2020"
    ],
    "month": [
        "01", "02", "03",
        "04", "05", "06",
        "07", "08", "09",
        "10", "11", "12"
    ],
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
    "area": [75, -30, 25, 50]#,
    "data_format": "grib"
}

client = cdsapi.Client()
client.retrieve(dataset, request, 
                '/home/smartmet/data/grib/C3S_20000101T000000_2000-2020_srb-24h-eu.grib').download()
