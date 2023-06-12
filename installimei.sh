#!/bin/bash

# Update system packages
sudo apt-get update

# Install pip3 and git if not installed
sudo apt-get install -y python3-pip git

# Install Flask
pip3 install flask

# Install OpenSSL for HTTPS
sudo apt-get install -y openssl

# Set the working directory
WORK_DIR="/home/$(whoami)/imei_app"

# Create the directory if not exist
mkdir -p $WORK_DIR

# Change directory to the working directory
cd $WORK_DIR

# Place your imei.py script here
cat << EOF > imei.py
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
EOF

# Run the server
FLASK_APP=imei.py flask run
