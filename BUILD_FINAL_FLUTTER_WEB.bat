@echo off
setlocal

cd /d "%~dp0"

if not exist "pubspec.yaml" (
    echo ERROR: This batch file must be run from the Charlie Chat project root.
    pause
    exit /b 1
)

echo [1/3] Updating pubspec.yaml with all current assets...
python tools\update_pubspec_assets.py
if errorlevel 1 (
    echo ERROR: update_pubspec_assets.py failed.
    pause
    exit /b 1
)

echo.
echo [2/3] Running flutter pub get...
call flutter pub get
if errorlevel 1 (
    echo ERROR: flutter pub get failed.
    pause
    exit /b 1
)

echo.
echo [3/3] Building for web...
call flutter build web
if errorlevel 1 (
    echo ERROR: flutter build web failed.
    pause
    exit /b 1
)

echo.
echo Build complete. Output is in build\web
echo.
pause
