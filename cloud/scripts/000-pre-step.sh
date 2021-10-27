#!/usr/bin/env bash

TELEGRAM_TOKEN=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/TELEGRAM_TOKEN)
curl -s -X POST https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage -d chat_id=${TELEGRAM_ID} -d text="Hello from ${HOSTNAME}"

sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y git jq bc make automake rsync htop curl \
    build-essential pkg-config libffi-dev libgmp-dev \
    libssl-dev libtinfo-dev libsystemd-dev zlib1g-dev \
    make g++ wget libncursesw5 libtool autoconf

curl -s -X POST https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage -d chat_id=${TELEGRAM_ID} -d text="${HOSTNAME} - apt upgrade done"