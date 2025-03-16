@echo off
setlocal enabledelayedexpansion
set "PROJECT_DIR=%CD%"
set LAUNCHER_PATH=%PROJECT_DIR%\launcher.bat
echo @echo off > "%LAUNCHER_PATH%"
set "CREDS_SET=0"

if defined AWS_DEFAULT_PROFILE (
    echo set AWS_DEFAULT_PROFILE=%AWS_DEFAULT_PROFILE%>> "%LAUNCHER_PATH%"
    set "CREDS_SET=1"
) else (
    if defined AWS_ACCESS_KEY_ID (
        if defined AWS_SECRET_ACCESS_KEY (
            if defined AWS_SESSION_TOKEN (
                echo SET AWS_ACCESS_KEY_ID=%AWS_ACCESS_KEY_ID%>> "%LAUNCHER_PATH%"
                echo SET AWS_SECRET_ACCESS_KEY=%AWS_SECRET_ACCESS_KEY%>> "%LAUNCHER_PATH%"
                echo SET AWS_SESSION_TOKEN=%AWS_SESSION_TOKEN%>> "%LAUNCHER_PATH%"
                set "CREDS_SET=1"
            )
        )
    )
)

if %CREDS_SET%==1 (
    echo start cmd /k "cd /d %PROJECT_DIR% && call scripts\start-dev.bat" >> "%LAUNCHER_PATH%"
    echo Launcher created successfully at %LAUNCHER_PATH%
    explorer .
    echo Opening explorer. Double click "launcher.bat"
) else (
    echo Error: AWS credentials are not set correctly.
    echo ---------------------------------------------
    echo Please set one of following environment variable before running this script:
    echo    AWS_DEFAULT_PROFILE
    echo            OR
    echo    AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, and AWS_SESSION_TOKEN.
    exit /b 1
)