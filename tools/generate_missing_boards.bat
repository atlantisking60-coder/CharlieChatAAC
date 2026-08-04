@echo off
setlocal
python tools\_generate_missing_boards.py
if %errorlevel% neq 0 (
  echo Failed to generate missing boards. Make sure Python is on your PATH.
  pause
  exit /b %errorlevel%
)
echo Done.
endlocal
