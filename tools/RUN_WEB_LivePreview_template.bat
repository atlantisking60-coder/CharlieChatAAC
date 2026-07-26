@echo off
setlocal EnableExtensions

:: Run from the script folder so relative paths work reliably
pushd "%~dp0" >nul || (
  echo ERROR: Could not change to script directory.
  pause
  exit /b 1
)

title Charlie Chat - Web Live Preview
color 0A
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
echo               lib/data/boards/ automatically.
echo.
echo Any .dart file saved in your editor will
echo reflect in the browser within 1-2 seconds.
echo.
echo =============================================
echo.
if not exist "pubspec.yaml" (
  echo ERROR: This batch file must be run from the Charlie Chat project root.
  popd
  pause
  exit /b 1
)

set "FLUTTER_CMD="
set "DART_CMD="

:: Locate flutter and dart on PATH (works when installed via flutter_windows_*.zip)
for /f "delims=" %%I in ('where flutter.bat 2^>nul') do if not defined FLUTTER_CMD set "FLUTTER_CMD=%%~fI"
for /f "delims=" %%I in ('where flutter 2^>nul') do if not defined FLUTTER_CMD set "FLUTTER_CMD=%%~fI"
for /f "delims=" %%I in ('where dart.exe 2^>nul') do if not defined DART_CMD set "DART_CMD=%%~fI"
for /f "delims=" %%I in ('where dart 2^>nul') do if not defined DART_CMD set "DART_CMD=%%~fI"

if not defined FLUTTER_CMD (
  echo ERROR: Flutter was not found in PATH.
  echo Make sure Flutter SDK is installed and its \bin folder is added to PATH.
  popd
  pause
  exit /b 1
)

:: If dart not found, try next to flutter.exe/flutter.bat
if not defined DART_CMD (
  for %%I in ("%FLUTTER_CMD%") do set "FLUTTER_DIR=%%~dpI"
  if exist "%FLUTTER_DIR%dart.exe" set "DART_CMD=%FLUTTER_DIR%dart.exe"
)

if not defined DART_CMD (
  echo ERROR: Dart was not found alongside Flutter.
  echo Please install or repair the Flutter SDK.
  popd
  pause
  exit /b 1
)

echo.
echo Ensuring Flutter dependencies are up to date...
call "%FLUTTER_CMD%" pub get
if errorlevel 1 (
  echo WARNING: flutter pub get failed. The web preview may still start if dependencies are already available.
)

if not exist "tools\dev_save_server.dart" (
  echo ERROR: tools/dev_save_server.dart was not found.
  popd
  pause
  exit /b 1
)

echo.
echo Launching Dev Save Server (to persist edits)...
:: Use cmd /c with start to ensure quoted executable + args work across environments
start "Charlie Chat Dev Save Server" /B cmd /c ""%DART_CMD%" run tools/dev_save_server.dart"

if exist "assets\symbols" (
  echo Web preview assets detected.
) else (
  echo Warning: assets/symbols was not found. The app may still run, but some assets may be missing.
)

echo.
echo Launching Flutter web server...
call "%FLUTTER_CMD%" config --enable-web
if errorlevel 1 (
  echo WARNING: Could not enable web support automatically. Continuing with the run step.
)

call "%FLUTTER_CMD%" run -d chrome --web-port=8080 --hot --web-hostname=localhost
if errorlevel 1 (
  echo.
  echo Chrome launch failed. Falling back to the web-server target.
  echo Open http://localhost:8080 after the server starts.
  call "%FLUTTER_CMD%" run -d web-server --web-port=8080 --web-hostname=0.0.0.0
)

echo.
echo Session ended. Press any key to close.
pause >nul
popd >nul
