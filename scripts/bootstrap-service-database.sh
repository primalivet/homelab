#!/usr/bin/env bash
set -e

SERVICE_NAME=$1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICES_DIR="$(cd "$SCRIPT_DIR/../services" && pwd)"
AVAILABLE_SERVICES=$(find "$SERVICES_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)

# Check if SERVICE_NAME is provided and that it exactly matches one of the available services
if [[ -z "$SERVICE_NAME" ]] || [[ ! -d "$SERVICES_DIR/$SERVICE_NAME" ]]; then
  echo "Usage: $0 <service_name>"
  echo "Please provide a service name from the available services:"
  for service in $AVAILABLE_SERVICES; do
    echo "- $service"
  done
  exit 1
fi

DB_HOST=${POSTGRES_HOST:-"localhost"}
DB_PORT=${POSTGRES_PORT:-"5432"}
DB_USER=${POSTGRES_USER:-"postgres"}

NEW_DB_USER="service_${SERVICE_NAME}"
NEW_DB_NAME="service_${SERVICE_NAME}"
NEW_DB_USER_PASSWORD=$(openssl rand -hex 36)

# For refernece, the more uncommon flags to psql below are there to get the
# count, not the actual row, to check existence.
# -t: tuples only (no headers) 
# -A: unaligned output 
# -c: run the command

CREATED_USER=0
# -tAc does not work on this command
USER_COUNT=$(PGPASSWORD=${POSTGRES_PASSWORD:-"postgres"} psql -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER} -tAc "SELECT COUNT(*) FROM pg_roles WHERE rolname='$NEW_DB_USER'")
if [ "$USER_COUNT" == "0" ]; then
  PGPASSWORD=${POSTGRES_PASSWORD:-"postgres"} psql -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER} -c "CREATE USER $NEW_DB_USER WITH PASSWORD '$NEW_DB_USER_PASSWORD';" > /dev/null
  CREATED_USER=1
  echo "USER:       '$NEW_DB_USER' created."
else
  echo "USER:       '$NEW_DB_USER' already exists."
fi

DB_COUNT=$(PGPASSWORD=${POSTGRES_PASSWORD:-"postgres"} psql -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER} -tAc "SELECT COUNT(*) FROM pg_database WHERE datname='$NEW_DB_NAME'")
if [ "$DB_COUNT" == "0" ]; then
  PGPASSWORD=${POSTGRES_PASSWORD:-"postgres"} createdb -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER} ${NEW_DB_NAME}
  echo "DATABASE:   '$NEW_DB_NAME' created."
else
  echo "DATABASE:   '$NEW_DB_NAME' already exists."
fi

# -tAc does not work on this command
PGPASSWORD=${POSTGRES_PASSWORD:-"postgres"} psql -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER} -c "GRANT ALL PRIVILEGES ON DATABASE $NEW_DB_NAME TO $NEW_DB_USER;" > /dev/null
echo "PRIVILEGES: '$NEW_DB_USER' granted all priviledges on database '$NEW_DB_NAME'."

if [ $CREATED_USER -eq 1 ]; then
  echo "PASSWORD:   $NEW_DB_USER_PASSWORD"
  echo "            (this is the only time it will be shown)"
else
  echo "PASSWORD:   <existing user, password not changed>"
fi
