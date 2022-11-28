# beyond-existing-security-solution

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

test vault available from your CLI:

```
curl http://localhost:8200/v1/sys/health
VAULT_ADDR=http://localhost:8200/ vault status
```

Test bess-go available
```
curl http://localhost:8080/
```
