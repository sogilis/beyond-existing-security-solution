
.PHONY: create-bess-net build run-db run down run-dev-vault
.DEFAULT_GOAL=run

check-def:
ifndef PG_ADMIN_PWD
	$(error you have to set PG_ADMIN_PWD as env var)
endif
ifndef VAULT_ROOT_TOKEN
	$(error you have to set VAULT_ROOT_TOKEN as env var)
endif


create-bess-net:
	docker network create bess || true

build:
	COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=1 docker-compose -f docker-compose.yml build

run-db: check-def
	COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=1 docker-compose -f docker-compose.yml up -d db

# run: run-dev-vault
run: check-def
	COMPOSE_DOCKER_CLI_BUILD=1 \
	DOCKER_BUILDKIT=1 \
	docker-compose up -d --build bess-go && docker ps

down:
	docker-compose down && docker ps
	# docker-compose down && docker volume rm $(shell docker volume ls | grep postgres-data | awk '{print $2}') && docker ps

cleanup:
	docker rm -f -v vault-dev pg-database bess-go
	docker volume rm beyond-existing-security-solution_data beyond-existing-security-solution_pg-data beyond-existing-security-solution_vault-data
	rm -rf ssl/*/*

create-root-ca:
# Create a token attached to a specific policy to ensure scope limitated access for handling the pki engine
	docker-compose exec vault-dev sh -c "vault policy write ca-admin /vault-policies/ca-admin.hcl"
	docker-compose exec -T vault-dev sh -c "vault token create -field token -policy='ca-admin'" > ./ssl/hash/ca-admin-token.hash
# Enabling the pki engine and settings important fields for the new root ca cert (using our new token)
	docker-compose exec vault-dev sh -c "vault secrets enable pki"
	docker-compose exec vault-dev sh -c "vault secrets tune -max-lease-ttl=87600h pki"
	docker-compose exec vault-dev sh -c "vault write pki/root/generate/internal common_name='local' issuer_name='rootca' ttl=87600h "
	docker-compose exec vault-dev sh -c "vault write pki/config/urls issuing_certificates='http://127.0.0.1:8200/v1/pki/ca' crl_distribution_points='http://127.0.0.1:8200/v1/pki/crl'"

create-sub-ca:
# Creating a new path inside the pki engine to handle an intermediate ca (for later cert generation)
	docker-compose exec vault-dev sh -c "vault secrets enable -path=pki_int pki"
	docker-compose exec vault-dev sh -c "vault secrets tune -max-lease-ttl=43800h pki_int"
# # Generating the intermediate ca cert
	docker-compose exec -T vault-dev sh -c "vault write -field=csr pki_int/intermediate/generate/internal common_name='exemple.local' issuer_name='rootca'" > ./ssl/csr/sub-ca.csr
# # Signing the intermediate CA cert using the root CA
	docker-compose exec -T vault-dev sh -c "vault write -format=json pki/root/sign-intermediate issuer_ref='rootca' csr=@/ssl/csr/sub-ca.csr format=pem_bundle ttl='43800h' " | jq -r '.data.certificate' > ./ssl/certs/sub-ca.pem
# # Importing the intermediate CA back
	docker-compose exec vault-dev sh -c "vault write pki_int/intermediate/set-signed certificate=@/ssl/certs/sub-ca.pem"

create-issuers-tokens:
	docker-compose exec -T vault-dev sh -c "vault write pki_int/roles/example-dot-local issuer_ref="$(vault read -field=default pki_int/config/issuers)" allowed_domains="*.example.local" allow_subdomains=true allow_glob_domains="true" max_ttl="720h""
	docker-compose exec -T vault-dev sh -c "vault policy write issuer /vault-policies/issuer.hcl"

	docker-compose exec -T vault-dev sh -c "vault write pki_int/issue/example-dot-local common_name='test-1.example.com' ttl='24h'"


	# docker-compose exec -T vault-dev sh -c "vault write auth/token/roles/issuers explicit_max_ttl='60m' ttl='30m' period='30m' renewable=true orphan=true allowed_policies='pki_int/'
	# docker-compose exec -T vault-dev sh -c "vault token create -role example-dot-local -policy

	# docker-compose exec vault-dev sh -c "vault write pki/roles/cert \
	#  allow_any_name=true allow_bare_domains=true \
	#  allow_subdomains=true allow_glob_domains=true \
	#  allow_localhost=true allow_ip_sans=true \
	#  ou="${COMPONENT}" organization="${DOMAIN}" \
	#  ttl="${CERT_TTL}" max_ttl="${CERT_MAX_TTL}"

gen-bess-cert:
# Creating a role for issuing new certificates from the intermediate CA
	docker-compose exec -T -e VAULT_TOKEN=`cat ssl/hash/intca-admin-token.hash` vault-dev sh -c "vault write pki_intermediate/roles/dot-local \
	 issuer_ref="$(vault read -field=default pki_intermediate/config/issuers)" \
	 allowed_domains='local' \
	 allow_subdomains=true \
	 max_ttl='720h'"
# Creating a token for our client
	docker-compose exec -T -e VAULT_TOKEN=`cat ssl/hash/intca-admin-token.hash` vault-dev sh -c "vault token create -field token -policy='intca-admin-token' " > ./ssl/hash/client-token.hash
# Creating a new certificate for our client
	docker-compose exec -T -e VAULT_TOKEN=`cat ssl/hash/client-token.hash` vault-dev sh -c "vault write pki_intermediate/issue/dot-local \
	 common_name='client.local' ttl='1h'"

vault-status:
	docker-compose exec vault-dev sh -c "vault status"

