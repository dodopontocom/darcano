#!/usr/bin/env bash

BASEDIR="$(cd $(dirname ${BASH_SOURCE[0]}) >/dev/null 2>&1 && pwd)"
echo "--- ${BASEDIR}"

API_GIT_URL="https://github.com/shellscriptx/shellbot.git"
tmp_folder=$(mktemp -d)

helper.get_api() {
  echo "[INFO] ShellBot API - Getting the newest version"
  git clone ${API_GIT_URL} ${tmp_folder} > /dev/null

  echo "[INFO] Providing the API for the bot's project folder"
  #cp ${tmp_folder}/ShellBot.sh ${BASEDIR}/
  #rm -fr ${tmp_folder}
}

helper.save_relay() {
    local ip=$1
    
    array=(${ip})
    array[0]="/relay"
    ip=(${array[@]:1})

    echo "${ip}" > /home/ubuntu/relay_ip
    echo "${ip}" > /tmp/relay_ip
}

helper.save_bp() {
    local ip=$1
    
    array=(${ip})
    array[0]="/bp"
    ip=(${array[@]:1})

    echo "${ip}" > /home/ubuntu/bp_ip
    echo "${ip}" > /tmp/bp_ip
}

helper.get_api

source ${tmp_folder}/ShellBot.sh
ShellBot.init --token "${TELEGRAM_TOKEN}" --monitor --flush

while :
do
	ShellBot.getUpdates --limit 100 --offset $(ShellBot.OffsetNext) --timeout 30

	for id in $(ShellBot.ListUpdates)
	do
	(
        if [[ "$(echo ${message_text[$id]%%@*} | grep "^\/relay" )" ]]; then
		    echo ${HOSTNAME} | grep blockproducer
            if [[ $? -eq 0 ]]; then
                helper.save_relay "${message_text[$id]}"
                ShellBot.sendMessage --chat_id ${message_chat_id[$id]} --text "done" --parse_mode markdown
                kill $$
            fi
        fi
        if [[ "$(echo ${message_text[$id]%%@*} | grep "^\/bp" )" ]]; then
		    echo ${HOSTNAME} | grep relaynode
            if [[ $? -eq 0 ]]; then
                helper.save_bp "${message_text[$id]}"
                ShellBot.sendMessage --chat_id ${message_chat_id[$id]} --text "done" --parse_mode markdown
                kill $$
            fi
        fi
	) &
	done
done