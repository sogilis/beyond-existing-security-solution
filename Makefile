
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

init-pki: create-root-ca create-sub-ca prepare-issuers

create-root-ca:
# Create a token attached to a specific policy to ensure scope limitated access for handling the pki engine
	docker-compose exec vault-dev sh -c "vault policy write ca-admin /vault-policies/ca-admin.hcl"
	docker-compose exec -T vault-dev sh -c "vault token create -field token -policy='ca-admin'" > ./ssl/keys/ca-admin-token.key
# Enabling the pki engine and settings important fields for the new root ca cert (using our new token)
	docker-compose exec vault-dev sh -c "vault secrets enable pki"
	docker-compose exec vault-dev sh -c "vault secrets tune -max-lease-ttl=87600h pki"
	docker-compose exec -T vault-dev sh -c "vault write -format=json pki/root/generate/internal common_name='local' issuer_name='rootca' ttl=87600h format=pem_bundle" | jq -r '.data.certificate' > ./ssl/certs/ca.pem
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
	docker-compose exec vault-dev sh -c "vault write pki_int/config/urls issuing_certificates='http://127.0.0.1:8200/v1/pki_int/ca' crl_distribution_points='http://127.0.0.1:8200/v1/pki_int/crl'"

prepare-issuers:
# Creating a role and a policy for generating token allowed to issue certificates with CN as domsub.exemple.local
	docker-compose exec -T vault-dev sh -c 'vault write pki_int/roles/example-dot-local issuer_ref=$(vault read -field=default pki_int/config/issuers) allowed_domains="*.example.local" allow_subdomains=true allow_glob_domains=true max_ttl="720h"'
	docker-compose exec -T vault-dev sh -c "vault policy write issuer /vault-policies/issuer.hcl"
	docker-compose exec vault-dev sh -c "vault write pki_int/roles/example-dot-local allow_any_name=true allow_bare_domains=true allow_subdomains=true allow_glob_domains=true allow_localhost=true allow_ip_sans=true"
# Create a token associated with the issuer role
	docker-compose exec -T vault-dev sh -c "vault token create -field token -policy='issuer'" > ./ssl/keys/issuer-token.key
# Issue a certificate using our newly created token (for testing access)
	docker-compose exec -T -e VAULT_TOKEN=`cat ssl/keys/issuer-token.key` vault-dev sh -c "vault write pki_int/issue/example-dot-local common_name='test-1.example.com' ttl='24h'"

vault-status:
	docker-compose exec vault-dev sh -c "vault status"

