@echo off
setlocal
cd /d "%~dp0\.."
python tools\build_montessori_boards.py
pause
