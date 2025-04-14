#!/bin/bash

source ~/.smart

#eval "$(conda shell.bash hook)"
eval "$(/home/ubuntu/mambaforge/bin/conda shell.bash hook)"
cd /home/ubuntu/data

python /home/ubuntu/bin/cds-era5-dsums.py 10m_wind_gust_since_previous_post_processing
python /home/ubuntu/bin/cds-era5-dsums.py maximum_2m_temperature_since_previous_post_processing
python /home/ubuntu/bin/cds-era5-dsums.py minimum_2m_temperature_since_previous_post_processing
python /home/ubuntu/bin/cds-era5-dsums.py total_precipitation
python /home/ubuntu/bin/cds-era5-dsums.py surface_latent_heat_flux
python /home/ubuntu/bin/cds-era5-dsums.py surface_net_solar_radiation
python /home/ubuntu/bin/cds-era5-dsums.py surface_net_thermal_radiation
python /home/ubuntu/bin/cds-era5-dsums.py surface_sensible_heat_flux
python /home/ubuntu/bin/cds-era5-dsums.py surface_solar_radiation_downwards
python /home/ubuntu/bin/cds-era5-dsums.py surface_thermal_radiation_downwards
python /home/ubuntu/bin/cds-era5-dsums.py top_net_thermal_radiation
python /home/ubuntu/bin/cds-era5-dsums.py evaporation
python /home/ubuntu/bin/cds-era5-dsums.py eastward_turbulent_surface_stress
python /home/ubuntu/bin/cds-era5-dsums.py northward_turbulent_surface_stress
