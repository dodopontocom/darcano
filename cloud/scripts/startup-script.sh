#!/usr/bin/env bash

bash <(curl -s https://raw.githubusercontent.com/dodopontocom/darcano/terraforming/cloud/scripts/000-pre-step.sh)
bash <(curl -s https://raw.githubusercontent.com/dodopontocom/darcano/terraforming/cloud/scripts/001-telegram-watcher.sh)
bash <(curl -s https://raw.githubusercontent.com/dodopontocom/darcano/terraforming/cloud/scripts/002-cardano-setup.sh)