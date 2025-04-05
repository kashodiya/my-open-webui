@echo off
setlocal enabledelayedexpansion

echo Waiting for the log to start...

set REMOTE_FILE=/home/ubuntu/user-data.log

:check_log
:: Run SSH command to check if file exists
ssh -i "%PROJECT_DIR%\keys\private_key.pem" ubuntu@%ELASTIC_IP_G% "test -f %REMOTE_FILE% && exit 0 || exit 1"
if %errorlevel% equ 0 (
    echo Log is ready. Starting tail...
    ssh -i "%PROJECT_DIR%\keys\private_key.pem" ubuntu@%ELASTIC_IP_G% "tail -f /home/ubuntu/user-data.log"
) else (
    echo Waiting for log to become available...
    timeout /t 5 /nobreak >nul
    goto check_log
)

endlocal