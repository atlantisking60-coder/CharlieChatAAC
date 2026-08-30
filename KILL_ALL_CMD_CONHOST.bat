@echo off

:: Kill any duplicate dev_server.py instances left bound to port 8787.
:: Windows can let multiple processes bind the same port (SO_REUSEADDR-like
:: behavior), which causes requests to randomly hit a stale/hung process
:: and the browser to report "didn't send any data". Clearing anything on
:: 8787 before a fresh RUN_WEB_LIVE_PREVIEW.bat launch avoids that.
:: NOTE: This must run BEFORE the conhost.exe/cmd.exe kill below, since
:: that kill terminates this very script's own cmd.exe host mid-run and
:: breaks the "for /f" subshell this loop depends on.
echo Killing anything listening on port 8787 (dev save server)...
for /f "tokens=5" %%P in ('netstat -ano ^| findstr /R /C:":8787 .*LISTENING"') do (
    taskkill /F /PID %%P >nul 2>&1
)

echo Killing all conhost.exe and cmd.exe processes...

taskkill /F /IM conhost.exe >nul 2>&1
taskkill /F /IM cmd.exe >nul 2>&1

:: This batch will also close itself.
