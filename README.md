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
export VAULT_ROOT_TOKEN="qt5%Fm2wk@Eg3zGUP9bH*2^%B#zuKP"
export VAULT_ADDR=http://localhost:8200/
make run
```

It's time to test your vault CLIent now:

```
curl http://localhost:8200/v1/sys/health
vault status
```

Test bess-go available
```
curl http://localhost:8080/
```
