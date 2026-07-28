@echo off
title Generate Boards
if "%~1"=="__child__" goto MAIN
cmd /k ""%~f0" __child__"
exit /b

:MAIN
cd /d "%~dp0.."

where python >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Python not found. Please install Python and add it to PATH.
    exit /b 1
)

echo Installing requirements...
python -m pip install -r requirements.txt --quiet
if %errorlevel% neq 0 (
    echo ERROR: pip install failed.
    exit /b 1
)

echo Running generate_boards.py...
python ".py Files\generate_boards.py" --verbose
if %errorlevel% neq 0 (
    echo.
    echo ERROR: generate_boards.py exited with code %errorlevel%.
    exit /b %errorlevel%
)

echo.
echo Done. Boards written to lib\data\boards\
