#!/bin/bash   
set -ex

# Installing the Azure CLI, https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-macos?view=azure-cli-latest
# Code taken from https://docs.microsoft.com/en-us/azure/app-service/containers/tutorial-multi-container-app

# Random suffix for resources to ensure uniqueness
INDEX=$RANDOM

# Change these four parameters as needed
RESOURCE_GROUP=hlfRg$INDEX
LOCATION=uksouth
SHARE_NAME=acishare
STORAGE_ACCOUNT_NAME=hlf$INDEX
SERVICEPLAN_NAME=hlfServicePlan$INDEX
VM_NAME=hlfVm$INDEX
SUBDOMAIN=hlf$INDEX
DOMAIN=$SUBDOMAIN.$LOCATION.cloudapp.azure.com

# # Create the resource group that will contain all other resources
az group create --location $LOCATION --name $RESOURCE_GROUP

# # Create a virtual machine
az vm create -n $VM_NAME -g $RESOURCE_GROUP --image UbuntuLTS --generate-ssh-keys

# VM networking
az vm open-port -g $RESOURCE_GROUP -n $VM_NAME --port '7050-7054'
IP_ADDRESS=$(az vm list-ip-addresses -g $RESOURCE_GROUP -n $VM_NAME --query '[0].virtualMachine.network.publicIpAddresses[0].ipAddress' | xargs)
IP_NAME=$(az vm list-ip-addresses -g $RESOURCE_GROUP -n $VM_NAME --query '[0].virtualMachine.network.publicIpAddresses[0].name' | xargs)
az network public-ip update --resource-group $RESOURCE_GROUP --name $IP_NAME --dns-name $SUBDOMAIN

# Connect to the VM
ssh-keyscan -H $IP_ADDRESS >> ~/.ssh/known_hosts
ssh $IP_ADDRESS 'bash -s' < install_chaincode.sh

# Connection Profile
CONNECTION_PROFILE=$(cat <<-END
{
    "name": "basic-network",
    "version": "1.0.0",
    "client": {
        "organization": "Org1",
        "connection": {
            "timeout": {
                "peer": {
                    "endorser": "300",
                    "eventHub": "300",
                    "eventReg": "300"
                },
                "orderer": "300"
            }
        }
    },
    "channels": {
        "mychannel": {
            "orderers": ["orderer.example.com"],
            "peers": {
                "peer0.org1.example.com": {}
            }
        }
    },
    "organizations": {
        "Org1": {
            "mspid": "Org1MSP",
            "peers": ["peer0.org1.example.com"],
            "certificateAuthorities": ["ca.org1.example.com"]
        }
    },
    "orderers": {
        "orderer.example.com": {
            "url": "grpc://$DOMAIN:7050"
        }
    },
    "peers": {
        "peer0.org1.example.com": {
            "url": "grpc://$DOMAIN:7051"
        }
    },
    "certificateAuthorities": {
        "ca.org1.example.com": {
            "url": "http://$DOMAIN:7054",
            "caName": "ca.org1.example.com",
            "registrar": [{
                "enrollId": "admin",
                "enrollSecret": "adminpw"
            }],
            "x-mspid": "Org1MSP"
        }
    }
}
END
) 

echo -e "Deployment successful!"
echo -e "Hyperledger Fabric is provisioned at $DOMAIN."
echo -e  ""
echo -e "The connection profile for this network is:"
echo -e "################################"
echo -e $CONNECTION_PROFILE
echo -e "################################"
