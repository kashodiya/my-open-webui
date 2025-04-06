#!/bin/bash

# THIS SCRIPT IS RUN AS USER "ubuntu" from user data script, see terraform\main.tf

exec > >(tee /home/ubuntu/user-data.log|logger -t user-data -s 2>&1) 2>&1

# Function to update and upgrade the system
update_system() {
    sudo apt-get update
    sudo apt-get upgrade -y
}

get_code_from_s3 (){

    echo "Downloading zips from S3."
    # Create the ~/code directory if it doesn't exist
    CODE_DIR=/home/ubuntu/code
    mkdir -p $CODE_DIR

    # Download all files from S3 bucket to ~/code
    aws s3 cp s3://${DATA_BUCKET_NAME}/code/gpu-ec2.zip $CODE_DIR
    aws s3 cp s3://${DATA_BUCKET_NAME}/code/scripts.zip $CODE_DIR

    # Check if the download was successful
    if [ $? -eq 0 ]; then
        echo "Files downloaded successfully from S3."
    else
        echo "Error downloading files from S3. Exiting."
        exit 1
    fi

    # Unzip all files in ~/code
    for zip_file in $CODE_DIR/*.zip; do
        if [ -f "$zip_file" ]; then
            # Extract the filename without extension
            folder_name=$(basename "$zip_file" .zip)

            # Create the directory if it doesn't exist
            mkdir -p "$CODE_DIR/$folder_name"

            unzip -o "$zip_file" -d "$CODE_DIR/$folder_name"
            if [ $? -eq 0 ]; then
                echo "Unzipped: $zip_file"
                # Optionally, remove the zip file after extraction
                # rm "$zip_file"
            else
                echo "Error unzipping: $zip_file"
            fi
        fi
    done

    # sudo chown -R ubuntu:ubuntu $CODE_DIR
    cp -a /home/ubuntu/code/gpu-ec2 /home/ubuntu/
    cp -a /home/ubuntu/code/scripts /home/ubuntu/

    echo "Download and unzip process completed."
}


add_vars_to_bashrc() {
    # Array of variable names to add to .bashrc
    variables=(
        "PROJECT_ID"
        "AWS_REGION"
        "CODE_SERVER_PASSWORD"
        "LITELLM_API_KEY"
        "BEDROCK_GATEWAY_API_KEY"
        "JUPYTER_LAB_TOKEN"
        "DATA_BUCKET_NAME"
    )

    # Path to .bashrc file
    bashrc_file="/home/ubuntu/.bashrc"

    # Function to add variable to .bashrc if it's set and not already present
    add_variable_to_bashrc() {
        local var_name=$1
        local var_value=${!var_name}
        
        if [ -n "$var_value" ]; then
            if ! grep -q "export $var_name=" "$bashrc_file"; then
                echo "export $var_name=\"$var_value\"" >> "$bashrc_file"
                echo "Added $var_name to .bashrc"
            else
                echo "$var_name already exists in .bashrc, skipping"
            fi
        else
            echo "$var_name is not set, skipping"
        fi
    }

    # Main loop to process each variable
    for var in "${variables[@]}"; do
        add_variable_to_bashrc "$var"
    done

    echo "Finished updating .bashrc"
}


create_apps_json() {
    SCRIPTS_DIR=/home/ubuntu/scripts
    cd $SCRIPTS_DIR
    # chown -R ubuntu:ubuntu $SCRIPTS_DIR
    export PATH=/home/ubuntu/miniconda/bin:$PATH
    python generate-app-urls.py
    echo "apps.json has been generated."
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
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

        echo "alias comfy='cd /home/ubuntu/projects/comfy/ComfyUI && python main.py --port 8108'" >> ~/.bashrc
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

        CERT_DIR="/etc/caddy/certs"
        DOMAIN="localhost"  # Using localhost as the default domain
        DAYS_VALID=365
        IP_ADDRESS=$(curl -s https://api.ipify.org)

        sudo mkdir -p $CERT_DIR

        sudo openssl genrsa -out $CERT_DIR/server.key 2048

        sudo bash -c "cat << EOF > $CERT_DIR/server.cnf
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
"

        sudo openssl req -x509 -nodes -days $DAYS_VALID \
            -keyout $CERT_DIR/server.key \
            -out $CERT_DIR/server.crt \
            -config $CERT_DIR/server.cnf

        sudo chown caddy:caddy $CERT_DIR/server.key $CERT_DIR/server.crt
        sudo chmod 600 $CERT_DIR/server.key
        sudo chmod 644 $CERT_DIR/server.crt

        # sudo rm $CERT_DIR/server.cnf

        echo "Self-signed certificate created for $DOMAIN and IP $IP_ADDRESS"
        echo "Certificate location: $CERT_DIR/server.crt"
        echo "Private key location: $CERT_DIR/server.key"


        echo "Copying caddy files from ubunt/home/ubuntu/gpu-ec2/caddyu to /etc/caddy"
        sudo cp -R /home/ubuntu/gpu-ec2/caddy /etc


        sudo bash -c 'cat << EOF > /etc/systemd/system/caddy.service
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
EOF'

        # Generate admin hash
        generate_caddy_users

        sudo systemctl daemon-reload
        sudo systemctl start caddy
        sudo systemctl enable caddy

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
        
        rm Miniconda3-latest-Linux-x86_64.sh

        # Add conda to PATH
        # echo 'export PATH="$HOME/miniconda/bin:$PATH"' >> $HOME/.bashrc
        /home/ubuntu/miniconda/bin/conda init
        source $HOME/.bashrc
        echo "DONE Installing mini-conda..."

        echo "Installing pytghon packages..."
        /home/ubuntu/miniconda/bin/pip install --quiet boto3 ansible
        echo "DONE Installing python packages"
    fi
    
    # Verify installation
    /home/ubuntu/miniconda/bin/conda --version



}

install_ansible() {
    if ! command -v ansible &> /dev/null; then
        echo "Installing Ansible..."
        sudo apt-get install -y software-properties-common
        sudo apt-add-repository --yes --update ppa:ansible/ansible
        sudo apt-get install -y ansible
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
bind-addr: 127.0.0.1:8104
auth: password
password: $CODE_SERVER_PASSWORD
cert: false
EOF
        sudo systemctl enable --now code-server@$USER
    else
        echo "code-server is already installed."
    fi
}

generate_caddy_users() {
    echo "Installing expect..."
    sudo apt install expect -y
    echo "DONE Installing expect..."
    echo "Generating admin pwd hash..."
    export PASSWORD="$ADMIN_PASSWORD"
    export VERIFICATION_PASSWORD="$ADMIN_PASSWORD"
    # Create a temporary expect script
    EXPECT_SCRIPT=$(mktemp)
    cat > "$EXPECT_SCRIPT" << 'EOF'
    #!/usr/bin/expect
    set timeout 10
    # Start the caddy hash command
    spawn caddy hash-password
    # Wait for the "Enter password:" prompt
    expect "Enter password:"
    send "$env(PASSWORD)\r"
    # Wait for the "Confirm password:" prompt
    expect "Confirm password:"
    send "$env(VERIFICATION_PASSWORD)\r"
    # Wait for the hash to be printed
    expect {
        "Passwords do not match" {
            puts "Error: Passwords do not match"
            exit 1
        }
        eof
    }
    # Capture the last line of output as the hash
    set HASH [wait]
    puts "$HASH"
EOF
    chmod +x "$EXPECT_SCRIPT"
    # Run the expect script and capture the output
    OUTPUT=$(expect "$EXPECT_SCRIPT")
    echo OUTPUT
    echo "$OUTPUT"
    echo OUTPUT-END
    # Extract the last line into the HASH variable
    HASH=$(echo "$OUTPUT" | awk '{lines[NR]=$0} END{print lines[NR-1]}')
    echo "HASH: $HASH"
    # Clean up the temporary expect script
    rm "$EXPECT_SCRIPT"
    # Add the admin user with the hashed password to the file
    echo "admin $HASH" | sudo tee -a /etc/caddy/users.txt
    echo "DONE Generating admin pwd hash..."
}

install_jupyterlab() {
    if command -v jupyter; then
        echo "JupyterLab is already installed."
    else
        echo "Installing JupyterLab..."
        /home/ubuntu/miniconda/bin/pip install --quiet jupyterlab
        /home/ubuntu/miniconda/bin/jupyter --version
    fi

    echo "Configuring JupyterLab to run on port 8103..."

    mkdir -p /home/ubuntu/.jupyter
    cat << EOF > /home/ubuntu/.jupyter/jupyter_server_config.py
c.ServerApp.port = 8103
c.ServerApp.ip = "0.0.0.0"
c.ServerApp.allow_origin = "*"
c.ServerApp.open_browser = False
c.ServerApp.disable_check_xsrf = True
c.ServerApp.root_dir = '/home/ubuntu'
c.ServerApp.token = "$JUPYTER_LAB_TOKEN"
EOF

    # chown -R ubuntu:ubuntu /home/ubuntu/.jupyter


    sudo bash -c 'cat << EOF > /etc/systemd/system/jupyter-lab.service
[Unit]
Description=Jupyter Lab
After=network.target

[Service]
Type=simple
User=ubuntu
Environment="PATH=/home/ubuntu/miniconda/bin:/home/ubuntu/.local/bin:/home/ubuntu/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin"
ExecStart=/bin/bash -c "source /home/ubuntu/.bashrc && jupyter lab --no-browser"
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF'


    sudo chmod 644 /etc/systemd/system/jupyter-lab.service
    sudo systemctl daemon-reload
    sudo systemctl enable jupyter-lab.service
    sudo systemctl start jupyter-lab.service

    echo "Jupyter Lab service has been created, enabled, and started."

    echo "JupyterLab installation and configuration completed."
}

docker_command() {
    local cmd="$1"
    local max_attempts=3
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if timeout 300 $cmd; then
            return 0
        fi
        echo "Docker command failed. Attempt $attempt of $max_attempts. Retrying in 10 seconds..."
        sleep 10
        ((attempt++))
    done

    echo "Docker command failed after $max_attempts attempts."
    return 1
}


start_containers() {
    export OPEN_WEBUI_DIR=/home/ubuntu/gpu-ec2/docker/open-webui
    # mkdir -p $OPEN_WEBUI_DIR

    echo "Creating docker network: shared_network"
    docker network create shared_network

    echo "Creating Open WebUI, Ollama, LiteLLM containers"
    cd $OPEN_WEBUI_DIR

    if ! docker_command "docker-compose up -d --quiet-pull"; then
        echo "Failed to start containers. Cleaning up and exiting."
        return
    fi

    echo "Open WebUI containers started. Building Bedrock gateway image..."

    mkdir -p /home/ubuntu/temp
    cd /home/ubuntu/temp
    git clone https://github.com/aws-samples/bedrock-access-gateway.git
    cd bedrock-access-gateway/src
    docker build -q -t bedrock-gateway -f Dockerfile_ecs .    
    cd ../..
    rm -rf bedrock-access-gateway

    export BEDROCK_GATEWAY_DIR=/home/ubuntu/gpu-ec2/docker/bedrock-gateway
    # mkdir -p $BEDROCK_GATEWAY_DIR

    # echo "$BEDROCK_GATEWAY_COMPOSE_CONTENT" > "$BEDROCK_GATEWAY_DIR/docker-compose.yml"
    # echo "$(eval "echo \"$BEDROCK_GATEWAY_COMPOSE_CONTENT\"")" > "$BEDROCK_GATEWAY_DIR/docker-compose.yml"
    # echo "Docker composefile for bedrock gateway created"

    # sudo chown -R ubuntu:ubuntu $BEDROCK_GATEWAY_DIR
    # sudo chown -R ubuntu:ubuntu /home/ubuntu/temp

    echo "Creating Bedrock Gateway container"
    cd $BEDROCK_GATEWAY_DIR

    if ! docker_command "docker-compose up -d --quiet-pull"; then
        echo "Failed to start containers. Cleaning up and exiting."
        return 
    fi

    # sudo chown -R ubuntu:ubuntu $OPEN_WEBUI_DIR/..

}

install_portainer() {
    echo "Installing portainer in docker"
    export PORTAINER_DIR=/home/ubuntu/gpu-ec2/docker/portainer
    # mkdir -p $PORTAINER_DIRID-gpu-ec2-setup
    # echo "$PORTAINER_COMPOSE_CONTENT" > "$PORTAINER_DIR/docker-compose.yml"
    cd $PORTAINER_DIR
    docker-compose up -d --quiet-pull
    # sudo chown -R ubuntu:ubuntu $PORTAINER_DIR
    echo "Portainer installed"
}

register_start() {
    current_datetime=$(date "+%Y-%m-%d %H:%M:%S")
    echo "$current_datetime" > "$PROJECT_ID-gpu-ec2-setup-started"
    echo "Copying $PROJECT_ID-gpu-ec2-setup-started to s3://$DATA_BUCKET_NAME"
    aws s3 cp $PROJECT_ID-gpu-ec2-setup-started s3://$DATA_BUCKET_NAME/
    rm $PROJECT_ID-gpu-ec2-setup-started

    S3_FILE_PATH="s3://${DATA_BUCKET_NAME}/${PROJECT_ID}-ec2-setup-ended"
    aws s3 rm "$S3_FILE_PATH" --quiet
}

register_end() {
    current_datetime=$(date "+%Y-%m-%d %H:%M:%S")
    echo "$current_datetime" > "$PROJECT_ID-gpu-ec2-setup-ended"
    echo "Copying $PROJECT_ID-gpu-ec2-setup-ended to s3://$DATA_BUCKET_NAME"
    aws s3 cp $PROJECT_ID-gpu-ec2-setup-ended s3://$DATA_BUCKET_NAME/
    rm $PROJECT_ID-gpu-ec2-setup-ended
}

# Main installation process for root user
root_installations() {
    echo "===---===---===--- START ===---"
    add_vars_to_bashrc    
    echo "===---===---===---"
    get_code_from_s3
    echo "===---===---===---"
    # update_system
    # echo "===---===---===---"
    install_caddy    
    echo "===---===---===---"
    install_docker_compose
    echo "===---===---===---"
    start_containers
    echo "===---===---===---"
    install_portainer
    echo "===---===---===---"
    install_ansible
}

# Main installation process for ubuntu user
ubuntu_installations() {
    echo "===---===---===---"
    install_code_server
    echo "===---===---===---"
    install_conda
    echo "===---===---===---"

    # Check if GPU_EC2_INSTALL_JUPYTERLAB is set
    if [ "${GPU_EC2_INSTALL_JUPYTERLAB}" = "true" ]; then
        install_jupyterlab
    else
        echo "Not installing Jupyter Lab."
    fi
    
    echo "===---===---===---"
    create_apps_json
    echo "===---===---===---"

    # Check if GPU_EC2_INSTALL_COMFYUI is set
    if [ "${GPU_EC2_INSTALL_COMFYUI}" = "true" ]; then
        install_comfyui
    else
        echo "Not installing ComfyUI."
    fi
}

# Execute root installations
register_start
root_installations
ubuntu_installations
register_end

echo "===---===---===---"
echo "All installations completed."
echo "===---===---===--- END  ===---"
