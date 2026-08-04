@echo off
setlocal
cd /d "%~dp0"

if "%~1"=="" (
    echo.
    echo Drag and drop a folder of pictures or a .txt word list onto this batch file.
    echo.
    pause
    exit /b
)

python "%~dp0.py Files\build_board_from_pictures.py" "%~1"

if %errorlevel% neq 0 cmd /k
