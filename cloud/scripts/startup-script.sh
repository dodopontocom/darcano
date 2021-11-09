#!/usr/bin/env bash

bash <(curl -s https://raw.githubusercontent.com/dodopontocom/darcano/terraforming-v0.6/cloud/scripts/000-pre-step.sh)
bash <(curl -s https://raw.githubusercontent.com/dodopontocom/darcano/terraforming-v0.6/cloud/scripts/001-cardano-setup.sh)
echo ${HOSTNAME} | grep relaynode && \
    bash <(curl -s https://raw.githubusercontent.com/dodopontocom/darcano/terraforming-v0.6/cloud/scripts/002-00-darlene1.sh)
echo ${HOSTNAME} | grep blockproducer && \
    bash <(curl -s https://raw.githubusercontent.com/dodopontocom/darcano/terraforming-v0.6/cloud/scripts/002-01-darcano.sh)
echo ${HOSTNAME} | grep relaynode && \
    bash <(curl -s https://raw.githubusercontent.com/dodopontocom/darcano/terraforming-v0.6/cloud/scripts/003-registering-pool.sh)
echo ${HOSTNAME} | grep relaynode && \    
    bash <(curl -s https://raw.githubusercontent.com/dodopontocom/darcano/terraforming-v0.6/cloud/scripts/004-topology-updater.sh)
