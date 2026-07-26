@echo off
setlocal EnableExtensions

:: Run from the script folder so relative paths work reliably
pushd "%~dp0" >nul || (
  echo ERROR: Could not change to script directory.
  pause
  exit /b 1
)

title Charlie Chat - Windows Live Preview
color 0B
cls

echo.
echo =============================================
echo   Charlie Chat  |  Windows Live Preview
echo =============================================
echo.
echo Starting Flutter Windows app with hot reload...
echo The native Windows window will open shortly.
echo.
echo HOT RELOAD  : Press r  in this window
echo HOT RESTART : Press R  in this window
echo QUIT        : Press q  in this window
echo.
echo Any .dart file saved in your editor will
echo reflect in the app window within 1-2 seconds.
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

:: Locate flutter on PATH
for /f "delims=" %%I in ('where flutter.bat 2^>nul') do if not defined FLUTTER_CMD set "FLUTTER_CMD=%%~fI"
for /f "delims=" %%I in ('where flutter 2^>nul') do if not defined FLUTTER_CMD set "FLUTTER_CMD=%%~fI"

if not defined FLUTTER_CMD (
  echo ERROR: Flutter was not found in PATH.
  echo Make sure Flutter SDK is installed and its \bin folder is added to PATH.
  popd
  pause
  exit /b 1
)

echo.
echo Ensuring Flutter dependencies are up to date...
call "%FLUTTER_CMD%" pub get
if errorlevel 1 (
  echo WARNING: flutter pub get failed. Continuing anyway...
)

echo.
echo Ensuring Windows desktop support is enabled...
call "%FLUTTER_CMD%" config --enable-windows-desktop
if errorlevel 1 (
  echo WARNING: Could not enable Windows desktop support automatically.
)

echo.
echo Regenerating Windows build files if needed...
call "%FLUTTER_CMD%" create --platforms=windows . >nul 2>&1
if errorlevel 1 (
  echo WARNING: flutter create had issues. Continuing anyway...
)

call "%FLUTTER_CMD%" run -d windows --hot
if errorlevel 1 (
  echo.
  echo ERROR: Flutter Windows launch failed.
  echo Check the error messages above for details.
)

echo.
echo Session ended. Press any key to close.
pause >nul
popd >nul
