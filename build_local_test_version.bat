if not exist bin mkdir bin

"tools\Ahk2Exe.exe" /in FastKeyboardScreenshot.ahk
copy /Y "bin\KeyboardScreenshot.exe" "E:\[--Sync--]\BKTools\Apps\FastKeyboardScreenshot\"
