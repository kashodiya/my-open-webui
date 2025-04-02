@echo off

set "PROJECT_DIR=%CD%"
set "PATH=%PROJECT_DIR\scripts%;%PATH%"
set "TERRAFORM_DIR=%PROJECT_DIR%\terraform"
set "KEYS_DIR=%PROJECT_DIR%\keys"
set "SCRIPTS_DIR=%~dp0"
set "SCRIPTS_DIR=%SCRIPTS_DIR:~0,-1%"

call %TERRAFORM_DIR%\set-tf-output-2-env-var.bat

echo ===== Terraform values set as env vars =====
type %TERRAFORM_DIR%\set-tf-output-2-env-var.bat

echo ===== Shortcuts =====
doskey tfa=%SCRIPTS_DIR%\tf-apply.bat
@REM doskey tfa=cd %TERRAFORM_DIR% $T echo "terraform apply" $T terraform apply  
echo tfa = Terraform apply

doskey tfd=%SCRIPTS_DIR%\tf-destroy.bat
@REM doskey tfd=cd %TERRAFORM_DIR% $T terraform destroy
echo tfd = Terraform destroy

doskey cdd=cd %PROJECT_DIR%
echo cdd = CD to project directory

doskey sshe=ssh -i %PROJECT_DIR%\keys\private_key.pem -o ServerAliveInterval=60 -o ServerAliveCountMax=180 ec2-user@%ELASTIC_IP%
echo sshe = SSH into EC2

doskey ssheg=ssh -i %PROJECT_DIR%\keys\private_key.pem -o ServerAliveInterval=60 -o ServerAliveCountMax=180 ubuntu@%ELASTIC_IP_G%
echo ssheg = SSH into GPU EC2

doskey ec2=aws ec2 start-instances --instance-ids %INSTANCE_ID%
echo ec2 = Start EC2

doskey ec2g=aws ec2 start-instances --instance-ids %INSTANCE_ID_G%
echo ec2g = Start GPU EC2

doskey ec2x=aws ec2 stop-instances --instance-ids %INSTANCE_ID%
echo ec2x = Stop EC2

doskey ec2xg=aws ec2 stop-instances --instance-ids %INSTANCE_ID_G%
echo ec2xg = Stop GPU EC2

doskey open-webui=start https://%ELASTIC_IP%:7101/
echo open-webui = Opens Open WebUI in Browser

doskey portainer=start https://%ELASTIC_IP%:7102/
echo portainer = Opens Portainer in Browser

doskey jupyterlab=start https://%ELASTIC_IP%:7103/
echo jupyterlab = Opens Jupyter Lab in Browser

doskey code-server=start https://%ELASTIC_IP%:7104/
echo code-server = Opens code-server in Browser

doskey litellm=start https://%ELASTIC_IP%:7105/
echo litellm = Opens LiteLLM in Browser

doskey controller=start %CONTROLLER_URL%
echo controller = Opens Controller in Browser

doskey esl=%SCRIPTS_DIR%\ec2-setup-logs.bat
echo esl = See EC2 setup logs

doskey ulc=%SCRIPTS_DIR%\update-litellm-config.bat
echo ulc = Update LiteLLM config

doskey tcl=aws logs tail /aws/lambda/myowu-controller --follow
echo tcl = Tail Controller Lambda logs

doskey tec2=ssh-keygen -R %ELASTIC_IP% $T cd %TERRAFORM_DIR% $T terraform taint aws_instance.main_instance $T %SCRIPTS_DIR%\tf-apply.bat 
echo tec2 = Taint ec2 and destroy and recreate it

doskey rkh=ssh-keygen -R %ELASTIC_IP%  
echo rkh = Remove known SSH host

doskey rkhg=ssh-keygen -R %ELASTIC_IP_G%  
echo rkhg = Remove known SSH host of GPU EC2

title %PROJECT_ID%

@REM doskey sshe=ssh -i %PROJECT_DIR%\keys\private_key.pem ec2-user@%ELASTIC_IP%