# hyperledger-fabric-utils
Utility code and scripts for Hyperledger Fabric

## Install a Development Hyperledger Fabric in a Microsoft Azure VM

These instructions will allow you to setup your own virtual machine on Microsoft Azure
with Hyperleger Fabric blockchain with the Clause Audit Trail chaincode running.

### Install the Azure CLI

Following these instructions:
https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-macos?view=azure-cli-latest

### Login to Azure

```
az login
```

### Deploy Hyperledger Fabric and Audit Trail chaincode

Run the `azure-deploy.sh` script to deploy HLF to Azure in a VM. The script will take about 10 minutes to complete.

### Copy the Connection Profile JSON

At the end of the script you should see the connection profile for the Hyperledger Fabric printed. It will look something like this:

```
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
            "url": "grpc://xxxxx.uksouth.cloudapp.azure.com:7050"
        }
    },
    "peers": {
        "peer0.org1.example.com": {
            "url": "grpc://xxxxx.uksouth.cloudapp.azure.com:7051"
        }
    },
    "certificateAuthorities": {
        "ca.org1.example.com": {
            "url": "http://xxxxx.uksouth.cloudapp.azure.com:7054",
            "caName": "ca.org1.example.com",
            "registrar": [{
                "enrollId": "admin",
                "enrollSecret": "adminpw"
            }],
            "x-mspid": "Org1MSP"
        }
    }
}
```

Copy this and save it into a file called `connection-profile.json`.

### Add User to docker group

Login to your VM using `ssh`. Scroll to the top of the script output and you will see the IP address for your VM.

```
ssh <my-ip-address>
```

In the remote VM, then add yourself to the `docker` group and then exit the VM:

```
sudo usermod -aG docker <my-user-name>
exit
```

Log back into the VM via ssh and verify that you have docker access:

```
ssh <my-ip-address>
docker ps -a
```

You should see output like this:

```
$ docker ps -a
CONTAINER ID        IMAGE                                                                                                      COMMAND                  CREATED             STATUS              PORTS                                            NAMES
1804f00188d0        dev-peer0.org1.example.com-clause-0.1.0-7b79dff73511a0052225c5019f4c301f36b6ca7ef09273fe7acf444d93ffb5c7   "/bin/sh -c 'cd /usr…"   12 minutes ago      Up 12 minutes                                                        dev-peer0.org1.example.com-clause-0.1.0
904163c3b86f        hyperledger/fabric-tools                                                                                   "/bin/bash"              13 minutes ago      Up 13 minutes                                                        cli
78a4c4520776        hyperledger/fabric-peer                                                                                    "peer node start"        15 minutes ago      Up 15 minutes       0.0.0.0:7051->7051/tcp, 0.0.0.0:7053->7053/tcp   peer0.org1.example.com
71496c27a8a2        hyperledger/fabric-ca                                                                                      "sh -c 'fabric-ca-se…"   15 minutes ago      Up 15 minutes       0.0.0.0:7054->7054/tcp                           ca.example.com
06726fea7e5b        hyperledger/fabric-orderer                                                                                 "orderer"                15 minutes ago      Up 15 minutes       0.0.0.0:7050->7050/tcp                           orderer.example.com
8c39fa795f9a        hyperledger/fabric-couchdb                                                                                 "tini -- /docker-ent…"   15 minutes ago      Up 15 minutes       4369/tcp, 9100/tcp, 0.0.0.0:5984->5984/tcp       couchdb
```

### Tail the chaincoe logs

You can use the `docker logs -f` command to inspect the logs for the audit trail chaincode container. Replace `1804f00188d0` with the id for your chaincode container (printed by `docker ps`).

```
docker logs -f 1804f00188d0

> clause@1.0.0 start /usr/local/src
> node clause.js "--peer.address" "peer0.org1.example.com:7052"

(node:17) DeprecationWarning: grpc.load: Use the @grpc/proto-loader module with grpc.loadPackageDefinition instead
=========== Instantiated Clause chaincode ===========
{ fcn: 'storeAuditEvent',
  params: [ 'FabricAudit', 'test connection from clause.io' ] }
============= START : Execute storeAuditEvent ===========
============= END : Execute storeAuditEvent ===========
```