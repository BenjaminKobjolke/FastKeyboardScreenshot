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

; Read FTP settings
IniRead, useInBuildFTP, %A_ScriptDir%\settings.ini, FTP, UseInBuildFTP, 0
IniRead, ftpHost, %A_ScriptDir%\settings.ini, FTP, host,
IniRead, ftpUser, %A_ScriptDir%\settings.ini, FTP, user,
IniRead, ftpPass, %A_ScriptDir%\settings.ini, FTP, pass,
IniRead, ftpPath, %A_ScriptDir%\settings.ini, FTP, path,
IniRead, ftpUrl, %A_ScriptDir%\settings.ini, FTP, url,

