#!/usr/bin/env bash

COLD_PAY_SKEY=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/COLD_PAY_SKEY)
COLD_NODE_SKEY=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/COLD_NODE_SKEY)
COLD_STAKE_SKEY=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/COLD_STAKE_SKEY)
VRF_VKEY=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/VRF_VKEY)
COLD_NODE_VKEY=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/COLD_NODE_VKEY)
COLD_STAKE_VKEY=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/COLD_STAKE_VKEY)
COLD_PAY_ADDR=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/COLD_PAY_ADDR)
POOL_METADATA_HASH=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/POOL_METADATA_HASH)
COLD_STAKE_ADDR=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/COLD_STAKE_ADDR)

USERNAME=ubuntu
CNODE_HOME="/home/ubuntu/cardano-gcloud-node"
NODE_CONFIG="testnet"
GENESIS_JSON="${CNODE_HOME}/${NODE_CONFIG}-shelley-genesis.json"
NETWORKID=$(jq -r .networkId ${GENESIS_JSON})
NWMAGIC=$(jq -r .networkMagic < ${GENESIS_JSON})
[[ "${NETWORKID}" = "Mainnet" ]] && HASH_IDENTIFIER="--mainnet" || HASH_IDENTIFIER="--testnet-magic ${NWMAGIC}"
[[ "${NWMAGIC}" = "764824073" ]] && NETWORK_IDENTIFIER="--mainnet" || NETWORK_IDENTIFIER="--testnet-magic ${NWMAGIC}"

echo $NETWORK_IDENTIFIER

currentSlot=""
currentSlot=$(CARDANO_NODE_SOCKET_PATH="${CNODE_HOME}/db/socket" /usr/local/bin/cardano-cli query tip ${NETWORK_IDENTIFIER} | jq -r .block)

echo currentSlot: $currentSlot

rewardBalance=$(CARDANO_NODE_SOCKET_PATH="${CNODE_HOME}/db/socket" /usr/local/bin/cardano-cli query stake-address-info ${NETWORK_IDENTIFIER} --address ${COLD_STAKE_ADDR} | jq -r ".[0].rewardAccountBalance")
echo "rewardBalance: ${rewardBalance}"

if [[ ${rewardBalance} -ne 0 ]]; then

    destinationAddress=${COLD_PAY_ADDR}
    echo destinationAddress: $destinationAddress
    CARDANO_NODE_SOCKET_PATH="${CNODE_HOME}/db/socket" /usr/local/bin/cardano-cli query utxo --address ${COLD_PAY_ADDR} ${NETWORK_IDENTIFIER} > fullUtxo.out
    tail -n +3 fullUtxo.out | sort -k3 -nr > balance.out
    cat balance.out
    
    tx_in=""
    total_balance=0
    while read -r utxo; do
        in_addr=$(awk '{ print $1 }' <<< "${utxo}")
        idx=$(awk '{ print $2 }' <<< "${utxo}")
        utxo_balance=$(awk '{ print $3 }' <<< "${utxo}")
        total_balance=$((${total_balance}+${utxo_balance}))
        echo TxHash: ${in_addr}#${idx}
        echo ADA: ${utxo_balance}
        tx_in="${tx_in} --tx-in ${in_addr}#${idx}"
    done < balance.out
    
    txcnt=$(cat balance.out | wc -l)
    echo Total ADA balance: ${total_balance}
    echo Number of UTXOs: ${txcnt}

    withdrawalString="${COLD_STAKE_ADDR}+${rewardBalance}"
    echo withdrawalString: $withdrawalString

    CARDANO_NODE_SOCKET_PATH="${CNODE_HOME}/db/socket" /usr/local/bin/cardano-cli transaction build-raw \
        ${tx_in} \
        --tx-out ${COLD_PAY_ADDR}+0 \
        --invalid-hereafter 99999999 \
        --fee 0 \
        --withdrawal ${withdrawalString} \
        --out-file tx.tmp

    echo txcnt: ${txcnt}
    
    CARDANO_NODE_SOCKET_PATH="${CNODE_HOME}/db/socket" /usr/local/bin/cardano-cli query protocol-parameters ${NETWORK_IDENTIFIER} --out-file params.json
    fee=$(CARDANO_NODE_SOCKET_PATH="${CNODE_HOME}/db/socket" /usr/local/bin/cardano-cli transaction calculate-min-fee \
        --tx-body-file tx.tmp \
        --tx-in-count ${txcnt} \
        --tx-out-count 1 \
        ${NETWORK_IDENTIFIER} \
        --witness-count 2 \
        --byron-witness-count 0 \
        --protocol-params-file params.json | awk '{ print $1 }')
    echo fee: $fee

    txOut=$((${total_balance}-${fee}+${rewardBalance}))
    echo Change Output: ${txOut}

    echo tx_in: $tx_in
    CARDANO_NODE_SOCKET_PATH="${CNODE_HOME}/db/socket" /usr/local/bin/cardano-cli transaction build-raw \
        ${tx_in} \
        --tx-out ${COLD_PAY_ADDR}+${txOut} \
        --invalid-hereafter 99999999 \
        --fee ${fee} \
        --withdrawal ${withdrawalString} \
        --out-file tx.raw

    echo ${COLD_PAY_SKEY} > gcloud.skey
    echo ${COLD_STAKE_SKEY} > stake.skey

    CARDANO_NODE_SOCKET_PATH="${CNODE_HOME}/db/socket" /usr/local/bin/cardano-cli transaction sign \
        --tx-body-file tx.raw \
        --signing-key-file gcloud.skey \
        --signing-key-file stake.skey \
        ${NETWORK_IDENTIFIER} \
        --out-file tx.signed

    CARDANO_NODE_SOCKET_PATH="${CNODE_HOME}/db/socket" /usr/local/bin/cardano-cli transaction submit --tx-file tx.signed ${NETWORK_IDENTIFIER}

else
    echo "rewardBalance: ${rewardBalance}"
fi