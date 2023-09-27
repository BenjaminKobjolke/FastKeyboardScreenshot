#Requires AutoHotkey >=v2.0
;https://www.autohotkey.com/boards/viewtopic.php?style=19&t=96159
;@Ahk2Exe-ExeName %A_ScriptDir%\release\KeyboardScreenshot.exe
#Include github_modules/Gdip/Gdip.ahk
#Include github_modules/OCR/lib/OCR.ahk

#SingleInstance force
CoordMode "Mouse", "Screen"

previewGui := Gui()

mouseSpeed := 50
mouseSPeedSlow := 10
interactiveMode := 0
state := 0
delayedScreenShot := 0
delayedScreenShotInProgress := 0
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

if (!a_iscompiled) {
	TraySetIcon "icon.ico",0,1
}

tray := A_TrayMenu ; For convenience.
tray.delete ; Delete the standard items.
tray.add ; separator
tray.add "Reload", Reload
tray.add "Exit", Exit

return

Reload:
	Reload
return

Exit:
	ExitApp
return

ScreenshotTimer() {
	global screenshotTimerIndex
	if(screenshotTimerIndex = 0) {
		ToolTip "Screenshot will be set in 4 seconds"
	}
	if(screenshotTimerIndex = 1) {
		ToolTip "Screenshot will be set in 3 seconds"
	}
	if(screenshotTimerIndex = 2) {
		ToolTip "Screenshot will be set in 2 seconds"
	}	
	if(screenshotTimerIndex = 3) {
		ToolTip "Screenshot will be set in 1 seconds"
	}
	if(screenshotTimerIndex = 4) {
		ToolTip  
		SetTimer ScreenshotTimer, 0
		CreateScreenshot()
		ScreenshotDone()

	}
	screenshotTimerIndex := screenshotTimerIndex + 1
}

!+q::
{	
	if(interactiveMode = 1) {
		ToolTip "Keyboard screenshot cancelled"
		ScreenshotDone()
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
		;SetTimer, MouseHintTimer, 100
		ToolTip "Move to START position with arrow keys`nthen press space"
	}	
}

#HotIf interactiveMode = 1
k::
{
	MouseMove 0, (mouseSpeed * -1), 0, "R"
}
+k::
{
	MouseMove 0, (mouseSpeedSlow * -1), 0, "R"
}
UP::
{
	MouseMove 0, (mouseSpeed * -1), 0, "R"
}
+UP::
{
	MouseMove 0, (mouseSpeedSlow * -1), 0, "R"
}
j::
{
	MouseMove 0, mouseSpeed, 0, "R"
}
+j::
{
	MouseMove 0, mouseSpeedSlow, 0, "R"
}
DOWN::
{
	MouseMove 0, mouseSpeed, 0, "R"
}
+DOWN::
{
	MouseMove 0, mouseSpeedSlow, 0, "R"
}
h::
{
	MouseMove (mouseSpeed * -1), 0, 0, "R"
}
+h::
{
	MouseMove (mouseSpeedSlow * -1), 0, 0, "R"
}
LEFT::
{
	MouseMove (mouseSpeed * -1), 0, 0, "R"
}
+LEFT::
{
	MouseMove (mouseSpeedSlow * -1), 0, 0, "R"
}
l::
{
	MouseMove mouseSpeed, 0, 0, "R"
}
+l::
{
	MouseMove mouseSpeedSlow, 0, 0, "R"
}
RIGHT::
{	
	MouseMove mouseSpeed, 0, 0, "R"
}
+RIGHT::
{
	MouseMove mouseSpeedSlow, 0, 0, "R"
}

; delay screenshot
D::
{
	if(delayedScreenShot = 1) {
		delayedScreenShot := 0
		ToolTip "Delayed screenshot cancelled"
	} else {
		delayedScreenShot := 1
		ToolTip "Delayed screenshot will be taken 5 seconds after you set the end position"
	}
}

; screenshot the same region again
F1::
{
	if(screenShotStartX = screenShotEndX) {
		return
	}

	interactiveMode := 0
	if(delayedScreenShot = 1) {
		SetTimer ScreenshotTimer, 1000
	} else {
		CreateScreenshot()
		ScreenshotDone()
	}	
}

Space::
{
	if(state = 1) {
		GetStartPosition()
		ToolTip "Move to END position with arrow keys`nthen press space"
	} else if(state = 2) {
		GetEndPosition()
	}
}

1::
{
	ToolTip "Screenshot will be resized to 75`% of original"
	resizeNextScreenshotBy := 1.5
}

2::
{
	ToolTip "Screenshot will be resized to 50`% of original"
	resizeNextScreenshotBy := 2
}

3::
{
	ToolTip "Screenshot will be resized to 25`% of original"
	resizeNextScreenshotBy := 4
}

f::
{
	ToolTip "Screenshot will be saved to file"
	saveToFile := 1
}	

u::
{
	ToolTip "Screenshot will be uploaded"
	uploadWithShareX := 1
	editWithShareX := 0
}

e::
{
	ToolTip "Screenshot will be edited"
	editWithShareX := 1
	uploadWithShareX := 0
}

o::
{
	ToolTip "Screenshot will be OCR'd"
	ocrScreenshot := 1
}	

GetStartPosition() {
	global state, screenShotStartX, screenShotStartY, delayedScreenShotInProgress, delayedScreenShot, previewGui
	state := 2
	MouseGetPos screenShotStartX, screenShotStartY
	if(delayedScreenShotInProgress = 0) {
		previewGui := Gui()
		SetTimer UpdatePreviewRectangle, 100
	}
}

GetEndPosition() {
	global state, screenShotEndX, screenShotEndY, delayedScreenShotInProgress, delayedScreenShot, previewGui
	state := 0
	interactiveMode := 0		
	MouseGetPos screenShotEndX, screenShotEndY
	SetTimer UpdatePreviewRectangle, 0
	if(delayedScreenShotInProgress = 0) {
		PreviewDestroy()
	}
	if(delayedScreenShot = 1) {
		SetTimer ScreenshotTimer, 1000
	} else {
		CreateScreenshot()
	}
}

ScreenshotDone() {
	global interactiveMode, state
	interactiveMode := 0
	state := 0		
	SetTimer UpdatePreviewRectangle, 0
	PreviewDestroy()
	Sleep 1000
	ToolTip  
}

UpdatePreviewRectangle() {
	MouseGetPos &x, &y
	width := Abs(x - screenShotStartX)
	height := Abs(y - screenShotStartY)
	;M sgBox, %width% %height%
   	scaling := 100 / (A_ScreenDPI/96*100)
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
}

CreateScreenshot() {
	global screenShotStartX, screenShotStartY, screenShotEndX, screenShotEndY, resizeNextScreenshotBy, saveToFile, uploadWithShareX, editWithShareX, ocrScreenshot, resizeNextScreenshotBy

	ToolTip  
    
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

	CaptureScreen(screenShotStartX ", " screenShotStartY ", " screenShotEndX ", " screenShotEndY, 0, saveToFile, uploadWithShareX, editWithShareX, ocrScreenshot, 0, resizeNextScreenshotBy) 
    ;ToolTip  Mouse region capture to clipboard
	Sleep 1000
	ToolTip 
}

PreviewUpdate(x, y, w, h) {
	global previewGui
	previewGui := Gui("+E0x80000 -Caption +ToolWindow +AlwaysOnTop +Lastfound +HWNDgSecond")
	;ToDo
	;WinSet Transcolor, E0x80000 20
	options := x%x% y%y% w%w% h%h%
	previewGui.Show(%options%)
}

PreviewDestroy() {
	global previewGui
	previewGui.Destroy()
}

CaptureScreen(aRect := 0, bCursor := False, saveToFile := 0, uploadWithShareX := 0, editWithShareX := 0, ocrScreenshot := 0, nQuality := "", resizeBy := 1)
{
    ; Add Gdip startup
    If !pToken := Gdip_Startup()
    {
        MsgBox 48, "Error!", "Gdiplus failed to start. Please ensure you have gdiplus on your system"
        ExitApp
    }

	If !aRect
	{
		nL := SysGet(76)  ; virtual screen left & top
		nT := SysGet(77)
		nW := SysGet(78)  ; virtual screen width & height 
		nH := SysGet(79)
	}
	Else If aRect = 1
		WinGetPos &nL, &nT, &nW, &nH, "A"
	Else If aRect = 2
	{
		WinGet hWnd, ID, "A"
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
		StringSplit rt, aRect, `,, %A_Space%%A_Tab%
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
		FormatTime currentDateTime, , yyyy_MM_dd_HH_mm_ss
		filename := A_ScriptDir . "\screenshots\" . currentDateTime . ".jpg"		
		;ToDo
		;Convert(0, filename) 
	}

    if(uploadWithShareX = 1) {
		;M sgBox, "C:\Program Files\ShareX\ShareX.exe" "%filename%"
		RunWait "C:\Program Files\ShareX\ShareX.exe" "%filename%"
		if(saveToFile = 0) {
			Sleep 1000
			FileDelete %filename%
		}
	}

	if(editWithShareX = 1) {
		;M sgBox, "C:\Program Files\ShareX\ShareX.exe" "%filename%"
		RunWait "C:\Program Files\ShareX\ShareX.exe" "-imageEditor" "%filename%"
		if(saveToFile = 0) {
			Sleep 1000
			FileDelete %filename%
		}
	}

	if(ocrScreenshot = 1) {
		;M sgBox, "C:\Program Files\ShareX\ShareX.exe" "%filename%"
		Result := OCR.FromFile(filename)
		text := Result.Text
		MsgBox %text%
		if(saveToFile = 0) {
			Sleep 1000
			FileDelete %filename%
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

CreateDIBSectionVariant(hDC, nW, nH, bpp := 32, pBits := "")
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