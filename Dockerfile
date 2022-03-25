FROM node:10-alpine

RUN apk update && apk add sqlite --no-cache \
  && rm -rf /var/cache/apk/* \
  && mkdir -p /home/node/app/node_modules \
  && chown -R node:node /home/node/app
  
WORKDIR /home/node/app

COPY package*.json ./

USER node

RUN npm install \
  && rm -rf /home/node/.npm

COPY --chown=node:node . .


CMD [ "npm", "start" ]
