import cdsapi
import sys

syear = sys.argv[1]
eyear = sys.argv[2]
mon = sys.argv[3]
years=list(range(int(syear),int(eyear)+1))
print(years)

c = cdsapi.Client()

c.retrieve(
    'satellite-lai-fapar',
    {
        'format': 'zip',
        'satellite': [
            'proba', 'spot',
        ],
        'variable': 'lai',
        'horizontal_resolution': '1km',
        'sensor': 'vgt',
        'product_version': 'V3',
        'year': years,
        'month': mon,
        'nominal_day': [
            '10', '20', '31',
        ],
    },
    'vito-lai_%s-%s_%s_dekad.zip'%(syear,eyear,mon)
)