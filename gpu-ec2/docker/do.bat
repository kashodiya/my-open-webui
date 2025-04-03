@echo off
setlocal enabledelayedexpansion

:: Check if at least one argument is provided
if "%~1"=="" (
    echo Error: Please provide a folder name.
    echo Usage: %~nx0 [folder_name] [after docker compose commands]
    echo Action: see .scripts folder
    exit /b 1
)

:: Get the folder name from the first argument
set "folder_name=%~1"
shift
set "params="

:loop
if "%~1"=="" goto end
set "params=%params% %~1"
shift
goto loop

:end
set "params=%params:~1%"

@REM :: Get the action from the second argument (if provided)
@REM set "action=%~2"

:: Check if the folder exists in the current directory
if exist "%CD%\%folder_name%\" (
    echo The folder "%folder_name%" exists in the current directory.
    call :deployService
    exit /b 0
) else (
    echo Error: The folder "%folder_name%" does not exist in the current directory.
    exit /b 1
)

:: Subroutine to deploy the service
:deployService
echo.
echo Using folder: %folder_name%
echo Using params: %params%

ssh -i %PDIR%keys\main.pem ubuntu@%EC2_IP_GPU% "mkdir -p /home/ubuntu/docker/%folder_name%"
scp -r -i %PDIR%keys\main.pem %PDIR%gpu-ec2\docker\%folder_name%\* ubuntu@%EC2_IP_GPU%:/home/ubuntu/docker/%folder_name%
@REM ssh -i %PDIR%keys\main.pem ubuntu@%EC2_IP_GPU% "cd /home/ubuntu/docker/%folder_name% && docker-compose %params%"

goto :eof