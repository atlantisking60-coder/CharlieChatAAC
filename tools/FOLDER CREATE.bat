@echo off
title Folder Icon Creator
echo.
echo  Drag an image file onto this batch file to create a folder icon.
echo.

if "%~1"=="" (
    echo  No file was dragged onto the script.
    echo  Please drag an image file onto this batch file.
    echo.
    pause
    exit /b 1
)

python "%~dp0folder_create.py" "%~1"
if errorlevel 1 (
    echo.
    echo  An error occurred. Make sure Python and Pillow are installed.
    echo  Install Pillow: pip install Pillow
    echo.
    pause
)
