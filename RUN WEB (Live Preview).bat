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
echo DEV SERVER  : Board edits will be saved to
echo               lib/data/boards/[Area]/[BoardName]/ automatically.
echo.
echo =============================================
echo.

if not exist "pubspec.yaml" (
  echo ERROR: This batch file must be run from the Charlie Chat project root.
  echo Current directory: %CD%
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
  set /p "USER_FLUTTER_PATH=Path to flutter\bin (or press Enter to try auto-detect again): "
  if not "!USER_FLUTTER_PATH!"=="" (
    if exist "!USER_FLUTTER_PATH!\flutter.bat" (
        set "FLUTTER_CMD=!USER_FLUTTER_PATH!\flutter.bat"
    ) else (
        echo.
        echo ERROR: "!USER_FLUTTER_PATH!\flutter.bat" does not exist.
        echo Press any key to try again...
        pause >nul
        goto :START
    )
  ) else (
    goto :START
  )
)

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

echo.
echo [1/4] Ensuring dependencies...
call "%FLUTTER_CMD%" pub get
if errorlevel 1 (
  echo WARNING: 'flutter pub get' failed.
)

if not exist "tools\dev_save_server.dart" (
  echo ERROR: tools/dev_save_server.dart was not found.
  goto :EXIT_PROMPT
)

echo.
echo [2/4] Launching Dev Save Server (background)...
:: If DART_CMD contains spaces or is a complex command, we wrap carefully
start "Charlie Chat Dev Save Server" /B cmd /c "%DART_CMD% run tools/dev_save_server.dart"

if exist "assets\symbols" (
  echo [3/4] Symbols folder detected.
) else (
  echo WARNING: assets/symbols was not found. Images may be missing.
)

echo.
echo [4/4] Starting Flutter Web Server...
call "%FLUTTER_CMD%" config --enable-web >nul

:: Start with Chrome. If it fails, fallback to web-server mode.
call "%FLUTTER_CMD%" run -d chrome --web-port=8080 --hot --web-hostname=localhost
if errorlevel 1 (
  echo.
  echo Chrome launch failed. Falling back to the generic web-server...
  echo Once started, open: http://localhost:8080
  echo.
  call "%FLUTTER_CMD%" run -d web-server --web-port=8080 --web-hostname=0.0.0.0
)

:EXIT_PROMPT
echo.
echo =============================================
echo Session ended or a fatal error occurred.
echo This window will NOT close automatically.
echo You can scroll up to copy any error messages.
echo =============================================
echo.
:: Instead of exit, we open a new cmd instance that stays open
cmd /k
