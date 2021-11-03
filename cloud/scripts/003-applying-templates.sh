#!/usr/bin/env bash

##############################################################################
############# Applying templates #############
##############################################################################

TELEGRAM_TOKEN=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/TELEGRAM_TOKEN)
TELEGRAM_ID=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/TELEGRAM_ID)
curl -s -X POST https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage -d chat_id=${TELEGRAM_ID} -d text="${HOSTNAME} - Applying templates"

HOME=/home/ubuntu
NODE_HOME=${HOME}/cardano-gcloud-node
NODE_CONFIG=testnet
BP_IP=${NODE_HOME}/bp_ip
RELAY_IP=${NODE_HOME}/relay_ip

if [[ ${RELAY_IP} ]]; then
    RN_NODE_EXTERNAL_IP=$(cat ${RELAY_IP})
    mv ${NODE_HOME}/${NODE_CONFIG}-topology.json ${NODE_HOME}/${NODE_CONFIG}-topology.json_bkp
    cat ${NODE_HOME}/${NODE_CONFIG}-topology.json_  | sed 's/RN_NODE_EXTERNAL_IP/'${RN_NODE_EXTERNAL_IP}/ > ${NODE_HOME}/${NODE_CONFIG}-topology.json
    systemctl restart cardano-node && \
        curl -s -X POST https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage -d chat_id=${TELEGRAM_ID} -d text="${HOSTNAME} - Node restarting..." || \
        curl -s -X POST https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage -d chat_id=${TELEGRAM_ID} -d text="${HOSTNAME} - Node could not restart..."
fi

if [[ ${BP_IP} ]]; then
    BP_NODE_INTERNAL_IP=$(cat ${BP_IP})
    mv ${NODE_HOME}/${NODE_CONFIG}-topology.json ${NODE_HOME}/${NODE_CONFIG}-topology.json_bkp
    cat ${NODE_HOME}/${NODE_CONFIG}-topology.json_  | sed 's/BP_NODE_INTERNAL_IP/'${BP_NODE_INTERNAL_IP}/ > ${NODE_HOME}/${NODE_CONFIG}-topology.json
    systemctl restart cardano-node && \
        curl -s -X POST https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage -d chat_id=${TELEGRAM_ID} -d text="${HOSTNAME} - Node restarting..." || \
        curl -s -X POST https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage -d chat_id=${TELEGRAM_ID} -d text="${HOSTNAME} - Node could not restart..."
fi