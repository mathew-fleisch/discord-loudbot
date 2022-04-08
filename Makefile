
REPONAME?=discord-loudbot
RELEASENAME?=$(REPONAME)
NAMESPACE?=bots
# Docker regitry: mathewfleisch/discord-loudbot
TARGET_REGISTRY_REPOSITORY?=$(REPONAME)
TARGET_TAG?=local
LOCAL_KIND_CONFIG?=kind-config.yaml
LOCAL_ENV_VARS?=$(PWD)/.env 
LOCAL_SQLITE_PATH?=$(PWD)/loudbot.sqlite

.PHONY: help
help:
	@echo '.____    ________   ____ ___________ __________ ___________________'
	@echo '|    |   \_____  \ |    |   \______ \\______   \\_____  \__    ___/'
	@echo '|    |    /   |   \|    |   /|    |  \|    |  _/ /   |   \|    |   '
	@echo '|    |___/    |    \    |  / |    `   \    |   \/    |    \    |   '
	@echo '|_______ \_______  /______/ /_______  /______  /\_______  /____|   '
	@echo '        \/       \/                 \/       \/         \/         '
	@echo " MAKEFILE TARGETS"
	@echo " <=> make docker-build <----> build the source code in a docker container"
	@echo " <=> make docker-lint <-----> run loudbot docker container through dockle tool"
	@echo " <=> make docker-run <------> run loudbot in a docker container"
	@echo " <=> make docker-run-exec <-> shell in a loudbot docker container"
	@echo " <=> make get-logs <--------> get last 10 lines of logs from running loudbot k8s pod"
	@echo " <=> make get-pods <--------> get pod name from running loudbot k8s pod"
	@echo " <=> make helm-delete <-----> delete an existing loudbot helm chart"
	@echo " <=> make helm-install <----> install loudbot into an existing k8s cluster"
	@echo " <=> make helm-lint <-------> lint the helm chart for syntax issues"
	@echo " <=> make help <------------> this dialog"
	@echo " <=> make kind-cleanup <----> delete an existin KinD cluster"
	@echo " <=> make kind-load <-------> load a locally built docker container into a running KinD cluster"
	@echo " <=> make kind-setup <------> create a KinD cluster with local config-yaml"
	@echo " <=> make kind-test <-------> "
	@echo " <=> make lint-actions <----> run .gihtub/workflows/*.yaml|yml through action-valdator tool"
	@echo " <=> make sqlite-count <----> get the number of rows in the sqlite db"
	@echo " <=> make sqlite-dump <-----> display all rows of the sqlite db"
	@echo " <=> make sqlite-random <---> display a random row of the sqlite db"
	@echo " <=> make sqlite-seed <-----> create an .sqlite db, create a yells table and seed it with WORLD"
	@echo " <=> make tail-logs <-------> tail and follow the logs of a running loudbot k8s pod"
	@echo " <=> make version <---------> get the currenet helm chart version"

.PHONY: lint-actions
lint-actions:
	find .github/workflows -type f \( -iname \*.yaml -o -iname \*.yml \) \
		| xargs -I action_yaml action-validator --verbose action_yaml

.PHONY: docker-build
docker-build:
	docker build -t $(TARGET_REGISTRY_REPOSITORY):$(TARGET_TAG) .

.PHONY: docker-lint
docker-lint:
	dockle --version
	dockle --exit-code 1 $(TARGET_REGISTRY_REPOSITORY):$(TARGET_TAG)

.PHONY: docker-run
docker-run:
	docker run --rm -it \
		-v ${PWD}/.env:/home/node/app/.env \
		-v ${PWD}/loudbot.sqlite:/home/node/app/loudbot.sqlite \
		$(TARGET_REGISTRY_REPOSITORY):$(TARGET_TAG)

.PHONY: docker-run-exec
docker-run-exec:
	docker run --rm -it \
		-v ${PWD}/.env:/home/node/app/.env \
		-v ${PWD}/loudbot.sqlite:/home/node/app/loudbot.sqlite \
		--entrypoint /bin/sh \
		$(TARGET_REGISTRY_REPOSITORY):$(TARGET_TAG)

.PHONY: kind-setup
kind-setup: docker-build
	yq '.nodes[0].extraMounts[0].hostPath="$(PWD)"' sample-kind-config.yaml > $(LOCAL_KIND_CONFIG)
	kind create cluster --config $(LOCAL_KIND_CONFIG) || true
	make kind-load

.PHONY: kind-load
kind-load:
	kind load docker-image $(TARGET_REGISTRY_REPOSITORY):$(TARGET_TAG)

.PHONY: kind-test
kind-test:
	kubectl -n $(NAMESPACE) logs --tail 1 $(shell make get-pods)

.PHONY: kind-cleanup
kind-cleanup:
	@make helm-delete
	kind delete cluster

.PHONY: get-pods
get-pods:
	@kubectl get pods \
		--namespace $(NAMESPACE) \
		-l "app.kubernetes.io/name=$(RELEASENAME),app.kubernetes.io/instance=$(RELEASENAME)" \
		-o jsonpath="{.items[0].metadata.name}"

.PHONY: get-logs
get-logs:
	kubectl -n $(NAMESPACE) logs --tail 10 \
		$(shell make get-pods) \
		| sed -e 's/\\n/\n/g'

.PHONY: tail-logs
tail-logs:
	kubectl -n $(NAMESPACE) logs -f \
		$(shell make get-pods) \
		| sed -e 's/\\n/\n/g'

.PHONY: helm-lint
helm-lint:
	helm lint charts/$(REPONAME)

.PHONY: helm-install
helm-install:
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
helm-delete:
	helm --namespace $(NAMESPACE) delete $(RELEASENAME) || true



.PHONY: sqlite-seed
sqlite-seed:
	@touch loudbot.sqlite
	@sqlite3 ./loudbot.sqlite "CREATE TABLE IF NOT EXISTS loudbot (yells TEXT);"
	@sqlite3 ./loudbot.sqlite "INSERT INTO loudbot (yells) VALUES ('WORLD');"

.PHONY: sqlite-count
sqlite-count:
	sqlite3 ./loudbot.sqlite "SELECT count(*) FROM loudbot;"

.PHONY: sqlite-random
sqlite-random:
	@sqlite3 ./loudbot.sqlite "SELECT * FROM loudbot ORDER BY RANDOM() LIMIT 1;"

.PHONY: sqlite-dump
sqlite-dump:
	sqlite3 ./loudbot.sqlite "SELECT * FROM loudbot;"

.PHONY: version
version:
	@yq e '.version' charts/discord-loudbot/Chart.yaml
