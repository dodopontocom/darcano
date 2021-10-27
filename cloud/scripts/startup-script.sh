#!/usr/bin/env bash
# run at startup
# 
bash <(curl -s https://raw.githubusercontent.com/dodopontocom/darcano/terraforming/cloud/scripts/000-pre-step.sh)
bash <(curl -s https://raw.githubusercontent.com/dodopontocom/darcano/terraforming/cloud/scripts/001-cardano-setup.sh)
bash <(curl -s https://raw.githubusercontent.com/dodopontocom/darcano/terraforming/cloud/scripts/002-telegram-watcher.sh)