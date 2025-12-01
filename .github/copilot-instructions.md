# Copilot Instructions: `harvesterseasons-smartmet`

High‑impact guidance for AI coding agents working on SmartMet + Harvester Seasons (ERA5 / ERA5‑Land, seasonal forecasts, HOPS). Keep changes backward compatible with data ingestion and producer naming conventions.

## 1. Architecture & Data Flow
`docker-compose.yaml` runs 4 services: SmartMet Server (`smartmet-server/`), Postgres (fminames), Redis (grid catalog), optional nginx SSL proxy. Retrieval scripts in `bin/` fetch external datasets (CDS/CAMS/Seasonal/HOPS) → produce GRIB (sometimes NetCDF) → host `../data/grib` (mounted `/srv/data/grib`) → ingested with `/bin/fmi/filesys2smartmet` and mapping CSVs → exposed via Timeseries/WMS/WFS.

## 2. Critical Files & Conventions
`smartmet-server/Dockerfile` MUST install `smartmet-server` plus required `smartmet-plugin-*`; missing the core package causes runtime symbol errors (e.g. `_ZN8SmartMet5Spine...addContentHandler`).
`smartmet-server/scripts/wait-for-postgres.sh` gates startup until DB ready.
`config/engines/grid-engine/producers.csv` first token of GRIB filename must match a producer.
`DATAMAPPING.md` + grid-files CSVs define parameter → FMI ID mappings; extend via `_ext.csv` files (never overwrite base).

## 3. GRIB & Retrieval Patterns
Filename pattern: `<PRODUCER>_<YYYYMMDD>T<HHMMSS>_<descriptor>.grib` (descriptor free-form but stable). Python `cds-*.py` scripts: positional `year month day`; add new optional args only at end guarded by `if len(sys.argv)>N`. Keep fixed area defaults unless feature demands change.

## 4. Ingestion Steps
Drop GRIB into `../data/grib` then run:
`docker exec --user smartmet smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0`
Verify via `/grid-gui` or stored queries. Ensure new producer + parameter mappings exist before bulk ingest.

## 5. Mapping & Extension Workflow
1. Look for existing FMI parameter in `fmi_parameters.csv`.
2. Add new to `fmi_parameters_ext.csv` if absent (unique numeric id).
3. For GRIB2: discipline/category/parameter; for GRIB1: table2version/parameterId. Auto mappings appear in `mapping_fmi_auto.csv`; force in `mapping_fmi.csv` or `_ext` variants.
4. Use `grid_dump` (inside container) to inspect GRIB headers when adding mappings.

## 6. Performance & Bias Scripts
Heavy climate/stat operations: prefer GNU `parallel` + `cdo` + `grib_set` (examples in README bias section). Keep ensemble member suffix `-<member>.grib`; derive aggregates with explicit commands (e.g. `cdo ensmean ...`).

## 7. Debug / Troubleshooting
Symbol lookup crash (plugins): confirm versions:
`rpm -q smartmet-server smartmet-plugin-admin`
List exported spine symbols:
`nm -D /usr/share/smartmet/lib/libsmartmet-spine.so | grep ContentHandlerMap`
If missing: add `smartmet-server` RPM or align plugin versions (pin exact releases in Dockerfile).
Health check: `curl -f http://localhost:8080/admin?what=qengine`.

## 8. Common Commands
Build all: `docker-compose up --detach --build`
Rebuild server only: `docker-compose build smartmet-server && docker-compose up --detach smartmet-server`
Ingest GRIB: see §4 command. Add producers before ingest.

## 9. API Smoke Examples
Timeseries: `/timeseries?param=place,utctime,WindSpeedMS:ERA5:26:0:0:0&latlon=60.192059,24.945831&format=debug&source=grid&producer=ERA5&starttime=data&timesteps=5`
Adjust params according to mapped FMI IDs or newbase names.

## 10. Safe Change Guidelines
Preserve filename patterns; don’t reorder existing positional args; extend via optional tail args. Put custom parameter & mapping changes only in `_ext.csv` files. Keep long timeout env defaults unless measured need to reduce.

Request clarification if adding a new data source (producer, mapping strategy, projection transform) or new plugin.