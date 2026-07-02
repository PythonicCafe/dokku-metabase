# Exposing Dokku databases to Metabase

Steps to follow:

- Kernel routing settings;
- UFW DNAT before.rules;
- UFW allow from Metabase and reject anything else 
- Dokku expose ONLY to 127.0.0.1

## Kernel settings

We must allow traffic routing to the loopback interface (localhost) in `/etc/sysctl.d/99-sysctl.conf`:

```shell
net.ipv4.conf.all.route_localnet=1
```

Apply the settings:

```shell
sysctl -p
```

## UFW DNAT Rules

Place the new rules **before the `*filter` line** in `/etc/ufw/before.rules`.

```shell
# Fort forwarding
*nat
:PREROUTING ACCEPT [0:0]

# pg_db1
-A PREROUTING -p tcp -d 149.56.34.20 --dport 15432 -j DNAT --to-destination 127.0.0.1:15432
# pg_db2
-A PREROUTING -p tcp -d 149.56.34.20 --dport 25432 -j DNAT --to-destination 127.0.0.1:25432
# pg_db3
-A PREROUTING -p tcp -d 149.56.34.20 --dport 35432 -j DNAT --to-destination 127.0.0.1:35432
# pg_some_other_db
-A PREROUTING -p tcp -d 149.56.34.20 --dport 45432 -j DNAT --to-destination 127.0.0.1:45432

COMMIT

# Don't delete these required lines, otherwise there will be errors
*filter
... filter rules ...
```

## UFW Rules

The rules must be added in order: first allow, then reject.

```shell
ufw allow from 192.99.5.40 to any port 15432 proto tcp
ufw reject in proto tcp to any port 15432

ufw allow from 192.99.5.40 to any port 25432 proto tcp
ufw reject in proto tcp to any port 25432

ufw allow from 192.99.5.40 to any port 35432 proto tcp
ufw reject in proto tcp to any port 35432

ufw allow from 192.99.5.40 to any port 45432 proto tcp
ufw reject in proto tcp to any port 45432
```

If you need to open the port for more than one IP, it is better to delete the port rules and add them again, like this:

```shell
# First, allow access for the desired IPs
ufw allow from 192.99.5.40 to any port 25432 proto tcp
ufw allow from 191.252.178.229 to any port 25432 proto tcp
ufw allow from 149.56.34.21 to any port 25432 proto tcp

# then reject everything else.
ufw reject in proto tcp to any port 25432
```

## Database expose in Dokku

The databases are exposed only to localhost.

```shell
dokku postgres:expose pg_db1 127.0.0.1:15432
dokku postgres:expose pg_db2 127.0.0.1:25432
dokku postgres:expose pg_db3 127.0.0.1:35432
dokku postgres:expose pg_some_other_db 127.0.0.1:45432
```

Below, we can see that the ports are exposed only to the local interface (loopback), and the firewall handles receiving the request from the Metabase IP and forwarding it to the appropriate container port.

```shell
LISTEN 127.0.0.1:45432  users:(("docker-proxy",pid=3303404,fd=8))

CONTAINER ID       PORTS                       NAMES
0a33a0e47ec1       127.0.0.1:45432->5432/tcp   dokku.postgres.pg17_criobot.ambassador
```
