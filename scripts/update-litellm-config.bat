scp -i "%PROJECT_DIR%\keys\private_key.pem" -r "%PROJECT_DIR%\docker\open-webui\litellm-config.yml" ec2-user@%ELASTIC_IP%:~/docker/open-webui/

ssh -i "%PROJECT_DIR%\keys\private_key.pem" ec2-user@%ELASTIC_IP% "cd ~/docker/open-webui && docker-compose stop litellm && docker-compose up -d litellm"

