#!/usr/bin/env bash

export HOME=/root
export BOOTSTRAP_HASKELL_NONINTERACTIVE=true

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

#
cd $HOME
curl --proto '=https' --tlsv1.2 -sSf -o ghcup.sh https://get-ghcup.haskell.org
chmod +x ghcup.sh
./ghcup.sh

.ghcup/bin/ghcup upgrade
.ghcup/bin/ghcup install cabal 3.4.0.0
.ghcup/bin/ghcup set cabal 3.4.0.0
