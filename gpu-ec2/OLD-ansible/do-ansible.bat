@echo off
setlocal enabledelayedexpansion

:: Get the full path of the script
set "SCRIPT_PATH=%~dp0"

:: Extract the filename from the parameter
for %%F in (%1) do set "FILENAME=%%~nxF"

:: Check if a parameter was provided
if "%1"=="" (
    echo No YAML file specified. Usage: %0 path\to\your_file.yml
    exit /b 1
)

:: Run the SCP command
scp -r -i %PDIR%keys\main.pem "%SCRIPT_PATH%%1" ec2-user@%EC2_IP_GPU%:/home/ec2-user/setup/ansible/"%FILENAME%"

if %ERRORLEVEL% neq 0 (
    echo SCP command failed.
    exit /b 1
)

echo File transferred successfully.

@REM TODO: Check if param is folder then call install.sh else do following
ssh -i %PDIR%keys\main.pem ec2-user@%EC2_IP_GPU% "cd /home/ec2-user/setup/ansible && ansible-playbook %1"
