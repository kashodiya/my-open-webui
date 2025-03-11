@echo off
set AWS_DEFAULT_PROFILE=sso-778130744137-AWSAdministratorAccess

set "PROJECT_DIR=%CD%"
set "PATH=%PROJECT_DIR\temp%;%PATH%"
set "TERRAFORM_DIR=%PROJECT_DIR%\terraform"
set "KEYS_DIR=%PROJECT_DIR%\keys"
set "SCRIPTS_DIR=%~dp0"
set "SCRIPTS_DIR=%SCRIPTS_DIR:~0,-1%"

call %TERRAFORM_DIR%\set-tf-output-2-env-var.bat

echo ===== Terraform values set as env vars =====
type %TERRAFORM_DIR%\set-tf-output-2-env-var.bat

echo ===== Shortcuts =====
doskey tfa=%SCRIPTS_DIR%\tf-apply.bat
echo tfa = Terraform apply

doskey sshe=ssh -i %PROJECT_DIR%\keys\private_key.pem -o ConnectTimeout=1200 ec2-user@%ELASTIC_IP%
echo sshe = SSH into EC2

doskey ec2=aws ec2 start-instances --instance-ids %INSTANCE_ID%
echo ec2 = Start EC2

doskey ec2x=aws ec2 stop-instances --instance-ids %INSTANCE_ID%
echo ec2x = Stop EC2

doskey open-webui=start https://%ELASTIC_IP%:8100/
echo open-webui = Opens Open WebUI in Browser

title %PROJECT_ID%

doskey sshe=ssh -i %PROJECT_DIR%\keys\private_key.pem ec2-user@%ELASTIC_IP%