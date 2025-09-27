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

dokku apps:create $APP_NAME
dokku domains:add $APP_NAME $APP_DOMAIN
dokku config:set --no-restart $APP_NAME "JAVA_OPTS=$JAVA_OPTS"
dokku letsencrypt:set $APP_NAME email $ADMIN_EMAIL
dokku checks:disable metabase

dokku postgres:create $PG_NAME
dokku postgres:link $PG_NAME $APP_NAME
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
