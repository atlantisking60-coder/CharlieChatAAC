@echo off
echo Renaming "Logos & Profile Pics" to "Logos and Profile Pics"...

if not exist "C:\Users\Craig\Downloads\Charlie Chat\assets\Logos & Profile Pics" (
  echo Source folder not found.
  pause
  exit /b 1
)

if exist "C:\Users\Craig\Downloads\Charlie Chat\assets\Logos and Profile Pics" (
  echo Destination already exists.
  pause
  exit /b 1
)

ren "C:\Users\Craig\Downloads\Charlie Chat\assets\Logos & Profile Pics" "Logos and Profile Pics"
if %errorlevel% neq 0 (
  echo Rename failed.
) else (
  echo Done.
)
pause
