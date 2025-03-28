@echo off
setlocal enabledelayedexpansion

:: Check if a parameter is provided
if "%~1"=="" (
    echo You must provide a folder name.
    exit /b 1
)

:: Set the folder name from the parameter
set "folderName=%~1"

:: Check if the folder exists
if exist "%folderName%\" (
    echo Folder "%folderName%" exists.
    echo Copying files to EC2...
    scp -i "%PROJECT_DIR%\keys\private_key.pem" -r "%folderName%" ec2-user@%ELASTIC_IP%:~/ansible
    scp -i "%PROJECT_DIR%\keys\private_key.pem" -r "%PROJECT_DIR%\web-apps\%folderName%\requirements.txt" ec2-user@%ELASTIC_IP%:~/web-apps/%folderName%/
    echo Running ansible playbook on EC2...
    ssh -i "%PROJECT_DIR%\keys\private_key.pem" ec2-user@%ELASTIC_IP% "cd ~/ansible/%folderName% && ansible-playbook %folderName%.yml"
    echo Done.
) else (
    echo Folder "%folderName%" does not exist.
)

endlocal
exit /b 0