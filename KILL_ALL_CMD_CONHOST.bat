@echo off

echo Killing all conhost.exe and cmd.exe processes...

taskkill /F /IM conhost.exe >nul 2>&1
taskkill /F /IM cmd.exe >nul 2>&1

:: This batch will also close itself.
