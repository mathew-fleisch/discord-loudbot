# DISCORD LOUDBOT 

Inspired by the slack bot: https://github.com/ceejbot/LOUDBOT

This bot uses sqlite to store yells and runs on discord instead of slack.


## Setup

First you will need a discord app and bot token to send messages. See this youtube playlist to learn how: https://www.youtube.com/playlist?list=PLRqwX-V7Uu6avBYxeBSwF48YhAnSn_sA4


***Run node js locally***

Requirements

 - nodejs
 - sqlite3

```
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


```
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


