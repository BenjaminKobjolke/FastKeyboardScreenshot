#Include %A_ScriptDir%\config.ahk
#Include github_modules/Gdip/Gdip.ahk

CoordMode, Mouse, Screen

; Global variable to store ShareX path
sharexPath := ""
sharexSearched := false

mouseSpeed := 50
mouseSPeedSlow := 10
interactiveMode := 0
state := 0
delayedScreenShot := 0
;delayedScreenShotInProgress := 0
;startpositionTimerIndex := 0
;endpositionTimerIndex := 0
screenshotTimerIndex := 0
screenShotStartX := -1
screenShotStartY := -1
screenShotEndX := -1
screenShotEndY := -1
resizeNextScreenshotBy := 1
saveToFile := 0
uploadWithShareX := 0
editWithShareX := 0
ocrScreenshot := 0
captureCursor := 0

; Function to find ShareX.exe on the C drive
FindShareX()
{
    ; Check common installation locations first (for efficiency)
    commonPaths := ["C:\Program Files\ShareX\ShareX.exe", "C:\Program Files (x86)\ShareX\ShareX.exe"]
    
    For index, path in commonPaths
    {
        If FileExist(path)
            Return path
    }
    
    ; If not found in common locations, search C drive
    Loop, Files, C:\*ShareX*.exe, R
    {
        If InStr(A_LoopFileName, "ShareX.exe")
            Return A_LoopFilePath
    }
    
    ; Not found
    Return ""
}

; Initialize ShareX path from settings or by searching
; First check if we have a stored path in settings.ini
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
if (!a_iscompiled) {
	Menu, tray, icon, icon.ico,0,1
}

Menu, tray, NoStandard
Menu, tray, add  ; Creates a separator line.
Menu, tray, add, Reload  
Menu, tray, add, Exit

return

Reload:
	Reload
return

Exit:
	ExitApp
return

/*
#q::
	reload
return
*/

ScreenshotTimer:
	if(screenshotTimerIndex = 0) {
		ToolTip, Screenshot will be set in 4 seconds
	}
	if(screenshotTimerIndex = 1) {
		ToolTip, Screenshot will be set in 3 seconds
	}
	if(screenshotTimerIndex = 2) {
		ToolTip, Screenshot will be set in 2 seconds
	}	
	if(screenshotTimerIndex = 3) {
		ToolTip, Screenshot will be set in 1 seconds
	}
	if(screenshotTimerIndex = 4) {
		ToolTip, 
		SetTimer, ScreenshotTimer, Off
		GoSub, CreateScreenshot
		GoSub, ScreenshotDone

	}
	screenshotTimerIndex := screenshotTimerIndex + 1
return

MouseHintTimer:
	MouseHintUpdate()
return

!+q::	
	if(interactiveMode = 1) {
		ToolTip, Keyboard screenshot cancelled
		GoSub, ScreenshotDone
	} else {
		interactiveMode := 1
		state := 1
		startpositionTimerIndex := 0
		endpositionTimerIndex := 0
		screenshotTimerIndex := 0
		delayedScreenShotInProgress := 0
		delayedScreenShot := 0
		resizeNextScreenshotBy := 1
		saveToFile := 0
		uploadWithShareX := 0
		editWithShareX := 0
		ocrScreenshot := 0
		captureCursor := 0
		SetTimer, MouseHintTimer, 100
		ToolTip, move to START position with arrow keys`nthen press space
	}
return

#If interactiveMode = 1
k::
	MouseMove, 0, (mouseSpeed * -1), 0, R
return
+k::
	MouseMove, 0, (mouseSpeedSlow * -1), 0, R
return
UP::
	MouseMove, 0, (mouseSpeed * -1), 0, R
return
+UP::
	MouseMove, 0, (mouseSpeedSlow * -1), 0, R
return
j::
	MouseMove, 0, mouseSpeed, 0, R
return
+j::
	MouseMove, 0, mouseSpeedSlow, 0, R
return
DOWN::
	MouseMove, 0, mouseSpeed, 0, R
return
+DOWN::
	MouseMove, 0, mouseSpeedSlow, 0, R
return
h::
	MouseMove, (mouseSpeed * -1), 0, 0, R
return
+h::
	MouseMove, (mouseSpeedSlow * -1), 0, 0, R
return
LEFT::
	MouseMove, (mouseSpeed * -1), 0, 0, R
return
+LEFT::
	MouseMove, (mouseSpeedSlow * -1), 0, 0, R
return
l::
	MouseMove, mouseSpeed, 0, 0, R
return
+l::
	MouseMove, mouseSpeedSlow, 0, 0, R
return
RIGHT::
	MouseMove, mouseSpeed, 0, 0, R
return
+RIGHT::
	MouseMove, mouseSpeedSlow, 0, 0, R
return

; delay screenshot
D::
	if(delayedScreenShot = 1) {
		delayedScreenShot := 0
		ToolTip, Delayed screenshot cancelled
	} else {
		delayedScreenShot := 1
		ToolTip, Delayed screenshot will be taken 5 seconds after you set the end position
	}

return

; screenshot the same region again
r::
	if(screenShotStartX = screenShotEndX) {
		return
	}

	ToolTip, will use the same region again
	Sleep, 1000	

	interactiveMode := 0
	if(delayedScreenShot = 1) {
		SetTimer, ScreenshotTimer, 1000
	} else {
		GoSub, CreateScreenshot
		GoSub, ScreenshotDone
	}	
Return

Space::
	if(state = 1) {
		GoSub, GetStartPosition
		ToolTip, move to END position with arrow keys`nthen press space
	} else if(state = 2) {
		GoSub, GetEndPosition
	}
return

1::
	ToolTip, Screenshot will be resized to 75`% of original
	resizeNextScreenshotBy := 1.5
return

2::
	ToolTip, Screenshot will be resized to 50`% of original
	resizeNextScreenshotBy := 2
return

3::
	ToolTip, Screenshot will be resized to 25`% of original
	resizeNextScreenshotBy := 4
return

f::
	ToolTip, Screenshot will be saved to file
	saveToFile := 1
return

m::
	if(captureCursor = 1) {
		captureCursor := 0
		ToolTip, Mouse cursor will NOT be captured
	} else {
		captureCursor := 1
		ToolTip, Mouse cursor WILL be captured
	}
return

u::
	ToolTip, Screenshot will be uploaded
	uploadWithShareX := 1
	editWithShareX := 0
return

e::
	ToolTip, Screenshot will be edited
	editWithShareX := 1
	uploadWithShareX := 0
return

o::
	ToolTip, Screenshot will be OCR'd
	ocrScreenshot := 1
return

GetStartPosition:
	state := 2
	MouseGetPos, screenShotStartX, screenShotStartY
	if(delayedScreenShotInProgress = 0) {
		SetTimer, UpdatePreviewRectangle, 100
	}
return

GetEndPosition:
	state := 0
	interactiveMode := 0		
	MouseGetPos, screenShotEndX, screenShotEndY
	SetTimer, UpdatePreviewRectangle, Off
	if(delayedScreenShotInProgress = 0) {
		DestroyGuis()
	}
	if(delayedScreenShot = 1) {
		SetTimer, ScreenshotTimer, 1000
	} else {
		GoSub, CreateScreenshot
	}
return

ScreenshotDone:
	interactiveMode := 0
	state := 0		
	SetTimer, UpdatePreviewRectangle, Off
	DestroyGuis()
	Sleep, 1000
	ToolTip, 
return

UpdatePreviewRectangle:
	MouseGetPos, x, y
	width := Abs(x - screenShotStartX)
	height := Abs(y - screenShotStartY)
	;M sgBox, %width% %height%
	scaling := 100 / (A_ScreenDPI/96*100)
	;M sgBox, %A_ScreenDPI% %scaling%
	width := width * scaling
	height := height * scaling
	;M sgBox, %width% %height%
	startX := screenShotStartX
	if(x < screenShotStartX) {
		startX := x
	}

	startY := screenShotStartY
	if(y < screenShotStartY) {
		startY := y
	}
	PreviewUpdate(startX, startY, width, height)
return



CreateScreenshot:
	ToolTip, 
    
    If (screenShotStartX > screenShotEndX)
    {
        helper := screenShotStartX
        screenShotStartX := screenShotEndX
        screenShotEndX := helper
    }
    If (screenShotStartY > screenShotEndY)
    {
        helper := screenShotStartY
		screenShotStartY := screenShotEndY
		screenShotEndY := helper
    }
	/*
    Screenshots := "C:\Users\" A_UserName "\Desktop\Screenshots"
    SnipFile := Screenshots "\" A_YYYY "-" A_MM "-" A_DD " " A_Hour "-" A_Min "-" A_Sec " Mouse region.png"
    CaptureScreen(Xi ", " Yi ", " Xf ", " Yf, 0, SnipFile)
    IfExist, %SnipFile%
        SetClipboardBitmap(SnipFile)
    SoundBeep, 500, 5
	*/

	CaptureScreen(screenShotStartX ", " screenShotStartY ", " screenShotEndX ", " screenShotEndY, captureCursor, saveToFile, uploadWithShareX, editWithShareX, ocrScreenshot, 0, resizeNextScreenshotBy, screenshotFolder, sharexPath) 
    ;ToolTip, Mouse region capture to clipboard
	Sleep, 1000
	ToolTip,
Return

MouseHintUpdate() {
    width := 50
	Gui, mousehint: -Caption +ToolWindow +AlwaysOnTop +Lastfound
    Gui, mousehint: Color, Yellow
    Gui, mousehint:Show, NoActivate w%width% h%width%, MouseSpot
        
    WinSet, Trans, 100, MouseSpot 
    WinSet, Region, 0-0 W%width% H%width% E, MouseSpot

    offset := width / 2  
    MouseGetPos, MX, MY
	WinMove, MouseSpot,,  MX - offset, MY - offset
}



PreviewUpdate(x, y, w, h) {
	Gui, preview: +E0x80000 -Caption +ToolWindow +AlwaysOnTop +Lastfound +HWNDgSecond
	WinSet, Transcolor, E0x80000 20
	Gui, preview:Show, x%x% y%y% w%w% h%h%
}

PreviewDestroy() {
	Gui, preview:Destroy
}

MouseHintDestroy() {
	Gui, mousehint:Destroy
}

DestroyGuis() {
	SetTimer, MouseHintTimer, Off
	PreviewDestroy()
	MouseHintDestroy()
}
; Note that if the Microsoft PowerToys are installed and one or more images are selected in Windows Explorer,
; then Ctrl+Win+P will open the ImageResizer tool https://www.bricelam.net/ImageResizer/   so I use Ctrl+Win+Alt+P now.

;-----------------------------------------------------------------------------------------------------------
; ===== PRINTSCREEN FUNCTIONS : START SCRIPT ===============================================================
;-----------------------------------------------------------------------------------------------------------
; https://autohotkey.com/board/topic/121619-screencaptureahk-broken-capturescreen-function-win-81-x64/ LinearSpoon (2015-02-20)
; CaptureScreen(aRect, bCursor, sFileTo, nQuality)
;
; 1) If the optional parameter bCursor is True, captures the cursor too.
; 2) If the optional parameter sFileTo is 0, set the image to Clipboard.
;    If it is omitted or "", saves to screen.bmp in the script folder,
;    otherwise to sFileTo which can be BMP/JPG/PNG/GIF/TIF.
; 3) The optional parameter nQuality is applicable only when sFileTo is JPG. Set it to the desired quality level of the resulting JPG, an integer between 0 - 100.
; 4) If aRect is 0/1/2/3, captures the entire desktop/active window/active client area/active monitor.
; 5) aRect can be comma delimited sequence of coordinates, e.g., "Left, Top, Right, Bottom" or "Left, Top, Right, Bottom, Width_Zoomed, Height_Zoomed".
;    In this case, only that portion of the rectangle will be captured. Additionally, in the latter case, zoomed to the new width/height, Width_Zoomed/Height_Zoomed.
;
; Example:
; CaptureScreen(0)
; CaptureScreen(1)
; CaptureScreen(2)
; CaptureScreen(3)
; CaptureScreen("100, 100, 200, 200")
; CaptureScreen("100, 100, 200, 200, 400, 400")   ; Zoomed
;-----------------------------------------------------------------------------------------------------------
; Convert(sFileFr, sFileTo, nQuality)
; Convert("C:\image.bmp", "C:\image.jpg")
; Convert("C:\image.bmp", "C:\image.jpg", 95)
; Convert(0, "C:\clip.png")   ; Save the bitmap in the clipboard to sFileTo if sFileFr is "" or 0.

CaptureScreen(aRect = 0, bCursor = False, saveToFile = 0, uploadWithShareX = 0, editWithShareX = 0, ocrScreenshot = 0, nQuality = "", resizeBy = 1, screenshotFolder = "", sharexPath = "")
{
    ; Add Gdip startup
    If !pToken := Gdip_Startup()
    {
        MsgBox, 48, Error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
        ExitApp
    }

	If !aRect
	{
		SysGet, nL, 76  ; virtual screen left & top
		SysGet, nT, 77
		SysGet, nW, 78	; virtual screen width and height
		SysGet, nH, 79
	}
	Else If aRect = 1
		WinGetPos, nL, nT, nW, nH, A
	Else If aRect = 2
	{
		WinGet, hWnd, ID, A
		VarSetCapacity(rt, 16, 0)
		DllCall("GetClientRect" , "ptr", hWnd, "ptr", &rt)
		DllCall("ClientToScreen", "ptr", hWnd, "ptr", &rt)
		nL := NumGet(rt, 0, "int")
		nT := NumGet(rt, 4, "int")
		nW := NumGet(rt, 8)
		nH := NumGet(rt,12)
	}
	Else If aRect = 3
	{
		VarSetCapacity(mi, 40, 0)
		DllCall("GetCursorPos", "int64P", pt), NumPut(40,mi,0,"uint")
		DllCall("GetMonitorInfo", "ptr", DllCall("MonitorFromPoint", "int64", pt, "Uint", 2, "ptr"), "ptr", &mi)
		nL := NumGet(mi, 4, "int")
		nT := NumGet(mi, 8, "int")
		nW := NumGet(mi,12, "int") - nL
		nH := NumGet(mi,16, "int") - nT
	}
	Else
	{
		StringSplit, rt, aRect, `,, %A_Space%%A_Tab%
		nL := rt1	; convert the Left,top, right, bottom into left, top, width, height
		nT := rt2
		nW := rt3 - rt1
		nH := rt4 - rt2
		znW := rt5
		znH := rt6
	}

	mDC := DllCall("CreateCompatibleDC", "ptr", 0, "ptr")
	hBM := CreateDIBSectionVariant(mDC, nW, nH)
	oBM := DllCall("SelectObject", "ptr", mDC, "ptr", hBM, "ptr")
	hDC := DllCall("GetDC", "ptr", 0, "ptr")
	DllCall("BitBlt", "ptr", mDC, "int", 0, "int", 0, "int", nW, "int", nH, "ptr", hDC, "int", nL, "int", nT, "Uint", 0x40CC0020)
	DllCall("ReleaseDC", "ptr", 0, "ptr", hDC)
	If bCursor
		CaptureCursor(mDC, nL, nT)
	DllCall("SelectObject", "ptr", mDC, "ptr", oBM)
	DllCall("DeleteDC", "ptr", mDC)
	If znW && znH
		hBM := Zoomer(hBM, nW, nH, znW, znH)


    ; Resize the screenshot
	if(resizeBy > 1) {
		pBitmap := Gdip_CreateBitmapFromHBITMAP(hBM)
		pBitmapResized := Gdip_ResizeBitmap(pBitmap, nW // resizeBy, nH // resizeBy)
		hBMResized := Gdip_CreateHBITMAPFromBitmap(pBitmapResized)
		
		; Replace the original hBM with the resized one
		DllCall("DeleteObject", "ptr", hBM)
		hBM := hBMResized

		; Free resources
		Gdip_DisposeImage(pBitmap)
		Gdip_DisposeImage(pBitmapResized)
	}

	SetClipboardData(hBM)
	
	if(saveToFile = 1 || uploadWithShareX = 1 || editWithShareX = 1 || ocrScreenshot = 1) {
		;Convert(hBM, "c:\test.bmp", nQuality), DllCall("DeleteObject", "ptr", hBM)
		Sleep, 200	
		FormatTime, currentDateTime, , yyyy_MM_dd_HH_mm_ss
		baseFilename := currentDateTime
		filename := baseFilename . ".jpg"		
		Convert(0, filename, "", screenshotFolder) 
	}

    if(uploadWithShareX = 1) {
		fullFilename := screenshotFolder . "\" . filename
		
		; Check if ShareX was found
		if (sharexPath = "") {
			MsgBox, 16, Error, ShareX not found. Cannot upload screenshot.
		} else {
			Sleep, 1000
			RunWait, %sharexPath% "%fullFilename%"
			baseFilename := A_ScriptDir . "\screenshots\" . currentDateTime
			filename := baseFilename . ".jpg"
			Sleep, 100
			Convert(0, filename, 100)
			; check if file exists
			if (FileExist(filename) = false) {
				MsgBox, file saving failed
			}
		}
	}

    if(uploadWithShareX = 1) {
		; Check if ShareX was found
		if (sharexPath = "") {
			MsgBox, 16, Error, ShareX not found. Cannot upload screenshot.
		} else {
			;M sgBox, %sharexPath% "%filename%"
			ToolTip, Uploading screenshot with ShareX
			Sleep, 100
			; copy sharex path and filename to clipboard
			complete_path = %sharexPath% "%filename%"
			clipboard := complete_path
			Sleep, 100
			RunWait, %sharexPath% "%filename%"
			if(saveToFile = 0) {
				Sleep, 1000
				FileDelete, %fullFilename%
			}
		}
	}

	if(editWithShareX = 1) {
		Sleep, 200
		fullFilename := screenshotFolder . "\" . filename
		
		; Check if ShareX was found
		if (sharexPath = "") {
			MsgBox, 16, Error, ShareX not found. Cannot edit screenshot.
		} else {
			;M sgBox, %sharexPath% "%fullFilename%"
			RunWait, %sharexPath% -imageEditor "%fullFilename%"
			if(saveToFile = 0) {
				Sleep, 1000
				FileDelete, %fullFilename%
			}
		}
	}

	if(ocrScreenshot = 1) {
		Sleep, 2000
		fullBaseFilename := screenshotFolder . "\" . baseFilename
		fullFilename := screenshotFolder . "\" . filename		
		if (!a_iscompiled) {
			RunWait, "ocr.ahk" "%fullBaseFilename%"
		} else {
			RunWait, "ocr.exe" "%fullBaseFilename%"
		}
		textFilename := fullBaseFilename . ".txt"
		FileRead, text, %textFilename%
		clipboard := text
		FileDelete, %textFilename%
		if(saveToFile = 0) {
			Sleep, 3000
			FileDelete, %fullFilename%
		}
	}

	DllCall("DeleteObject", "ptr", hBM)
    ; Add Gdip shutdown at the end of the function
    Gdip_Shutdown(pToken)	
}


Gdip_ResizeBitmap(pBitmap, newWidth, newHeight)
{
    pBitmapResized := Gdip_CreateBitmap(newWidth, newHeight)
    G := Gdip_GraphicsFromImage(pBitmapResized)
    Gdip_SetInterpolationMode(G, 7) ; High quality bicubic interpolation
    Gdip_DrawImage(G, pBitmap, 0, 0, newWidth, newHeight, 0, 0, Gdip_GetImageWidth(pBitmap), Gdip_GetImageHeight(pBitmap))
    Gdip_DeleteGraphics(G)
    return pBitmapResized
}


CaptureCursor(hDC, nL, nT)
{
	VarSetCapacity(mi, 32, 0), Numput(16+A_PtrSize, mi, 0, "uint")
	DllCall("GetCursorInfo", "ptr", &mi)
	bShow   := NumGet(mi, 4, "uint")
	hCursor := NumGet(mi, 8)
	xCursor := NumGet(mi,8+A_PtrSize, "int")
	yCursor := NumGet(mi,12+A_PtrSize, "int")

	DllCall("GetIconInfo", "ptr", hCursor, "ptr", &mi)
	xHotspot := NumGet(mi, 4, "uint")
	yHotspot := NumGet(mi, 8, "uint")
	hBMMask  := NumGet(mi,8+A_PtrSize)
	hBMColor := NumGet(mi,16+A_PtrSize)

	If bShow
		DllCall("DrawIcon", "ptr", hDC, "int", xCursor - xHotspot - nL, "int", yCursor - yHotspot - nT, "ptr", hCursor)
	If hBMMask
		DllCall("DeleteObject", "ptr", hBMMask)
	If hBMColor
		DllCall("DeleteObject", "ptr", hBMColor)
}

Zoomer(hBM, nW, nH, znW, znH)
{
	mDC1 := DllCall("CreateCompatibleDC", "ptr", 0, "ptr")
	mDC2 := DllCall("CreateCompatibleDC", "ptr", 0, "ptr")
	zhBM := CreateDIBSectionVariant(mDC2, znW, znH)
	oBM1 := DllCall("SelectObject", "ptr", mDC1, "ptr",  hBM, "ptr")
	oBM2 := DllCall("SelectObject", "ptr", mDC2, "ptr", zhBM, "ptr")
	DllCall("SetStretchBltMode", "ptr", mDC2, "int", 4)
	DllCall("StretchBlt", "ptr", mDC2, "int", 0, "int", 0, "int", znW, "int", znH, "ptr", mDC1, "int", 0, "int", 0, "int", nW, "int", nH, "Uint", 0x00CC0020)
	DllCall("SelectObject", "ptr", mDC1, "ptr", oBM1)
	DllCall("SelectObject", "ptr", mDC2, "ptr", oBM2)
	DllCall("DeleteDC", "ptr", mDC1)
	DllCall("DeleteDC", "ptr", mDC2)
	DllCall("DeleteObject", "ptr", hBM)
	Return zhBM
}

Convert(sFileFr = "", sFileTo = "", nQuality = "", screenshotFolder = "")
{
	If (sFileTo = "")
		sFileTo := A_ScriptDir . "\screen.bmp"

	SplitPath, sFileTo, , sDirTo, sExtTo, sNameTo
	sDirTo := screenshotFolder

	if (!FileExist(sDirTo))
	{
	   FileCreateDir, %sDirTo%
	}		
	
	If Not hGdiPlus := DllCall("LoadLibrary", "str", "gdiplus.dll", "ptr")
		Return	sFileFr+0 ? SaveHBITMAPToFile(sFileFr, sDirTo (sDirTo = "" ? "" : "\") sNameTo ".bmp") : ""
	VarSetCapacity(si, 16, 0), si := Chr(1)
	DllCall("gdiplus\GdiplusStartup", "UintP", pToken, "ptr", &si, "ptr", 0)

	If !sFileFr
	{
		DllCall("OpenClipboard", "ptr", 0)
		If	(DllCall("IsClipboardFormatAvailable", "Uint", 2) && (hBM:=DllCall("GetClipboardData", "Uint", 2, "ptr")))
			DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "ptr", hBM, "ptr", 0, "ptr*", pImage)
		DllCall("CloseClipboard")
	}
	Else If	sFileFr Is Integer
		DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "ptr", sFileFr, "ptr", 0, "ptr*", pImage)
	Else	DllCall("gdiplus\GdipLoadImageFromFile", "wstr", sFileFr, "ptr*", pImage)
	DllCall("gdiplus\GdipGetImageEncodersSize", "UintP", nCount, "UintP", nSize)
	VarSetCapacity(ci,nSize,0)
	DllCall("gdiplus\GdipGetImageEncoders", "Uint", nCount, "Uint", nSize, "ptr", &ci)
	struct_size := 48+7*A_PtrSize, offset := 32 + 3*A_PtrSize, pCodec := &ci - struct_size
	Loop, %	nCount
		If InStr(StrGet(Numget(offset + (pCodec+=struct_size)), "utf-16") , "." . sExtTo)
			break

	If (InStr(".JPG.JPEG.JPE.JFIF", "." . sExtTo) && nQuality<>"" && pImage && pCodec < &ci + nSize)
	{
		DllCall("gdiplus\GdipGetEncoderParameterListSize", "ptr", pImage, "ptr", pCodec, "UintP", nCount)
		VarSetCapacity(pi,nCount,0), struct_size := 24 + A_PtrSize
		DllCall("gdiplus\GdipGetEncoderParameterList", "ptr", pImage, "ptr", pCodec, "Uint", nCount, "ptr", &pi)
		Loop, %	NumGet(pi,0,"uint")
			If (NumGet(pi,struct_size*(A_Index-1)+16+A_PtrSize,"uint")=1 && NumGet(pi,struct_size*(A_Index-1)+20+A_PtrSize,"uint")=6)
			{
				pParam := &pi+struct_size*(A_Index-1)
				NumPut(nQuality,NumGet(NumPut(4,NumPut(1,pParam+0,"uint")+16+A_PtrSize,"uint")),"uint")
				Break
			}
	}
	
	filePath = %sDirTo%\%sFileTo%
	
	If pImage
		pCodec < &ci + nSize	? DllCall("gdiplus\GdipSaveImageToFile", "ptr", pImage, "wstr", filePath, "ptr", pCodec, "ptr", pParam) : DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "ptr", pImage, "ptr*", hBitmap, "Uint", 0) . SetClipboardData(hBitmap), DllCall("gdiplus\GdipDisposeImage", "ptr", pImage)

	DllCall("gdiplus\GdiplusShutdown" , "Uint", pToken)
	DllCall("FreeLibrary", "ptr", hGdiPlus)
}

CreateDIBSectionVariant(hDC, nW, nH, bpp = 32, ByRef pBits = "")
{
	VarSetCapacity(bi, 40, 0)
	NumPut(40, bi, "uint")
	NumPut(nW, bi, 4, "int")
	NumPut(nH, bi, 8, "int")
	NumPut(bpp, NumPut(1, bi, 12, "UShort"), 0, "Ushort")
	Return DllCall("gdi32\CreateDIBSection", "ptr", hDC, "ptr", &bi, "Uint", 0, "UintP", pBits, "ptr", 0, "Uint", 0, "ptr")
}

SaveHBITMAPToFile(hBitmap, sFile)
{
	VarSetCapacity(oi,104,0)
	DllCall("GetObject", "ptr", hBitmap, "int", 64+5*A_PtrSize, "ptr", &oi)
	fObj := FileOpen(sFile, "w")
	fObj.WriteShort(0x4D42)
	fObj.WriteInt(54+NumGet(oi,36+2*A_PtrSize,"uint"))
	fObj.WriteInt64(54<<32)
	fObj.RawWrite(&oi + 16 + 2*A_PtrSize, 40)
	fObj.RawWrite(NumGet(oi, 16+A_PtrSize), NumGet(oi,36+2*A_PtrSize,"uint"))
	fObj.Close()
}

SetClipboardData(hBitmap)
{
	VarSetCapacity(oi,104,0)
	DllCall("GetObject", "ptr", hBitmap, "int", 64+5*A_PtrSize, "ptr", &oi)
	sz := NumGet(oi,36+2*A_PtrSize,"uint")
	hDIB :=	DllCall("GlobalAlloc", "Uint", 2, "Uptr", 40+sz, "ptr")
	pDIB := DllCall("GlobalLock", "ptr", hDIB, "ptr")
	DllCall("RtlMoveMemory", "ptr", pDIB, "ptr", &oi + 16 + 2*A_PtrSize, "Uptr", 40)
	DllCall("RtlMoveMemory", "ptr", pDIB+40, "ptr", NumGet(oi, 16+A_PtrSize), "Uptr", sz)
	DllCall("GlobalUnlock", "ptr", hDIB)
	DllCall("DeleteObject", "ptr", hBitmap)
	DllCall("OpenClipboard", "ptr", 0)
	DllCall("EmptyClipboard")
	DllCall("SetClipboardData", "Uint", 8, "ptr", hDIB)
	DllCall("CloseClipboard")
}
; ===== PRINTSCREEN : END SCRIPT ===========================================================================
