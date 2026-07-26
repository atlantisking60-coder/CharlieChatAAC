@echo off
cd /d "C:\Users\Craig\Downloads\Charlie Chat"
flutter analyze --no-pub > "C:\Users\Craig\Downloads\Charlie Chat\tools\analyze.log" 2>&1
echo Exit code: %ERRORLEVEL%
