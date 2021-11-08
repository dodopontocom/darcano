#!/usr/bin/env bash

DARLENE1_TOKEN=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/DARLENE1_TOKEN)
TELEGRAM_ID=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/TELEGRAM_ID)

cat > /home/ubuntu/darlene1.sh << EOF
#!/usr/bin/env bash

DARLENE1_TOKEN=\$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/attributes/DARLENE1_TOKEN)
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

helper.save_bp() {
    local ip=\$1
    
    array=(\${ip})
    array[0]="/bp"
    ip=(\${array[@]:1})

    echo "\${ip}" > /home/ubuntu/bp_ip
    BP_NODE_INTERNAL_IP=\$(cat /home/ubuntu/bp_ip)
    sed -i 's/BP_NODE_INTERNAL_IP/'\${BP_NODE_INTERNAL_IP}/ \${NODE_HOME}/\${NODE_CONFIG}-topology.json_
    mv \${NODE_HOME}/\${NODE_CONFIG}-topology.json_ \${NODE_HOME}/\${NODE_CONFIG}-topology.json
    sudo systemctl restart cardano-node.service
}

helper.get_api

source \${tmp_folder}/ShellBot.sh
ShellBot.init --token "\${DARLENE1_TOKEN}" --monitor --flush

curl -s -X POST https://api.telegram.org/bot\${DARLENE1_TOKEN}/sendMessage -d chat_id=\${TELEGRAM_ID} -d text="Bot is ready to receive ips"

while :
do
	ShellBot.getUpdates --limit 100 --offset \$(ShellBot.OffsetNext) --timeout 30

	for id in \$(ShellBot.ListUpdates)
	do
	(
        if [[ "\$(echo \${message_text[\$id]%%@*} | grep "^\/bp" )" ]]; then
            helper.save_bp "\${message_text[\$id]}"
            ShellBot.sendMessage --chat_id \${message_chat_id[\$id]} --text "ok, bye" --parse_mode markdown
        fi
        if [[ "\$(echo \${message_text[\$id]%%@*} | grep "^\/kill-darlene1" )" ]]; then
            ShellBot.sendMessage --chat_id \${message_chat_id[\$id]} --text "ok, bye" --parse_mode markdown
            sleep 2
            sudo systemctl stop darlene1-bot
        fi
	) &
	done
done
EOF

cat > /home/ubuntu/darlene1-bot.service << EOF 
# file: /etc/systemd/system/darlene1-bot.service

[Unit]
Description     = Darlene1 Bot service
Wants           = network-online.target
After           = network-online.target 

[Service]
User            = ubuntu
Type            = simple
WorkingDirectory= /home/ubuntu
ExecStart       = /bin/bash -c '/home/ubuntu/darlene1.sh'
KillSignal=SIGINT
RestartKillSignal=SIGINT
TimeoutStopSec=2
LimitNOFILE=32768
Restart=always
RestartSec=5
SyslogIdentifier=darlene1-bot

[Install]
WantedBy	= multi-user.target
EOF

chown -R ubuntu:ubuntu /home/ubuntu

mv /home/ubuntu/darlene1-bot.service /etc/systemd/system/darlene1-bot.service
chmod 644 /etc/systemd/system/darlene1-bot.service
chmod +x /home/ubuntu/darlene1.sh
systemctl daemon-reload
systemctl enable darlene1-bot
systemctl reload-or-restart darlene1-bot
systemctl start darlene1-bot

sleep 15
NODE_EXTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)
curl -s -X POST https://api.telegram.org/bot${DARLENE1_TOKEN}/sendMessage -d chat_id=${TELEGRAM_ID} -d text="/relay ${NODE_EXTERNAL_IP}"