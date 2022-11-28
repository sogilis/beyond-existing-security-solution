
.PHONY: create-bess-net build run-db run down run-dev-vault
.DEFAULT_GOAL=run

check-def:
ifndef PG_ADMIN_PWD
	$(error you have to set PG_ADMIN_PWD as env var)
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

# run-dev-vault: create-bess-net
# 	docker rm -f dev-vault
# 	docker run -d --network wiismile -p 8200:8200 -e 'VAULT_DEV_ROOT_TOKEN_ID=bess-vault-dev-root-token' -e 'VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200' --name dev-vault vault
# 	sleep 2
# 	(cd vault/root/cmd && go build && chmod +x cmd && BESS_VAULT_ROOT_TOKEN=bess-vault-dev-root-token BESS_VAULT_PORT=8200 ./cmd)
