;@Ahk2Exe-SetMainIcon icon.ico
;@Ahk2Exe-ExeName %A_ScriptDir%\bin\KeyboardScreenshot.exe

#NoEnv 
SendMode Input
#SingleInstance force
SetTitleMatchMode, 2
SetWorkingDir %A_ScriptDir%
ListLines Off
SetBatchLines -1

; Read settings from settings.ini
IniRead, screenshotFolder, %A_ScriptDir%\settings.ini, General, ScreenshotFolder, %A_ScriptDir%\screenshots

