@echo off
setlocal enabledelayedexpansion

scp -i "%PROJECT_DIR%\keys\private_key.pem" "Caddyfile" ec2-user@%ELASTIC_IP%:/tmp

ssh -i "%PROJECT_DIR%\keys\private_key.pem" ec2-user@%ELASTIC_IP% "sudo cp /tmp/Caddyfile /etc/caddy"

if exist "users.txt" (
    scp -i "%PROJECT_DIR%\keys\private_key.pem" "users.txt" ec2-user@%ELASTIC_IP%:/tmp
    ssh -i "%PROJECT_DIR%\keys\private_key.pem" ec2-user@%ELASTIC_IP% "sudo cp /tmp/users.txt /etc/caddy"
)

ssh -i "%PROJECT_DIR%\keys\private_key.pem" ec2-user@%ELASTIC_IP% "sudo systemctl reload caddy && sudo systemctl status caddy"

