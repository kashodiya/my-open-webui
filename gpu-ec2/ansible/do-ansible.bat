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
echo "Copying %SCRIPT_PATH%%1 to /home/ubuntu/ansible/%FILENAME%"
scp -r -i %PDIR%keys\main.pem "%SCRIPT_PATH%%1" ubuntu@%EC2_IP_GPU%:"/home/ubuntu/ansible/%FILENAME%"

if %ERRORLEVEL% neq 0 (
    echo SCP command failed.
    exit /b 1
)

echo Ansible files transferred successfully.

ssh -i %PDIR%keys\main.pem ubuntu@%EC2_IP_GPU% "cd /home/ubuntu/ansible && bash run-ansible.sh %1"
