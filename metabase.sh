#!/bin/bash
# Convert Dokku variables to the format Metabase expects, then run it

export MB_DB_TYPE=postgres
export MB_DB_CONNECTION_URI="jdbc:$(echo $DATABASE_URL | sed 's|postgres://|postgresql://|')"
export MB_JETTY_PORT=5000

echo "-----> Starting Metabase"

/app/run_metabase.sh
