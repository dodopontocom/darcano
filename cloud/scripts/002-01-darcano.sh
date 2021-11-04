#!/usr/bin/env bash

#TODO: make it as daemon systemd!

DARCANO_TOKEN=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/DARCANO_TOKEN)
TELEGRAM_ID=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/TELEGRAM_ID)
API_GIT_URL="https://github.com/shellscriptx/shellbot.git"
tmp_folder=$(mktemp -d)

helper.get_api() {
  echo "[INFO] ShellBot API - Getting the newest version"
  git clone ${API_GIT_URL} ${tmp_folder} > /dev/null

  echo "[INFO] Providing the API for the bot's project folder"
}

helper.save_relay() {
    local ip=$1
    
    array=(${ip})
    array[0]="/relay"
    ip=(${array[@]:1})

    echo "${ip}" > /home/ubuntu/relay_ip
}

helper.get_api

source ${tmp_folder}/ShellBot.sh
ShellBot.init --token "${DARCANO_TOKEN}" --monitor --flush

curl -s -X POST https://api.telegram.org/bot${DARCANO_TOKEN}/sendMessage -d chat_id=${TELEGRAM_ID} -d text="Bot is ready to receive ips"

while :
do
	ShellBot.getUpdates --limit 100 --offset $(ShellBot.OffsetNext) --timeout 30

	for id in $(ShellBot.ListUpdates)
	do
	(
        if [[ "$(echo ${message_text[$id]%%@*} | grep "^\/relay" )" ]]; then
		    helper.save_bp "${message_text[$id]}"
            ShellBot.sendMessage --chat_id ${message_chat_id[$id]} --text "done" --parse_mode markdown
        fi
        if [[ "$(echo ${message_text[$id]%%@*} | grep "^\/kill-darcano" )" ]]; then
            ShellBot.sendMessage --chat_id ${message_chat_id[$id]} --text "done, by" --parse_mode markdown
            sleep 2
            kill $$
        fi
	) &
	done
done