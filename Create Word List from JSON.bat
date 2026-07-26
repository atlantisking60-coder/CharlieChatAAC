@echo off
setlocal
cd /d "%~dp0"
if "%~1"=="" (
    echo Drag and drop a prebuilt JSON file onto this batch file.
    echo.
    pause
    exit /b
)
node "%~dp0create_wordlist_from_json.js" "%~1"
echo.
pause
