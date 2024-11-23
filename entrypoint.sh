#!/bin/bash

OPENVPN_DIR="/etc/openvpn"
EASYRSA_DIR="$OPENVPN_DIR/easy-rsa"
PKI_DIR="$EASYRSA_DIR/pki"
SERVER_CONF="$OPENVPN_DIR/server.conf"

# Function to initialize EasyRSA and create certificates
initialize_easyrsa() {
    echo "Initializing EasyRSA..."
    make-cadir "$EASYRSA_DIR"
    cd "$EASYRSA_DIR"

    ./easyrsa init-pki
    echo -ne '\n' | ./easyrsa build-ca nopass
    ./easyrsa gen-dh
    ./easyrsa build-server-full server nopass
    ./easyrsa build-client-full client1 nopass

    # Copy files to OpenVPN directory
    cp "$PKI_DIR/ca.crt" "$OPENVPN_DIR/"
    cp "$PKI_DIR/issued/server.crt" "$OPENVPN_DIR/"
    cp "$PKI_DIR/private/server.key" "$OPENVPN_DIR/"
    cp "$PKI_DIR/dh.pem" "$OPENVPN_DIR/"
}

# Function to create server.conf
create_server_conf() {
    echo "Creating server.conf..."
    cat <<EOL > "$SERVER_CONF"
port 1194
proto tcp
dev tun
ca /etc/openvpn/ca.crt
cert /etc/openvpn/server.crt
key /etc/openvpn/server.key
dh /etc/openvpn/dh.pem
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
keepalive 10 120
cipher AES-256-CBC
persist-key
persist-tun
status /etc/openvpn/openvpn-status.log
verb 3
EOL
    echo "server.conf created."
}

# Check if PKI and config files already exist
if [ ! -f "$SERVER_CONF" ]; then
    echo "No existing configuration found. Creating all files..."
    mkdir -p "$OPENVPN_DIR"
    initialize_easyrsa
    create_server_conf
else
    echo "Existing configuration detected. Skipping file creation."
fi

# Start OpenVPN
exec openvpn --config "$SERVER_CONF"
