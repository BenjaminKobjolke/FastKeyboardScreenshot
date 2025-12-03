; hotkeys.ahk - Main hotkey and all interactive mode hotkeys

; Helper function for #If directive to access global variable
IsInteractiveMode() {
    global interactiveMode
    return interactiveMode = 1
}

; Main hotkey to start/cancel screenshot mode
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
		showWindow := 0
		SetTimer, MouseHintTimer, 100
		ToolTip, move to START position with arrow keys`nthen press space
	}
return

#If IsInteractiveMode()

; Movement keys - vim style
k::
	MouseMove, 0, (mouseSpeed * -1), 0, R
return
+k::
	MouseMove, 0, (mouseSpeedSlow * -1), 0, R
return
j::
	MouseMove, 0, mouseSpeed, 0, R
return
+j::
	MouseMove, 0, mouseSpeedSlow, 0, R
return
h::
	MouseMove, (mouseSpeed * -1), 0, 0, R
return
+h::
	MouseMove, (mouseSpeedSlow * -1), 0, 0, R
return
l::
	MouseMove, mouseSpeed, 0, 0, R
return
+l::
	MouseMove, mouseSpeedSlow, 0, 0, R
return

; Movement keys - arrow keys
UP::
	MouseMove, 0, (mouseSpeed * -1), 0, R
return
+UP::
	MouseMove, 0, (mouseSpeedSlow * -1), 0, R
return
DOWN::
	MouseMove, 0, mouseSpeed, 0, R
return
+DOWN::
	MouseMove, 0, mouseSpeedSlow, 0, R
return
LEFT::
	MouseMove, (mouseSpeed * -1), 0, 0, R
return
+LEFT::
	MouseMove, (mouseSpeedSlow * -1), 0, 0, R
return
RIGHT::
	MouseMove, mouseSpeed, 0, 0, R
return
+RIGHT::
	MouseMove, mouseSpeedSlow, 0, 0, R
return

; Delay screenshot
D::
	if(delayedScreenShot = 1) {
		delayedScreenShot := 0
		ToolTip, Delayed screenshot cancelled
	} else {
		delayedScreenShot := 1
		ToolTip, Delayed screenshot will be taken 5 seconds after you set the end position
	}
return

; Screenshot the same region again
r::
	if(screenShotStartX = screenShotEndX) {
		return
	}

	ToolTip, will use the same region again
	Sleep, 1000

	interactiveMode := 0
	SetTimer, MouseHintTimer, Off
	DestroyGuis()
	if(delayedScreenShot = 1) {
		SetTimer, ScreenshotTimer, 1000
	} else {
		GoSub, CreateScreenshot
		GoSub, ScreenshotDone
	}
Return

; Confirm position
Space::
	if(state = 1) {
		GoSub, GetStartPosition
		ToolTip, move to END position with arrow keys`nthen press space
	} else if(state = 2) {
		GoSub, GetEndPosition
	}
return

; Resize options
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

; Save to file
f::
	ToolTip, Screenshot will be saved to file
	saveToFile := 1
return

; Capture mouse cursor
m::
	if(captureCursor = 1) {
		captureCursor := 0
		ToolTip, Mouse cursor will NOT be captured
	} else {
		captureCursor := 1
		ToolTip, Mouse cursor WILL be captured
	}
return

; Upload with ShareX
u::
	ToolTip, Screenshot will be uploaded
	uploadWithShareX := 1
	editWithShareX := 0
return

; Edit with ShareX
e::
	ToolTip, Screenshot will be edited
	editWithShareX := 1
	uploadWithShareX := 0
return

; OCR screenshot
o::
	ToolTip, Screenshot will be OCR'd
	ocrScreenshot := 1
return

; Show in window
w::
	if(showWindow = 1) {
		showWindow := 0
		ToolTip, Screenshot will NOT be shown in window
	} else {
		showWindow := 1
		ToolTip, Screenshot WILL be shown in window
	}
return

; Capture active window
a::
	global screenshotFolder, sharexPath
	ToolTip, Capturing active window
	interactiveMode := 0
	SetTimer, MouseHintTimer, Off
	DestroyGuis()
	CaptureScreen(1, captureCursor, saveToFile, uploadWithShareX, editWithShareX, ocrScreenshot, 0, resizeNextScreenshotBy, screenshotFolder, sharexPath, showWindow)
	GoSub, ScreenshotDone
return

; Show help window (toggle)
F1::
	GoSub, ToggleHelpWindow
return

#If
