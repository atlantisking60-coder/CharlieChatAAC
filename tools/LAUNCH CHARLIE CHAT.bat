@echo off
title Charlie Chat Launcher
color 0F
cls

:MENU
echo.
echo  ============================================
echo    Charlie Chat  ^|  Live Preview Launcher
echo  ============================================
echo.
echo    [1]  Web Preview     (Chrome, port 8080)
echo    [2]  Windows Preview (native window)
echo    [3]  Both            (web + windows)
echo    [Q]  Quit
echo.
echo  ============================================
echo.

set /p CHOICE="  Your choice: "

if /i "%CHOICE%"=="1" goto WEB
if /i "%CHOICE%"=="2" goto WINDOWS
if /i "%CHOICE%"=="3" goto BOTH
if /i "%CHOICE%"=="q" goto QUIT
if /i "%CHOICE%"=="Q" goto QUIT

echo  Invalid choice. Try again.
goto MENU

:WEB
cls
echo.
echo  Starting Web preview...
echo  HOT RELOAD: r   HOT RESTART: R   QUIT: q
echo.
cd /d "%~dp0"
flutter run -d chrome --web-port=8080 --hot
goto END

:WINDOWS
cls
echo.
echo  Starting Windows preview...
echo  HOT RELOAD: r   HOT RESTART: R   QUIT: q
echo.
cd /d "%~dp0"
where nuget >nul 2>&1
if %errorlevel% neq 0 (
    pwsh -Command "& {Invoke-WebRequest -Uri 'https://dist.nuget.org/win-x86-commandline/latest/nuget.exe' -OutFile '%~dp0nuget.exe'}"
    set PATH=%~dp0;%PATH%
)
flutter create --platforms=windows . >nul 2>&1
flutter run -d windows --hot
goto END

:BOTH
cls
echo.
echo  Launching Windows app in background...
start "Charlie Chat Windows" cmd /k "cd /d "%~dp0" && flutter run -d windows --hot"
echo  Windows app launched in separate window.
echo.
echo  Starting Web preview in this window...
echo  HOT RELOAD: r   HOT RESTART: R   QUIT: q
echo.
cd /d "%~dp0"
flutter run -d chrome --web-port=8080 --hot
goto END

:QUIT
exit /b 0

:END
echo.
echo  Session ended.
pause >nul
