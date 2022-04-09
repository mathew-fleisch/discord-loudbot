# DISCORD LOUDBOT

[![KinD Tests](https://github.com/mathew-fleisch/discord-loudbot/actions/workflows/pr-test-and-build.yaml/badge.svg)](https://github.com/mathew-fleisch/discord-loudbot/actions/workflows/pr-test-and-build.yaml)
[![Release Containers & Helm Chart](https://github.com/mathew-fleisch/discord-loudbot/actions/workflows/release.yaml/badge.svg)](https://github.com/mathew-fleisch/discord-loudbot/actions/workflows/release.yaml)
[Docker Hub](https://hub.docker.com/r/mathewfleisch/discord-loudbot/tags?page=1&ordering=last_updated)

Inspired by the slack bot: https://github.com/ceejbot/LOUDBOT

This bot uses sqlite to store yells and runs on discord instead of slack.

## Setup

First you will need a discord app and bot token to send messages. See this youtube playlist to learn how: https://www.youtube.com/playlist?list=PLRqwX-V7Uu6avBYxeBSwF48YhAnSn_sA4

Once you have a discord token, create a [.env file](sample.env) to point at your discord channel. Setting `LOUDBOT_CHANNEL` restricts loudbot to listening in a specific channel and `LOUDBOT_ID` prevents loudbot from triggering itself.

```bash
PATH_TO_SQLITE_DB=/home/node/app/loudbot.sqlite
DISCORD_TOKEN=
LOUDBOT_CHANNEL=
LOUDBOT_ID=
```

### Run node js locally

Requirements

 - nodejs
 - sqlite3

```bash
# Create a sqlite db placeholder
touch loudbot.sqlite

# Copy sample .env file
cp sample.env .env
# Set unique values in .env file

# Download dependencies
npm install

# Run bot
node index.js
```

### Build/Run Docker

Requirements

- docker

```bash
# Clone repository
git clone https://github.com/mathew-fleisch/discord-loudbot.git && cd discord-loudbot

# Build container
make docker-build

# Create a sqlite db placeholder
touch loudbot.sqlite

# Copy sample .env file
cp sample.env .env
# Set unique values in .env file

# Run the docker container and mount the local .env and .sqlite files inside the container
make docker-run

# Or upstream by setting the registry-path and container tag
TARGET_REGISTRY_REPOSITORY=mathewfleisch/discord-loudbot \
  TARGET_TAG=v1.0.3 \
  make docker-run
```

### Run as Kubernetes deployment in KinD

Requirements

- docker
- KinD

The sqlite db and .env files are mounted as volumes into the container and can be updated on the host machine dynamically and allow for persistence if/when the pod dies. This repository includes a helm chart to install this bot in a kubernetes cluster. After creating the `loudbot.sqlite` and `.env` files locally, create the following yaml file to mount these configs into a kind cluster (update `hostPath` to directory path of your local config files and save this file as `kind-config.yaml`):

```yaml
apiVersion: kind.x-k8s.io/v1alpha4
kind: Cluster
nodes:
  - role: control-plane
    extraMounts:
      - hostPath: /local/path/to/discord-loudbot-configs
        containerPath: /loudbot-configs
```

Next, run the [makefile target](Makefile) to start a kind cluster, and build/load the source locally in a docker container:

```bash
# These environment variables can be overridden 
# REPONAME?=discord-loudbot
# TARGET_REGISTRY_REPOSITORY?=$(REPONAME)
# TARGET_TAG?=local
# LOCAL_KIND_CONFIG?=kind-config.yaml
make kind-setup
```

With a running kind cluster, use the [makefile target](Makefile) to run that container as a helm deployment:

```bash
# These environment variables can be overridden 
# REPONAME?=discord-loudbot
# NAMESPACE?=bots
# TARGET_REGISTRY_REPOSITORY?=$(REPONAME)
# TARGET_TAG?=local
make helm-install

# Or upstream by setting the registry-path and container tag
TARGET_REGISTRY_REPOSITORY=mathewfleisch/discord-loudbot \ 
  TARGET_TAG=v1.0.3 \
  make helm-install
```

### Install in Existing Kubernetes Cluster

Loudbot must be tied to a single node in a kubernetes cluster for persistence of the sqlite db and .env files. Create the .env and sqlite on a node of your cluster and take note of path for environment variables (ENV_VARS_PATH, SQLITE_PATH, LOUDBOT_HOSTNAME).

```bash
# Add the helm repo to your cluster
helm repo add discord-loudbot https://mathew-fleisch.github.io/discord-loudbot

# Define variables that will be used as overrides in helm install command
export RELEASENAME=loudbot
export NAMESPACE=bots
export TARGET_REGISTRY_REPOSITORY=mathewfleisch/discord-loudbot
export TARGET_TAG=v1.0.3
export ENV_VARS_PATH=/path/to/.env
export SQLITE_PATH=/path/to/loudbot.sqlite
export LOUDBOT_HOSTNAME=NODENAME

helm upgrade ${RELEASENAME} discord-loudbot \
  --install \
  --create-namespace \
  --namespace ${NAMESPACE} \
  --set image.repository=${TARGET_REGISTRY_REPOSITORY} \
  --set image.tag=${TARGET_TAG} \
  --set envvarsPath=${ENV_VARS_PATH} \
  --set sqlitePath=${SQLITE_PATH} \
  --set nodeName=${LOUDBOT_HOSTNAME} \
  --debug \
  --wait
```
