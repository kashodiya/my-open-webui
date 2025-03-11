@echo off
set AWS_DEFAULT_PROFILE=sso-778130744137-AWSAdministratorAccess

set "PROJECT_DIR=%CD%"
set "PATH=%PROJECT_DIR\temp%;%PATH%"
set "TERRAFORM_DIR=%PROJECT_DIR%\terraform"
set "KEYS_DIR=%PROJECT_DIR%\keys"
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"


call %TERRAFORM_DIR%\set-tf-output-2-env-var.bat

echo ===== Terraform values set as env vars =====
type %TERRAFORM_DIR%\set-tf-output-2-env-var.bat


echo ===== Shortcuts =====
doskey tfa=%SCRIPT_DIR%\tf-apply.bat
echo tfa = Terraform apply

doskey sshe=ssh -i %PROJECT_DIR%\keys\private_key.pem ec2-user@%ELASTIC_IP%