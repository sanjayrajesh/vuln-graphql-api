FROM node:14.12.0-buster

ARG SERVER_PORT=3000
ENV SERVER_PORT=${SERVER_PORT}
EXPOSE ${SERVER_PORT}:${SERVER_PORT}

RUN apt update && apt upgrade -y
RUN useradd -m app
COPY --chown=app ./app /graphql
COPY ./docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
WORKDIR /graphql

RUN sed -i'' -e "s/%SERVER_PORT%/${SERVER_PORT}/g" /graphql/app.ts

# Install vulnerable NPM packages and other dependencies
RUN npm install lodash@4.17.11 marked@0.3.6 jquery@3.4.0 minimist@1.2.0 request@2.88.0 axios@0.21.1 \
    sqlite3 express-fileupload@1.1.9 \
    adm-zip@0.4.7 argon2 crypto-js@3.1.9-1 moment@2.19.3 --ignore-scripts

RUN npm install
RUN npm run tsc

# Needed for sequelize to work now
RUN npm install -g node-pre-gyp \
    && node-pre-gyp rebuild -C ./node_modules/argon2

RUN npm run sequelize db:migrate
RUN npm run sequelize db:seed:all
RUN chown app /graphql

USER app
ENTRYPOINT [ "docker-entrypoint.sh" ]
