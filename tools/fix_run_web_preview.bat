@echo off
setlocal EnableExtensions
set "SCRIPT_PATH=%~dp0RUN WEB (Live Preview).bat"
if not exist "%SCRIPT_PATH%" exit /b 0

copy /Y "%~dp0RUN_WEB_LivePreview_template.bat" "%SCRIPT_PATH%" 2>nul
if errorlevel 1 (
  echo Failed to copy template to %SCRIPT_PATH%
  exit /b 1
)
echo Repaired %SCRIPT_PATH%
