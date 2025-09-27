# dokku-metabase

Deploy [Metabase](https://metabase.com/) on a Dokku host.

First, execute on the server:

```shell
# Change the variable values:
APP_NAME="metabase"
APP_DOMAIN="metabase.example.com"
ADMIN_EMAIL="admin@example.com"
PG_NAME="pg_${APP_NAME}"
JAVA_OPTS="-Xmx16g -Xss512k -XX:CICompilerCount=2 -Dfile.encoding=UTF-8"
# `-Xmx16g` means JVM will use up to 16GB of RAM
STORAGE_PATH="/var/lib/dokku/data/storage/$APP_NAME"

# Create app and set general configs
dokku apps:create $APP_NAME
dokku domains:add $APP_NAME $APP_DOMAIN
dokku config:set --no-restart $APP_NAME "JAVA_OPTS=$JAVA_OPTS"
dokku config:set --no-restart $APP_NAME "MB_UNAGGREGATED_QUERY_ROW_LIMIT=100000"
dokku config:set --no-restart $APP_NAME "MB_AGGREGATED_QUERY_ROW_LIMIT=200000"
dokku config:set --no-restart $APP_NAME "MB_PLUGINS_DIR=/data/plugins"
dokku letsencrypt:set $APP_NAME email $ADMIN_EMAIL
dokku checks:disable metabase

# Database
dokku postgres:create $PG_NAME
dokku postgres:link $PG_NAME $APP_NAME

# Storage
mkdir -p "$STORAGE_PATH"
chown -R 1000:1000 "$STORAGE_PATH"
dokku storage:mount $APP_NAME "$STORAGE_PATH:$DATA_DIR"
```

On your local machine:

```shell
git clone https://github.com/PythonicCafe/dokku-metabase.git
cd dokku-metabase
git remote add dokku dokku@<dokku-server>:<app-name>
git push dokku main
```

Finally, on the server:

```shell
dokku letsencrypt:enable metabase
```

## To do

Configure plugins directory to avoid "WARN metabase.plugins :: Metabase cannot
use the plugins directory /app/plugins".

## Backup

To backup the main postgres database, execute:

```shell
APP_NAME="metabase"
PG_NAME="pg_${APP_NAME}"
dokku postgres:export $PG_NAME | gzip - > postgres-${APP_NAME}-$(date --iso=seconds).sql.gz
```
