@echo off
title Folder Icon Creator
echo.
echo  Drag image files onto this batch file to create folder icons.
echo  (Up to 50 files at a time)
echo.

if "%~1"=="" (
    echo  No files were dragged onto the script.
    echo  Please drag image files onto this batch file.
    echo.
    pause
    exit /b 1
)

python "%~dp0folder_create.py" %*
if errorlevel 1 (
    echo.
    echo  An error occurred. Make sure Python and Pillow are installed.
    echo  Install Pillow: pip install Pillow
    echo.
    pause
)
