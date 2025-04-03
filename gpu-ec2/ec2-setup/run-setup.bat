@echo off
setlocal enabledelayedexpansion

:: Run the SCP command
scp -r -i %PROJECT_DIR%\keys\private_key.pem setup.sh ubuntu@%ELASTIC_IP_G%:/home/ubuntu

echo setup.sh file transferred successfully.

ssh -i %PROJECT_DIR%\keys\private_key.pem ubuntu@%ELASTIC_IP_G% "sudo bash /home/ubuntu/setup.sh"
