@echo off
setlocal enabledelayedexpansion

:: Check if a parameter is provided
if "%~1"=="" (
    echo You must provide a folder name of the extension.
    exit /b 1
)

:: Set the folder name from the parameter
set "folderName=%~1"

:: Check if the folder exists
if exist "%folderName%\" (
    echo Folder "%folderName%" exists.
    echo Copying files to EC2...
    set EXT_DIR=/home/ec2-user/code-server-extensions

    @REM TODO: Remve following 2 lines
    @REM Create folder
    @REM ssh -i "%PROJECT_DIR%\keys\private_key.pem" ec2-user@%ELASTIC_IP% "mkdir -p !EXT_DIR!"

    @REM TODO: Remve following 2 lines
    @REM Copy deploy bash script
    @REM scp -i "%PROJECT_DIR%\keys\private_key.pem" -r deploy.sh ec2-user@%ELASTIC_IP%:!EXT_DIR!/

    @REM Copy Extension
    scp -i "%PROJECT_DIR%\keys\private_key.pem" -r "%folderName%" ec2-user@%ELASTIC_IP%:!EXT_DIR!
    @REM Deploy extension
    ssh -i "%PROJECT_DIR%\keys\private_key.pem" ec2-user@%ELASTIC_IP% "cd !EXT_DIR! && bash deploy.sh %folderName%"
    echo Done.
) else (
    echo Folder "%folderName%" does not exist.
)

endlocal
exit /b 0