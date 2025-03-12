#!/bin/bash

# Redirect output to a log file
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to update dnf
update_dnf() {
    echo "Updating dnf..."
    sudo dnf update -y
}

# Function to install Docker
install_docker() {
    if command_exists docker; then
        echo "Docker is already installed."
    else
        echo "Installing Docker..."
        sudo dnf install docker -y
        sudo systemctl start docker
        sudo systemctl enable docker
        sudo usermod -aG docker ec2-user
        sudo chown root:docker /var/run/docker.sock
        sudo systemctl restart docker        
        newgrp docker
        docker --version
    fi
}

# Function to install Docker Compose
install_docker_compose() {
    if command_exists docker-compose; then
        echo "Docker Compose is already installed."
    else
        echo "Installing Docker Compose..."
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o ~/docker-compose
        sudo mv ~/docker-compose /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        docker-compose --version
    fi
}

start_containers() {
    export OPEN_WEBUI_DIR=/home/ec2-user/docker/open-webui
    mkdir -p $OPEN_WEBUI_DIR

    # See terraform\main.tf file for LITELLM_CONFIG_CONTENT and DOCKER_COMPOSE_CONTENT

    echo "Creating LiteLLM config file"
    echo "$LITELLM_CONFIG_CONTENT" > "$OPEN_WEBUI_DIR/litellm-config.yml"
    echo "LiteLLM config file created"

    echo "$DOCKER_COMPOSE_CONTENT" > "$OPEN_WEBUI_DIR/docker-compose.yml"
    echo "$(eval "echo \"$DOCKER_COMPOSE_CONTENT\"")" > "$OPEN_WEBUI_DIR/docker-compose.yml"
    echo "Docker compose file created"

    sudo chown -R ec2-user:ec2-user $OPEN_WEBUI_DIR

    echo "Creating containers"
    cd $OPEN_WEBUI_DIR
    docker-compose up -d
    echo "Containers started"
}


# Function to install Caddy
install_caddy() {
    if command_exists caddy; then
        echo "Caddy is already installed."
    else
        echo "Installing Caddy..."
        cd /tmp
        wget -q https://github.com/caddyserver/caddy/releases/download/v2.9.1/caddy_2.9.1_linux_amd64.tar.gz
        tar xzf caddy_2.9.1_linux_amd64.tar.gz
        sudo mv caddy /usr/local/bin/
        sudo chmod +x /usr/local/bin/caddy
        caddy version
        sudo mkdir -p /etc/caddy/certs


        # Set variables
        CERT_DIR="/etc/caddy/certs"
        DOMAIN="localhost"  # Using localhost as the default domain
        DAYS_VALID=365
        IP_ADDRESS=$(curl -s https://api.ipify.org)

        # Ensure the certificate directory exists
        sudo mkdir -p $CERT_DIR

        # Generate a private key
        sudo openssl genrsa -out $CERT_DIR/server.key 2048

        # Create a configuration file for the certificate
        cat << EOF > $CERT_DIR/server.cnf
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
x509_extensions = v3_req

[dn]
C = US
ST = State
L = City
O = Organization
OU = OrganizationalUnit
CN = $DOMAIN

[v3_req]
subjectAltName = @alt_names

[alt_names]
DNS.1 = $DOMAIN
IP.1 = $IP_ADDRESS
EOF

        # Generate a self-signed certificate
        sudo openssl req -x509 -nodes -days $DAYS_VALID \
            -keyout $CERT_DIR/server.key \
            -out $CERT_DIR/server.crt \
            -config $CERT_DIR/server.cnf

        # Set appropriate permissions
        sudo chown caddy:caddy $CERT_DIR/server.key $CERT_DIR/server.crt
        sudo chmod 600 $CERT_DIR/server.key
        sudo chmod 644 $CERT_DIR/server.crt

        # Clean up the configuration file
        sudo rm $CERT_DIR/server.cnf

        echo "Self-signed certificate created for $DOMAIN and IP $IP_ADDRESS"
        echo "Certificate location: $CERT_DIR/server.crt"
        echo "Private key location: $CERT_DIR/server.key"

        echo "$CADDYFILE_CONTENT" > "/etc/caddy/Caddyfile"

        cat << EOF > /etc/systemd/system/caddy.service
[Unit]
Description=Caddy
After=network.target

[Service]
ExecStart=/usr/local/bin/caddy run --config /etc/caddy/Caddyfile
ExecReload=/usr/local/bin/caddy reload --config /etc/caddy/Caddyfile
TimeoutStopSec=5
LimitNOFILE=1048576
LimitNPROC=512
PrivateTmp=true
ProtectSystem=full
AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOF
        sudo systemctl daemon-reload
        sudo systemctl start caddy
        sudo systemctl enable caddy
    fi
}

# Function to install code-server
install_code_server() {
    if su - ec2-user -c 'command -v code-server'; then
        echo "code-server is already installed."
    else
        echo "Installing code-server..."
        su - ec2-user -c '
            curl -fsSL https://code-server.dev/install.sh | sh -s -- --version=4.96.2

            mkdir -p /home/ec2-user/.config/code-server

            cat << EOF > /home/ec2-user/.config/code-server/config.yaml
bind-addr: 127.0.0.1:8104
auth: password
password: ce2d9ae4bdb79236c1e6f27f
cert: false
EOF
        '
        sudo systemctl enable --now code-server@ec2-user
        
    fi
}

install_portainer() {
    echo "Installing portainer in docker"
    export PORTAINER_DIR=/home/ec2-user/docker/portainer
    mkdir -p $PORTAINER_DIR
    echo "$PORTAINER_COMPOSE_CONTENT" > "$PORTAINER_DIR/docker-compose.yml"
    cd $PORTAINER_DIR
    docker-compose up -d
    sudo chown -R ec2-user:ec2-user $PORTAINER_DIR
    echo "Portainer installed"
}

# Function to install Miniconda
install_miniconda() {
    if [ -d "/home/ec2-user/miniconda" ]; then
        echo "Miniconda is already installed."
    else
        echo "Installing Miniconda..."
        su - ec2-user -c '
            wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
            chmod +x Miniconda3-latest-Linux-x86_64.sh
            ./Miniconda3-latest-Linux-x86_64.sh -b -p $HOME/miniconda
            rm Miniconda3-latest-Linux-x86_64.sh
            $HOME/miniconda/bin/conda init
            source ~/.bashrc
            conda --version
            python --version
        '
    fi
}


# Function to install JupyterLab
install_jupyterlab() {
    if su - ec2-user -c 'command -v jupyter'; then
        echo "JupyterLab is already installed."
    else
        echo "Installing JupyterLab..."
        su - ec2-user -c '
            $HOME/miniconda/bin/pip install jupyterlab
            $HOME/miniconda/bin/jupyter --version
        '
    fi

    # Configure JupyterLab to run on port 8106
    echo "Configuring JupyterLab to run on port 8106..."

    su - ec2-user -c '
        JUPYTER_LAB_TOKEN=$(openssl rand -base64 15 | tr -dc 'a-zA-Z0-9' | head -c 20)
        mkdir -p $HOME/.jupyter
        cat << EOF > $HOME/.jupyter/jupyter_server_config.py
c.ServerApp.port = 8103
c.ServerApp.ip = "0.0.0.0"
c.ServerApp.allow_origin = "*"
c.ServerApp.open_browser = False
c.ServerApp.token = "$JUPYTER_LAB_TOKEN"
EOF
'

    sudo bash -c 'cat << EOF > /etc/systemd/system/jupyter-lab.service
[Unit]
Description=Jupyter Lab
After=network.target

[Service]
Type=simple
User=ec2-user
Environment="PATH=/home/ec2-user/.local/bin:/home/ec2-user/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin"
ExecStart=/bin/bash -c "source /home/ec2-user/.bashrc && jupyter lab --no-browser"
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF'


    chmod 644 /etc/systemd/system/jupyter-lab.service
    systemctl daemon-reload
    systemctl enable jupyter-lab.service
    systemctl start jupyter-lab.service

    echo "Jupyter Lab service has been created, enabled, and started."

    echo "JupyterLab installation and configuration completed."
}


# Main execution
update_dnf
install_ansible
install_docker
install_docker_compose
start_containers
install_portainer
install_caddy
install_code_server
install_miniconda
install_jupyterlab

echo "All installations completed."