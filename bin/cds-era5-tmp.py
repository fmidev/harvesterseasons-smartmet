import cdsapi,sys

var=sys.argv[1]
print(var)

c = cdsapi.Client()

c.retrieve(
    'reanalysis-era5-single-levels-monthly-means',
    {
#        "stream": "oper",
#        "levtype": "sfc",
        'variable': [
            var,
        ],
   "year": [
        "1995", "1996", "1997",
        "1998", "1999", "2000",
        "2001", "2002", "2003",
        "2004", "2005", "2006",
        "2007", "2008", "2009",
        "2010", "2011", "2012",
        "2013", "2014", "2015",
        "2016", "2017", "2018",
        "2019", "2020", "2021",
        "2022", "2023", "2024",
        "2025", "2026"
    ],
    "month": [
        "01", "02", "03",
        "04", "05", "06",
        "07", "08", "09",
        "10", "11", "12"
    ],
        'time':'00:00',
        'area': [ 83, -33, 28, 55],
        "download_format": "unarchived",
        'data_format': 'grib',
    },
    '/home/ubuntu/data/era5-%s-sl-mon-eu.grib'%(var))