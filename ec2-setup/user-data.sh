#!/bin/bash

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
    export OPEN_WEBUI_DIR=/home/ec2-user/open-webui
    mkdir $OPEN_WEBUI_DIR

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
        sudo mkdir -p /etc/caddy
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

# Main execution
update_dnf
install_ansible
install_docker
install_docker_compose
start_containers

echo "All installations completed."