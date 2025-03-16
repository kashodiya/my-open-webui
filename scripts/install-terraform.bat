@echo off

REM Step 1: Check if running as admin
not session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Not running as Admin. Attempting to elevate permissions...

    :: Step 2: Re-launch the same script with admin privileges:
    :: -Use Powershell to start a new cmd instance with -Verb RunAS
    powershell -Command "Start-Process cmd -ArgumentList "/c \"\"%~f0\" %*\"' -Verb runAs"
    
    :: Step 3: Exit this script (since it's not elevated)
    exit /b 0
)

REM Check if Terraform is already installed
terraform -version >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo Terraform is already installed
    Terraform -version
    pause
    exit /b 0
)

echo Fetching latest Terraform version

REM Use PowerShell to get the latest version of Terraform
for /f "tokens=* usebackq" %%i in ('powershell -NoProfile -Command ^
    "$latest = (Invoke-WebRequest -UseBasicParsing 'https://checkpoint-api.hashicorp.com/v1/check/terraform' | ConvertFrom-Json).current_version; ^
    Write-Host $latest"') do (
    set LATEST_TERRAFORM_VERSION=%%i
)

echo Latest Terraform version is %LATEST_TERRAFORM_VERSION%.
echo Downloading Terraform v%LATEST_TERRAFORM_VERSION% ...

REM Download the latest Terraform ZIP to %TEMP%
powershell -NoProfile -Command ^
    "Invoke-WebRequest -UseBasicParsing -Uri 'https://releases.hashicorp.com/terraform/%LATEST_TERRAFORM_VERSION%/terraform_%LATEST_TERRAFORM_VERSION%_windows_amd64.zip' -OutFile '%TEMP%\terraform.zip'"

REM Create Terraform directory (if it doesn't exist)
mkdir "C:\Program Files\Terraform" 2>nul

REM unzip to Terraform directory
powershell -NoProfile -Command ^
"Expand-Archive -Path '%TEMP%\terraform.zip' -DestinationPath 'C:\Program Files\Terraform' -Force"

REM Add Terraform to System Path
setx PATH "%PATH%;C:\Program Files\Terraform" /M

REM Clean up
del "%TEMP%\terraform.zip"

echo Terraform v%LATEST_TERRAFORM_VERSION% installtion complete.
echo Please restart your Command Prompt (or open a new one) to use Terraform. 
pause