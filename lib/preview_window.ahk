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
	global previewHwnd, previewImageWidth, previewImageHeight, previewPBitmap

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

	; Leave space for text at bottom
	availHeight := height - 30

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
		offsetY := (availHeight - scaledHeight) / 2
	} else {
		; Image is taller - fit to height
		scaledHeight := availHeight
		scaledWidth := availHeight * imageAspect
		offsetX := (width - scaledWidth) / 2
		offsetY := 0
	}

	; Round to integers for stable rendering
	scaledWidth := Floor(scaledWidth)
	scaledHeight := Floor(scaledHeight)
	offsetX := Floor(offsetX)
	offsetY := Floor(offsetY)

	; Draw the scaled image
	Gdip_DrawImage(pGraphics, previewPBitmap, offsetX, offsetY, scaledWidth, scaledHeight)

	; Cleanup
	Gdip_DeleteGraphics(pGraphics)
	DllCall("EndPaint", "ptr", hwnd, "ptr", &ps)
}

ShowImageWindow(tempFile, nW, nH, resizeBy = 1)
{
	global previewImagePath, previewImageWidth, previewImageHeight
	global previewPToken, previewPBitmap, previewHwnd, previewTempFile

	; Close existing preview window if already open
	if (previewHwnd) {
		; Destroy the window first
		Gui, ImageView:Destroy

		; Unregister WM_PAINT handler
		OnMessage(0x000F, "ImageViewPaint", 0)

		; Cleanup GDI+ resources
		if (previewPBitmap)
			Gdip_DisposeImage(previewPBitmap)
		if (previewPToken)
			Gdip_Shutdown(previewPToken)

		; Delete old temp file
		if (previewTempFile && FileExist(previewTempFile))
			FileDelete, %previewTempFile%

		; Reset variables
		previewPBitmap := 0
		previewPToken := 0
		previewHwnd := 0
		previewTempFile := ""

		; Small delay to ensure window is fully closed
		Sleep, 50
	}

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

	; Initialize GDI+ for preview window
	If !previewPToken := Gdip_Startup()
	{
		MsgBox, 48, Error!, Gdiplus failed to start for preview window
		return
	}

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
	global previewPBitmap, previewPToken, previewHwnd, previewTempFile

	; Save window position and size
	WinGetPos, winX, winY, winWidth, winHeight, Screenshot Preview
	IniWrite, %winWidth%, %A_ScriptDir%\settings.ini, PreviewWindow, Width
	IniWrite, %winHeight%, %A_ScriptDir%\settings.ini, PreviewWindow, Height
	IniWrite, %winX%, %A_ScriptDir%\settings.ini, PreviewWindow, X
	IniWrite, %winY%, %A_ScriptDir%\settings.ini, PreviewWindow, Y

	; Unregister WM_PAINT handler
	OnMessage(0x000F, "ImageViewPaint", 0)

	; Cleanup GDI+ resources
	if (previewPBitmap)
		Gdip_DisposeImage(previewPBitmap)
	if (previewPToken)
		Gdip_Shutdown(previewPToken)

	; Clean up temp file
	if (previewTempFile && FileExist(previewTempFile))
		FileDelete, %previewTempFile%

	previewPBitmap := 0
	previewPToken := 0
	previewHwnd := 0
	previewTempFile := ""

	Gui, ImageView:Destroy
return

; Hotkeys for preview window
#If WinActive("Screenshot Preview")
Esc::
	global previewPBitmap, previewPToken, previewHwnd, previewTempFile

	; Save window position and size
	WinGetPos, winX, winY, winWidth, winHeight, Screenshot Preview
	IniWrite, %winWidth%, %A_ScriptDir%\settings.ini, PreviewWindow, Width
	IniWrite, %winHeight%, %A_ScriptDir%\settings.ini, PreviewWindow, Height
	IniWrite, %winX%, %A_ScriptDir%\settings.ini, PreviewWindow, X
	IniWrite, %winY%, %A_ScriptDir%\settings.ini, PreviewWindow, Y

	; Unregister WM_PAINT handler
	OnMessage(0x000F, "ImageViewPaint", 0)

	; Cleanup GDI+ resources
	if (previewPBitmap)
		Gdip_DisposeImage(previewPBitmap)
	if (previewPToken)
		Gdip_Shutdown(previewPToken)

	; Clean up temp file
	if (previewTempFile && FileExist(previewTempFile))
		FileDelete, %previewTempFile%

	previewPBitmap := 0
	previewPToken := 0
	previewHwnd := 0
	previewTempFile := ""

	Gui, ImageView:Destroy
return

; Hotkey to save the screenshot from preview window
f::
	global previewTempFile, screenshotFolder

	; Check if we have a temp file to save
	if (!previewTempFile || !FileExist(previewTempFile)) {
		ToolTip, Error: No screenshot to save
		Sleep, 2000
		ToolTip,
		return
	}

	; Create screenshots folder if it doesn't exist
	if (!FileExist(screenshotFolder)) {
		FileCreateDir, %screenshotFolder%
	}

	; Generate timestamp-based filename
	FormatTime, currentDateTime, , yyyy_MM_dd_HH_mm_ss
	filename := currentDateTime . ".bmp"
	fullFilePath := screenshotFolder . "\" . filename

	; Copy the temp file to the screenshots folder
	FileCopy, %previewTempFile%, %fullFilePath%, 1

	; Show feedback to user
	if (ErrorLevel = 0) {
		ToolTip, Screenshot saved to: %fullFilePath%
		Sleep, 2000
		ToolTip,
	} else {
		ToolTip, Error: Failed to save screenshot
		Sleep, 2000
		ToolTip,
	}
return
#If
