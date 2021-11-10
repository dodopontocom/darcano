#!/usr/bin/env bash

export HOME=/home/ubuntu

DARLENE1_TOKEN=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/DARLENE1_TOKEN)
TELEGRAM_ID=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/TELEGRAM_ID)
curl -s -X POST https://api.telegram.org/bot${DARLENE1_TOKEN}/sendMessage -d chat_id=${TELEGRAM_ID} -d text="Topology updater..."

NODE_HOME=${HOME}/cardano-gcloud-node
NODE_CONFIG="testnet"

NODE_LOG_DIR="${NODE_HOME}/logs"
if [ ! -d ${NODE_LOG_DIR} ]; then
  mkdir -p ${NODE_LOG_DIR};
fi

NODE_EXTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)

cat > ${NODE_HOME}/topology-updater.sh << EOF
#!/usr/bin/env bash

USERNAME=ubuntu
CNODE_PORT=3001
CNODE_HOSTNAME="${NODE_EXTERNAL_IP}"
CNODE_BIN="/usr/local/bin"
CNODE_HOME="/home/ubuntu/cardano-gcloud-node"
NODE_CONFIG="testnet"
GENESIS_JSON="\${CNODE_HOME}/\${NODE_CONFIG}-shelley-genesis.json"
NETWORKID=\$(jq -r .networkId \${GENESIS_JSON})
CNODE_VALENCY=1
NWMAGIC=\$(jq -r .networkMagic < \${GENESIS_JSON})
[[ "\${NETWORKID}" = "Mainnet" ]] && HASH_IDENTIFIER="--mainnet" || HASH_IDENTIFIER="--testnet-magic \${NWMAGIC}"
[[ "\${NWMAGIC}" = "764824073" ]] && NETWORK_IDENTIFIER="--mainnet" || NETWORK_IDENTIFIER="--testnet-magic \${NWMAGIC}"
 
blockNo=\$(CARDANO_NODE_SOCKET_PATH="\${CNODE_HOME}/db/socket" /usr/local/bin/cardano-cli query tip \${NETWORK_IDENTIFIER} | jq -r .block)

T_HOSTNAME="&hostname=\${CNODE_HOSTNAME}"

curl -4 -s "https://api.clio.one/htopology/v1/?port=\${CNODE_PORT}&blockNo=\${blockNo}&valency=\${CNODE_VALENCY}&magic=\${NWMAGIC}\${T_HOSTNAME}"
EOF

chmod +x ${NODE_HOME}/topology-updater.sh
sudo chown -R ubuntu:ubuntu ${HOME}
#sudo systemctl daemon-reload
#sudo systemctl enable cardano-node
#sudo systemctl reload-or-restart cardano-node
#sudo systemctl start cardano-node

message=$(uptime -p)
curl -s -X POST https://api.telegram.org/bot${DARLENE1_TOKEN}/sendMessage -d chat_id=${TELEGRAM_ID} -d text="${HOSTNAME} - ${message}"

while [[ $(cat ${NODE_HOME}/logs/topology-updater_lastresult.json | grep "glad you're staying with us" | wc -l) -lt 4 ]]; do
    message="Topology Updater counter: "
    message+=$(cat ${NODE_HOME}/logs/topology-updater_lastresult.json | grep "glad you're staying with us" | wc -l)
    curl -s -X POST https://api.telegram.org/bot${DARLENE1_TOKEN}/sendMessage -d chat_id=${TELEGRAM_ID} -d text="${message}"
    sleep 1200
done

message=$(uptime -p)
curl -s -X POST https://api.telegram.org/bot${DARLENE1_TOKEN}/sendMessage -d chat_id=${TELEGRAM_ID} -d text="${HOSTNAME} - ${message}"

BP_NODE_INTERNAL_IP=$(cat ${HOME}/bp_ip)
BLOCKPRODUCING_PORT=3000
curl -4 -s -o ${NODE_HOME}/testnet-topology.json_script "https://api.clio.one/htopology/v1/fetch/?max=20&magic=1097911063&customPeers=${BP_NODE_INTERNAL_IP}:${BLOCKPRODUCING_PORT}:2|relays-new.cardano-testnet.iohkdev.io:3001:2"

mv ${NODE_HOME}/testnet-topology.json ${NODE_HOME}/testnet-topology.json_bkp
mv ${NODE_HOME}/testnet-topology.json_script ${NODE_HOME}/testnet-topology.json

#sed -i '2 i\ \ { "addr": "'${BP_NODE_INTERNAL_IP}'", "port": 3000, "valency": 2 } ,' ${NODE_HOME}/${NODE_CONFIG}-topology.json
#sed -i 's/BP_NODE_INTERNAL_IP/'${BP_NODE_INTERNAL_IP}/ ${NODE_HOME}/${NODE_CONFIG}-topology.json
#sed -i 's/\"port\": 3000, \"valency\": 1/\"port\": 3000, \"valency\": 2/' ${NODE_HOME}/${NODE_CONFIG}-topology.json
sudo systemctl restart cardano-node.service

curl -s -X POST https://api.telegram.org/bot${DARLENE1_TOKEN}/sendMessage -d chat_id=${TELEGRAM_ID} -d text="/txsProcessedNum"

sudo chown -R ubuntu:ubuntu ${HOME}