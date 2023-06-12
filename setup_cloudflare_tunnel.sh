#!/bin/bash

# Install cloudflared
sudo -i
apt install curl lsb-release
curl -L https://pkg.cloudflare.com/cloudflare-main.gpg | tee /usr/share/keyrings/cloudflare-archive-keyring.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/cloudflare-archive-keyring.gpg] https://pkg.cloudflare.com/cloudflared $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/cloudflared.list
apt update
apt install cloudflared

# Login
cloudflared tunnel login

# Set the tunnel name and localhost url
TUNNEL_NAME="api"
LOCAL_URL="http://localhost:5000"

# Create the tunnel and get the tunnel ID
TUNNEL_ID=$(cloudflared tunnel create $TUNNEL_NAME | awk '/id/{print $4}')

# Generate the tunnel configuration file
cat << EOF > /root/.cloudflared/$TUNNEL_NAME.yml
tunnel: $TUNNEL_ID
credentials-file: /root/.cloudflared/$TUNNEL_ID.json

ingress:
  - hostname: $TUNNEL_NAME.provenphone.com # replace with your actual domain
    service: $LOCAL_URL
  - service: http_status:404
EOF

# Install service
cloudflared --config /root/.cloudflared/$TUNNEL_NAME.yml service install
systemctl enable cloudflared

# Route the DNS of the tunnel
cloudflared tunnel route dns $TUNNEL_ID $TUNNEL_NAME.provenphone.com # replace with your actual domain

# Run the tunnel
cloudflared tunnel run $TUNNEL_NAME



