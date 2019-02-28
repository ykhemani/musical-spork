#!/bin/bash
set -x 

#Login to vault and export the token
VAULT_TOKEN=`vault login -token-only -method=userpass username=vault password=vault`
export VAULT_TOKEN

#Add shell-in-a-box
wget https://rpmfind.net/linux/epel/7/x86_64/Packages/s/shellinabox-2.20-5.el7.x86_64.rpm
sudo yum install -y /home/ec2-user/musical-spork/application/shellinabox-2.20-5.el7.x86_64.rpm
sudo cp shellinaboxd /etc/sysconfig/shellinaboxd
sudo systemctl start shellinaboxd

#Start consul template
sudo kill -9 `pidof consul-template`
nohup consul-template -template "./config.ini.ctmpl:/var/lib/docker/volumes/consul-template/_data/config.ini" >/dev/null 2>&1

#Start Consul Proxy for the Profit service
nohup consul connect proxy -service web -upstream profitapp_connect:8080 > /dev/null 2>&1

#Build Container and Run it
docker rm -f c1
sudo docker build -t tempcontainer .;sudo docker run --network="host"  --rm -v consul-template:/usr/src/app/config -e VAULT_TOKEN=$VAULT_TOKEN -p 5000:5000 --name c1 tempcontainer


