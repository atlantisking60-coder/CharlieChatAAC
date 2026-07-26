@echo off
setlocal
cd /d "%~dp0"
echo Processing images... Please wait.
python image_processor.py %*
echo.
if %errorlevel% neq 0 (
    echo ERROR: Python script failed with exit code %errorlevel%
    echo.
    cmd /k
) else (
    echo All done! You can close this window.
    pause
)
