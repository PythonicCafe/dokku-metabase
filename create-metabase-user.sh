#!/bin/bash
set -euo pipefail

SERVICE_NAME="${1:-}"
if [[ -z "$SERVICE_NAME" ]]; then
  echo "ERROR: please provide the service_name. Example: $0 <service_name>" >&2
  exit 1
fi

RO_USER="metabase"
RO_PASS="$(openssl rand -base64 48 | tr -d '\n\\/=+')"

# Discover the database name (the service's default DB) using exactly the command that worked for you
DB_NAME="$(
  echo -e '\set QUIET 1\n\pset tuples_only on\n\pset format unaligned\nselect current_database();' \
  | dokku postgres:connect "$SERVICE_NAME" \
  | awk 'NF {print $1; exit}'
)"

if [[ -z "$DB_NAME" ]]; then
  echo "ERROR: could not determine the database name via current_database()" >&2
  exit 2
fi

# Create/update the metabase user and grant read-only access across all current non-system schemas,
# plus DEFAULT PRIVILEGES so new tables/sequences created by role postgres inherit read-only grants.
echo "
BEGIN;

DO \$\$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '${RO_USER}') THEN
    EXECUTE format('CREATE ROLE %I LOGIN PASSWORD %L', '${RO_USER}', '${RO_PASS}');
  ELSE
    EXECUTE format('ALTER ROLE %I WITH LOGIN PASSWORD %L', '${RO_USER}', '${RO_PASS}');
  END IF;
END
\$\$;

GRANT CONNECT ON DATABASE \"${DB_NAME}\" TO \"${RO_USER}\";

DO \$\$
DECLARE s RECORD;
BEGIN
  FOR s IN
    SELECT nspname
    FROM pg_namespace
    WHERE nspname NOT LIKE 'pg_%'
      AND nspname <> 'information_schema'
  LOOP
    EXECUTE format('GRANT USAGE ON SCHEMA %I TO %I', s.nspname, '${RO_USER}');
    EXECUTE format('GRANT SELECT ON ALL TABLES IN SCHEMA %I TO %I', s.nspname, '${RO_USER}');
    EXECUTE format('GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA %I TO %I', s.nspname, '${RO_USER}');

    -- New tables/sequences created by owner postgres in these schemas will inherit these privileges:
    EXECUTE format('ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA %I GRANT SELECT ON TABLES TO %I', s.nspname, '${RO_USER}');
    EXECUTE format('ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA %I GRANT USAGE, SELECT ON SEQUENCES TO %I', s.nspname, '${RO_USER}');
  END LOOP;
END
\$\$;

COMMIT;
" | dokku postgres:connect "$SERVICE_NAME" >/dev/null

echo "DB_NAME=${DB_NAME}"
echo "RO_USER=${RO_USER}"
echo "RO_PASS=${RO_PASS}"
