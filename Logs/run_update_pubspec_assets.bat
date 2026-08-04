@echo off
pushd "%~dp0"

python tools\update_pubspec_assets.py
if %errorlevel% neq 0 py tools\update_pubspec_assets.py

echo.
if %errorlevel% neq 0 (
    echo Asset update failed.
) else (
    echo pubspec.yaml updated. Now run: flutter pub get, then flutter build web
)
pause
