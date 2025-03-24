@REM ssh -i "%PROJECT_DIR%\keys\private_key.pem" ec2-user@%ELASTIC_IP% "tail_setup_log"


@echo off
setlocal enabledelayedexpansion

echo Waiting for the log to start...

set REMOTE_FILE=/home/ec2-user/.local/bin/tail_setup_log



:check_log
:: Run SSH command to check if file exists
ssh -i "%PROJECT_DIR%\keys\private_key.pem" ec2-user@%ELASTIC_IP% "test -f %REMOTE_FILE% && exit 0 || exit 1"
@REM ssh -i "%PROJECT_DIR%\keys\private_key.pem" ec2-user@%ELASTIC_IP% "command -v tail_setup_log" >nul 2>&1
@REM if %errorlevel% equ 0 (
if %errorlevel% equ 0 (
    echo Log is ready. Starting tail...
    ssh -i "%PROJECT_DIR%\keys\private_key.pem" ec2-user@%ELASTIC_IP% "tail_setup_log"
) else (
    echo Waiting for log to become available...
    timeout /t 5 /nobreak >nul
    goto check_log
)

endlocal