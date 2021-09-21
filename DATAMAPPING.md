# Mapping data variables into SmartMet-Server variables

Data from GRIB files need to be mapped onto variables that the SmartMet-Server system recognizes. This will enable querying for the data from timeseries, WMS or other plugins.
1. First check if config/libraries/grid-files/fmi_parameters.csv has already a suitable parameter that just was not automatically mapped (the system tries to, but it might fail). If there is note the FmiParameterId number and go to 3.
2. In case no FmiParameterId is suitable, define a new one in the fmi_parameters_ext.csv . In the comments at the beginning of this file are the fields that need to be defined in a new line of this file. The first number needs to be a number that is not present in fmi_parameters.csv or fmi_parameters_ext.csv. For the rest follow the example of existing definitions. you can leave some fields undefined. Make sure you have ; separators as many as required (=7).
3. Now check your existing grib files to identify grib-ids for mapping with the fmiParameterId
  * grib1 files need table2version and parameterId numbers (each a number between 0 and 255)
  * grib2 files need parameterId, param category and discipline numbers (0..255 each)
4. Mapping is usually automatic then these number combinations already exist in the system and the mapping pops up in engines/grid-engine/mapping_fmi_auto.csv . If not, the mapping can be forced in the mapping_fmi.csv or 
5. In case of new grib files additional steps are needed to have these grib parameters known to the system. New grib variables (grib1 and grib2) need to find global grib-ids. These are defined in another batch of csvs:
  * For Grib1 these grib-ids are being looked for in the  "grib1_parameters.csv" file (the parameterId here is the  grib-id). in fmi_parameterId_grib1.csv the automatic mappings can be checked and if the desired mapping is missing, the system can be made to identify data by adding a specific mapping into fmi_parameterId_grib1_ext.csv
    * here grib1_parameters.csv  
  * For Grib2 grib-id searching is similar as for grib1, but with a 3 number combination the csv files are more complex and unfortunately levelTypes are different, so these configurations are needed in "grib2_parameters.csv" or _ext.csv filea.
  * Succesful searches can be helped with investiagtin the grib files with the grid_dump cmd line program to show each variables' grib parameters (table2version and parameterId or discipline, category and parameterId).
  * grib-ids can also be listed in "grib_parameters.csv" where some grib1 and 2 consistent variables have been defined
  * other attributes of grib files like level type and levels should also be set correctly. Their available settings are in the grib?_levels.csv, grib?_timeRanges.csv, grib_tables.csv, grib_units.csv with ? being either 1 or 2. 
  * for super complete configurations fmi_producerId s can also be defined and mapped. But generally not defining them (empty fields in csvs) in the above files enables data usage easier.

Many of the csv files can be automatically updated from a FMI database. The _ext versions are used to bypass this database update, so it will not overwrite local configurations. So it is recommended to add own settings mainly into the _ext.csv files.

In the end it should be possible to query daya in timeseries requests or WMS layer definitions with newbase names or strings with FMI-ID:::: names. Those names are in the fmi_parameters.csv

![](https://github.com/fmidev/chile-smartmet/blob/master/parameter-mapping.png)
