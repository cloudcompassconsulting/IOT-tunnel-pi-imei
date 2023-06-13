#!/bin/bash

# Update the system
sudo apt update
sudo apt upgrade -y

# Install the required packages
sudo apt-get install usbmuxd libimobiledevice6 libimobiledevice-utils python3 python3-pip build-essential python-dev -y

# Install Flask and uWSGI
sudo pip3 install flask flask-httpauth uwsgi

# Create the uWSGI ini file
sudo tee /home/hunnidpi/imei/uwsgi.ini > /dev/null <<EOT
[uwsgi]
module = imei:app
master = true
processes = 5
socket = imei.sock
chmod-socket = 660
vacuum = true
die-on-term = true
EOT

# Create the uWSGI service
sudo tee /etc/systemd/system/uwsgi.service > /dev/null <<EOT
[Unit]
Description=uWSGI Service
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=/home/hunnidpi/imei/
ExecStart=/usr/local/bin/uwsgi --ini /home/hunnidpi/imei/uwsgi.ini

[Install]
WantedBy=multi-user.target
EOT

# Create the Flask app file
sudo tee /home/hunnidpi/imei/imei.py > /dev/null <<EOT
from flask import Flask, jsonify
import subprocess

app = Flask(__name__)

def get_device_list():
    try:
        result = subprocess.run(['idevice_id', '-l'], capture_output=True, text=True)
        devices = result.stdout.splitlines()
    except Exception as e:
        devices = []
    return devices

def get_imei(device):
    try:
        result = subprocess.run(['ideviceinfo', '-u', device], capture_output=True, text=True)
        for line in result.stdout.splitlines():
            if line.startswith('InternationalMobileEquipmentIdentity'):
                return line.split(': ')[1]
    except Exception as e:
        return None

@app.route('/imeis', methods=['GET'])
def get_imeis():
    devices = get_device_list()
    imeis = {device: get_imei(device) for device in devices}
    return jsonify(imeis)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOT

# Enable and start the uWSGI service
sudo systemctl daemon-reload
sudo systemctl start uwsgi.service
sudo systemctl enable uwsgi.service

# Install cloudflared
sudo apt install curl lsb-release -y
curl -L https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-archive-keyring.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/cloudflare-archive-keyring.gpg] https://pkg.cloudflare.com/cloudflared $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflared.list >/dev/null
sudo apt update
sudo apt install cloudflared -y

# Login
cloudflared tunnel login

# Set the tunnel name and localhost url
TUNNEL_NAME="api"
LOCAL_URL="http://localhost:5000"

# Create the tunnel and get the tunnel ID
TUNNEL_ID=$(cloudflared tunnel create $TUNNEL_NAME | awk '/id/{print $4}')

# Generate the tunnel configuration file
sudo mkdir /etc/cloudflared
sudo tee /etc/cloudflared/$TUNNEL_NAME.yml > /dev/null <<EOT
tunnel: $TUNNEL_ID
credentials-file: /root/.cloudflared/$TUNNEL_ID.json

ingress:
  - hostname: $TUNNEL_NAME.provenphone.com
    service: http://localhost:5000
  - service: http_status:404
EOT

# Create the cloudflared service
sudo tee /etc/systemd/system/cloudflared.service > /dev/null <<EOT
[Unit]
Description=Cloudflare Tunnel
After=syslog.target network-online.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/cloudflared tunnel --config /etc/cloudflared/$TUNNEL_NAME.yml run $TUNNEL_NAME
Restart=on-failure
RestartSec=5
KillMode=process

[Install]
WantedBy=multi-user.target
EOT

# Enable and start the cloudflared service
sudo systemctl daemon-reload
sudo systemctl enable cloudflared.service
sudo systemctl start cloudflared.service

# Reboot the system
sudo reboot