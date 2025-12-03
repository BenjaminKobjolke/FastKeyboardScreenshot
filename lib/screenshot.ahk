; screenshot.ahk - Screenshot workflow and state management

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

GetStartPosition:
	CoordMode, Mouse, Screen
	state := 2
	MouseGetPos, screenShotStartX, screenShotStartY
	if(delayedScreenShotInProgress = 0) {
		SetTimer, UpdatePreviewRectangle, 100
	}
return

GetEndPosition:
	CoordMode, Mouse, Screen
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
	CoordMode, Mouse, Screen
	MouseGetPos, x, y
	width := Abs(x - screenShotStartX)
	height := Abs(y - screenShotStartY)
	scaling := 100 / (A_ScreenDPI/96*100)
	width := width * scaling
	height := height * scaling
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
	global screenshotFolder, sharexPath
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

	CaptureScreen(screenShotStartX ", " screenShotStartY ", " screenShotEndX ", " screenShotEndY, captureCursor, saveToFile, uploadWithShareX, editWithShareX, ocrScreenshot, 0, resizeNextScreenshotBy, screenshotFolder, sharexPath, showWindow)
	Sleep, 1000
	ToolTip,
Return
