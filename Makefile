
REPONAME?=discord-loudbot
RELEASENAME?=$(REPONAME)
NAMESPACE?=bots
# Docker regitry: mathewfleisch/discord-loudbot
TARGET_REGISTRY_REPOSITORY?=$(REPONAME)
TARGET_TAG?=local
LOCAL_KIND_CONFIG?=kind-config.yaml
LOCAL_ENV_VARS?=$(PWD)/.env 
LOCAL_SQLITE_PATH?=$(PWD)/loudbot.sqlite

##@ Docker stuff

.PHONY: docker-build
docker-build: ## build the source code in a docker container
	docker build -t $(TARGET_REGISTRY_REPOSITORY):$(TARGET_TAG) .

.PHONY: docker-lint
docker-lint: ## run loudbot docker container through dockle tool
	dockle --version
	dockle --exit-code 1 $(TARGET_REGISTRY_REPOSITORY):$(TARGET_TAG)

.PHONY: docker-run
docker-run: ## run loudbot in a docker container
	docker run --rm -it \
		-v ${PWD}/.env:/home/node/app/.env \
		-v ${PWD}/loudbot.sqlite:/home/node/app/loudbot.sqlite \
		$(TARGET_REGISTRY_REPOSITORY):$(TARGET_TAG)

.PHONY: docker-run-exec
docker-run-exec: ## shell in a loudbot docker container
	docker run --rm -it \
		-v ${PWD}/.env:/home/node/app/.env \
		-v ${PWD}/loudbot.sqlite:/home/node/app/loudbot.sqlite \
		--entrypoint /bin/sh \
		$(TARGET_REGISTRY_REPOSITORY):$(TARGET_TAG)

##@ Kubernetes in Docker (KinD) stuff

.PHONY: kind-setup
kind-setup: docker-build ## create a KinD cluster with local config-yaml
	yq '.nodes[0].extraMounts[0].hostPath="$(PWD)"' sample-kind-config.yaml > $(LOCAL_KIND_CONFIG)
	kind create cluster --config $(LOCAL_KIND_CONFIG) -v 5 || true
	make kind-load

.PHONY: kind-load
kind-load: ## load a locally built docker container into a running KinD cluster
	kind load docker-image $(TARGET_REGISTRY_REPOSITORY):$(TARGET_TAG)

.PHONY: kind-test
kind-test: ## display last log line of running loudbot to prove it is connected
	kubectl -n $(NAMESPACE) logs --tail 1 $(shell make get-pods)

.PHONY: kind-cleanup
kind-cleanup: ## delete an existin KinD cluster
	@make helm-delete
	kind delete cluster

##@ Kubernetes stuff

.PHONY: get-pods
get-pods: ## get pod name from running loudbot k8s pod
	@kubectl get pods \
		--namespace $(NAMESPACE) \
		-l "app.kubernetes.io/name=$(RELEASENAME),app.kubernetes.io/instance=$(RELEASENAME)" \
		-o jsonpath="{.items[0].metadata.name}"

.PHONY: get-logs
get-logs: ## get last 10 lines of logs from running loudbot k8s pod
	kubectl -n $(NAMESPACE) logs --tail 10 \
		$(shell make get-pods) \
		| sed -e 's/\\n/\n/g'

.PHONY: tail-logs
tail-logs: ## tail and follow the logs of a running loudbot k8s pod
	kubectl -n $(NAMESPACE) logs -f \
		$(shell make get-pods) \
		| sed -e 's/\\n/\n/g'


##@ Helm stuff

.PHONY: helm-lint
helm-lint: ## lint the helm chart for syntax issues
	helm lint charts/$(REPONAME)

.PHONY: helm-install
helm-install: ## install loudbot into an existing k8s cluster
	helm upgrade $(RELEASENAME) charts/$(REPONAME) \
		--install \
		--create-namespace \
		--namespace $(NAMESPACE) \
		--set image.repository=$(TARGET_REGISTRY_REPOSITORY) \
		--set image.tag=$(TARGET_TAG) \
		--set envvarsPath=$(LOCAL_ENV_VARS) \
		--set sqlitePath=$(LOCAL_SQLITE_PATH) \
		--debug \
		--wait

.PHONY: helm-delete
helm-delete: ## delete an existing loudbot helm chart
	helm --namespace $(NAMESPACE) delete $(RELEASENAME) || true

##@ SQLite stuff

.PHONY: sqlite-seed
sqlite-seed: ## create an .sqlite db, create a yells table and seed it with WORLD
	@touch loudbot.sqlite
	@sqlite3 ./loudbot.sqlite "CREATE TABLE IF NOT EXISTS loudbot (yells TEXT);"
	@sqlite3 ./loudbot.sqlite "INSERT INTO loudbot (yells) VALUES ('WORLD');"

.PHONY: sqlite-count
sqlite-count: ## get the number of rows in the sqlite db
	sqlite3 ./loudbot.sqlite "SELECT count(*) FROM loudbot;"

.PHONY: sqlite-random
sqlite-random: ## display a random row of the sqlite db
	@sqlite3 ./loudbot.sqlite "SELECT * FROM loudbot ORDER BY RANDOM() LIMIT 1;"

.PHONY: sqlite-dump
sqlite-dump: ## display all rows of the sqlite db
	sqlite3 ./loudbot.sqlite "SELECT * FROM loudbot;"

##@ Miscellanous stuff

.PHONY: lint-actions
lint-actions: ## run .gihtub/workflows/*.yaml|yml through action-valdator tool
	find .github/workflows -type f \( -iname \*.yaml -o -iname \*.yml \) \
		| xargs -I action_yaml action-validator --verbose action_yaml

.PHONY: version
version: ## get the currenet helm chart version
	@yq e '.version' charts/discord-loudbot/Chart.yaml

.PHONY: help
help: ## show this dialog
	@echo '.____    ________   ____ ___________ __________ ___________________'
	@echo '|    |   \_____  \ |    |   \______ \\______   \\_____  \__    ___/'
	@echo '|    |    /   |   \|    |   /|    |  \|    |  _/ /   |   \|    |   '
	@echo '|    |___/    |    \    |  / |    `   \    |   \/    |    \    |   '
	@echo '|_______ \_______  /______/ /_______  /______  /\_______  /____|   '
	@echo '        \/       \/                 \/       \/         \/         '
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
