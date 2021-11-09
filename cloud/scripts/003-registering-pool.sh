#!/usr/bin/env bash

export HOME=/home/ubuntu

DARLENE1_TOKEN=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/DARLENE1_TOKEN)
TELEGRAM_ID=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/TELEGRAM_ID)
curl -s -X POST https://api.telegram.org/bot${DARLENE1_TOKEN}/sendMessage -d chat_id=${TELEGRAM_ID} -d text="Pool registration started..."

COLD_PAY_SKEY=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/COLD_PAY_SKEY)
COLD_NODE_SKEY=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/COLD_NODE_SKEY)
COLD_STAKE_SKEY=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/COLD_STAKE_SKEY)
VRF_VKEY=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/VRF_VKEY)
COLD_NODE_VKEY=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/COLD_NODE_VKEY)
COLD_STAKE_VKEY=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/COLD_STAKE_VKEY)
COLD_PAY_ADDR=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/COLD_PAY_ADDR)
POOL_METADATA_HASH=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/POOL_METADATA_HASH)

NODE_EXTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)

NODE_HOME="${HOME}/cardano-gcloud-node"
NODE_CONFIG="testnet"
nwmagic="$(cat ${NODE_HOME}/${NODE_CONFIG}-shelley-genesis.json | jq -r .networkMagic)"
nwmagic_arg="testnet-magic ${nwmagic}"

export CARDANO_NODE_SOCKET_PATH="${NODE_HOME}/db/socket"
cardano-cli query protocol-parameters --${nwmagic_arg} --out-file ${NODE_HOME}/protocol.json

stakePoolDeposit=$(cat ${NODE_HOME}/protocol.json | jq -r '.stakePoolDeposit')
echo "stakePoolDeposit: ${stakePoolDeposit}"

echo ${VRF_VKEY} > ${NODE_HOME}/vrf.vkey
echo ${COLD_NODE_VKEY} > ${NODE_HOME}/node.vkey
echo ${COLD_STAKE_VKEY} > ${NODE_HOME}/stake.vkey

cardano-cli stake-pool registration-certificate \
    --cold-verification-key-file ${NODE_HOME}/node.vkey \
    --vrf-verification-key-file ${NODE_HOME}/vrf.vkey \
    --pool-pledge 1000000 \
    --pool-cost 350000000 \
    --pool-margin 0 \
    --pool-reward-account-verification-key-file ${NODE_HOME}/stake.vkey \
    --pool-owner-stake-verification-key-file ${NODE_HOME}/stake.vkey \
    --${nwmagic_arg} \
    --pool-relay-ipv4 ${NODE_EXTERNAL_IP} \
    --pool-relay-port 3001 \
    --metadata-url https://bit.ly/3zIdc1a \
    --metadata-hash ${POOL_METADATA_HASH} \
    --out-file ${NODE_HOME}/pool.cert

cardano-cli stake-address delegation-certificate \
    --stake-verification-key-file ${NODE_HOME}/stake.vkey \
    --cold-verification-key-file ${NODE_HOME}/node.vkey \
    --out-file ${NODE_HOME}/deleg.cert

cardano-cli query utxo \
    --address ${COLD_PAY_ADDR} \
    --${nwmagic_arg} | tail -n +3 | sort -k3 -nr > ${NODE_HOME}/balance.out

cat ${NODE_HOME}/balance.out

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
done < ${NODE_HOME}/balance.out
txcnt=$(cat ${NODE_HOME}/balance.out | wc -l)
echo "Total ADA balance: ${total_balance}"
echo "Number of UTXOs: ${txcnt}"

currentSlot=$(cardano-cli query tip --${nwmagic_arg} | jq -r '.slot')
echo "Current Slot: ${currentSlot}"

##
## If first time then use deposit
## if updating only then remove deposit reference
##
#--tx-out ${COLD_PAY_ADDR}+$(( ${total_balance} - ${stakePoolDeposit})) \
cardano-cli transaction build-raw \
    ${tx_in} \
    --tx-out ${COLD_PAY_ADDR}+${total_balance} \
    --invalid-hereafter $(( ${currentSlot} + 10000)) \
    --fee 0 \
    --certificate-file ${NODE_HOME}/pool.cert \
    --certificate-file ${NODE_HOME}/deleg.cert \
    --out-file ${NODE_HOME}/tx.tmp

fee=$(cardano-cli transaction calculate-min-fee \
    --tx-body-file ${NODE_HOME}/tx.tmp \
    --tx-in-count ${txcnt} \
    --tx-out-count 1 \
    --${nwmagic_arg} \
    --witness-count 3 \
    --byron-witness-count 0 \
    --protocol-params-file ${NODE_HOME}/protocol.json | awk '{ print $1 }')
echo "fee: ${fee}"

#txOut=$((${total_balance}-${stakePoolDeposit}-${fee}))
txOut=$((${total_balance}-${fee}))
echo "Change Output: ${txOut}"

cardano-cli transaction build-raw \
    ${tx_in} \
    --tx-out ${COLD_PAY_ADDR}+${txOut} \
    --invalid-hereafter $(( ${currentSlot} + 10000)) \
    --fee ${fee} \
    --certificate-file ${NODE_HOME}/pool.cert \
    --certificate-file ${NODE_HOME}/deleg.cert \
    --out-file ${NODE_HOME}/tx.raw

echo ${COLD_PAY_SKEY} > ${NODE_HOME}/gcloud.skey
echo ${COLD_NODE_SKEY} > ${NODE_HOME}/node.skey
echo ${COLD_STAKE_SKEY} > ${NODE_HOME}/stake.skey

cardano-cli transaction sign \
    --tx-body-file ${NODE_HOME}/tx.raw \
    --signing-key-file ${NODE_HOME}/gcloud.skey \
    --signing-key-file ${NODE_HOME}/node.skey \
    --signing-key-file ${NODE_HOME}/stake.skey \
    --${nwmagic_arg} \
    --out-file ${NODE_HOME}/tx.signed

cardano-cli transaction submit --tx-file ${NODE_HOME}/tx.signed --${nwmagic_arg}
if [[ "$?" -eq "0" ]]; then
    curl -s -X POST https://api.telegram.org/bot${DARLENE1_TOKEN}/sendMessage -d chat_id=${TELEGRAM_ID} -d text="Pool registration done..."
    else
        curl -s -X POST https://api.telegram.org/bot${DARLENE1_TOKEN}/sendMessage -d chat_id=${TELEGRAM_ID} -d text="Pool registration failed for some reason..."
fi
rm -f ${NODE_HOME}/gcloud.skey ${NODE_HOME}/node.skey ${NODE_HOME}/stake.skey
