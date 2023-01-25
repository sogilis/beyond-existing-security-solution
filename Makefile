
.PHONY: create-bess-net build run-db run down run-dev-vault
.DEFAULT_GOAL=run

check-def:
ifndef PG_ADMIN_PWD
	$(error you have to set PG_ADMIN_PWD as env var)
endif
ifndef VAULT_ROOT_TOKEN
	$(error you have to set VAULT_ROOT_TOKEN as env var)
endif

# This target is creating a new Docker network named 'bess' by running the 'docker network create' command. If the network already exists, the command will return an error, but the '|| true' at the end of the command will make sure that the Makefile continues to run without stopping.
create-bess-net:
	docker network create bess || true

# This command will build the images for all the services defined in the compose file, but it will not start the containers.
build:
	COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=1 docker-compose -f docker-compose.yml build

# This target is starting the container for the database service by running the 'docker-compose up -d' command with the 'db' service specified. It also sets the environment variables 'COMPOSE_DOCKER_CLI_BUILD' and 'DOCKER_BUILDKIT' to '1' and specifies the compose file to use with the '-f' option. Before running this target, it is checking if the environment variables 'PG_ADMIN_PWD' and 'VAULT_ROOT_TOKEN' are defined using the 'check-def' target
run-db: check-def
	COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=1 docker-compose -f docker-compose.yml up -d db

# run: run-dev-vault
run: check-def
	COMPOSE_DOCKER_CLI_BUILD=1 \
	DOCKER_BUILDKIT=1 \
	docker-compose up -d --build bess-go && docker ps
	docker ps

# This target is stopping and removing all the containers and networks defined in the compose file by running the 'docker-compose down' command. It will also remove the volumes associated with those containers, but it will not remove the images.
down:
	docker-compose down && docker ps

# This target can be useful when you need to clean up resources that were created during testing or development and start fresh.
cleanup:
	docker stop vault-dev pg-database bess-go; \
	docker rm -f -v vault-dev pg-database bess-go; \
	docker volume rm beyond-existing-security-solution_data beyond-existing-security-solution_pg-data beyond-existing-security-solution_vault-data; \
	rm -rf ssl/*/* ; \
	rm -rf vault.d/tls-listener.hcl

init-pki: start-vault create-root-ca create-sub-ca prepare-issuers vault-status

start-vault:
	docker-compose up -d vault-dev
	sleep 60

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
#	docker-compose exec -T -e VAULT_TOKEN=`cat ssl/keys/issuer-token.key` vault-dev sh -c "vault write pki_int/issue/example-dot-local common_name='test-1.example.com' ttl='24h'"

vault-ssl-activation:
	docker-compose exec -T -e VAULT_TOKEN=`cat ssl/keys/issuer-token.key` vault-dev sh -c "vault write -format=json pki_int/issue/example-dot-local common_name='vault-dev' format=pem_bundle ttl='21900h'" > ./ssl/certs/vault-dev.json
	cat ./ssl/certs/vault-dev.json | jq -r '.data.private_key' > ./ssl/keys/vault-dev.key
	# cat ./ssl/certs/vault-dev.json | jq -r '.data.ca_chain[0]' > ./ssl/certs/vault-dev.pem
	# cat ./ssl/certs/vault-dev.json | jq -r '.data.ca_chain[1]' >> ./ssl/certs/vault-dev.pem
	cat ./ssl/certs/vault-dev.json | jq -r '.data.certificate' >> ./ssl/certs/vault-dev.pem

vault-status:
	docker-compose exec vault-dev sh -c "vault status"
	docker-compose exec vault-dev sh -c "vault policy list"
	for policy in `docker-compose exec -T vault-dev sh -c "vault policy list"`;do  docker-compose exec vault-dev sh -c "vault policy read ${policy}" ; done
