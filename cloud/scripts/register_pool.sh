#!/usr/bin/env bash

#DARLENE1_TOKEN=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/DARLENE1_TOKEN)
#TELEGRAM_ID=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/TELEGRAM_ID)
#curl -s -X POST https://api.telegram.org/bot\${DARLENE1_TOKEN}/sendMessage -d chat_id=\${TELEGRAM_ID} -d text="Pool registration started..."

#COLD_PAY_SKEY=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/COLD_PAY_SKEY)
#COLD_NODE_SKEY=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/COLD_NODE_SKEY)
#COLD_STAKE_SKEY=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/COLD_STAKE_SKEY)
#VRF_VKEY=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/VRF_VKEY)
#COLD_NODE_VKEY=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/COLD_NODE_VKEY)
#COLD_STAKE_VKEY=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/COLD_STAKE_VKEY)
#POOL_METADATA_HASH=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/POOL_METADATA_HASH)
POOL_METADATA_HASH="5072f2001e5c97e70e8ff7c10c2094fe2e3801f10dacdcdcb2f593460a24aa60"

#NODE_EXTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)
NODE_EXTERNAL_IP="35.225.200.106"

payment_addr="addr_test1qrtf2xm92vx26xr8v7wl0cx4gmv4shkrnm7yjsj2r4x0f2jvhapq0990h875y9cnzma9xu6g8068u87s259n3nt7cacq7gw8xj"
destina_addr=""
node_home="/home/ubuntu/cardano/cardano-src/cardano-node"
nwmagic="$(cat ${node_home}/testnet-shelley-genesis.json | jq -r .networkMagic)"
certs_path="/home/ubuntu/git/keys_bkp/keys/"
relay_check="/home/ubuntu/bp_ip"

nwmagic_arg="testnet-magic ${nwmagic}"

stakePoolDeposit=$(cat ${node_home}/protocol.json | jq -r '.stakePoolDeposit')
echo stakePoolDeposit: $stakePoolDeposit

echo ${VRF_VKEY} > vrf.vkey
echo ${COLD_NODE_VKEY} > node.vkey
echo ${COLD_STAKE_VKEY} > stake.vkey

cardano-cli stake-pool registration-certificate \
    --cold-verification-key-file node.vkey \
    --vrf-verification-key-file vrf.vkey \
    --pool-pledge 1000000 \
    --pool-cost 350000000 \
    --pool-margin 0 \
    --pool-reward-account-verification-key-file stake.vkey \
    --pool-owner-stake-verification-key-file stake.vkey \
    --${nwmagic_arg} \
    --pool-relay-ipv4 ${NODE_EXTERNAL_IP} \
    --pool-relay-port 3001 \
    --metadata-url https://bit.ly/3zIdc1a \
    --metadata-hash ${POOL_METADATA_HASH} \
    --out-file pool.cert

cardano-cli stake-address delegation-certificate \
    --stake-verification-key-file stake.vkey \
    --cold-verification-key-file node.vkey \
    --out-file deleg.cert

cardano-cli query utxo \
    --address ${payment_addr} \
    --${nwmagic_arg} | tail -n +3 | sort -k3 -nr > balance.out

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

currentSlot=$(cardano-cli query tip --${nwmagic_arg} | jq -r '.slot')
echo Current Slot: $currentSlot

##
## If first time then use deposit
## if updating only then remove deposit reference
##
#--tx-out ${payment_addr}+$(( ${total_balance} - ${stakePoolDeposit})) \
cardano-cli transaction build-raw \
    ${tx_in} \
    --tx-out ${payment_addr}+${total_balance} \
    --invalid-hereafter $(( ${currentSlot} + 10000)) \
    --fee 0 \
    --certificate-file pool.cert \
    --certificate-file deleg.cert \
    --out-file tx.tmp

fee=$(cardano-cli transaction calculate-min-fee \
    --tx-body-file tx.tmp \
    --tx-in-count ${txcnt} \
    --tx-out-count 1 \
    --${nwmagic_arg} \
    --witness-count 3 \
    --byron-witness-count 0 \
    --protocol-params-file ${node_home}/protocol.json | awk '{ print $1 }')
echo fee: $fee

#txOut=$((${total_balance}-${stakePoolDeposit}-${fee}))
txOut=$((${total_balance}-${fee}))
echo Change Output: ${txOut}

cardano-cli transaction build-raw \
    ${tx_in} \
    --tx-out ${payment_addr}+${txOut} \
    --invalid-hereafter $(( ${currentSlot} + 10000)) \
    --fee ${fee} \
    --certificate-file pool.cert \
    --certificate-file deleg.cert \
    --out-file tx.raw

echo ${COLD_PAY_SKEY} > gcloud.skey
echo ${COLD_NODE_SKEY} > node.skey
echo ${COLD_STAKE_SKEY} > stake.skey

cardano-cli transaction sign \
    --tx-body-file tx.raw \
    --signing-key-file gcloud.skey \
    --signing-key-file node.skey \
    --signing-key-file stake.skey \
    --${nwmagic_arg} \
    --out-file tx.signed

cardano-cli transaction submit --tx-file tx.signed --${nwmagic_arg}
#if [[ "$?" -eq "0" ]]; then
#    curl -s -X POST https://api.telegram.org/bot\${DARLENE1_TOKEN}/sendMessage -d chat_id=\${TELEGRAM_ID} -d text="Pool registration done..."
#    else
#    curl -s -X POST https://api.telegram.org/bot\${DARLENE1_TOKEN}/sendMessage -d chat_id=\${TELEGRAM_ID} -d text="Pool registration failed for some reason..."
#
#fi
#rm -f gcloud.skey node.skey stake.skey
