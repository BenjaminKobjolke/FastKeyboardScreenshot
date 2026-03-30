; Resolve settings file: prefer COMPUTERNAME_settings.ini if it exists
settingsFile := A_ScriptDir . "\" . A_ComputerName . "_settings.ini"
if !FileExist(settingsFile)
    settingsFile := A_ScriptDir . "\settings.ini"

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
IniRead, screenshotFolder, %settingsFile%, General, ScreenshotFolder, %A_ScriptDir%\screenshots

; Read FTP settings
IniRead, useInBuildFTP, %settingsFile%, FTP, UseInBuildFTP, 0
IniRead, ftpHost, %settingsFile%, FTP, host,
IniRead, ftpUser, %settingsFile%, FTP, user,
IniRead, ftpPass, %settingsFile%, FTP, pass,
IniRead, ftpPath, %settingsFile%, FTP, path,
IniRead, ftpUrl, %settingsFile%, FTP, url,
; Read action tooltip duration (used for both FTP upload and OCR)
IniRead, actionTooltipDuration, %settingsFile%, General, ActionTooltipDuration, 5000

