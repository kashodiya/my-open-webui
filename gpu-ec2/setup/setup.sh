#!/bin/bash

# Function to update and upgrade the system
update_system() {
    apt-get update
    apt-get upgrade -y
}

install_comfyui() {
    COMFY_DIR="/home/ubuntu/projects/comfy/ComfyUI"
    
    if [ -d "$COMFY_DIR" ] && [ -f "$COMFY_DIR/main.py" ]; then
        echo "ComfyUI is already installed in $COMFY_DIR"
    else
        echo "Installing ComfyUI..."
        mkdir -p /home/ubuntu/projects/comfy
        cd /home/ubuntu/projects/comfy
        git clone https://github.com/comfyanonymous/ComfyUI.git
        cd ComfyUI
        source $HOME/.bashrc
        export PATH="$HOME/miniconda/bin:$PATH"
        $HOME/miniconda/bin/pip install -r requirements.txt        

        cd $COMFY_DIR/custom_nodes/
        git clone https://github.com/ltdrdata/ComfyUI-Manager comfyui-manager

        echo "alias comfy='cd /home/ubuntu/projects/comfy/ComfyUI && python main.py --port 9104'" >> ~/.bashrc
        echo "DONE Installing ComfyUI..."
    fi
}


install_docker_compose() {
    if command -v docker-compose &> /dev/null
    then
        echo "docker-compose is already installed"
    else
        echo "Installing docker-compose..."
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
        echo "DONE Installing docker-compose..."
    fi
    
    # Verify installation
    docker-compose --version
}

install_caddy() {
    if command -v caddy &> /dev/null; then
        echo "Caddy is already installed."
        caddy -v
    else
        echo "Installing Caddy..."
        cd /tmp
        wget -q https://github.com/caddyserver/caddy/releases/download/v2.9.1/caddy_2.9.1_linux_amd64.tar.gz
        tar -xzvf caddy_2.9.1_linux_amd64.tar.gz
        sudo mv caddy /usr/local/bin/
        rm caddy_2.9.1_linux_amd64.tar.gz

        DOMAIN=ec2-34-195-186-102.compute-1.amazonaws.com
        sudo mkdir -p /etc/caddy/certs

        # Generate private key
        sudo openssl genrsa -out /etc/caddy/certs/server.key 2048

        # Create temporary config files
        cat > /tmp/openssl_csr.cnf <<EOF
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no
[req_distinguished_name]
CN = $DOMAIN
[v3_req]
subjectAltName = DNS:$DOMAIN
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
EOF

        cat > /tmp/openssl_cert.cnf <<EOF
[v3_req]
subjectAltName = DNS:$DOMAIN
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
EOF

        # Create CSR with Subject Alternative Name
        sudo openssl req -new -key /etc/caddy/certs/server.key -out /etc/caddy/certs/server.csr -subj "/CN=$DOMAIN" -config /tmp/openssl_csr.cnf

        # Generate self-signed certificate
        sudo openssl x509 -req -days 365 -in /etc/caddy/certs/server.csr -signkey /etc/caddy/certs/server.key -out /etc/caddy/certs/server.crt -extfile /tmp/openssl_cert.cnf -extensions v3_req

        # Clean up temporary files
        rm /tmp/openssl_csr.cnf /tmp/openssl_cert.cnf

        # Set ownership and permissions
        sudo chmod 600 /etc/caddy/certs/server.key
        sudo chmod 644 /etc/caddy/certs/server.crt
        sudo chown ubuntu:ubuntu /etc/caddy/certs/server.key /etc/caddy/certs/server.crt

        # Create a systemd service file for Caddy
        sudo tee /etc/systemd/system/caddy.service > /dev/null <<EOF
[Unit]
Description=Caddy
Documentation=https://caddyserver.com/docs/
After=network.target network-online.target
Requires=network-online.target

[Service]
User=ubuntu
Group=ubuntu
ExecStart=/usr/local/bin/caddy run --config /etc/caddy/Caddyfile
ExecReload=/usr/local/bin/caddy reload --config /etc/caddy/Caddyfile
TimeoutStopSec=5s
LimitNOFILE=1048576
LimitNPROC=512
PrivateTmp=true
ProtectSystem=full
AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOF

        # Create a basic Caddyfile
        sudo tee /etc/caddy/Caddyfile > /dev/null <<'EOF'
{
    auto_https off
}

(common) {
    encode gzip
    tls /etc/caddy/certs/server.crt /etc/caddy/certs/server.key
}

(auth_config) {
    basicauth {
        admin $2a$14$TMXXMj3dYHvPE0rQb.GpauM4Yuydaqk1AUOMtpBSZpkI6O1Y/Y3Mm
    }
    request_header X-Authenticated-User {http.auth.user.id}
}

:7100 {
    respond "Hello from my server!"
}

# portainer
:7102 {
    import common
    reverse_proxy https://localhost:9102 {
        transport http {
            tls_insecure_skip_verify
        }
    }    
}

# jupyter-lab
:7103 {
    import common
    reverse_proxy localhost:9103
}

# comfyui
:7104 {
    reverse_proxy localhost:9104
    import common
    import auth_config
}

# code-server
:7109 {
    import common
    reverse_proxy localhost:9109
}
EOF

        sudo chown ubuntu:ubuntu /etc/caddy/Caddyfile
        # Reload systemd, enable and start Caddy service
        sudo systemctl daemon-reload
        sudo systemctl enable caddy
        sudo systemctl start caddy

        echo "Caddy has been installed and started successfully."
    fi
}


install_conda() {
    if command -v /home/ubuntu/miniconda/bin/conda &> /dev/null
    then
        echo "Conda is already installed"
    else
        echo "Installing mini conda..."
        mkdir -p /home/ubuntu/temp
        cd /home/ubuntu/temp
        wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
        bash Miniconda3-latest-Linux-x86_64.sh -b -p $HOME/miniconda
        
        # Add conda to PATH
        # echo 'export PATH="$HOME/miniconda/bin:$PATH"' >> $HOME/.bashrc
        /home/ubuntu/miniconda/bin/conda init
        source $HOME/.bashrc
        echo "DONE Installing mini-conda..."
    fi
    
    # Verify installation
    /home/ubuntu/miniconda/bin/conda --version
}

install_ansible() {
    if ! command -v ansible &> /dev/null; then
        echo "Installing Ansible..."
        apt-get install -y software-properties-common
        apt-add-repository --yes --update ppa:ansible/ansible
        apt-get install -y ansible
    else
        echo "Ansible is already installed."
        ansible --version
    fi
}

install_code_server() {
    if ! command -v code-server &> /dev/null; then
        echo "Installing code-server..."
        curl -fsSL https://code-server.dev/install.sh | sh

        # Define the file path
        CONFIG_FILE="/home/ubuntu/.config/code-server/config.yaml"

        # Create the directory if it doesn't exist
        mkdir -p "$(dirname "$CONFIG_FILE")"

        # Create the file with the specified content
        cat << EOF > "$CONFIG_FILE"
bind-addr: 127.0.0.1:9109
auth: password
password: testtest
cert: false
EOF
        sudo systemctl enable --now code-server@$USER
    else
        echo "code-server is already installed."
    fi
}


# Main installation process for root user
root_installations() {
    echo "===---===---===--- START ===---"
    # update_system
    # echo "===---===---===---"
    install_caddy    
    echo "===---===---===---"
    install_docker_compose
    echo "===---===---===---"
    install_ansible
}

# Main installation process for ubuntu user
# IMPORTANT: Whatever function you use in this must be declared in "su - ubuntu << EOF" block below
ubuntu_installations() {
    echo "===---===---===---"
    install_code_server
    echo "===---===---===---"
    install_conda
    echo "===---===---===---"
    install_comfyui
}

# Execute root installations
root_installations

# Switch to ubuntu user and execute ubuntu installations
su - ubuntu << EOF
$(declare -f ubuntu_installations)
$(declare -f install_conda)
$(declare -f install_comfyui)
$(declare -f install_code_server)

ubuntu_installations
EOF



# mkdir -p /home/ubuntu/.config/code-server
# touch /home/ubuntu/.config/code-server/config.yaml
# mkdir -p /home/ubuntu/setup/ansible
# mkdir -p /home/ubuntu/docker


echo "===---===---===---"
echo "All installations completed."
echo "===---===---===--- END  ===---"
