@echo off
setlocal

cd /d "%~dp0"

if not exist "pubspec.yaml" (
    echo ERROR: This batch file must be run from the Charlie Chat project root.
    pause
    exit /b 1
)

if not exist "build\web\index.html" (
    echo.
    echo ERROR: build\web\index.html is missing. Run RUN_WEB_LIVE_PREVIEW.bat first to build the web app.
    pause
    exit /b 1
)

if not exist "Logs" mkdir "Logs"
set "LOGFILE=Logs\live_preview_fast_log.txt"

echo ============================================= > "%LOGFILE%"
echo   Charlie Chat - Fast Web Live Preview       >> "%LOGFILE%"
echo   Started: %date% %time%                     >> "%LOGFILE%"
echo ============================================= >> "%LOGFILE%"
echo.                                              >> "%LOGFILE%"

:: Clean any stale dev server on 8787
for %%P in (8787) do (
    echo Cleaning port %%P...
    for /f "tokens=5" %%I in ('netstat -aon 2^>nul ^| findstr /r ":%%P .*LISTENING"') do (
        if %%I GTR 4 (
            taskkill /F /PID %%I >nul 2>&1
        )
    )
)
timeout /t 1 /nobreak >nul

echo [1/2] Starting dev save server on port 8787...
echo [1/2] Starting dev save server on port 8787... >> "%LOGFILE%"
start "Charlie Chat Dev Server 8787" /min python tools\dev_server.py 8787

timeout /t 2 /nobreak >nul

echo [2/2] Opening browser at http://localhost:8787...
echo [2/2] Opening browser at http://localhost:8787... >> "%LOGFILE%"
start http://localhost:8787

echo.
echo Fast live preview is running at http://localhost:8787
echo Skipped build -- use this only when you have not changed code, assets, or board JSON files.
echo.
echo Logs: %LOGFILE%
echo.
