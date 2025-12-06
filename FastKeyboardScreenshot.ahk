; FastKeyboardScreenshot - Main Entry Point
; Create screenshots by selecting regions with keyboard navigation

#Include %A_ScriptDir%\config.ahk
#Include github_modules/Gdip/Gdip.ahk

; Include library modules (functions only - no hotkeys/labels)
#Include %A_ScriptDir%\lib\utils.ahk
#Include %A_ScriptDir%\lib\gui.ahk
#Include %A_ScriptDir%\lib\image.ahk
#Include %A_ScriptDir%\lib\capture.ahk
#Include %A_ScriptDir%\lib\crop.ahk
#Include %A_ScriptDir%\lib\FTP_Upload.ahk
#Include %A_ScriptDir%\github_modules\RapidOCR-AutoHotkey\RapidOCR\RapidOCR.ahk

; Initialize GDI+ once at startup (keep running for entire script lifetime)
pGdipToken := Gdip_Startup()
if (!pGdipToken) {
    MsgBox, 48, Error!, GDI+ failed to initialize
    ExitApp
}
OnExit("CleanupGdip")

CoordMode, Mouse, Screen

; Initialize RapidOCR for English text
rapidOcr := new RapidOCR({model: "en"})

; Global variables for ShareX
sharexPath := ""
sharexSearched := false

; Global variables for mouse/screenshot state
mouseSpeed := 50
mouseSPeedSlow := 10
interactiveMode := 0
state := 0
delayedScreenShot := 0
screenshotTimerIndex := 0
screenShotStartX := -1
screenShotStartY := -1
screenShotEndX := -1
screenShotEndY := -1
resizeNextScreenshotBy := 1
saveToFile := 0
uploadAfterCapture := 0
editWithShareX := 0
ocrScreenshot := 0
captureCursor := 0
showWindow := 0

; Register message handler for resolution changes
OnMessage(0x007E, "HandleResolutionChange")

; Global variables for preview window
previewImagePath := ""
previewImageWidth := 0
previewImageHeight := 0
previewPBitmap := 0
previewHwnd := 0
previewTempFile := ""
previewSavedFilePath := ""  ; Track saved file for overwrite

; Global variables for crop mode
previewMode := "viewing"  ; "viewing" or "crop"
cropLeft := 0
cropTop := 0
cropRight := 0
cropBottom := 0
cropStep := 10  ; Pixels per keypress

; Global variables for text preview window
textPreviewHwnd := 0

; Global variables for action tooltips (FTP upload and OCR)
lastUploadedUrl := ""
pendingOcrText := ""

; Initialize ShareX path from settings or by searching
IniRead, sharexPath, %A_ScriptDir%\settings.ini, General, ShareXPath, NOT_FOUND
IniRead, sharexNotFound, %A_ScriptDir%\settings.ini, General, ShareXNotFound, 0

; If path is not in settings or marked as not found, search for it
if (sharexPath = "NOT_FOUND" && sharexNotFound = 0) {
    sharexPath := FindShareX()
    sharexSearched := true

    ; Store the result in settings.ini
    if (sharexPath = "") {
        ; ShareX was not found, mark it as not found
        IniWrite, 1, %A_ScriptDir%\settings.ini, General, ShareXNotFound
    } else {
        ; ShareX was found, store the path
        IniWrite, %sharexPath%, %A_ScriptDir%\settings.ini, General, ShareXPath
        IniWrite, 0, %A_ScriptDir%\settings.ini, General, ShareXNotFound
    }
} else if (sharexNotFound = 1) {
    ; ShareX was previously not found, set path to empty
    sharexPath := ""
}

; Set tray icon
if (!a_iscompiled) {
	Menu, tray, icon, icon.ico,0,1
}

; Setup tray menu
Menu, tray, NoStandard
Menu, tray, add  ; Creates a separator line.
Menu, tray, add, Reload
Menu, tray, add, Exit

return

; Include files with hotkeys/labels AFTER auto-execute section (they end auto-execute)
#Include %A_ScriptDir%\lib\help_window.ahk
#Include %A_ScriptDir%\lib\screenshot.ahk
#Include %A_ScriptDir%\lib\preview_window.ahk
#Include %A_ScriptDir%\lib\hotkeys.ahk

Reload:
	Reload
return

Exit:
	ExitApp
return

; Action tooltip hotkeys (for FTP upload and OCR)
OpenLastUrl:
    global lastUploadedUrl, pendingOcrText
    if(lastUploadedUrl != "") {
        Run, %lastUploadedUrl%
    } else if(pendingOcrText != "") {
        ; Create temp file on-demand and open in default editor
        FormatTime, ts, , yyyy_MM_dd_HH_mm_ss
        tempTxt := A_Temp . "\ocr_" . ts . ".txt"
        FileAppend, %pendingOcrText%, %tempTxt%
        Run, %tempTxt%
        pendingOcrText := ""
    }
    GoSub, ClearActionTooltip
return

CancelActionTooltip:
    GoSub, ClearActionTooltip
return

ClearActionTooltip:
    global pendingOcrText
    ToolTip
    Hotkey, o, OpenLastUrl, Off
    Hotkey, Escape, CancelActionTooltip, Off
    SetTimer, ClearActionTooltip, Off
    pendingOcrText := ""  ; Clear pending text if user dismissed
return

; Cleanup GDI+ on script exit
CleanupGdip() {
    global pGdipToken
    if (pGdipToken)
        Gdip_Shutdown(pGdipToken)
}
