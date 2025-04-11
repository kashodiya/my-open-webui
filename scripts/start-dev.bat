@echo off

set "PROJECT_DIR=%CD%"
set "PATH=%PROJECT_DIR\scripts%;%PATH%"
set "TERRAFORM_DIR=%PROJECT_DIR%\terraform"
set "KEYS_DIR=%PROJECT_DIR%\keys"
set "SCRIPTS_DIR=%~dp0"
set "SCRIPTS_DIR=%SCRIPTS_DIR:~0,-1%"

call %TERRAFORM_DIR%\set-tf-output-2-env-var.bat

echo ===== Terraform values set as env vars ===== > help.txt
type %TERRAFORM_DIR%\set-tf-output-2-env-var.bat >> help.txt

echo set PROJECT_DIR=%PROJECT_DIR% >> help.txt
echo set TERRAFORM_DIR=%TERRAFORM_DIR% >> help.txt
echo set KEYS_DIR=%KEYS_DIR% >> help.txt
echo set SCRIPTS_DIR=%SCRIPTS_DIR% >> help.txt

echo ===== Shortcuts ===== >> help.txt
doskey tfa=%SCRIPTS_DIR%\tf-apply.bat
@REM doskey tfa=cd %TERRAFORM_DIR% $T echo "terraform apply" $T terraform apply  
echo tfa   = Terraform apply >> help.txt

doskey tfd=%SCRIPTS_DIR%\tf-destroy.bat
@REM doskey tfd=cd %TERRAFORM_DIR% $T terraform destroy
echo tfd   = Terraform destroy >> help.txt

doskey cdd=cd %PROJECT_DIR%
echo cdd   = CD to project directory >> help.txt

doskey sshe=ssh -i %PROJECT_DIR%\keys\private_key.pem -o ServerAliveInterval=60 -o ServerAliveCountMax=180 ec2-user@%ELASTIC_IP%
echo sshe  = SSH into EC2 >> help.txt

doskey ssheg=ssh -i %PROJECT_DIR%\keys\private_key.pem -o ServerAliveInterval=60 -o ServerAliveCountMax=180 ubuntu@%ELASTIC_IP_G%
echo ssheg = SSH into GPU EC2 >> help.txt

doskey tog=aws ssm start-session --target %INSTANCE_ID_G% --document-name AWS-StartPortForwardingSession --parameters "{\"localPortNumber\":[\"11434\"],\"portNumber\":[\"9114\"]}"
echo tog   = Tunnel to Ollama into GPU EC2 >> help.txt

doskey ec2=aws ec2 start-instances --instance-ids %INSTANCE_ID%
echo ec2   = Start EC2 >> help.txt

doskey ec2g=aws ec2 start-instances --instance-ids %INSTANCE_ID_G%
echo ec2g  = Start GPU EC2 >> help.txt

doskey ec2x=aws ec2 stop-instances --instance-ids %INSTANCE_ID%
echo ec2x  = Stop EC2 >> help.txt

doskey ec2xg=aws ec2 stop-instances --instance-ids %INSTANCE_ID_G%
echo ec2xg = Stop GPU EC2 >> help.txt

doskey ec2s=aws ec2 describe-instances --query "Reservations[].Instances[].[InstanceId, Tags[?Key=='Name'].Value | [0], State.Name]" --output table
echo ec2s  = EC2 status >> help.txt

doskey open-webui=start https://%ELASTIC_IP%:7101/
echo open-webui   = Opens Open WebUI in Browser >> help.txt

doskey portainer=start https://%ELASTIC_IP%:7102/
echo portainer    = Opens Portainer in Browser >> help.txt

doskey jupyterlab=start https://%ELASTIC_IP%:7103/
echo jupyterlab   = Opens Jupyter Lab in Browser >> help.txt

doskey code-server=start https://%ELASTIC_IP%:7104/
echo code-server  = Opens code-server in Browser >> help.txt

doskey litellm=start https://%ELASTIC_IP%:7105/
echo litellm      = Opens LiteLLM in Browser >> help.txt

doskey controller=start %CONTROLLER_URL%
echo controller   = Opens Controller in Browser >> help.txt

doskey comfy=start https://%ELASTIC_IP_G%:7108/
echo comfy        = Opens ComfyUI on GPU in Browser >> help.txt

doskey litellmg=start https://%ELASTIC_IP%:7105/
echo litellmg     = Opens LiteLLM on GPU in Browser >> help.txt

doskey code-serverg=start https://%ELASTIC_IP_G%:7104/
echo code-serverg = Opens code-server on GPU in Browser >> help.txt

doskey open-webuig=start https://%ELASTIC_IP_G%:7101/
echo open-webuig  = Opens Open WebUI on GPU in Browser >> help.txt

doskey jupyterlabg=start https://%ELASTIC_IP%:7103/
echo jupyterlabg  = Opens Jupyter Lab on GPU in Browser >> help.txt


doskey esl=%SCRIPTS_DIR%\ec2-setup-logs.bat
echo esl   = See EC2 setup logs >> help.txt

doskey eslg=%SCRIPTS_DIR%\gpu-ec2-setup-logs.bat
echo eslg   = See EC2 setup logs for GPU >> help.txt

doskey ulc=%SCRIPTS_DIR%\update-litellm-config.bat
echo ulc   = Update LiteLLM config >> help.txt

doskey tcl=aws logs tail /aws/lambda/%PROJECT_ID%-controller --follow
echo tcl   = Tail Controller Lambda logs >> help.txt

doskey tec2=ssh-keygen -R %ELASTIC_IP% $T cd %TERRAFORM_DIR% $T terraform taint aws_instance.main_instance $T %SCRIPTS_DIR%\tf-apply.bat 
echo tec2  = Taint ec2 and destroy and recreate it >> help.txt

doskey tec2g=ssh-keygen -R %ELASTIC_IP_G% $T cd %TERRAFORM_DIR% $T terraform taint aws_instance.gpu_instance[0] $T %SCRIPTS_DIR%\tf-apply.bat 
echo tec2g = Taint GPU ec2 and destroy and recreate it >> help.txt

doskey rkh=ssh-keygen -R %ELASTIC_IP%  
echo rkh   = Remove known SSH host >> help.txt

doskey rkhg=ssh-keygen -R %ELASTIC_IP_G%  
echo rkhg  = Remove known SSH host of GPU EC2 >> help.txt

doskey help=type %PROJECT_DIR%\help.txt
echo help  = Print this help >> help.txt

title %PROJECT_ID%

type help.txt
@REM doskey sshe=ssh -i %PROJECT_DIR%\keys\private_key.pem ec2-user@%ELASTIC_IP%