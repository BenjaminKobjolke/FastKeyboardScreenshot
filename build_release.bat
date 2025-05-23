mkdir bin
del bin\* /Q
mkdir release
del release\* /Q
"tools\Ahk2Exe.exe" /in FastKeyboardScreenshot.ahk
"tools\Ahk2Exe.exe" /bin tools\AutoHotkey64_v2.exe /in ocr.ahk
cd bin
7z a ..\release\FastKeyboardScreenshot.zip *
cd ..