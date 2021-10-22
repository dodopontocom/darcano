#!/usr/bin/env bash

# --testnet-magic 1097911063

##############################################################################
############# Hardening the system #############
##############################################################################


##############################################################################
############# Initial setup - cabal, ghc, cardano-cli, cardano-node ##########
##############################################################################

export HOME=/home/ubuntu
export BOOTSTRAP_HASKELL_NONINTERACTIVE=true

CARDANO_NODE_TAG=1.30.1
GHC_VERSION=8.10.7
NODE_PORT=3000
NODE_HOME=$HOME/cardano-my-node

TELEGRAM_TOKEN=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/TELEGRAM_TOKEN)
TELEGRAM_ID=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/TELEGRAM_ID)
COLD_DELEG_CERT=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/COLD_DELEG_CERT)
COLD_NODE_CERT=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/COLD_NODE_CERT)
COLD_NODE_COUNTER=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/COLD_NODE_COUNTER)
COLD_NODE_SKEY=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/COLD_NODE_SKEY)
COLD_NODE_VKEY=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/COLD_NODE_VKEY)
COLD_PAY_ADDR=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/COLD_PAY_ADDR)
COLD_PAY_SKEY=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/COLD_PAY_SKEY)
COLD_PAY_VKEY=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/COLD_PAY_VKEY)
COLD_POOL_CERT=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/COLD_POOL_CERT)
COLD_STAKE_ADDR=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/COLD_STAKE_ADDR)
COLD_STAKE_CERT=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/COLD_STAKE_CERT)
COLD_STAKE_SKEY=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/COLD_STAKE_SKEY)
COLD_STAKE_VKEY=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/COLD_STAKE_VKEY)
EVOLVING_SKEY=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/EVOLVING_SKEY)
EVOLVING_VKEY=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/EVOLVING_VKEY)
VRF_SKEY=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/VRF_SKEY)
VRF_VKEY=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/VRF_VKEY)

curl -s -X POST https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage -d chat_id=${TELEGRAM_ID} -d text="Hello from ${HOSTNAME}"

sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y git jq bc make automake rsync htop curl \
    build-essential pkg-config libffi-dev libgmp-dev \
    libssl-dev libtinfo-dev libsystemd-dev zlib1g-dev \
    make g++ wget libncursesw5 libtool autoconf

curl -s -X POST https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage -d chat_id=${TELEGRAM_ID} -d text="${HOSTNAME} - apt upgrade done"

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

curl -s -X POST https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage -d chat_id=${TELEGRAM_ID} -d text="${HOSTNAME} - install libsodium done"

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

echo export NODE_HOME=$HOME/cardano-my-node >> $HOME/.bashrc
NODE_CONFIG=testnet

echo export NODE_CONFIG=testnet >> $HOME/.bashrc
NODE_BUILD_NUM=$(curl https://hydra.iohk.io/job/Cardano/iohk-nix/cardano-deployment/latest-finished/download/1/index.html | grep -e "build" | sed 's/.*build\/\([0-9]*\)\/download.*/\1/g')

echo export NODE_BUILD_NUM=$(curl https://hydra.iohk.io/job/Cardano/iohk-nix/cardano-deployment/latest-finished/download/1/index.html | grep -e "build" | sed 's/.*build\/\([0-9]*\)\/download.*/\1/g') >> $HOME/.bashrc
source $HOME/.bashrc

cabal update
cabal --version
ghc --version

curl -s -X POST https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage -d chat_id=${TELEGRAM_ID} -d text="${HOSTNAME} - ghcup,cabal setup done"

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

curl -s -X POST https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage -d chat_id=${TELEGRAM_ID} -d text="${HOSTNAME} - configure and build cardano cli node done"

mkdir $NODE_HOME
cd $NODE_HOME
wget -N https://hydra.iohk.io/build/${NODE_BUILD_NUM}/download/1/${NODE_CONFIG}-byron-genesis.json
wget -N https://hydra.iohk.io/build/${NODE_BUILD_NUM}/download/1/${NODE_CONFIG}-topology.json
wget -N https://hydra.iohk.io/build/${NODE_BUILD_NUM}/download/1/${NODE_CONFIG}-shelley-genesis.json
wget -N https://hydra.iohk.io/build/${NODE_BUILD_NUM}/download/1/${NODE_CONFIG}-alonzo-genesis.json
wget -N https://hydra.iohk.io/build/${NODE_BUILD_NUM}/download/1/${NODE_CONFIG}-config.json

#leave TraceMempool as it is in BP and false in relay
sed -i ${NODE_CONFIG}-config.json -e "s/TraceBlockFetchDecisions\": false/TraceBlockFetchDecisions\": true/g"
#sed -i ${NODE_CONFIG}-config.json -e "s/TraceMempool\": true/TraceMempool\": false/g"

CARDANO_NODE_SOCKET_PATH="${NODE_HOME}/db/socket"
echo export CARDANO_NODE_SOCKET_PATH="${NODE_HOME}/db/socket" >> $HOME/.bashrc
source $HOME/.bashrc

chown -R ubuntu:ubuntu $HOME/cardano-my-node
# sudo journalctl -u google-startup-scripts.service

curl -s -X POST https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage -d chat_id=${TELEGRAM_ID} -d text="Almost there"

# run blockchain to sync data
/usr/local/bin/cardano-node run --config ${NODE_HOME}/${NODE_CONFIG}-config.json \
    --database-path ${NODE_HOME}/db --socket-path ${NODE_HOME}/db/socket \
    --host-addr 0.0.0.0 --port ${NODE_PORT} --topology ${NODE_HOME}/${NODE_CONFIG}-topology.json \
    > ${NODE_HOME}/run.out 2>&1 &

message=$(tail -1 ${NODE_HOME}/run.out)
curl -s -X POST https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage -d chat_id=${TELEGRAM_ID} -d text="seems all went good"
#curl -s -X POST https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage -d chat_id=${TELEGRAM_ID} -d text="last line log"
#curl -s -X POST https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage -d chat_id=${TELEGRAM_ID} -d text="${message}"
message=$(uptime -p)
curl -s -X POST https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage -d chat_id=${TELEGRAM_ID} -d text="${message}"

sleep 120
sudo chown -R ubuntu:ubuntu ${HOME}
while [[ $(CARDANO_NODE_SOCKET_PATH="/home/ubuntu/cardano-my-node/db/socket" /usr/local/bin/cardano-cli query tip --testnet-magic 1097911063 | grep -i sync | awk '{ print $2 }' | cut -d'.' -f1 | cut -c 2-) < 99 ]]; do
    message="${HOSTNAME} - sync progress: "
    message+=$(CARDANO_NODE_SOCKET_PATH="/home/ubuntu/cardano-my-node/db/socket" /usr/local/bin/cardano-cli query tip --testnet-magic 1097911063 | grep -i sync | awk '{ print $2 }' | cut -d'.' -f1 | cut -c 2-)
    curl -s -X POST https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage -d chat_id=${TELEGRAM_ID} -d text="${message}"
    sleep 1200
done

##############################################################################
############# Configuring/Starting Nodes systemd #############
##############################################################################

##############################################################################
############# Applying templates #############
##############################################################################

##############################################################################
############# Creating transactions certificates #############
##############################################################################

##############################################################################
############# Initial setup - cabal/ghc/cardano-cli/cardano-node #############
##############################################################################
