#!/usr/bin/env bash

DARCANO_TOKEN=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/DARCANO_TOKEN)
TELEGRAM_ID=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/TELEGRAM_ID)

cat > /home/ubuntu/darcano.sh << EOF
#!/usr/bin/env bash
DARCANO_TOKEN=\$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/DARCANO_TOKEN)
TELEGRAM_ID=\$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/TELEGRAM_ID)
API_GIT_URL="https://github.com/shellscriptx/shellbot.git"
tmp_folder=/home/ubuntu/shellBot

HOME=/home/ubuntu
NODE_HOME=\${HOME}/cardano-gcloud-node
NODE_CONFIG=testnet

helper.get_api() {
  echo "[INFO] ShellBot API - Getting the newest version"
  git clone \${API_GIT_URL} \${tmp_folder} > /dev/null

  echo "[INFO] Providing the API for the bot's project folder"
}

helper.save_relay() {
    local ip=\$1
    
    array=(\${ip})
    array[0]="/relay"
    ip=(\${array[@]:1})

    echo "\${ip}" > /home/ubuntu/relay_ip
    RN_NODE_EXTERNAL_IP=\$(cat /home/ubuntu/relay_ip)
    sed -i 's/RN_NODE_EXTERNAL_IP/'\${RN_NODE_EXTERNAL_IP}/ \${NODE_HOME}/\${NODE_CONFIG}-topology.json_
    mv \${NODE_HOME}/\${NODE_CONFIG}-topology.json_ \${NODE_HOME}/\${NODE_CONFIG}-topology.json
    sudo systemctl restart cardano-node.service
}

helper.get_api

source \${tmp_folder}/ShellBot.sh
ShellBot.init --token "\${DARCANO_TOKEN}" --monitor --flush

curl -s -X POST https://api.telegram.org/bot\${DARCANO_TOKEN}/sendMessage -d chat_id=\${TELEGRAM_ID} -d text="Bot is ready to receive ips"

while :
do
	ShellBot.getUpdates --limit 100 --offset \$(ShellBot.OffsetNext) --timeout 30

	for id in \$(ShellBot.ListUpdates)
	do
	(
        if [[ "\$(echo \${message_text[\$id]%%@*} | grep "^\/relay" )" ]]; then
		    helper.save_relay "\${message_text[\$id]}"
            ShellBot.sendMessage --chat_id \${message_chat_id[\$id]} --text "done, bye" --parse_mode markdown
        fi
        if [[ "\$(echo \${message_text[\$id]%%@*} | grep "^\/txsProcessedNum" )" ]]; then
		    message="Tx Processed: "
            message+=\$(curl 127.0.0.1:12798/metrics | grep -i cardano_node_metrics_txsProcessedNum)
            ShellBot.sendMessage --chat_id \${message_chat_id[\$id]} --text "\$(echo -e \${message})" --parse_mode markdown
        fi
        if [[ "\$(echo \${message_text[\$id]%%@*} | grep "^\/kill-darcano" )" ]]; then
            ShellBot.sendMessage --chat_id \${message_chat_id[\$id]} --text "done, bye" --parse_mode markdown
            sleep 2
            sudo systemctl stop darcano-bot
        fi
	) &
	done
done
EOF

cat > /home/ubuntu/darcano-bot.service << EOF 
# file: /etc/systemd/system/darcano-bot.service

[Unit]
Description     = Darcano Bot service
Wants           = network-online.target
After           = network-online.target 

[Service]
User            = ubuntu
Type            = simple
WorkingDirectory= /home/ubuntu
ExecStart       = /bin/bash -c '/home/ubuntu/darcano.sh'
KillSignal=SIGINT
RestartKillSignal=SIGINT
TimeoutStopSec=2
LimitNOFILE=32768
Restart=always
RestartSec=5
SyslogIdentifier=darcano-bot

[Install]
WantedBy	= multi-user.target
EOF

chown -R ubuntu:ubuntu /home/ubuntu

mv /home/ubuntu/darcano-bot.service /etc/systemd/system/darcano-bot.service
chmod 644 /etc/systemd/system/darcano-bot.service
chmod +x /home/ubuntu/darcano.sh
systemctl daemon-reload
systemctl enable darcano-bot
systemctl reload-or-restart darcano-bot
systemctl start darcano-bot

sleep 15
NODE_INTERNAL_IP=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/network-interfaces/0/ip)
curl -s -X POST https://api.telegram.org/bot${DARCANO_TOKEN}/sendMessage -d chat_id=${TELEGRAM_ID} -d text="/bp ${NODE_INTERNAL_IP}"

#curl -s -X POST https://api.telegram.org/bot${DARCANO_TOKEN}/sendMessage -d chat_id=${TELEGRAM_ID} -d text="You have 1 hour to send the ips..."
#sleep 3600
