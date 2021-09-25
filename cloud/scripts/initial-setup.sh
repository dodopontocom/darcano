#!/usr/bin/env bash

export HOME=/home/ubuntu
export BOOTSTRAP_HASKELL_NONINTERACTIVE=true

CARDANO_NODE_TAG=1.29.0 

sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install git jq bc make automake rsync htop curl build-essential pkg-config libffi-dev libgmp-dev libssl-dev libtinfo-dev libsystemd-dev zlib1g-dev make g++ wget libncursesw5 libtool autoconf -y

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

sudo apt-get -y install pkg-config libgmp-dev libssl-dev libtinfo-dev libsystemd-dev zlib1g-dev build-essential curl libgmp-dev libffi-dev libncurses-dev libtinfo5

cd $HOME
curl --proto '=https' --tlsv1.2 -sSf -o ghcup.sh https://get-ghcup.haskell.org
chmod +x ghcup.sh
./ghcup.sh

source $HOME/.ghcup/env

ghcup upgrade
ghcup install cabal 3.4.0.0
ghcup set cabal 3.4.0.0
###

ghcup install ghc 8.10.7
ghcup set ghc 8.10.7

echo "path: ${PATH}"

echo PATH="$HOME/.local/bin:$PATH" >> $HOME/.bashrc
LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"
echo export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH" >> $HOME/.bashrc
NODE_HOME=$HOME/cardano-my-node
echo export NODE_HOME=$HOME/cardano-my-node >> $HOME/.bashrc
NODE_CONFIG=testnet
echo export NODE_CONFIG=testnet >> $HOME/.bashrc
NODE_BUILD_NUM=$(curl https://hydra.iohk.io/job/Cardano/iohk-nix/cardano-deployment/latest-finished/download/1/index.html | grep -e "build" | sed 's/.*build\/\([0-9]*\)\/download.*/\1/g')
echo export NODE_BUILD_NUM=$(curl https://hydra.iohk.io/job/Cardano/iohk-nix/cardano-deployment/latest-finished/download/1/index.html | grep -e "build" | sed 's/.*build\/\([0-9]*\)\/download.*/\1/g') >> $HOME/.bashrc
source $HOME/.bashrc

# --testnet-magic 1097911063

cabal update
cabal --version
ghc --version

cd $HOME/git
git clone https://github.com/input-output-hk/cardano-node.git
cd cardano-node
git fetch --all --recurse-submodules --tags
git checkout tags/${CARDANO_NODE_TAG}

cabal configure -O0 -w ghc-8.10.7

echo -e "package cardano-crypto-praos\n flags: -external-libsodium-vrf" > cabal.project.local
sed -i $HOME/.cabal/config -e "s/overwrite-policy:/overwrite-policy: always/g"
rm -rf $HOME/git/cardano-node/dist-newstyle/build/x86_64-linux/ghc-8.10.7

cabal build cardano-cli cardano-node
#

#HEAD is now at 877ce057f Merge #3305
#HEAD is now at edc6d4672 Merge pull request #3430 from input-output-hk/hkm/windows-cross
#Scripts: startup-script: cabal: Cannot find the program 'ghc'. User-specified path 'ghc-8.10.7' does
#startup-script: not refer to an executable and the program is not on the system path.

cp $(find $HOME/git/cardano-node/dist-newstyle/build -type f -name "cardano-cli") /usr/local/bin/cardano-cli
cp $(find $HOME/git/cardano-node/dist-newstyle/build -type f -name "cardano-node") /usr/local/bin/cardano-node

cardano-node version
cardano-cli version

mkdir $NODE_HOME
cd $NODE_HOME
wget -N https://hydra.iohk.io/build/${NODE_BUILD_NUM}/download/1/${NODE_CONFIG}-byron-genesis.json
wget -N https://hydra.iohk.io/build/${NODE_BUILD_NUM}/download/1/${NODE_CONFIG}-topology.json
wget -N https://hydra.iohk.io/build/${NODE_BUILD_NUM}/download/1/${NODE_CONFIG}-shelley-genesis.json
wget -N https://hydra.iohk.io/build/${NODE_BUILD_NUM}/download/1/${NODE_CONFIG}-alonzo-genesis.json
wget -N https://hydra.iohk.io/build/${NODE_BUILD_NUM}/download/1/${NODE_CONFIG}-config.json

sed -i ${NODE_CONFIG}-config.json -e "s/TraceBlockFetchDecisions\": false/TraceBlockFetchDecisions\": true/g"
sed -i ${NODE_CONFIG}-config.json -e "s/TraceMempool\": true/TraceMempool\": false/g"

CARDANO_NODE_SOCKET_PATH="$NODE_HOME/db/socket"
echo export CARDANO_NODE_SOCKET_PATH="$NODE_HOME/db/socket" >> $HOME/.bashrc
source $HOME/.bashrc

chown -R ubuntu:ubuntu $HOME/cardano-my-node
# sudo journalctl -u google-startup-scripts.service

# run blockchain to update data
cardano-node run --config ${NODE_HOME}/${NODE_CONFIG}-config.json --database-path ${NODE_HOME}/db --socket-path ${NODE_HOME}/db/socket --host-addr 127.0.0.1 --port 1337 --topology ${NODE_HOME}/${NODE_CONFIG}-topology.json