@echo off
setlocal enabledelayedexpansion
set "BASE=lib\data\boards\Legends\Characters\Disney Stories"
for /d %%D in ("%BASE%\*") do (
    for %%F in ("%%D\*.json") do (
        set "FOUND=0"
        for /f "delims=" %%L in ('findstr /n "." "%%F"') do (
            set "LINE=%%L"
            echo !LINE! | findstr /r "_1[89][0-9][0-9]_ _20[0-9][0-9]_" >nul 2>&1
            if !errorlevel! equ 0 (
                echo !LINE! | findstr /c:"label" >nul 2>&1
                if !errorlevel! equ 0 (
                    if !FOUND! equ 0 (
                        echo === %%~nxF ===
                        set "FOUND=1"
                    )
                    echo !LINE!
                )
            )
        )
    )
)
