#!/bin/bash   
set -ex

# Fetch the chaincode from GitHub
git clone https://github.com/clausehq/fabric-samples
cd fabric-samples
git checkout release-1.2

sudo apt-get install zip -y
cd chaincode/clause
zip -r node.zip node
mv node.zip ../../basic-network/
cd ../../basic-network

# Install docker and docker-compose
wget -qO- https://get.docker.com/ | sh
COMPOSE_VERSION=`git ls-remote https://github.com/docker/compose | grep refs/tags | grep -oP "[0-9]+\.[0-9][0-9]+\.[0-9]+$" | tail -n 1`
sudo sh -c "curl -L https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose"
sudo chmod +x /usr/local/bin/docker-compose
sudo sh -c "curl -L https://raw.githubusercontent.com/docker/compose/${COMPOSE_VERSION}/contrib/completion/bash/docker-compose > /etc/bash_completion.d/docker-compose"

# Start the docker network
sudo ./start.sh
sudo docker-compose -f docker-compose.yml up -d cli

# Move the chaincode into a container
sudo docker cp node.zip cli:/node.zip

# Install the chaincode
sudo docker exec cli bash -c "unzip /node.zip -d /"
sudo docker exec cli bash -c "peer chaincode install -n clause -v 0.1.0 -p /node -l node"
sudo docker exec cli bash -c "peer chaincode instantiate -n clause -c '{\"Args\":[]}' -P \"OR ('Org1.member','Org2.member')\" -C mychannel -v 0.1.0 -l node"
