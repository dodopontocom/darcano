#!/usr/bin/env bash

# runs on both BP&R

# --testnet-magic 1097911063

##############################################################################
############# Hardening the system #############
##############################################################################


##############################################################################
############# Initial setup - cabal, ghc, cardano-cli, cardano-node ##########
##############################################################################

export DARLENE1_TOKEN=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/DARLENE1_TOKEN)
export TELEGRAM_ID=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/TELEGRAM_ID)
export COLD_DELEG_CERT=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/COLD_DELEG_CERT)
export COLD_NODE_CERT=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/COLD_NODE_CERT)
export COLD_NODE_COUNTER=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/COLD_NODE_COUNTER)
export COLD_NODE_SKEY=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/COLD_NODE_SKEY)
export COLD_NODE_VKEY=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/COLD_NODE_VKEY)
export COLD_PAY_ADDR=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/COLD_PAY_ADDR)
export COLD_PAY_SKEY=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/COLD_PAY_SKEY)
export COLD_PAY_VKEY=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/COLD_PAY_VKEY)
export COLD_POOL_CERT=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/COLD_POOL_CERT)
export COLD_STAKE_ADDR=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/COLD_STAKE_ADDR)
export COLD_STAKE_CERT=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/COLD_STAKE_CERT)
export COLD_STAKE_SKEY=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/COLD_STAKE_SKEY)
export COLD_STAKE_VKEY=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/COLD_STAKE_VKEY)
export EVOLVING_SKEY=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/EVOLVING_SKEY)
export EVOLVING_VKEY=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/EVOLVING_VKEY)
export VRF_SKEY=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/VRF_SKEY)
export VRF_VKEY=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/VRF_VKEY)

export HOME=/home/ubuntu
export BOOTSTRAP_HASKELL_NONINTERACTIVE=true

CARDANO_NODE_TAG=1.30.1
GHC_VERSION=8.10.7
NODE_PORT=3000
NODE_HOME=${HOME}/cardano-gcloud-node

mkdir ~/git
cd ~/git
git clone https://github.com/input-output-hk/libsodium
cd libsodium
git checkout 66f017f1
./autogen.sh
./configure
make
sudo make install

sudo ln -s /usr/local/lib/libsodium.so.23.3.0 /usr/lib/libsodium.so.23

curl -s -X POST https://api.telegram.org/bot${DARLENE1_TOKEN}/sendMessage -d chat_id=${TELEGRAM_ID} -d text="${HOSTNAME} - install libsodium done"

sudo apt-get -y install pkg-config libgmp-dev libssl-dev \
    libtinfo-dev libsystemd-dev zlib1g-dev build-essential \
    curl libgmp-dev libffi-dev libncurses-dev libtinfo5

cd $HOME
curl --proto '=https' --tlsv1.2 -sSf -o ghcup.sh https://get-ghcup.haskell.org
chmod +x ghcup.sh
./ghcup.sh

source $HOME/.ghcup/env

ghcup upgrade
ghcup install cabal 3.4.0.0
ghcup set cabal 3.4.0.0
###

ghcup install ghc ${GHC_VERSION}
ghcup set ghc ${GHC_VERSION}

echo PATH="$HOME/.local/bin:$PATH" >> $HOME/.bashrc
LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"

echo export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH" >> $HOME/.bashrc

echo export NODE_HOME=${HOME}/cardano-gcloud-node >> $HOME/.bashrc
NODE_CONFIG=testnet

echo export NODE_CONFIG=testnet >> $HOME/.bashrc
NODE_BUILD_NUM=$(curl https://hydra.iohk.io/job/Cardano/iohk-nix/cardano-deployment/latest-finished/download/1/index.html | grep -e "build" | sed 's/.*build\/\([0-9]*\)\/download.*/\1/g')

echo export NODE_BUILD_NUM=$(curl https://hydra.iohk.io/job/Cardano/iohk-nix/cardano-deployment/latest-finished/download/1/index.html | grep -e "build" | sed 's/.*build\/\([0-9]*\)\/download.*/\1/g') >> $HOME/.bashrc
source $HOME/.bashrc

cabal update
cabal --version
ghc --version

curl -s -X POST https://api.telegram.org/bot${DARLENE1_TOKEN}/sendMessage -d chat_id=${TELEGRAM_ID} -d text="${HOSTNAME} - ghcup,cabal setup done"

cd $HOME/git
git clone https://github.com/input-output-hk/cardano-node.git
cd cardano-node
git fetch --all --recurse-submodules --tags
git checkout tags/${CARDANO_NODE_TAG}

cabal configure -O0 -w ghc-${GHC_VERSION}

echo -e "package cardano-crypto-praos\n flags: -external-libsodium-vrf" > cabal.project.local
sed -i $HOME/.cabal/config -e "s/overwrite-policy:/overwrite-policy: always/g"
#rm -rf $HOME/git/cardano-node/dist-newstyle/build/x86_64-linux/ghc-${GHC_VERSION}

cabal build cardano-cli cardano-node

sudo cp $(find $HOME/git/cardano-node/dist-newstyle/build -type f -name "cardano-cli") /usr/local/bin/cardano-cli
sudo cp $(find $HOME/git/cardano-node/dist-newstyle/build -type f -name "cardano-node") /usr/local/bin/cardano-node

/usr/local/bin/cardano-node --version
/usr/local/bin/cardano-cli --version

curl -s -X POST https://api.telegram.org/bot${DARLENE1_TOKEN}/sendMessage -d chat_id=${TELEGRAM_ID} -d text="${HOSTNAME} - configure and build cardano cli node done"

mkdir $NODE_HOME
cd $NODE_HOME
wget -N https://hydra.iohk.io/build/${NODE_BUILD_NUM}/download/1/${NODE_CONFIG}-byron-genesis.json
wget -N https://hydra.iohk.io/build/${NODE_BUILD_NUM}/download/1/${NODE_CONFIG}-topology.json
wget -N https://hydra.iohk.io/build/${NODE_BUILD_NUM}/download/1/${NODE_CONFIG}-shelley-genesis.json
wget -N https://hydra.iohk.io/build/${NODE_BUILD_NUM}/download/1/${NODE_CONFIG}-alonzo-genesis.json
wget -N https://hydra.iohk.io/build/${NODE_BUILD_NUM}/download/1/${NODE_CONFIG}-config.json

#leave TraceMempool as it is in BP and false in relay
sed -i ${NODE_CONFIG}-config.json -e "s/TraceBlockFetchDecisions\": false/TraceBlockFetchDecisions\": true/g"
if [[ $(echo ${HOSTNAME} | grep relaynode) ]]; then
  sed -i ${NODE_CONFIG}-config.json -e "s/TraceMempool\": true/TraceMempool\": false/g"
fi

CARDANO_NODE_SOCKET_PATH="${NODE_HOME}/db/socket"
echo export CARDANO_NODE_SOCKET_PATH="${NODE_HOME}/db/socket" >> ${HOME}/.bashrc
source ${HOME}/.bashrc

chown -R ubuntu:ubuntu ${HOME}/cardano-gcloud-node
# sudo journalctl -u google-startup-scripts.service

curl -s -X POST https://api.telegram.org/bot${DARLENE1_TOKEN}/sendMessage -d chat_id=${TELEGRAM_ID} -d text="${HOSTNAME} - Almost there"
message=$(uptime -p)
curl -s -X POST https://api.telegram.org/bot${DARLENE1_TOKEN}/sendMessage -d chat_id=${TELEGRAM_ID} -d text="${HOSTNAME} - ${message}"

sudo chown -R ubuntu:ubuntu ${HOME}

##############################################################################
############# Configuring/Starting Nodes systemd #############
##############################################################################

echo ${HOSTNAME} | grep blockproducer
if [[ $? -eq 0 ]]; then
    cat > ${NODE_HOME}/kes.skey <<< ${EVOLVING_SKEY}
    cat > ${NODE_HOME}/vrf.skey <<< ${VRF_SKEY}
    cat > ${NODE_HOME}/node.cert <<< ${COLD_NODE_CERT}
    sudo chown -R ubuntu:ubuntu ${HOME}
    sudo chmod 400 ${NODE_HOME}/kes.skey
    sudo chmod 400 ${NODE_HOME}/vrf.skey
    sudo chmod 400 ${NODE_HOME}/node.cert

    cat > ${NODE_HOME}/startNode.sh << EOF
#!/bin/bash

DIRECTORY=/home/ubuntu/cardano-gcloud-node

PORT=3000
HOSTADDR=0.0.0.0
TOPOLOGY=\${DIRECTORY}/testnet-topology.json
DB_PATH=\${DIRECTORY}/db
SOCKET_PATH=\${DIRECTORY}/db/socket
CONFIG=\${DIRECTORY}/testnet-config.json
KES=\${DIRECTORY}/kes.skey
VRF=\${DIRECTORY}/vrf.skey
CERT=\${DIRECTORY}/node.cert
/usr/local/bin/cardano-node run --topology \${TOPOLOGY} --database-path \${DB_PATH} --socket-path \${SOCKET_PATH} --host-addr \${HOSTADDR} --port \${PORT} --config \${CONFIG} --shelley-kes-key \${KES} --shelley-vrf-key \${VRF} --shelley-operational-certificate \${CERT}
EOF

    cat > ${NODE_HOME}/${NODE_CONFIG}-topology.json_ << EOF
{
  "Producers": [
    {
      "addr": "RN_NODE_EXTERNAL_IP",
      "port": 3001,
      "valency": 2
    }
  ]
}
EOF
    else
        cat > ${NODE_HOME}/startNode.sh << EOF
#!/bin/bash

DIRECTORY=/home/ubuntu/cardano-gcloud-node

PORT=3001
HOSTADDR=0.0.0.0
TOPOLOGY=\${DIRECTORY}/testnet-topology.json
DB_PATH=\${DIRECTORY}/db
SOCKET_PATH=\${DIRECTORY}/db/socket
CONFIG=\${DIRECTORY}/testnet-config.json
/usr/local/bin/cardano-node run --topology \${TOPOLOGY} --database-path \${DB_PATH} --socket-path \${SOCKET_PATH} --host-addr \${HOSTADDR} --port \${PORT} --config \${CONFIG}
EOF

    cat > ${NODE_HOME}/${NODE_CONFIG}-topology.json_ << EOF
{ "resultcode": "201", "networkMagic": "1097911063", "ipType":4, "requestedIpVersion":"4", "max":"20", "Producers": [ 
    { "addr": "BP_NODE_INTERNAL_IP", "port": 3000, "valency": 2 } ,
    { "addr": "relays-new.cardano-testnet.iohkdev.io", "port": 3001, "valency": 2 } ,
    { "addr": "108.236.80.77", "port": 4564, "valency": 1, "distance":922,  "continent":"NA",  "country":"US",  "region":"TX" },
    { "addr": "143.198.233.125", "port": 6000, "valency": 1, "distance":1229,  "continent":"NA",  "country":"US",  "region":"TX" },
    { "addr": "40.85.191.178", "port": 3001, "valency": 1, "distance":1528,  "continent":"NA",  "country":"US",  "region":"VA" },
    { "addr": "71.244.164.205", "port": 6001, "valency": 1, "distance":1640,  "continent":"NA",  "country":"US",  "region":"MD" },
    { "addr": "45.79.161.84", "port": 4321, "valency": 1, "distance":1813,  "continent":"NA",  "country":"US",  "region":"NJ" },
    { "addr": "35.197.74.18", "port": 6000, "valency": 1, "distance":2088,  "continent":"NA",  "country":"US",  "region":"OR" },
    { "addr": "12.105.221.218", "port": 6002, "valency": 1, "distance":2227,  "continent":"NA",  "country":"US",  "region":"FL" },
    { "addr": "138.197.199.161", "port": 7777, "valency": 1, "distance":2298,  "continent":"NA",  "country":"US",  "region":"CA" },
    { "addr": "testnet.ada.vegas", "port": 7004, "valency": 1, "distance":6869,  "continent":"EU",  "country":"GB",  "region":"ENG" },
    { "addr": "45.147.54.171", "port": 6000, "valency": 1, "distance":6891,  "continent":"EU",  "country":"GB",  "region":"ENG" },
    { "addr": "206.189.107.154", "port": 6000, "valency": 1, "distance":7126,  "continent":"EU",  "country":"NL",  "region":"NH" },
    { "addr": "81.232.88.249", "port": 7055, "valency": 1, "distance":7278,  "continent":"EU",  "country":"SE",  "region":"AB" },
    { "addr": "194.163.139.28", "port": 6000, "valency": 1, "distance":7319,  "continent":"EU",  "country":"DE",  "region":"HH" },
    { "addr": "95.111.242.64", "port": 3001, "valency": 1, "distance":7437,  "continent":"EU",  "country":"DE",  "region":"null" },
    { "addr": "95.179.169.157", "port": 6600, "valency": 1, "distance":7481,  "continent":"EU",  "country":"DE",  "region":"HE" },
    { "addr": "cnode.ch", "port": 3003, "valency": 1, "distance":7597,  "continent":"EU",  "country":"CH",  "region":"GE" },
    { "addr": "cntr-1.services.kindstudios.gr", "port": 25437, "valency": 1, "distance":7665,  "continent":"EU",  "country":"DE",  "region":"BY" },
    { "addr": "173.249.16.130", "port": 5001, "valency": 1, "distance":7785,  "continent":"EU",  "country":"DE",  "region":"BY" },
    { "addr": "relay-test.adaseal.eu", "port": 6000, "valency": 1, "distance":7978,  "continent":"EU",  "country":"CZ",  "region":"64" },
    { "addr": "relay0.alpha.sp.paradigmshift.icu", "port": 6000, "valency": 1, "distance":9738,  "continent":"AS",  "country":"JP",  "region":"13" }
  ]
}
EOF

fi

cat > ${NODE_HOME}/cardano-node.service << EOF 
# The Cardano node service (part of systemd)
# file: /etc/systemd/system/cardano-node.service

[Unit]
Description     = Cardano node service
Wants           = network-online.target
After           = network-online.target 

[Service]
User            = ubuntu
Type            = simple
WorkingDirectory= ${NODE_HOME}
ExecStart       = /bin/bash -c '${NODE_HOME}/startNode.sh'
KillSignal=SIGINT
RestartKillSignal=SIGINT
TimeoutStopSec=2
LimitNOFILE=32768
Restart=always
RestartSec=5
SyslogIdentifier=cardano-node

[Install]
WantedBy	= multi-user.target
EOF

sudo mv ${NODE_HOME}/cardano-node.service /etc/systemd/system/cardano-node.service
sudo chmod 644 /etc/systemd/system/cardano-node.service
sudo chmod +x ${NODE_HOME}/startNode.sh
sudo systemctl daemon-reload
sudo systemctl enable cardano-node
sudo systemctl reload-or-restart cardano-node
sudo systemctl start cardano-node

sleep 120
ps -ef | grep cardano-node | grep -v grep >/dev/null 2>&1
if [[ $? -eq 0 ]]; then
    message="${HOSTNAME} - Node is running on systemd now..."
    curl -s -X POST https://api.telegram.org/bot${DARLENE1_TOKEN}/sendMessage -d chat_id=${TELEGRAM_ID} -d text="${message}"
fi

##############################################################################
############# Watch blockchain syncronization #############
##############################################################################
message=$(uptime -p)
curl -s -X POST https://api.telegram.org/bot${DARLENE1_TOKEN}/sendMessage -d chat_id=${TELEGRAM_ID} -d text="${HOSTNAME} - ${message}"
while [[ $(CARDANO_NODE_SOCKET_PATH="/home/ubuntu/cardano-gcloud-node/db/socket" /usr/local/bin/cardano-cli query tip --testnet-magic 1097911063 | grep -i sync | awk '{ print $2 }' | cut -d'.' -f1 | cut -c 2-) -lt 100 ]]; do
    message="${HOSTNAME} - sync progress: "
    message+=$(CARDANO_NODE_SOCKET_PATH="/home/ubuntu/cardano-gcloud-node/db/socket" /usr/local/bin/cardano-cli query tip --testnet-magic 1097911063 | grep -i sync | awk '{ print $2 }' | cut -d'.' -f1 | cut -c 2-)
    curl -s -X POST https://api.telegram.org/bot${DARLENE1_TOKEN}/sendMessage -d chat_id=${TELEGRAM_ID} -d text="${message}"
    sleep 1200
done
message=$(uptime -p)
curl -s -X POST https://api.telegram.org/bot${DARLENE1_TOKEN}/sendMessage -d chat_id=${TELEGRAM_ID} -d text="${HOSTNAME} - ${message}"

##############################################################################
############# Initial setup - cabal/ghc/cardano-cli/cardano-node #############
##############################################################################
