#Requires AutoHotkey >=v2.0
;@Ahk2Exe-ExeName %A_ScriptDir%\bin\ocr.exe
#include github_modules\OCR\Lib\OCR.ahk
#NoTrayIcon
command := A_Args[1]
imageFilename := command . ".jpg"
textFilename := command . ".txt"
;M sgBox imageFilename
result := OCR.FromFile(imageFilename)
resultText := result.Text
;M sgBox resultText
if (FileExist(textFilename))
	FileDelete textFilename
FileAppend resultText, textFilename