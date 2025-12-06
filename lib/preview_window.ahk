; preview_window.ahk - Screenshot preview window functionality

; ============================================
; Text Preview Window (for OCR output)
; ============================================

ShowTextWindow(text)
{
    global textPreviewHwnd, TextContent

    ; Close existing text preview if open
    if (textPreviewHwnd) {
        Gui, TextPreview:Destroy
        textPreviewHwnd := 0
    }

    ; Load saved window size/position and font size
    IniRead, savedWidth, %A_ScriptDir%\settings.ini, TextPreviewWindow, Width, 600
    IniRead, savedHeight, %A_ScriptDir%\settings.ini, TextPreviewWindow, Height, 400
    IniRead, savedX, %A_ScriptDir%\settings.ini, TextPreviewWindow, X, Center
    IniRead, savedY, %A_ScriptDir%\settings.ini, TextPreviewWindow, Y, Center
    IniRead, fontSize, %A_ScriptDir%\settings.ini, TextPreviewWindow, FontSize, 14

    ; Create text preview GUI with dark theme
    Gui, TextPreview:Destroy
    Gui, TextPreview:+Resize +AlwaysOnTop +HWNDtextPreviewHwnd
    Gui, TextPreview:Color, 1e1e1e, 2d2d2d
    Gui, TextPreview:Margin, 10, 10
    Gui, TextPreview:Font, s%fontSize% cE0E0E0, Consolas
    Gui, TextPreview:Add, Edit, vTextContent w580 h360 ReadOnly Background2d2d2d, %text%

    ; Show window
    if (savedX = "Center" || savedY = "Center")
        Gui, TextPreview:Show, w%savedWidth% h%savedHeight%, OCR Text Preview
    else
        Gui, TextPreview:Show, x%savedX% y%savedY% w%savedWidth% h%savedHeight%, OCR Text Preview

    return
}

TextPreviewGuiClose:
TextPreviewGuiEscape:
    global textPreviewHwnd
    ; Save window position
    WinGetPos, winX, winY, winWidth, winHeight, OCR Text Preview
    IniWrite, %winWidth%, %A_ScriptDir%\settings.ini, TextPreviewWindow, Width
    IniWrite, %winHeight%, %A_ScriptDir%\settings.ini, TextPreviewWindow, Height
    IniWrite, %winX%, %A_ScriptDir%\settings.ini, TextPreviewWindow, X
    IniWrite, %winY%, %A_ScriptDir%\settings.ini, TextPreviewWindow, Y
    Gui, TextPreview:Destroy
    textPreviewHwnd := 0
return

TextPreviewGuiSize:
    ; Resize the Edit control with the window
    GuiControl, Move, TextContent, % "w" . (A_GuiWidth - 20) . " h" . (A_GuiHeight - 20)
return

; ============================================
; Image Preview Window
; ============================================

ImageViewPaint(wParam, lParam, msg, hwnd)
{
	global previewHwnd, previewImageWidth, previewImageHeight, previewPBitmap, previewMode

	; Only handle paint for our preview window
	if (hwnd != previewHwnd || !previewPBitmap)
		return

	; Begin paint
	VarSetCapacity(ps, 64, 0)
	hdc := DllCall("BeginPaint", "ptr", hwnd, "ptr", &ps, "ptr")

	; Get client area dimensions
	VarSetCapacity(rect, 16, 0)
	DllCall("GetClientRect", "ptr", hwnd, "ptr", &rect)
	width := NumGet(rect, 8, "int")
	height := NumGet(rect, 12, "int")

	; Leave space for top and bottom status bars
	topBarHeight := 30
	bottomBarHeight := 45
	availHeight := height - topBarHeight - bottomBarHeight

	; Create GDI+ graphics from the paint DC
	pGraphics := Gdip_GraphicsFromHDC(hdc)
	Gdip_SetInterpolationMode(pGraphics, 7) ; High quality

	; Clear background with dark color
	Gdip_GraphicsClear(pGraphics, 0xFF1e1e1e)

	; Calculate aspect ratio
	imageAspect := previewImageWidth / previewImageHeight
	availAspect := width / availHeight

	; Calculate scaled dimensions to fit while maintaining aspect ratio
	if (imageAspect > availAspect) {
		; Image is wider - fit to width
		scaledWidth := width
		scaledHeight := width / imageAspect
		offsetX := 0
		offsetY := topBarHeight + (availHeight - scaledHeight) / 2
	} else {
		; Image is taller - fit to height
		scaledHeight := availHeight
		scaledWidth := availHeight * imageAspect
		offsetX := (width - scaledWidth) / 2
		offsetY := topBarHeight
	}

	; Round to integers for stable rendering
	scaledWidth := Floor(scaledWidth)
	scaledHeight := Floor(scaledHeight)
	offsetX := Floor(offsetX)
	offsetY := Floor(offsetY)

	; Draw the scaled image
	Gdip_DrawImage(pGraphics, previewPBitmap, offsetX, offsetY, scaledWidth, scaledHeight)

	; Draw crop overlay if in crop mode
	if (previewMode = "crop")
		DrawCropOverlay(pGraphics, offsetX, offsetY, scaledWidth, scaledHeight)

	; Draw status bars
	DrawStatusBar(pGraphics, width, height)
	DrawTopStatusBar(pGraphics, width)

	; Cleanup
	Gdip_DeleteGraphics(pGraphics)
	DllCall("EndPaint", "ptr", hwnd, "ptr", &ps)
}

ShowImageWindow(tempFile, nW, nH, resizeBy = 1)
{
	global previewImagePath, previewImageWidth, previewImageHeight
	global previewPBitmap, previewHwnd, previewTempFile

	; Close existing preview window if already open
	if (previewHwnd) {
		; Destroy the window first
		Gui, ImageView:Destroy

		; Unregister WM_PAINT handler
		OnMessage(0x000F, "ImageViewPaint", 0)

		; Cleanup GDI+ bitmap
		if (previewPBitmap)
			Gdip_DisposeImage(previewPBitmap)

		; Delete old temp file
		if (previewTempFile && FileExist(previewTempFile))
			FileDelete, %previewTempFile%

		; Reset variables
		previewPBitmap := 0
		previewHwnd := 0
		previewTempFile := ""

		; Small delay to ensure window is fully closed
		Sleep, 50
	}

	; Reset crop state when opening new preview
	ResetCropState()

	; Store image path and temp file globally
	previewImagePath := tempFile
	previewTempFile := tempFile
	previewImageWidth := nW // resizeBy
	previewImageHeight := nH // resizeBy

	; Always load saved window size and position from settings
	; Use image dimensions as fallback if no saved settings
	IniRead, savedWidth, %A_ScriptDir%\settings.ini, PreviewWindow, Width, %previewImageWidth%
	IniRead, savedHeight, %A_ScriptDir%\settings.ini, PreviewWindow, Height, %previewImageHeight%
	IniRead, savedX, %A_ScriptDir%\settings.ini, PreviewWindow, X, Center
	IniRead, savedY, %A_ScriptDir%\settings.ini, PreviewWindow, Y, Center

	; Load the bitmap from file
	previewPBitmap := Gdip_CreateBitmapFromFile(tempFile)

	; Create GUI to display the image with dark theme
	Gui, ImageView:Destroy
	Gui, ImageView:+Resize +AlwaysOnTop +HWNDpreviewHwnd
	Gui, ImageView:Color, 1e1e1e

	; Register WM_PAINT handler
	OnMessage(0x000F, "ImageViewPaint")

	; Show window at saved position or centered
	if (savedX = "Center" || savedY = "Center")
		Gui, ImageView:Show, w%savedWidth% h%savedHeight%, Screenshot Preview
	else
		Gui, ImageView:Show, x%savedX% y%savedY% w%savedWidth% h%savedHeight%, Screenshot Preview

	; Force initial paint
	DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)

	return
}

; GUI resize handler to trigger repaint when window is resized
ImageViewGuiSize:
	global previewHwnd

	if (A_EventInfo = 1)  ; Window minimized
		return

	; Invalidate the window to trigger WM_PAINT
	DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
return

; GUI close handler for when user clicks X button
ImageViewGuiClose:
	global previewPBitmap, previewHwnd, previewTempFile, previewSavedFilePath

	; Save window position and size
	WinGetPos, winX, winY, winWidth, winHeight, Screenshot Preview
	IniWrite, %winWidth%, %A_ScriptDir%\settings.ini, PreviewWindow, Width
	IniWrite, %winHeight%, %A_ScriptDir%\settings.ini, PreviewWindow, Height
	IniWrite, %winX%, %A_ScriptDir%\settings.ini, PreviewWindow, X
	IniWrite, %winY%, %A_ScriptDir%\settings.ini, PreviewWindow, Y

	; Unregister WM_PAINT handler
	OnMessage(0x000F, "ImageViewPaint", 0)

	; Cleanup GDI+ bitmap
	if (previewPBitmap)
		Gdip_DisposeImage(previewPBitmap)

	; Clean up temp file
	if (previewTempFile && FileExist(previewTempFile))
		FileDelete, %previewTempFile%

	ResetCropState()
	previewPBitmap := 0
	previewHwnd := 0
	previewTempFile := ""
	previewSavedFilePath := ""

	Gui, ImageView:Destroy
return

; Hotkeys for preview window
#If WinActive("Screenshot Preview")
Esc::
	global previewPBitmap, previewHwnd, previewTempFile, previewMode, previewSavedFilePath

	; If in crop mode, just exit to viewing mode
	if (previewMode = "crop") {
		ResetCropState()
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
		return
	}

	; Save window position and size
	WinGetPos, winX, winY, winWidth, winHeight, Screenshot Preview
	IniWrite, %winWidth%, %A_ScriptDir%\settings.ini, PreviewWindow, Width
	IniWrite, %winHeight%, %A_ScriptDir%\settings.ini, PreviewWindow, Height
	IniWrite, %winX%, %A_ScriptDir%\settings.ini, PreviewWindow, X
	IniWrite, %winY%, %A_ScriptDir%\settings.ini, PreviewWindow, Y

	; Unregister WM_PAINT handler
	OnMessage(0x000F, "ImageViewPaint", 0)

	; Cleanup GDI+ bitmap
	if (previewPBitmap)
		Gdip_DisposeImage(previewPBitmap)

	; Clean up temp file
	if (previewTempFile && FileExist(previewTempFile))
		FileDelete, %previewTempFile%

	ResetCropState()
	previewPBitmap := 0
	previewHwnd := 0
	previewTempFile := ""
	previewSavedFilePath := ""

	Gui, ImageView:Destroy
return

; Enter crop mode
c::
	global previewMode, previewHwnd, cropLeft, cropTop, cropRight, cropBottom
	if (previewMode = "viewing") {
		previewMode := "crop"
		cropLeft := 0
		cropTop := 0
		cropRight := 0
		cropBottom := 0
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	}
return

; Crop adjustments - shrink from left
h::
Left::
	global previewMode, cropStep, previewHwnd
	if (previewMode = "crop") {
		AdjustCropEdge("left", cropStep)
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	}
return

; Crop adjustments - extend left (Shift)
+h::
+Left::
	global previewMode, cropStep, previewHwnd
	if (previewMode = "crop") {
		AdjustCropEdge("left", -cropStep)
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	}
return

; Crop adjustments - shrink from right
l::
Right::
	global previewMode, cropStep, previewHwnd
	if (previewMode = "crop") {
		AdjustCropEdge("right", cropStep)
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	}
return

; Crop adjustments - extend right (Shift)
+l::
+Right::
	global previewMode, cropStep, previewHwnd
	if (previewMode = "crop") {
		AdjustCropEdge("right", -cropStep)
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	}
return

; Crop adjustments - shrink from top
k::
Up::
	global previewMode, cropStep, previewHwnd
	if (previewMode = "crop") {
		AdjustCropEdge("top", cropStep)
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	}
return

; Crop adjustments - extend top (Shift)
+k::
+Up::
	global previewMode, cropStep, previewHwnd
	if (previewMode = "crop") {
		AdjustCropEdge("top", -cropStep)
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	}
return

; Crop adjustments - shrink from bottom
j::
Down::
	global previewMode, cropStep, previewHwnd
	if (previewMode = "crop") {
		AdjustCropEdge("bottom", cropStep)
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	}
return

; Crop adjustments - extend bottom (Shift)
+j::
+Down::
	global previewMode, cropStep, previewHwnd
	if (previewMode = "crop") {
		AdjustCropEdge("bottom", -cropStep)
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	}
return

; Apply crop
Enter::
	global previewMode, previewHwnd
	if (previewMode = "crop") {
		ApplyCrop()
		previewMode := "viewing"
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	}
return

; Hotkey to save the screenshot from preview window (viewing mode only)
f::
	global previewPBitmap, screenshotFolder, previewSavedFilePath, previewMode

	; Only work in viewing mode
	if (previewMode != "viewing")
		return

	; Check if we have a bitmap to save
	if (!previewPBitmap) {
		ToolTip, Error: No screenshot to save
		Sleep, 2000
		ToolTip,
		return
	}

	; If already saved, overwrite same file
	if (previewSavedFilePath && previewSavedFilePath != "") {
		fullFilePath := previewSavedFilePath
	} else {
		; First save: create new file with timestamp
		saveFolder := screenshotFolder
		if (!saveFolder || saveFolder = "" || saveFolder = "ERROR") {
			saveFolder := A_ScriptDir . "\screenshots"
		}

		; Create screenshots folder if it doesn't exist
		if (!FileExist(saveFolder)) {
			FileCreateDir, %saveFolder%
		}

		; Generate timestamp-based filename
		FormatTime, currentDateTime, , yyyy_MM_dd_HH_mm_ss
		fullFilePath := saveFolder . "\" . currentDateTime . ".jpg"
		previewSavedFilePath := fullFilePath  ; Track for future overwrites
	}

	; Save the in-memory bitmap (works with cropped images)
	result := SaveGdipBitmap(previewPBitmap, fullFilePath)

	; Show feedback to user
	if (result = 0) {
		ToolTip, Screenshot saved to: %fullFilePath%
		Sleep, 2000
		ToolTip,
	} else {
		; Show specific error
		if (result = -1)
			ToolTip, Error: Unsupported file format
		else if (result = -2)
			ToolTip, Error: Could not get encoders
		else if (result = -3)
			ToolTip, Error: No matching encoder
		else if (result = -4)
			ToolTip, Error: Could not get filename
		else if (result = -5)
			ToolTip, Error: Could not save to disk
		else
			ToolTip, Error: Failed to save (code: %result%)
		Sleep, 2000
		ToolTip,
	}
return

; Hotkey to upload the screenshot from preview window (viewing mode only)
u::
	global previewPBitmap, previewMode, screenshotFolder, previewSavedFilePath

	; Only work in viewing mode
	if (previewMode != "viewing")
		return

	if (!previewPBitmap) {
		ToolTip, Error: No screenshot to upload
		Sleep, 2000
		ToolTip,
		return
	}

	; Save to file first if not already saved
	if (!previewSavedFilePath || previewSavedFilePath = "") {
		saveFolder := screenshotFolder
		if (!saveFolder || saveFolder = "" || saveFolder = "ERROR")
			saveFolder := A_ScriptDir . "\screenshots"
		if (!FileExist(saveFolder))
			FileCreateDir, %saveFolder%
		FormatTime, currentDateTime, , yyyy_MM_dd_HH_mm_ss
		fullFilePath := saveFolder . "\" . currentDateTime . ".jpg"
		SaveGdipBitmap(previewPBitmap, fullFilePath)
		previewSavedFilePath := fullFilePath
	} else {
		fullFilePath := previewSavedFilePath
	}

	UploadFile(fullFilePath)
return
#If
