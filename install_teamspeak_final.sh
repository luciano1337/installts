
#!/bin/bash

set -e

TS_USER="teamspeak"
TS_VERSION="3.13.7"
TS_ARCHIVE="teamspeak3-server_linux_amd64-${TS_VERSION}.tar.bz2"
TS_URL="https://files.teamspeak-services.com/releases/server/${TS_VERSION}/${TS_ARCHIVE}"
TS_INSTALL_DIR="/opt/teamspeak"
TS_DATA_DIR="/var/lib/teamspeak"
SERVICE_FILE="/etc/systemd/system/teamspeak.service"

echo "Actualizare pachete..."
apt update
apt install -y wget bzip2 tar

echo "Creare utilizator pentru Teamspeak..."
if id -u $TS_USER >/dev/null 2>&1; then
    echo "Utilizatorul $TS_USER există deja."
else
    adduser --system --group --home $TS_DATA_DIR $TS_USER
    mkdir -p $TS_DATA_DIR
    chown $TS_USER:$TS_USER $TS_DATA_DIR
fi

echo "Descărcare Teamspeak Server..."
wget -q $TS_URL -O /tmp/teamspeak.tar.bz2

echo "Dezarhivare în $TS_INSTALL_DIR..."
mkdir -p $TS_INSTALL_DIR
tar -xjf /tmp/teamspeak.tar.bz2 -C $TS_INSTALL_DIR
rm -f /tmp/teamspeak.tar.bz2

echo "Setare permisiuni..."
chown -R $TS_USER:$TS_USER $TS_INSTALL_DIR
chmod -R 755 $TS_INSTALL_DIR

echo "Creare systemd service..."
cat > $SERVICE_FILE <<EOF
[Unit]
Description=TeamSpeak 3 Server
After=network.target

[Service]
Type=forking
User=$TS_USER
Group=$TS_USER
WorkingDirectory=$TS_INSTALL_DIR
ExecStart=$TS_INSTALL_DIR/ts3server_startscript.sh start
ExecStop=$TS_INSTALL_DIR/ts3server_startscript.sh stop
ExecReload=$TS_INSTALL_DIR/ts3server_startscript.sh restart
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

echo "Reîncărcare systemd..."
systemctl daemon-reload
systemctl enable teamspeak.service

echo "Pornire server Teamspeak..."
systemctl start teamspeak.service

echo "Așteaptă 15 secunde pentru generare token admin..."
sleep 15

echo "Token-ul de admin se găsește în fișierele de log:"
echo "$TS_INSTALL_DIR/logs/ts3server_*.log"
echo "Caută linia cu 'token='"

echo "Instalare completă! Serverul Teamspeak rulează acum ca serviciu."
echo "Poți folosi comenzile:"
echo "  sudo systemctl status teamspeak"
echo "  sudo systemctl stop teamspeak"
echo "  sudo systemctl start teamspeak"
echo "  sudo journalctl -u teamspeak -f"
