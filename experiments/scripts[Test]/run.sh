#!/bin/bash

# Build app container
docker build -t mt5 -f ./Dockerfile.mt5.pywindows .

docker network create mt5-net

docker volume create mt5-data

docker run --detach --restart=always --volume=mt5-data:/data --net=mt5-net --name=mt5-app mt5

cd caddy || exit

# Build web proxy container
docker build -t mt5-caddy .

HASH_PASS=$(docker run --rm -it mt5-caddy caddy hash-password -plaintext 'mypass')
USER="user"

docker run --detach --restart=always --volume=mt5-data:/data --net=mt5-net --name=mt5-web --env=APP_USERNAME="${USER}" --env=APP_PASSWORD_HASH="${HASH_PASS}" --publish=8080:8080 mt5-caddy