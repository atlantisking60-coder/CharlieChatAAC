@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: Run from the script folder so relative paths work reliably
pushd "%~dp0" >nul || (
  echo ERROR: Could not change to script directory.
  pause
  exit /b 1
)

title Charlie Chat - Web Live Preview
color 0A

:: ── Live-error log setup ──────────────────────────────────────────
set "LOGFILE=%~dp0live_preview_log.txt"
set "LOGTIMESTAMP=%date% %time%"

:: Create / overwrite the log file immediately with a header
(
  echo =============================================
  echo   Charlie Chat - Web Live Preview Error Log
  echo =============================================
  echo Session started: %LOGTIMESTAMP%
  echo ---------------------------------------------
  echo.
) > "%LOGFILE%"

:START
cls
echo.
echo =============================================
echo   Charlie Chat  ^|  Web Live Preview
echo =============================================
echo.
echo Starting Flutter web server with hot reload...
echo Your browser will open automatically when possible.
echo.
echo HOT RELOAD  : Press r  in this window
echo HOT RESTART : Press R  in this window
echo QUIT        : Press q  in this window
echo.
echo NOTE        : Ports 8080 and 8787 are cleaned up
echo               automatically when this window closes.
echo.
echo DEV SERVER  : Board edits will be saved to
echo               lib/data/boards/[Area]/[BoardName]/ automatically.
echo.
echo LIVE LOG    : %LOGFILE%
echo.
echo =============================================
echo.

>> "%LOGFILE%" echo =============================================
>> "%LOGFILE%" echo   Charlie Chat  ^|  Web Live Preview
>> "%LOGFILE%" echo =============================================
>> "%LOGFILE%" echo.
>> "%LOGFILE%" echo Starting Flutter web server with hot reload...
>> "%LOGFILE%" echo Session: %LOGTIMESTAMP%
>> "%LOGFILE%" echo.

if not exist "pubspec.yaml" (
  echo ERROR: This batch file must be run from the Charlie Chat project root.
  echo Current directory: %CD%
  >> "%LOGFILE%" echo [FATAL] Not in project root. pubspec.yaml missing. CD=%CD%
  goto :EXIT_PROMPT
)

set "FLUTTER_CMD="
set "DART_CMD="

:: 1. Try finding flutter in system PATH
for /f "delims=" %%I in ('where flutter.bat 2^>nul') do if not defined FLUTTER_CMD set "FLUTTER_CMD=%%~fI"
for /f "delims=" %%I in ('where flutter 2^>nul') do if not defined FLUTTER_CMD set "FLUTTER_CMD=%%~fI"

:: 2. Try common installation locations if not found
if not defined FLUTTER_CMD (
    for %%D in ("C:\flutter\bin" "C:\src\flutter\bin" "D:\flutter\bin" "%USERPROFILE%\flutter\bin" "%USERPROFILE%\src\flutter\bin") do (
        if exist "%%~D\flutter.bat" set "FLUTTER_CMD=%%~D\flutter.bat"
    )
)

:: 3. Manual path prompt if still not found
if not defined FLUTTER_CMD (
  echo ERROR: Flutter was not found in your PATH or common installation folders.
  echo.
  echo If you have Flutter installed, please enter the full path to the 'flutter\bin' folder.
  echo Example: C:\src\flutter\bin
  echo.
  >> "%LOGFILE%" echo [FATAL] Flutter not found in PATH or common locations.
  set /p "USER_FLUTTER_PATH=Path to flutter\bin (or press Enter to try auto-detect again): "
  if not "!USER_FLUTTER_PATH!"=="" (
    if exist "!USER_FLUTTER_PATH!\flutter.bat" (
      set "FLUTTER_CMD=!USER_FLUTTER_PATH!\flutter.bat"
    ) else (
      echo.
      echo ERROR: "!USER_FLUTTER_PATH!\flutter.bat" does not exist.
      >> "%LOGFILE%" echo [FATAL] User-supplied path does not exist: !USER_FLUTTER_PATH!\flutter.bat
      echo Press any key to try again...
      pause >nul
      goto :START
    )
  ) else (
    goto :START
  )
)

>> "%LOGFILE%" echo [INFO] Flutter found: %FLUTTER_CMD%

:: Locate dart - try several common locations inside Flutter SDK
for %%I in ("%FLUTTER_CMD%") do set "FLUTTER_DIR=%%~dpI"

if exist "%FLUTTER_DIR%dart.exe" (
    set "DART_CMD=%FLUTTER_DIR%dart.exe"
) else if exist "%FLUTTER_DIR%cache\dart-sdk\bin\dart.exe" (
    set "DART_CMD=%FLUTTER_DIR%cache\dart-sdk\bin\dart.exe"
) else (
    :: Fallback to PATH
    for /f "delims=" %%I in ('where dart.exe 2^>nul') do if not defined DART_CMD set "DART_CMD=%%~fI"
)

:: Last ditch: use "flutter dart" command if we have flutter but no direct dart.exe path
if not defined DART_CMD (
    set "DART_CMD=%FLUTTER_CMD% dart"
)

>> "%LOGFILE%" echo [INFO] Dart found: %DART_CMD%

echo.
echo [1/4] Ensuring dependencies...
>> "%LOGFILE%" echo [1/4] Running flutter clean ...
call "%FLUTTER_CMD%" clean >> "%LOGFILE%" 2>&1
>> "%LOGFILE%" echo [1/4] Running flutter pub get ...
call "%FLUTTER_CMD%" pub get >> "%LOGFILE%" 2>&1
if errorlevel 1 (
  echo WARNING: 'flutter pub get' failed.
  >> "%LOGFILE%" echo [WARNING] flutter pub get failed with errorlevel %errorlevel%.
) else (
  >> "%LOGFILE%" echo [1/4] flutter pub get succeeded.
)

if not exist "tools\dev_save_server.dart" (
  echo ERROR: tools/dev_save_server.dart was not found.
  >> "%LOGFILE%" echo [FATAL] tools/dev_save_server.dart not found.
  goto :EXIT_PROMPT
)

:: ── Clean up stale ports from previous sessions ────────────────
echo [2/4] Cleaning up stale ports (8080, 8787)...
>> "%LOGFILE%" echo [2/4] Cleaning up stale ports (8080, 8787)...
for %%P in (8080 8787) do (
  for /f "tokens=5" %%I in ('netstat -aon 2^>nul ^| findstr /r ":%%P .*LISTENING"') do (
    :: Never kill system/idle processes (PID 0 and 4 are reserved).
    if %%I GTR 4 (
      >> "%LOGFILE%" echo [CLEANUP] Killing PID %%I on port %%P
      taskkill /F /PID %%I >nul 2>&1
    ) else (
      >> "%LOGFILE%" echo [CLEANUP] Skipping protected PID %%I on port %%P
    )
  )
)
>> "%LOGFILE%" echo [2/4] Port cleanup complete.
timeout /t 1 /nobreak >nul

echo.
echo [3/4] Launching Dev Save Server (via tee script)...
>> "%LOGFILE%" echo [3/4] Launching Dev Save Server (via tee script)...
:: The dev save server is now started by tools/web_live_preview_tee.dart.

if exist "assets\symbols" (
  echo Symbols folder detected.
  >> "%LOGFILE%" echo [3/4] Symbols folder detected.
) else (
  echo WARNING: assets/symbols was not found. Images may be missing.
  >> "%LOGFILE%" echo [WARNING] assets/symbols not found. Images may be missing.
)

echo.
echo [4/4] Starting Flutter Web Server...
>> "%LOGFILE%" echo [4/4] Starting Flutter Web Server...
call "%FLUTTER_CMD%" config --enable-web >nul

:: ── Start Flutter with live logging via Dart tee helper ───────────
:: All stdout + stderr are shown in the console AND appended to the log.
echo.
echo [LOG] All Flutter output is being saved to:
echo       %LOGFILE%
echo.

>> "%LOGFILE%" echo ---------------------------------------------
>> "%LOGFILE%" echo   Flutter run output begins below
>> "%LOGFILE%" echo ---------------------------------------------
>> "%LOGFILE%" echo.

:: Start with Chrome. If it fails, fallback to web-server mode.
call "%DART_CMD%" run tools/web_live_preview_tee.dart "%FLUTTER_CMD%" "%LOGFILE%" chrome
if errorlevel 1 (
  echo.
  echo Chrome launch failed. Falling back to the generic web-server...
  >> "%LOGFILE%" echo.
  >> "%LOGFILE%" echo [FATAL] Chrome launch failed. Falling back to web-server mode...
  >> "%LOGFILE%" echo.
  echo Once started, open: http://localhost:8080
  echo.
  call "%DART_CMD%" run tools/web_live_preview_tee.dart "%FLUTTER_CMD%" "%LOGFILE%" web-server
)

:EXIT_PROMPT
:: ── Kill any remaining processes on ports 8080 and 8787 ─────────
echo Cleaning up ports 8080 and 8787...
>> "%LOGFILE%" echo.
>> "%LOGFILE%" echo [CLEANUP] Killing remaining processes on ports 8080, 8787...
for %%P in (8080 8787) do (
  for /f "tokens=5" %%I in ('netstat -aon 2^>nul ^| findstr /r ":%%P .*LISTENING"') do (
    :: Never kill system/idle processes (PID 0 and 4 are reserved).
    if %%I GTR 4 (
      >> "%LOGFILE%" echo [CLEANUP] Killing PID %%I on port %%P
      taskkill /F /PID %%I >nul 2>&1
    ) else (
      >> "%LOGFILE%" echo [CLEANUP] Skipping protected PID %%I on port %%P
    )
  )
)
>> "%LOGFILE%" echo [CLEANUP] Done.
>> "%LOGFILE%" echo.
>> "%LOGFILE%" echo ---------------------------------------------
>> "%LOGFILE%" echo   Session ended: %date% %time%
>> "%LOGFILE%" echo ---------------------------------------------
echo =============================================
echo Session ended. Ports 8080 and 8787 released.
echo This window will NOT close automatically.
echo You can scroll up to copy any error messages.
echo.
echo Live log saved to:
echo   %LOGFILE%
echo =============================================
echo.
:: Stay open so user can copy messages
cmd /k
