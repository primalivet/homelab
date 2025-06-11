#!/usr/bin/env bash
set -e

# Psql connection variables defaults
PGUSER=${PGUSER:-"postgres"}
PGPASSWORD=${PGPASSWORD:-"postgres"}
PGHOST=${PGHOST:-"localhost"}
PGPORT=${PGPORT:-"5432"}

# Parse given flags
while [[ "$1" =~ ^- ]]; do 
  case $1 in
    -u|--user)  PGUSER="$2";     shift 2 ;;
    --password) PGPASSWORD="$2"; shift 2 ;;
    -h|--host)  PGHOST="$2";     shift 2 ;;
    -p|--port)  PGPORT="$2";     shift 2 ;;
    *)          echo "Invalid option: $1" >&2; exit 1 ;;
  esac
done

# Expose psql connection variables to the environment
export PGUSER PGPASSWORD PGHOST PGPORT

SERVICE_NAME=$1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICES_DIR="$(cd "$SCRIPT_DIR/../services" && pwd)"

# Check if SERVICE_NAME is provided and that it exactly matches one of the available services
if [[ -z "$SERVICE_NAME" ]] || [[ ! -d "$SERVICES_DIR/$SERVICE_NAME" ]]; then
  AVAILABLE_SERVICES=$(find "$SERVICES_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
  echo "Usage: $0 <service_name>"
  echo "Please provide a service name from the available services:"
  for service in $AVAILABLE_SERVICES; do
    echo "- $service"
  done
  exit 1
fi

NEW_DB_USER="service_${SERVICE_NAME}"
NEW_DB_NAME="service_${SERVICE_NAME}"
NEW_DB_USER_PASSWORD=$(openssl rand -hex 36)

# For refernece, the more uncommon flags to psql below are there to get the
# count, not the actual row, to check existence.
# -t: tuples only (no headers) 
# -A: unaligned output 
# -c: run the command

# Create a new user if it does not already exist
USER_COUNT=$(psql -tAc "SELECT COUNT(*) FROM pg_roles WHERE rolname='$NEW_DB_USER'")
if [ "$USER_COUNT" == "0" ]; then
  psql -c "CREATE USER $NEW_DB_USER WITH PASSWORD '$NEW_DB_USER_PASSWORD';" > /dev/null
  echo "USER:       '$NEW_DB_USER' created."
  echo "PASSWORD:   $NEW_DB_USER_PASSWORD"
  echo "            (this is the only time it will be shown)"
else
  echo "USER:       '$NEW_DB_USER' already exists."
  echo "PASSWORD:   <existing user, password not changed>"
fi

# Create a new database if it does not already exist
DB_COUNT=$(psql -tAc "SELECT COUNT(*) FROM pg_database WHERE datname='$NEW_DB_NAME'")
if [ "$DB_COUNT" == "0" ]; then
  createdb ${NEW_DB_NAME}
  echo "DATABASE:   '$NEW_DB_NAME' created."
else
  echo "DATABASE:   '$NEW_DB_NAME' already exists."
fi

# Grant all privileges on the database to the user
psql -c "GRANT ALL PRIVILEGES ON DATABASE $NEW_DB_NAME TO $NEW_DB_USER;" > /dev/null # -tAc does not work on this command

# This is crucial for PostgreSQL 15+ where public schema permissions changed
psql -d $NEW_DB_NAME -c "GRANT ALL ON SCHEMA public TO $NEW_DB_USER;" > /dev/null
psql -d $NEW_DB_NAME -c "GRANT CREATE ON SCHEMA public TO $NEW_DB_USER;" > /dev/null

# Grant privileges on all existing tables and sequences in public schema
psql -d $NEW_DB_NAME -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $NEW_DB_USER;" > /dev/null
psql -d $NEW_DB_NAME -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $NEW_DB_USER;" > /dev/null

# Set default privileges for future objects created in public schema
psql -d $NEW_DB_NAME -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $NEW_DB_USER;" > /dev/null
psql -d $NEW_DB_NAME -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO $NEW_DB_USER;" > /dev/null

echo "PRIVILEGES: '$NEW_DB_USER' granted all priviledges on database '$NEW_DB_NAME'."
