#!/bin/bash

# docker stop -t mt5

# docker stop -t mt5-caddy

docker network remove mt5-net

docker volume remove mt5-data

docker system prune