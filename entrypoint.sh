#!/bin/sh
set -e

required_vars="DB_POSTGRESDB_HOST DB_POSTGRESDB_PORT DB_POSTGRESDB_DATABASE DB_POSTGRESDB_USER DB_POSTGRESDB_PASSWORD"
missing=""
for var in $required_vars; do
  eval val=\$$var
  if [ -z "$val" ]; then
    missing="$missing $var"
  fi
done

if [ -n "$missing" ]; then
  echo "ERROR: Missing required environment variables:$missing"
  exit 1
fi

echo "Running n8n database migrations..."
n8n db:migrate

echo "Starting n8n..."
exec n8n start
