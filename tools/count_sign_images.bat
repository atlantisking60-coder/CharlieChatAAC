@echo off
set "d=C:\Users\Craig\Downloads\Charlie Chat\assets\sign\00. A-Z of Sign"
set /a count=0
for %%f in ("%d%\*.png") do set /a count+=1
(
  echo Total PNG files: %count%
) > "C:\Users\Craig\Downloads\Charlie Chat\tools\sign_image_count.txt"
