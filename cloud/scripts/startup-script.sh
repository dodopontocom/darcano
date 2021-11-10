#!/usr/bin/env bash

# this is the startup script sequencer

bash <(curl -s https://raw.githubusercontent.com/dodopontocom/darcano/terraforming-v0.6/cloud/scripts/000-pre-step.sh)
bash <(curl -s https://raw.githubusercontent.com/dodopontocom/darcano/terraforming-v0.6/cloud/scripts/001-cardano-setup.sh)
if [[ $(echo ${HOSTNAME} | grep relaynode) ]]; then
    bash <(curl -s https://raw.githubusercontent.com/dodopontocom/darcano/terraforming-v0.6/cloud/scripts/002-00-darlene1.sh)
fi
if [[ $(echo ${HOSTNAME} | grep blockproducer) ]]; then
    bash <(curl -s https://raw.githubusercontent.com/dodopontocom/darcano/terraforming-v0.6/cloud/scripts/002-01-darcano.sh)
fi
if [[ $(echo ${HOSTNAME} | grep relaynode) ]]; then
    bash <(curl -s https://raw.githubusercontent.com/dodopontocom/darcano/terraforming-v0.6/cloud/scripts/003-registering-pool.sh)
    bash <(curl -s https://raw.githubusercontent.com/dodopontocom/darcano/terraforming-v0.6/cloud/scripts/004-topology-updater.sh)
fi
