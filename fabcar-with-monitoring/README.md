# Setting up Hyperledger v2.1 Fabcar sample with monitoring using Prometheus and Grafana
In this code sample, we will setup a single node Hyperledger Fabcar sample application with monitoring using Prometheus and Grafana

For more information on Hyperledger v2.1 refer to the link https://hyperledger-fabric.readthedocs.io/en/release-2.1/whatis.html

## Setup Hyper ledger Fabric with Fabcar sample
Set up an Ubuntu 18.04 server with minimal install configuration. All the code example assumes here that you are installing everything as `root` user and everything under the root home directory `/root`
### Install Pre-requisites
The detailed information about the pre-requisites can be referred at https://hyperledger-fabric.readthedocs.io/en/release-2.1/prereqs.html
#### Install SSH, Curl, Docker & Docker Compose
```
apt-get install openssh-server curl -y
apt-get remove docker docker-engine docker.io containerd runc
apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
apt-key fingerprint 0EBFCD88
add-apt-repository    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
apt-get update
apt-get install docker-ce docker-ce-cli containerd.io -y
curl -L "https://github.com/docker/compose/releases/download/1.25.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
```
#### Install GO version 1.14.x
```
wget https://dl.google.com/go/go1.14.2.linux-amd64.tar.gz
tar -xvzf go1.14.2.linux-amd64.tar.gz
```
#### Install NodeJS version 10.15.3 or higher
```
wget https://nodejs.org/dist/latest-v10.x/node-v10.20.1-linux-x64.tar.gz
tar -xvzf node-v10.20.1-linux-x64.tar.gz
cp -av node-v10.20.1-linux-x64 /usr/local/
```
#### Install Python Version 2.7
```
apt-get install python
```
### Install HyperLedger Fabric
Refer this link for more information : https://hyperledger-fabric.readthedocs.io/en/release-2.1/install.html
#### Clone Hyperledger Fabric Repo & the images
```
curl -sSL https://bit.ly/2ysbOFE | bash -s
```
#### Set necessary environment variables
```
export GOPATH=$HOME/go
export PATH=$PATH:/usr/local/node-v10.20.1-linux-x64/bin:$GOPATH/bin:$HOME/fabric-samples/bin
export FABRIC_CFG_PATH=/root/fabric-samples/config
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/root/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/root/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051
```
#### Set necessary environment variables for subsequent logins
```
echo "export GOPATH=$HOME/go" >>/root/.bashrc
echo "export PATH=$PATH:/usr/local/node-v10.20.1-linux-x64/bin:$GOPATH/bin:$HOME/fabric-samples/bin" >> /root/.bashrc
echo "export FABRIC_CFG_PATH=/root/fabric-samples/config" >>/root/.bashrc
echo "export CORE_PEER_TLS_ENABLED=true" >>/root/.bashrc
echo "export CORE_PEER_LOCALMSPID=\"Org1MSP\"" >>/root/.bashrc
echo "export CORE_PEER_TLS_ROOTCERT_FILE=/root/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" >>/root/.bashrc
echo "export CORE_PEER_MSPCONFIGPATH=/root/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp" >>/root/.bashrc
echo "export CORE_PEER_ADDRESS=localhost:7051" >>/root/.bashrc
```

### Customize the image and scripts
The steps in this section are custom steps that you wont find in the hyperledger documentation. By default the hyperledger images has the operations metrics disabled. What we do here is to enable it in the image and expose the service in the docker configuration.
#### Create a new image,
In this example, we are not using the TLS communication . So we are not setting any certificates and `https`. However, in a real application, you will have to set it.
```
docker run --rm --entrypoint cat hyperledger/fabric-peer:latest /etc/hyperledger/fabric/core.yaml > core.yaml
sed 's/provider: disabled/provider: prometheus/g' core.yaml > core.yaml.tmp
sed 's/listenAddress: 127.0.0.1:9443/listenAddress: 0.0.0.0:9443/g' core.yaml.tmp > core.yaml
cat <<EOF >Dockerfile
FROM hyperledger/fabric-peer:latest
ADD ./core.yaml /etc/hyperledger/fabric/core.yaml
EOF
docker build . -t hyperledger/fabric-peer:latest
docker run --rm --entrypoint cat hyperledger/fabric-orderer:latest /etc/hyperledger/fabric/orderer.yaml > orderer.yaml
sed 's/Provider: disabled/provider: prometheus/g' orderer.yaml > orderer.yaml.tmp
sed 's/ListenAddress: 127.0.0.1:8443/listenAddress: 0.0.0.0:9443/g' orderer.yaml.tmp > orderer.yaml
cat <<EOF >Dockerfile
FROM hyperledger/fabric-orderer:latest
ADD ./orderer.yaml /etc/hyperledger/fabric/orderer.yaml
EOF
docker build . -t hyperledger/fabric-orderer:latest
```
#### Edit the default docker-compose files
To expose the metrics port, the docker-compose file used by the `network.sh` script need to be edited. This file can be located here:- `~/fabric-samples/test-network/docker/docker-compose-test-net.yaml`

In this file add extra lines to expose the port for each of the services, 
For example locate the section  `services: --> orderer.example.com: --> ports:` and add an extra line. After adding it may look like this (The local port number can be of your choice)
```
    ports:
      - 7050:7050
      - 9444:9443
```
Similarly, add entries for the other services too (Both the peer nodes) as shown respectively,
Service section : `services: --> peer0.org1.example.com: ports:`
```
    ports:
      - 7051:7051
      - 9445:9443
```
Service section : `services: --> peer0.org2.example.com: ports:`
```
    ports:
      - 9051:9051
      - 9446:9443
```
With this the metrics will be available at the following address on the server,  
* Orderer Metrics   : http://<IP Address>:9444/metrics
* Peer Org1 Metrics : http://<IP Address>:9445/metrics
* Peer Org2 Metrics : http://<IP Address>:9446/metrics

### Bring the Blockchain network up
From here on, its the standard procedure as explained here : https://hyperledger-fabric.readthedocs.io/en/release-2.1/test_network.html
```
cd fabric-samples/test-network
./network.sh up
./network.sh createChannel
./network.sh deployCC
```
### Interact with the Blockchain
Query blockchain to get the details,
```
peer chaincode query -C mychannel -n fabcar -c '{"Args":["queryAllCars"]}'

```
Update a record,
```
cd /root/fabric-samples/test-network
peer chaincode invoke  \
     -o localhost:7050  \
     --ordererTLSHostnameOverride orderer.example.com \
     --tls true \
     --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
     -C mychannel \
     -n fabcar \
     --peerAddresses localhost:7051 \
     --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
     --peerAddresses localhost:9051 \
     --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt \
     -c '{"function":"changeCarOwner","Args":["CAR9","Dave"]}'
```
You can follow the procedure for installing and configuring Prometheus as explained [here](../prometheus/README.md)

Once the prometheus is configured, follow the procedure [here](../grafana/README.md) to configure the grafana dashboard for blockchain.

Happy Coding...