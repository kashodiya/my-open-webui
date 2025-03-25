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
) else (
    echo Folder "%folderName%" does not exist.
)

endlocal
exit /b 0