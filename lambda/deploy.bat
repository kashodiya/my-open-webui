@echo off
setlocal

REM Check if a parameter is provided
if "%~1"=="" (
    echo Please provide a folder name as a parameter.
    exit /b 1
)

REM Set the folder name from the parameter
set "FOLDER_NAME=%~1"

REM Check if the folder exists
if not exist "%FOLDER_NAME%" (
    echo Folder "%FOLDER_NAME%" does not exist.
    exit /b 1
)

REM Create the zip file using tar
tar -acf function.zip -C "%FOLDER_NAME%" .

echo Zip file created: function.zip

REM Set your Lambda function name
set FUNCTION_NAME=%PROJECT_ID%-%FOLDER_NAME%

REM Set the path to your function.zip file
set ZIP_FILE_PATH=function.zip

REM Check if the ZIP file exists
if not exist "%ZIP_FILE_PATH%" (
    echo Error: function.zip not found at %ZIP_FILE_PATH%
    exit /b 1
)

REM Deploy the Lambda function
echo Deploying Lambda function %FUNCTION_NAME%...
aws lambda update-function-code ^
    --function-name %FUNCTION_NAME% ^
    --zip-file fileb://%ZIP_FILE_PATH% 

if %ERRORLEVEL% neq 0 (
    echo Error: Failed to deploy Lambda function.
    exit /b 1
)

@REM del %ZIP_FILE_PATH%

echo Lambda function %FUNCTION_NAME% deployed successfully.

endlocal