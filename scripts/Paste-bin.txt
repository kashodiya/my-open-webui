@echo off

REM Step 1: Check if running as admin
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Not running as Admin. Attempting to elevate permissions...
    
    :: Step 2: Re-launch the same script with admin privileges:
    ::    - Use PowerShell to start a new cmd instance with -Verb RunAs
    powershell -Command "Start-Process cmd -ArgumentList '/c \"\"%~f0\" %*\"' -Verb runAs"

    :: Step 3: Exit this script (since it's not elevated)
    exit /b 0
)

REM Step 2: Check if Terraform is already installed
terraform -version >nul 2>&1
if %ERRORLEVEL%==0 (
    echo Terraform is already installed.
    terraform -version
    pause
    exit /b 0
)

echo Installing Terraform...

REM -------------------------------------------
REM STEP 3: Test fetching latest Terraform version
REM -------------------------------------------

REM Set a desired version just for demonstration
for /f "tokens=* usebackq" %%i in (`powershell -NoProfile -Command "(Invoke-WebRequest -UseBasicParsing 'https://checkpoint-api.hashicorp.com/v1/check/terraform' | ConvertFrom-Json).current_version"`) do (
    set LATEST_TERRAFORM_VERSION=%%i
)

echo The latest published Terraform version is "%LATEST_TERRAFORM_VERSION%".


REM Download Terraform (64-bit Windows AMD64)
powershell -Command ^
"Invoke-WebRequest -Uri 'https://releases.hashicorp.com/terraform/%LATEST_TERRAFORM_VERSION%/terraform_%LATEST_TERRAFORM_VERSION%_windows_amd64.zip' -OutFile '%TEMP%\terraform.zip'"

REM Create Terraform directory
mkdir "C:\Program Files\Terraform"

REM Unzip to Terraform directory
powershell -Command ^
"Expand-Archive -Path '%TEMP%\terraform.zip' -DestinationPath 'C:\Program Files\Terraform' -Force"

REM Set Terraform in System PATH
setx PATH "%PATH%;C:\Program Files\Terraform" /M

REM Cleanup downloaded zip
del "%TEMP%\terraform.zip"

echo Terraform installation complete. Please restart Command Prompt to use Terraform.

pause