# Beyond Existing Security Solution (BESS) workshop

## Prerequisites
* Docker (if you can fetch the images before the D day it's cool)
* Vault client (see the [hashiCorp Vault dowload page](https://developer.hashicorp.com/vault/downloads))
* Code/Text editor of your choice

## Manage you env :

```
PG_APP_DB='bess' PG_ADMIN_PWD='correcthorsestapplebattery' VAULT_ROOT_TOKEN='qt5%Fm2wk@Eg3zGUP9bH*2^%B#zuKP' make run
```

or

```
cp .env.sample .env
set -a; source .env; set +a
make run
```

## Go service API
Test API with root URL:
```
curl http://localhost:8080/
```

Request Credentials
```
curl http://localhost:8080/creds
```

### Reload bess-go (if you modify it)
```
docker-compose up
```

## Interract with vault, via the vault client
It's time to test your vault CLIent now:

```
curl http://localhost:8200/v1/sys/health
vault status
```

## Create the admin user of this workshop
Note: you could use the vault root token to perform administration tasks, but .... Never do that !!! It's a really bad habit. Instead of this define an administrator policy that fits the exact rights you need to administrate your vault service and use the root token in the only purpose of setting this new credentials set.

Retrieve root token form logs (only available in dev mode):
```
docker logs vault-dev
```

export root token as vault client token:
```
export VAULT_TOKEN=e6fcd968-8858-11ed-823b-23b05637c622
```

let use the admin policy defined within the [./policies/bess-admin.hcl](./policies/bess-admin.hcl) file:

Create the policy within vault (use root token)
```
vault policy write bess-admin-policy ./policies/bess-admin.hcl
```

Generate a token with this policy :

```
vault token create -field token -policy=bess-admin-policy
```

Use this credentials for administrative tasks (such as setting secret engines)
```
export VAULT_TOKEN=<bess-admin-token>
```

### Setup Database usecase
#### Create Postgres role for vault
```
docker exec -i pg-database psql postgresql://admin:${PG_ADMIN_PWD}@localhost:5432/bess -c "CREATE ROLE \"ro\" NOINHERIT;"
```

Give that role super power !

```
docker exec -i pg-database psql postgresql://admin:${PG_ADMIN_PWD}@localhost:5432/bess -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"ro\";"
```

#### Configure vault database secret engine
```
vault secrets enable database
```

```
vault write database/config/bess-pg \
     plugin_name=postgresql-database-plugin \
     connection_url="postgresql://{{username}}:{{password}}@db/bess?sslmode=disable" \
     allowed_roles=readonly \
     username="admin" \
     password="${PG_ADMIN_PWD}"
```

#### Create a token for readonly role

```
tee readonly.sql <<EOF
CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}' INHERIT;
GRANT ro TO "{{name}}";
EOF
```

```
vault write database/roles/readonly \
      db_name=bess-pg \
      creation_statements=@readonly.sql \
      default_ttl=1h \
      max_ttl=24h
```

```
vault policy write bess-go-policy ./policies/bess-go.hcl
```

```
vault token create -field token -policy=bess-go-policy
```

:warning: Save the returned token, you'll need it later.

### Get credential manually
Set service token
```
export VAULT_TOKEN=hvs.CAESIFKFrOvHMFKBd-l88_JX7RZgQXvZ0RfUkVlcxrtkB8srGh4KHGh2cy5zOERNcnM0bmhsakdzNWdlcWpPUlRNaDg
```

Read credentials

```
vault read database/creds/readonly
```
