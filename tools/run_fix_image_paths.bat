@echo off
py -3 tools\fix_image_paths.py
if %errorlevel% neq 0 (
  python tools\fix_image_paths.py
)
pause
