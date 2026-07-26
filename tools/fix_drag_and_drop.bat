@echo off
setlocal EnableExtensions
set "ROOT=%~dp0"
set "PS1=%ROOT%fix_drag_and_drop.ps1"
if not exist "%PS1%" (
  echo ERROR: %PS1% was not found.
  pause
  exit /b 1
)

:: Run the PowerShell script (more reliable than a complex inline command)
pwsh -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
if errorlevel 1 (
  echo FAILED: The drag-and-drop fix could not be applied.
  pause
  exit /b 1
)
echo Done.
pause >nul
