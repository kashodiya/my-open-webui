@echo off
setlocal enabledelayedexpansion

:: Run the SCP command
scp -r -i %PDIR%keys\main.pem "%PDIR%gpu-ec2\caddy\Caddyfile" ubuntu@%EC2_IP_GPU%:/etc/caddy/Caddyfile

echo File transferred successfully.

@REM Only do following 2 lines first time
@REM scp -r -i %PDIR%keys\main.pem "%PDIR%gpu-ec2\caddy\gen-certs.sh" ec2-user@%EC2_IP_GPU%:/tmp/
@REM ssh -i %PDIR%keys\main.pem ec2-user@%EC2_IP_GPU% "sh /tmp/gen-certs.sh"

@REM TODO: Check if param is folder then call install.sh else do following
ssh -i %PDIR%keys\main.pem ubuntu@%EC2_IP_GPU% "sudo systemctl reload caddy && sudo systemctl status caddy"
