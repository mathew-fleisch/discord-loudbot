# DISCORD LOUDBOT 

Inspired by the slack bot: https://github.com/ceejbot/LOUDBOT

This bot uses sqlite to store yells and runs on discord instead of slack.


## Setup

First you will need a discord app and bot token to send messages. See this youtube playlist to learn how: https://www.youtube.com/playlist?list=PLRqwX-V7Uu6avBYxeBSwF48YhAnSn_sA4


***Run node js locally***

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

***build docker***

Requirements

 - docker


```bash
# Clone repository
git clone https://github.com/mathew-fleisch/discord-loudbot.git && cd discord-loudbot

# Build container
docker build -t discord-loudbot .

# Create sqlite file and .env like in local setup

# Run the docker container and mount the local .env and .sqlite files inside the container
docker run --rm -it \
  -v ${PWD}/.env:/home/node/app/.env \
  -v ${PWD}/loudbot.sqlite:/home/node/app/loudbot.sqlite \
  discord-loudbot:latest
```

***Run Docker (from docker hub)***

Requirements

 - docker


```bash
# Create local directory to hold secrets and db 
mkdir -p discord-loudbot && cd discord-loudbot

# Create sqlite file and .env like in local setup

# Run the docker container and mount the local .env and .sqlite files inside the container
docker run --rm -it \
  -v ${PWD}/.env:/home/node/app/.env \
  -v ${PWD}/loudbot.sqlite:/home/node/app/loudbot.sqlite \
  mathewfleisch/discord-loudbot:latest
```


***Run as kubernetes deployment in minikube***


The sqlite db and .env files are mounted as volumes into the container and can be updated on the host machine dynamically and allow for persistence if/when the pod dies. This deployment yaml can act as a template:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: discordloudbot
  name: discordloudbot
  namespace: loudbot
spec:
  progressDeadlineSeconds: 600
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: discordloudbot
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: discordloudbot
    spec:
      containers:
      - image: mathewfleisch/discord-loudbot:v1.0.1
        imagePullPolicy: IfNotPresent
        name: loudbot
        resources: {}
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        workingDir: /home/node/app
        volumeMounts:
        - name: loudbotsqlite
          mountPath: /home/node/app/loudbot.sqlite
        - name: env-vars
          mountPath: /home/node/app/.env
      volumes:
        - name: loudbotsqlite
          hostPath:
            path: /tmp/loudbot/loudbot.sqlite
        - name: env-vars
          hostPath:
            path: /tmp/loudbot/.env
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      terminationGracePeriodSeconds: 30
```

```bash
# Create local directory to hold secrets and db 
mkdir -p discord-loudbot && cd discord-loudbot

# Create sqlite file and .env like in local setup

# Mount the files locally
screen minikube mount ${PWD}:/tmp/loudbot

# Detach screen from terminal: ctrl+a+d

# Apply deployment to loudbot namespace
kubectl create namespace loudbot
kubectl -n loudbot apply -f loudbot-deployment.yaml
```


