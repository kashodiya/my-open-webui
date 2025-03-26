@echo off
setlocal enabledelayedexpansion

:: Check if a parameter is provided
if "%~1"=="" (
    echo You must provide a folder name of the web app.
    exit /b 1
)

:: Set the folder name from the parameter
set "folderName=%~1"

:: Check if the folder exists
if exist "%folderName%\" (
    echo Folder "%folderName%" exists.
    echo Copying files to EC2...
    scp -i "%PROJECT_DIR%\keys\private_key.pem" -r "%folderName%" ec2-user@%ELASTIC_IP%:~/web-apps
    echo Done.
) else (
    echo Folder "%folderName%" does not exist.
)

endlocal
exit /b 0