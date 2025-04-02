#!/bin/bash
# Enable error handling
set -e

# Function for logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a /var/log/setup.log
}

# Function to run commands as ubuntu user
# run_as_ubuntu() {
#     sudo -u ubuntu "$@"
# }

run_as_ubuntu() {
    sudo -u ubuntu bash << EOF
    $@
EOF
}

install_dependencies() {
    log "Installing dependencies..."
    sudo apt-get update
    sudo apt-get install -y curl ca-certificates
}

install_ansible() {
    if ! command -v ansible &> /dev/null; then
        log "Installing Ansible..."
        sudo apt-get install -y software-properties-common
        sudo apt-add-repository --yes --update ppa:ansible/ansible
        sudo apt-get install -y ansible
    else
        log "Ansible is already installed."
    fi
}

install_code_server() {
    if ! run_as_ubuntu command -v code-server &> /dev/null; then
        log "Installing code-server..."
        run_as_ubuntu curl -fsSL https://code-server.dev/install.sh | run_as_ubuntu sh
    else
        log "code-server is already installed."
    fi
}

configure_system() {
    log "Configuring system..."
    # Add any additional system configurations here
    # For example:
    run_as_ubuntu mkdir -p /home/ubuntu/.config/code-server
    run_as_ubuntu mkdir -p /home/ubuntu/setup/ansible
    run_as_ubuntu mkdir -p /home/ubuntu/docker
    run_as_ubuntu mkdir -p /home/ubuntu/projects/comfy
    run_as_ubuntu touch /home/ubuntu/.config/code-server/config.yaml
}

install_comfyui() {
    log "Installing ComfyUI..."
    cd /home/ubuntu/projects/comfy
    git clone https://github.com/comfyanonymous/ComfyUI.git
    cd ComfyUI
    pip3 install -r requirements.txt
    log "DONE Installing ComfyUI..."
}

install_docker_compose() {
    log "Installing docker-compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
    # docker-compose --version
    log "DONE Installing docker-compose..."
}


install_conda() {
    log "Installing mini conda..."
    mkdir -p /home/ubuntu/temp
    cd /home/ubuntu/temp
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
    bash Miniconda3-latest-Linux-x86_64.sh    
    log "DONE Installing mini-conda..."
}

install_portainer() {
    log "Installing portainer..."
    docker volume create portainer_data
    docker run -d \
        --name portainer \
        --restart always \
        -p 9105:9443 \
        -v portainer_data:/data \
        -v /var/run/docker.sock:/var/run/docker.sock \
        portainer/portainer-ce:latest
    log "DONE Installing portainer..."
}

main() {
    log "Starting setup script execution"
    
    install_dependencies
    install_ansible
    # install_code_server
    install_conda
    install_comfyui
    install_docker_compose
    install_portainer
    configure_system
    
    log "Setup script execution completed"
}

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Run the main function
main