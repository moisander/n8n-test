#!/bin/sh
set -e

# Parse DATABASE_URL (postgresql://user:pass@host:port/dbname?params) into
# the individual env vars that n8n expects.
if [ -n "$DATABASE_URL" ]; then
  # Strip the scheme
  url_body="${DATABASE_URL#*://}"

  # Extract user:password
  userinfo="${url_body%%@*}"
  export DB_POSTGRESDB_USER="${userinfo%%:*}"
  export DB_POSTGRESDB_PASSWORD="${userinfo#*:}"

  # Extract host:port/dbname
  hostpart="${url_body#*@}"
  hostport="${hostpart%%/*}"
  export DB_POSTGRESDB_HOST="${hostport%%:*}"
  export DB_POSTGRESDB_PORT="${hostport#*:}"

  # Extract database name (strip query params if present)
  dbname="${hostpart#*/}"
  export DB_POSTGRESDB_DATABASE="${dbname%%\?*}"

  # Enable SSL if the URL contains sslmode=require
  case "$DATABASE_URL" in
    *sslmode=require*) export DB_POSTGRESDB_SSL_ENABLED=true ;;
  esac

  echo "Parsed DATABASE_URL -> host=$DB_POSTGRESDB_HOST port=$DB_POSTGRESDB_PORT db=$DB_POSTGRESDB_DATABASE user=$DB_POSTGRESDB_USER ssl=$DB_POSTGRESDB_SSL_ENABLED"
fi

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
  echo "Set DATABASE_URL or the individual DB_POSTGRESDB_* variables."
  exit 1
fi

echo "Running n8n database migrations..."
n8n db:migrate

echo "Starting n8n..."
exec n8n start
