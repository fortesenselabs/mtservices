#!/bin/bash

# Build app container
docker build -t thunderbird .

docker network create thunderbird-net

docker volume create thunderbird-data

docker run --detach --restart=always --volume=thunderbird-data:/data --net=thunderbird-net --name=thunderbird-app thunderbird

cd caddy || exit

# Build web proxy container
docker build -t thunderbird-caddy .

HASH_PASS=$(docker run --rm -it thunderbird-caddy caddy hash-password -plaintext 'mypass')
USER="user"

docker run --detach --restart=always --volume=thunderbird-data:/data --net=thunderbird-net --name=thunderbird-web --env=APP_USERNAME="${USER}" --env=APP_PASSWORD_HASH="${HASH_PASS}" --publish=8080:8080 thunderbird-caddy