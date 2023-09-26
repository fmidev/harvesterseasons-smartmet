#!/bin/sh
# wait-for-postgres.sh

set -e

host="$1"
shift
cmd="$@"

until PGPASSWORD=$POSTGRES_PASSWORD psql -h "$host" -U "fminames_user" -c '\q'; do
  >&2 echo "Postgres is unavailable - sleeping..."
  sleep 5
done

>&2 echo "Postgres is up - executing command '${cmd}'"
exec $cmd
