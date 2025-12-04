if exist bin rmdir /S /Q bin
mkdir bin
if exist release rmdir /S /Q release
mkdir release

REM Copy RapidOCR files (exe and models)
xcopy "github_modules\RapidOCR-AutoHotkey\RapidOCR\Exe\*" "bin\" /E /I /H /Y

"tools\Ahk2Exe.exe" /in FastKeyboardScreenshot.ahk
cd bin
7z a ..\release\FastKeyboardScreenshot.zip *
cd ..
