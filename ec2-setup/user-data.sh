exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

update_dnf() {
    echo "Updating dnf..."
    sudo dnf -q update -y
}

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
    # mkdir -p $OPEN_WEBUI_DIR

    echo "Creating docker network: shared_network"
    docker network create shared_network

    # See terraform\main.tf file for LITELLM_CONFIG_CONTENT and DOCKER_COMPOSE_CONTENT

    # echo "Creating LiteLLM config file"
    # echo "$LITELLM_CONFIG_CONTENT" > "$OPEN_WEBUI_DIR/litellm-config.yml"
    # echo "LiteLLM config file created"

    # echo "$DOCKER_COMPOSE_CONTENT" > "$OPEN_WEBUI_DIR/docker-compose.yml"
    # echo "$(eval "echo \"$DOCKER_COMPOSE_CONTENT\"")" > "$OPEN_WEBUI_DIR/docker-compose.yml"
    # echo "Docker compose file created"

    echo "Creating Open WebUI, Ollama, LiteLLM containers"
    cd $OPEN_WEBUI_DIR

    if ! docker_command "docker-compose up -d --quiet-pull"; then
        log "Failed to start containers. Cleaning up and exiting."
        cleanup
        exit 1
    fi

    echo "Open WebUI containers started. Building Bedrock gateway image..."

    mkdir -p /home/ec2-user/temp
    cd /home/ec2-user/temp
    git clone https://github.com/aws-samples/bedrock-access-gateway.git
    cd bedrock-access-gateway/src
    docker build -q -t bedrock-gateway -f Dockerfile_ecs .    
    cd ../..
    rm -rf bedrock-access-gateway

    export BEDROCK_GATEWAY_DIR=/home/ec2-user/docker/bedrock-gateway
    # mkdir -p $BEDROCK_GATEWAY_DIR

    # echo "$BEDROCK_GATEWAY_COMPOSE_CONTENT" > "$BEDROCK_GATEWAY_DIR/docker-compose.yml"
    # echo "$(eval "echo \"$BEDROCK_GATEWAY_COMPOSE_CONTENT\"")" > "$BEDROCK_GATEWAY_DIR/docker-compose.yml"
    # echo "Docker composefile for bedrock gateway created"

    sudo chown -R ec2-user:ec2-user $BEDROCK_GATEWAY_DIR
    sudo chown -R ec2-user:ec2-user /home/ec2-user/temp

    echo "Creating Bedrock Gateway container"
    cd $BEDROCK_GATEWAY_DIR

    if ! docker_command "docker-compose up -d --quiet-pull"; then
        log "Failed to start containers. Cleaning up and exiting."
        cleanup
        exit 1
    fi

    sudo chown -R ec2-user:ec2-user $OPEN_WEBUI_DIR/..


    echo "Creating OpenHands container..."
    export OPENHANDS_DIR=/home/ec2-user/docker/openhands
    cd $OPENHANDS_DIR
    if ! docker_command "docker-compose up -d --quiet-pull"; then
        log "Failed to start open hands containers."
    fi
    sudo chown -R ec2-user:ec2-user $OPENHANDS_DIR/..
    echo "Done creating OpenHands container."

}

docker_command() {
    local cmd="$1"
    local max_attempts=3
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if timeout 300 $cmd; then
            return 0
        fi
        log "Docker command failed. Attempt $attempt of $max_attempts. Retrying in 10 seconds..."
        sleep 10
        ((attempt++))
    done

    log "Docker command failed after $max_attempts attempts."
    return 1
}

get_code_from_s3 (){

    # Create the ~/code directory if it doesn't exist
    CODE_DIR=/home/ec2-user/code
    mkdir -p $CODE_DIR

    # Download all files from S3 bucket to ~/code
    aws s3 sync s3://${DATA_BUCKET_NAME}/code $CODE_DIR

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

    sudo chown -R ec2-user:ec2-user $CODE_DIR
    cp -a /home/ec2-user/code/docker /home/ec2-user/
    cp -a /home/ec2-user/code/scripts /home/ec2-user/
    cp -a /home/ec2-user/code/ansible /home/ec2-user/
    cp -a /home/ec2-user/code/web-apps /home/ec2-user/
    cp -a /home/ec2-user/code/code-server-extensions /home/ec2-user/

    echo "Download and unzip process completed."
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

        sudo openssl req -x509 -nodes -days $DAYS_VALID \
            -keyout $CERT_DIR/server.key \
            -out $CERT_DIR/server.crt \
            -config $CERT_DIR/server.cnf

        sudo chown caddy:caddy $CERT_DIR/server.key $CERT_DIR/server.crt
        sudo chmod 600 $CERT_DIR/server.key
        sudo chmod 644 $CERT_DIR/server.crt

        sudo rm $CERT_DIR/server.cnf

        echo "Self-signed certificate created for $DOMAIN and IP $IP_ADDRESS"
        echo "Certificate location: $CERT_DIR/server.crt"
        echo "Private key location: $CERT_DIR/server.key"

        # # echo "$CADDYFILE_CONTENT" > "/etc/caddy/Caddyfile"
        # echo "Download caddy.zip from S3 and expand in /etc/caddy"

        # # Download caddy.zip from S3
        # echo "Downloading caddy.zip from S3..."
        # aws s3 cp s3://${DATA_BUCKET_NAME}/code/caddy.zip /tmp/caddy.zip

        # # Check if the download was successful
        # if [ $? -ne 0 ]; then
        #     echo "Error: Failed to download caddy.zip from S3."
        #     exit 1
        # fi

        # # Expand the zip file in /etc/caddy
        # echo "Expanding caddy.zip in /etc/caddy..."
        # sudo unzip -o /tmp/caddy.zip -d /etc/caddy

        # # Check if the expansion was successful
        # if [ $? -ne 0 ]; then
        #     echo "Error: Failed to expand caddy.zip."
        #     exit 1
        # fi

        # # Clean up the temporary zip file
        # rm /tmp/caddy.zip

        # echo "caddy.zip has been successfully downloaded and expanded in /etc/caddy."

        echo "Copying caddy files from /home/ec2-user/code/caddy to /etc/caddy"
        sudo cp -R /home/ec2-user/code/caddy /etc

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

install_code_server() {
    if su - ec2-user -c 'command -v code-server'; then
        echo "code-server is already installed."
    else
        echo "Installing code-server..."
        su - ec2-user -c "
            curl -fsSL https://code-server.dev/install.sh | sh -s -- --version=4.96.2

            mkdir -p /home/ec2-user/.config/code-server

            cat << EOF > /home/ec2-user/.config/code-server/config.yaml
bind-addr: 127.0.0.1:8104
auth: password
password: $CODE_SERVER_PASSWORD
cert: false
EOF
        "
        sudo systemctl enable --now code-server@ec2-user
        
    fi
}

install_portainer() {
    echo "Installing portainer in docker"
    export PORTAINER_DIR=/home/ec2-user/docker/portainer
    # mkdir -p $PORTAINER_DIR
    # echo "$PORTAINER_COMPOSE_CONTENT" > "$PORTAINER_DIR/docker-compose.yml"
    cd $PORTAINER_DIR
    docker-compose up -d --quiet-pull
    sudo chown -R ec2-user:ec2-user $PORTAINER_DIR
    echo "Portainer installed"
}

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

install_jupyterlab() {
    if su - ec2-user -c 'command -v jupyter'; then
        echo "JupyterLab is already installed."
    else
        echo "Installing JupyterLab..."
        su - ec2-user -c '
            $HOME/miniconda/bin/pip install --quiet jupyterlab boto3 ansible
            $HOME/miniconda/bin/jupyter --version
        '
    fi

    echo "Configuring JupyterLab to run on port 8106..."

    mkdir -p /home/ec2-user/.jupyter
    cat << EOF > /home/ec2-user/.jupyter/jupyter_server_config.py
c.ServerApp.port = 8103
c.ServerApp.ip = "0.0.0.0"
c.ServerApp.allow_origin = "*"
c.ServerApp.open_browser = False
c.ServerApp.disable_check_xsrf = True
c.ServerApp.root_dir = '/home/ec2-user'
c.ServerApp.token = "$JUPYTER_LAB_TOKEN"
EOF

    chown -R ec2-user:ec2-user /home/ec2-user/.jupyter


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

create_utils() {
    echo "Installing git..."
    sudo yum install git -y    

    echo "Installing nodejs..."
    sudo dnf install nodejs -y

    echo "Installing vsce..."
    sudo npm install -g vsce

    mkdir -p /home/ec2-user/.local/bin
    cat << 'EOF' > /home/ec2-user/.local/bin/tail_setup_log
#!/bin/bash
sudo tail -f /var/log/user-data.log  
EOF


    cat << 'EOF' > /home/ec2-user/.local/bin/less_setup_log
#!/bin/bash
sudo less +G /var/log/user-data.log
EOF



    cat << EOF > /home/ec2-user/.local/bin/show_passwords
#!/bin/bash
echo === Password for code-server ===
echo To change this password, edit file: /home/ec2-user/.config/code-server/config.yaml 
grep -E 'password:' /home/ec2-user/.config/code-server/config.yaml
echo 
echo === Token for Jupyter Lab ===
echo To change this token, edit file: /home/ec2-user/.jupyter/jupyter_server_config.py 
grep -E c.ServerApp.token /home/ec2-user/.jupyter/jupyter_server_config.py
echo 
echo === LiteLLM Key ===
echo To change this key, edit file: /home/ec2-user/docker/open-webui/docker-compose.yml 
grep -E 'LITELLM_API_KEY=' /home/ec2-user/docker/open-webui/docker-compose.yml | sed 's/^[[:space:]]*//'
echo
echo === Controller Lambda auth key ===
echo To change this key edit the parameter store value "/$PROJECT_ID/info", update key "controller_auth_key"
aws ssm get-parameter --name "/$PROJECT_ID/info" --with-decryption | jq -r '.Parameter.Value' | jq -r '.controller_auth_key'
EOF

    chmod 755 /home/ec2-user/.local/bin/tail_setup_log
    chmod 755 /home/ec2-user/.local/bin/less_setup_log
    chmod 755 /home/ec2-user/.local/bin/show_passwords

    chown -R ec2-user:ec2-user /home/ec2-user/.local

}

create_apps_json() {
    SCRIPTS_DIR=/home/ec2-user/scripts

    # mkdir -p $SCRIPTS_DIR

    # cp /etc/caddy/Caddyfile $SCRIPTS_DIR

    cd $SCRIPTS_DIR

    # echo "$GENERATE_APP_URLS_PY_CONTENT" > "$SCRIPTS_DIR/generate-app-urls.py"

    chown -R ec2-user:ec2-user $SCRIPTS_DIR
    
    su - ec2-user -c '
        cd /home/ec2-user/scripts
        python generate-app-urls.py
    '

    # echo Contents of apps.json
    # cat apps.json

    # echo "Copying apps.json to s3://$DATA_BUCKET_NAME"

    # aws s3 cp apps.json s3://$DATA_BUCKET_NAME/

    # if [ $? -eq 0 ]; then
    #     echo "File uploaded successfully to s3"
    # else
    #     echo "Error uploading file"
    #     exit 1  
    # fi    

    # apps_value=$(cat apps.json)

    # aws ssm put-parameter \
    #     --name "/$PROJECT_ID/apps" \
    #     --value "$apps_value" \
    #     --type "String" \
    #     --overwrite    

    # # rm Caddyfile
    # # rm apps.json

    echo "apps.json has been generated."
}

register_start() {
    current_datetime=$(date "+%Y-%m-%d %H:%M:%S")
    echo "$current_datetime" > "$PROJECT_ID-ec2-setup-started"
    echo "Copying $PROJECT_ID-ec2-setup-started to s3://$DATA_BUCKET_NAME"
    aws s3 cp $PROJECT_ID-ec2-setup-started s3://$DATA_BUCKET_NAME/
    rm $PROJECT_ID-ec2-setup-started

    S3_FILE_PATH="s3://${DATA_BUCKET_NAME}/${PROJECT_ID}-ec2-setup-ended"
    aws s3 rm "$S3_FILE_PATH" --quiet
}

register_end() {
    current_datetime=$(date "+%Y-%m-%d %H:%M:%S")
    echo "$current_datetime" > "$PROJECT_ID-ec2-setup-ended"
    echo "Copying $PROJECT_ID-ec2-setup-ended to s3://$DATA_BUCKET_NAME"
    aws s3 cp $PROJECT_ID-ec2-setup-ended s3://$DATA_BUCKET_NAME/
    rm $PROJECT_ID-ec2-setup-ended
}

add_vars_to_bashrc() {
    # Array of variable names to add to .bashrc
    variables=(
        "PROJECT_ID"
        "AWS_REGION"
        "AWS_DEFAULT_REGION"
        "CODE_SERVER_PASSWORD"
        "LITELLM_API_KEY"
        "BEDROCK_GATEWAY_API_KEY"
        "JUPYTER_LAB_TOKEN"
        "DATA_BUCKET_NAME"
    )

    # Path to .bashrc file
    bashrc_file="/home/ec2-user/.bashrc"

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

# Main execution
register_start
update_dnf
add_vars_to_bashrc
get_code_from_s3
create_utils
install_ansible
install_docker
install_docker_compose
start_containers
install_portainer
install_caddy
install_code_server
install_miniconda
install_jupyterlab
create_apps_json
register_end

echo "All installations completed."