@echo off
setlocal
cd /d "%~dp0"
if "%~1"=="" (
    echo Drag and drop a folder of PNG icons onto this batch file.
    echo.
    pause
    exit /b
)
node "%~dp0.js Files\create_json_from_folder.js" "%~1"
echo.
pause
