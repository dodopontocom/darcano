#!/usr/bin/env bash

export TELEGRAM_TOKEN=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/TELEGRAM_TOKEN)
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

sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y git jq bc make automake rsync htop curl \
    build-essential pkg-config libffi-dev libgmp-dev \
    libssl-dev libtinfo-dev libsystemd-dev zlib1g-dev \
    make g++ wget libncursesw5 libtool autoconf

curl -s -X POST https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage -d chat_id=${TELEGRAM_ID} -d text="${HOSTNAME} - apt upgrade done"