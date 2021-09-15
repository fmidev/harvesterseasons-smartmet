#!/usr/bin/env python3
import sys
import cdsapi
year= sys.argv[1]
month= sys.argv[2]

c = cdsapi.Client()

c.retrieve(
        'efas-historical',
        {
                    'format': 'grib',
                    'origin': 'ecmwf',
                    'simulation_version': 'version_3_5',
                    'variable': [
                                    'soil_depth', 'volumetric_soil_moisture',
                                ],
                    'model_levels': 'soil_levels',
                    'soil_level': [
                                    '1', '2', '3',
                                ],
                    'hyear': year,
                    'hmonth': month,
                    'hday': [
                                    '01', '02', '03',
                                    '04', '05', '06',
                                    '07', '08', '09',
                                    '10', '11', '12',
                                    '13', '14', '15',
                                    '16', '17', '18',
                                    '19', '20', '21',
                                    '22', '23', '24',
                                    '25', '26', '27',
                                    '28', '29', '30',
                                    '31',
                                ]
                },
        '/home/smartmet/data/efas-ana-%s.grib'%(year))
