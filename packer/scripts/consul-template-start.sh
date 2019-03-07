#!/bin/bash
set -x 

#Login to vault and export the token
VAULT_TOKEN=`vault login -token-only -method=userpass username=vault password=vault`
export VAULT_TOKEN

#Start consul template
sudo kill -9 `pidof consul-template`
nohup consul-template -template "/tmp/config.ini.ctmpl:/var/lib/docker/volumes/consul-template/_data/config.ini" >/dev/null 2>&1

#Start Consul Proxy for the Profit service
nohup consul connect proxy -service web -upstream profitapp_connect:8080 > /dev/null 2>&1

#Build Container and Run it
docker rm -f c1
sudo docker build -t frontend:latest .;sudo docker run --network="host"  --rm -v consul-template:/usr/src/app/config -e VAULT_TOKEN=$VAULT_TOKEN -p 5000:5000 --name spork-frontend frontend:latest
