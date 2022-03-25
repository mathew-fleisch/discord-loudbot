# DISCORD LOUDBOT 

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

### build docker

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
TARGET_REGISTRY_REPOSITORY=mathewfleisch/discord-loudbot TARGET_TAG=v1.0.1 make docker-run
```


***Run as kubernetes deployment in KinD***

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
TARGET_REGISTRY_REPOSITORY=mathewfleisch/discord-loudbot TARGET_TAG=v1.0.1 make docker-run
```

