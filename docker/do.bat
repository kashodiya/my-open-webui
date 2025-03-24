@echo off
setlocal enabledelayedexpansion
REM Check if at least two parameters are provided
if "%~2"=="" (
    echo Usage: %0 ^<folder^> ^<arguments...^>
    exit /b 1
)
REM Assign the first parameter to the folder variable
set "folder=%~1"
REM Initialize the action variable
set "action="
REM Concatenate all arguments except the first one into the action variable
shift
:loop
if not "%~1"=="" (
    set "action=!action! %~1"
    shift
    goto :loop
)
REM Remove the leading space from the action variable
if defined action set "action=%action:~1%"

REM Display the variables for verification
echo Folder: %folder%
echo Action: %action%

REM Check if ELASTIC_IP environment variable is set
if "%ELASTIC_IP%"=="" (
    echo Error: ELASTIC_IP environment variable is not set.
    exit /b 1
)

REM Check if PROJECT_DIR environment variable is set
if "%PROJECT_DIR%"=="" (
    echo Error: PROJECT_DIR environment variable is not set.
    exit /b 1
)


REM Copy the folder to the EC2 instance using SCP
echo scp -i "%PROJECT_DIR%\keys\private_key.pem" -r "%CD%\%folder%" ec2-user@%ELASTIC_IP%:~/docker/
scp -i "%PROJECT_DIR%\keys\private_key.pem" -r "%CD%\%folder%" ec2-user@%ELASTIC_IP%:~/docker/

REM Check if SCP was successful
if %errorlevel% neq 0 (
    echo Error: Failed to copy folder to EC2 instance.
    exit /b 1
)

REM Run docker-compose command on EC2 using SSH
ssh -i "%PROJECT_DIR%\keys\private_key.pem" ec2-user@%ELASTIC_IP% "cd ~/docker/%folder% && docker-compose %action%"

REM Check if SSH command was successful
if %errorlevel% neq 0 (
    echo Error: Failed to run docker-compose command on EC2 instance.
    exit /b 1
)

echo Operation completed successfully.
exit /b 0