#!/bin/bash

DOMAIN="ec2-98-80-38-60.compute-1.amazonaws.com"
CERT_DIR="/var/lib/caddy/custom_certs"

# Ensure the certificate directory exists
sudo mkdir -p $CERT_DIR

# Generate private key
sudo openssl genrsa -out $CERT_DIR/server.key 2048

# Generate CSR with the specified domain
sudo openssl req -new -key $CERT_DIR/server.key -out $CERT_DIR/server.csr -subj "/CN=$DOMAIN"

# Generate self-signed certificate
sudo openssl x509 -req -days 365 -in $CERT_DIR/server.csr -signkey $CERT_DIR/server.key -out $CERT_DIR/server.crt

# Set proper ownership and permissions
sudo chown ec2-user:ec2-user $CERT_DIR/server.key $CERT_DIR/server.crt
sudo chmod 600 $CERT_DIR/server.key
sudo chmod 644 $CERT_DIR/server.crt

# Clean up CSR file (optional)
sudo rm $CERT_DIR/server.csr

echo "SSL certificate generation complete for $DOMAIN"