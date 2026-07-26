@echo off
setlocal
set LOGFILE=%~dp0update_flutter.log
>"%LOGFILE%" 2>&1 (
  echo Starting Flutter upgrade at %date% %time%
  C:\Flutter\bin\flutter.bat upgrade --force
  echo.
  echo Exit code: %ERRORLEVEL%
  echo Finished at %date% %time%
  echo.
  echo Running flutter doctor...
  C:\Flutter\bin\flutter.bat doctor -v
)
echo Done. Log written to %LOGFILE%
