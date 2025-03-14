@echo off
setlocal enabledelayedexpansion

set "PROJECT_DIR=%CD%"

set LAUNCHER_PATH=%PROJECT_DIR%\launcher.bat

echo @echo off > "%LAUNCHER_PATH%"

if defined AWS_DEFAULT_PROFILE (
    echo set AWS_DEFAULT_PROFILE=%AWS_DEFAULT_PROFILE% >> "%LAUNCHER_PATH%"
) else (
    if not defined AWS_ACCESS_KEY_ID (
        echo Error: AWS_ACCESS_KEY_ID is not set.
        exit /b 1
    )
    if not defined AWS_SECRET_ACCESS_KEY (
        echo Error: AWS_SECRET_ACCESS_KEY is not set.
        exit /b 1
    )
    if not defined AWS_SESSION_TOKEN (
        echo Error: AWS_SESSION_TOKEN is not set.
        exit /b 1
    )

    echo SET AWS_ACCESS_KEY_ID=%AWS_ACCESS_KEY_ID% >> "%LAUNCHER_PATH%"
    echo SET AWS_SECRET_ACCESS_KEY=%AWS_SECRET_ACCESS_KEY% >> "%LAUNCHER_PATH%"
    echo SET AWS_SESSION_TOKEN=%AWS_SESSION_TOKEN% >> "%LAUNCHER_PATH%"
)

echo start cmd /k "cd /d %PROJECT_DIR% && call scripts\start-dev.bat" >> "%LAUNCHER_PATH%"

echo Launcher created successfully at %LAUNCHER_PATH%

explorer .

echo Opening explorer. Double click "launcher.bat"