#!/usr/bin/env bash

export HOME=/root
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

# as NOINTERACTIVE is activated we have to use full path when calling the apps
$HOME/.ghcup/bin/ghcup upgrade
$HOME/.ghcup/bin/ghcup install cabal 3.4.0.0
$HOME/.ghcup/bin/ghcup set cabal 3.4.0.0
###

$HOME/.ghcup/bin/ghcup install ghc 8.10.7
$HOME/.ghcup/bin/ghcup set ghc 8.10.7

echo "path: ${PATH}"

echo PATH="$HOME/.local/bin:$PATH" >> $HOME/.bashrc
echo export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH" >> $HOME/.bashrc
echo export NODE_HOME=$HOME/cardano-my-node >> $HOME/.bashrc
echo export NODE_CONFIG=mainnet>> $HOME/.bashrc
echo export NODE_BUILD_NUM=$(curl https://hydra.iohk.io/job/Cardano/iohk-nix/cardano-deployment/latest-finished/download/1/index.html | grep -e "build" | sed 's/.*build\/\([0-9]*\)\/download.*/\1/g') >> $HOME/.bashrc
source $HOME/.bashrc

echo export NODE_CONFIG=testnet>> $HOME/.bashrc
source $HOME/.bashrc

# --testnet-magic 1097911063

.ghcup/bin/cabal update
.ghcup/bin/cabal --version
.ghcup/bin/ghc --version

cd $HOME/git
git clone https://github.com/input-output-hk/cardano-node.git
cd cardano-node
git fetch --all --recurse-submodules --tags
git checkout tags/${CARDANO_NODE_TAG}

$HOME/.ghcup/bin/cabal configure -O0 -w ghc-8.10.7

#echo -e "package cardano-crypto-praos\n flags: -external-libsodium-vrf" > cabal.project.local
#sed -i $HOME/.cabal/config -e "s/overwrite-policy:/overwrite-policy: always/g"
#rm -rf $HOME/git/cardano-node/dist-newstyle/build/x86_64-linux/ghc-8.10.7

$HOME/.ghcup/bin/cabal build cardano-cli cardano-node
