@echo off
setlocal enabledelayedexpansion
set "file=%~1"
set "scp_command=scp -i "%PROJECT_DIR%\keys\private_key.pem" -r "%file%" ec2-user@%ELASTIC_IP%:/tmp"

echo Copying file to EC2: 
echo %scp_command%

%scp_command%

ssh -i "%PROJECT_DIR%\keys\private_key.pem" ec2-user@%ELASTIC_IP% "sudo cp -R /tmp/%file% /etc/caddy/apps && python ~/scripts/generate-app-urls.py && sudo systemctl reload caddy && sudo systemctl status caddy"
