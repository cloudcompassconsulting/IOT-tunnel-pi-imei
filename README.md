# IOT tunnel pi imei 
 Raspberry Pi running checking iPhone for IMEI and restfulAPI
 
This repository contains scripts and code for setting up a server on a Raspberry Pi device that provides IMEI information of connected iPhones. It also includes scripts to establish a secure Cloudflare tunnel and ensure that the services start on boot.

## Installation

### Python Server

1. Run the script `installimie.sh` to install necessary dependencies and set up the server. 

### Cloudflare Tunnel

1. Run the script `setup_cloudflare_tunnel.sh` to install Cloudflare, create a new tunnel, generate the tunnel configuration, install the tunnel service, and start the tunnel.

## Usage

The Python server will be running on `http://localhost:5000`. If you've set up the Cloudflare tunnel, you can access it from the Internet using your specified domain.

To get the IMEIs of connected iPhones, send a GET request to `http://localhost:5000/imeis` (or your Cloudflare tunnel URL).

## Notes

Remember to replace placeholders in the scripts with your actual paths, domains, and other relevant information.

## Security

The server uses an ad-hoc SSL certificate for HTTPS. It's recommended to use a certificate from a trusted Certificate Authority for a real-world deployment.

