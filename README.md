# Beyond Existing Security Solution (BESS) workshop

## Prerequisites
* Docker (if you can fetch the images before the D day it's cool)
* Vault client (see the [hashiCorp Vault dowload page](https://developer.hashicorp.com/vault/downloads))
* Code/Text editor of your choice

## Manage you env :

```
PG_ADMIN_PWD="correcthorsestapplebattery" VAULT_ROOT_TOKEN="qt5%Fm2wk@Eg3zGUP9bH*2^%B#zuKP" make run
```

or

```
export PG_ADMIN_PWD="correcthorsestapplebattery"
export VAULT_TOKEN="qt5%Fm2wk@Eg3zGUP9bH*2^%B#zuKP"
export VAULT_ADDR=http://localhost:8200/
make run
```

## Interract with vault, via the vault client
It's time to test your vault CLIent now:

```
curl http://localhost:8200/v1/sys/health
vault status
```

### Create the admin user of this workshop
Note: you could use the vault root token to perform administration tasks, but .... Never tdo that !!! It's a really bad habit. Instead of this define an administrator policy that fits the exact rights you need to administrate your vault service and use the root token in the only purpose of setting this new credentials set.

let do this, using the admin policy defined in within the [./policies/bess-admin.hcl](./policies/bess-admin.hcl) file:

Create the policy within vault
```
VAULT_TOKEN=<Root_Token> vault policy write bess-admin-policy ./policies/bess-admin.hcl
```

Generate a token with this policy :

```
VAULT_TOKEN=<Root_Token> vault token create -field token -policy=bess-admin-policy
```

Use this credentials for administrative tasks (such as setting secret engines)
```
export VAULT_TOKEN=<bess-admin-token>
```
## Interract with go service:
Test bess-go available

```
curl http://localhost:8080/
```

### Reload bess-go (if you modify it)
```
docker-compose up
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

```
vault secrets enable database
```

```
vault write database/config/postgresql \
     plugin_name=postgresql-database-plugin \
     connection_url="postgresql://{{username}}:{{password}}@$POSTGRES_URL/bess?sslmode=disable" \
     allowed_roles=readonly \
     username="admin" \
     password="${PG_ADMIN_PWD}"
```
