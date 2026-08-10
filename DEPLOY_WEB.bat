@echo off
setlocal

cd /d "%~dp0"

if not exist "pubspec.yaml" (
    echo ERROR: This batch file must be run from the Charlie Chat project root.
    pause
    exit /b 1
)

echo [1/4] Updating pubspec.yaml with all current assets...
python tools\update_pubspec_assets.py
if errorlevel 1 (
    echo Python updater failed; trying PowerShell fallback...
    powershell -ExecutionPolicy Bypass -File "tools\update_pubspec_assets.ps1"
    if errorlevel 1 (
        echo ERROR: update_pubspec_assets failed.
        pause
        exit /b 1
    )
)

echo.
echo [2/4] Running flutter pub get...
call flutter pub get
if errorlevel 1 (
    echo ERROR: flutter pub get failed.
    pause
    exit /b 1
)

echo.
echo [3/4] Cleaning and building for web...
if exist "build\web" rd /s /q "build\web"
call flutter build web
if errorlevel 1 (
    echo ERROR: flutter build web failed.
    pause
    exit /b 1
)

echo.
echo [4/4] Committing and pushing to GitHub...
git config --global core.longpaths true
git add -f build\web
git add .

git diff --cached --quiet
if %errorlevel% == 0 (
    echo Nothing changed. Skipping commit.
    pause
    exit /b 0
)

git commit -m "Update web build - %date% %time%"
if errorlevel 1 (
    echo ERROR: git commit failed. Check your git user.name and user.email config.
    pause
    exit /b 1
)

git push
if errorlevel 1 (
    echo ERROR: git push failed.
    pause
    exit /b 1
)

echo.
echo Done. Netlify will pick up the new commit and publish the updated site.
echo.
pause
