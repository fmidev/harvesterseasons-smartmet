# Mapping data variables into SmartMet-Server variables

Data from GRIB files need to be mapped onto variables that the SmartMet-Server system recognizes. This will ease querying for the data from timeseries, WMS or other plugins.

* Different grib variables (grib1 and grib2) need to find global grib-ids.
  * For Grib1 these grib-ids are being looked for in the  "grib1_parameters.csv" file (the parameterId = grib-id).
  * For Grib2 grib-id searching in "grib2_parameters.csv" file.
  * Succesful searches can be checked with the  grid_dump cmd line program showing each variable  grids grib-i.
  * If  grib-id is also listed in "grib_parameters.csv", other attributes of grib should also be set
* When a grib-id is identified, it needs to be mapped to a FMI-ID in "fmi_parametrerId_grib.csv"
  * if FMI-ID is not yet available, these can be defined in "fmi_parameters.csv" file
* A newbase -parameter name is found with the FMI-ID
  * if this does not work, the mapping needs to be added to the "fmi_parameterId_newbase.csv" file

In the end it should be possible to query daya in timeseries requests or WMS layer definitions with newbase names or strings with FMI-ID:::: names.