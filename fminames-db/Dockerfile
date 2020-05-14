# PostgreSQL container for Fminames database without replication from FMI master database

FROM mdillon/postgis:9.5

# natural-earth postgis db to be added
#ENV IMPORT_DATA_DIR=/tmp \
#    NATURAL_EARTH_DB=/tmp/natural_earth_vector.sqlite
#RUN apt-get update && apt-get install -y --no-install-recommends \
#      wget \
#      unzip \
#      gdal-bin \
#      sqlite3 \
# && rm -rf /var/lib/apt/lists/*

#RUN wget --quiet http://naciscdn.org/naturalearth/packages/natural_earth_vector.sqlite.zip \
#    && unzip -oj natural_earth_vector.sqlite.zip -d "$IMPORT_DATA_DIR" \
#    && rm natural_earth_vector.sqlite.zip
#COPY ./natural_earth_vector.sqlite $IMPORT_DATA_DIR

# https://hub.docker.com/_/postgres/
# Initialization scripts
# Add database named fminames with schemas and tables
COPY ./db-init-scripts/* /docker-entrypoint-initdb.d/
# postgis.sh needs to be run before the import_natural_earth script
#RUN mv /docker-entrypoint-initdb.d/postgis.sh /docker-entrypoint-initdb.d/10_postgis.sh
#COPY ./db-init-scripts/import_natural_earth.sh /docker-entrypoint-initdb.d/20_import_natural_earth.sh
# Dont use root to run commands in container from this on
USER postgres