@echo off
setlocal
cd /d "%~dp0"
echo ============================================
echo  Second pass: Remove interior white backgrounds
echo  Input: PNGs already processed by Remove Background
echo  Output: Cleaned PNGs in a 'cleaned' subfolder
echo ============================================
echo.
python clean_interior.py %*
echo.
if %errorlevel% neq 0 (
    echo ERROR: Python script failed with exit code %errorlevel%
    echo.
    cmd /k
) else (
    echo All done! You can close this window.
    pause
)
