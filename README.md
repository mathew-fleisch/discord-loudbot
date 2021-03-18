# DISCORD LOUDBOT 

Inspired by the slack bot: https://github.com/ceejbot/LOUDBOT

This bot uses sqlite to store yells and runs on discord instead of slack.

## Requirements

 - nodejs
 - sqlite3

## Setup

First you will need a discord app and bot token to send messages. See this youtube playlist to learn how: https://www.youtube.com/playlist?list=PLRqwX-V7Uu6avBYxeBSwF48YhAnSn_sA4

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
