@echo off
setlocal

cd /d "%~dp0"

if not exist "pubspec.yaml" (
    echo ERROR: This batch file must be run from the Charlie Chat project root.
    pause
    exit /b 1
)

if not exist "Logs" mkdir "Logs"
set "LOGFILE=Logs\live_preview_log.txt"

echo ============================================= > "%LOGFILE%"
echo   Charlie Chat - Web Live Preview          >> "%LOGFILE%"
echo   Started: %date% %time%                   >> "%LOGFILE%"
echo ============================================= >> "%LOGFILE%"
echo.                                            >> "%LOGFILE%"

echo [1/3] Updating pubspec assets and building Flutter web app...
echo [1/3] Updating pubspec assets and building Flutter web app... >> "%LOGFILE%"

echo [1a] Updating pubspec.yaml...
echo [1a] Updating pubspec.yaml...               >> "%LOGFILE%"
python tools\update_pubspec_assets.py           >> "%LOGFILE%" 2>&1
if errorlevel 1 (
    echo.
    echo ERROR: update_pubspec_assets.py failed. See %LOGFILE% for details.
    pause
    exit /b 1
)

echo [1b] Running flutter clean...
echo [1b] Running flutter clean...               >> "%LOGFILE%"
call flutter clean                              >> "%LOGFILE%" 2>&1

echo [1c] Running flutter pub get...
echo [1c] Running flutter pub get...             >> "%LOGFILE%"
call flutter pub get                            >> "%LOGFILE%" 2>&1
if errorlevel 1 (
    echo.
    echo ERROR: flutter pub get failed. See %LOGFILE% for details.
    pause
    exit /b 1
)

echo [1d] Building Flutter web app...
echo [1d] Building Flutter web app...            >> "%LOGFILE%"
if exist "build\web" rd /s /q "build\web"
call flutter build web --no-wasm-dry-run --no-tree-shake-icons >> "%LOGFILE%" 2>&1
if errorlevel 1 (
    echo.
    echo ERROR: flutter build web failed. See %LOGFILE% for details.
    pause
    exit /b 1
)

if not exist "build\web\index.html" (
    echo.
    echo ERROR: build\web\index.html is missing. The build did not produce a web app.
    echo Check %LOGFILE% for details.
    pause
    exit /b 1
)

echo [2/3] Starting dev save server on port 8787...
echo [2/3] Starting dev save server on port 8787... >> "%LOGFILE%"
start "Charlie Chat Dev Server 8787" /min python tools\dev_server.py 8787

timeout /t 3 /nobreak >nul

echo [3/3] Opening browser at http://localhost:8787...
echo [3/3] Opening browser at http://localhost:8787... >> "%LOGFILE%"
start http://localhost:8787

echo.
echo Live preview is running at http://localhost:8787
echo This dev server also serves the latest build from build\web.
echo.
echo Logs: %LOGFILE%
echo.
exit /b 0
