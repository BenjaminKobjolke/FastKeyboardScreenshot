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

	; Create off-screen buffer for double buffering (prevents flickering)
	hdcBuffer := DllCall("CreateCompatibleDC", "ptr", hdc, "ptr")
	hBitmap := DllCall("CreateCompatibleBitmap", "ptr", hdc, "int", width, "int", height, "ptr")
	hOldBitmap := DllCall("SelectObject", "ptr", hdcBuffer, "ptr", hBitmap, "ptr")

	; Leave space for top and bottom status bars
	topBarHeight := 30
	bottomBarHeight := 45
	availHeight := height - topBarHeight - bottomBarHeight

	; Create GDI+ graphics from buffer DC
	pGraphics := Gdip_GraphicsFromHDC(hdcBuffer)
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

	; Draw arrows overlay if in arrow mode
	if (previewMode = "arrow")
		DrawArrowsOverlay(pGraphics, offsetX, offsetY, scaledWidth, scaledHeight)

	; Draw numbers overlay if in number mode
	if (previewMode = "number")
		DrawNumbersOverlay(pGraphics, offsetX, offsetY, scaledWidth, scaledHeight)

	; Draw rectangles overlay if in rectangle mode
	if (previewMode = "rectangle")
		DrawRectanglesOverlay(pGraphics, offsetX, offsetY, scaledWidth, scaledHeight)

	; Draw status bars
	DrawStatusBar(pGraphics, width, height)
	DrawTopStatusBar(pGraphics, width)

	; Cleanup GDI+
	Gdip_DeleteGraphics(pGraphics)

	; Copy buffer to screen in one operation (no flicker)
	DllCall("BitBlt", "ptr", hdc, "int", 0, "int", 0, "int", width, "int", height, "ptr", hdcBuffer, "int", 0, "int", 0, "uint", 0x00CC0020) ; SRCCOPY

	; Cleanup buffer
	DllCall("SelectObject", "ptr", hdcBuffer, "ptr", hOldBitmap)
	DllCall("DeleteObject", "ptr", hBitmap)
	DllCall("DeleteDC", "ptr", hdcBuffer)

	DllCall("EndPaint", "ptr", hwnd, "ptr", &ps)
}

; Handle WM_ERASEBKGND - return 1 to prevent Windows from erasing background (prevents flicker)
ImageViewEraseBkgnd(wParam, lParam, msg, hwnd) {
	global previewHwnd
	if (hwnd = previewHwnd)
		return 1  ; Tell Windows we handled it, don't erase
}

; Handle WM_LBUTTONDOWN - mouse click in preview window
PreviewMouseDown(wParam, lParam, msg, hwnd) {
	global previewHwnd, previewMode

	if (hwnd != previewHwnd)
		return

	; Update cursor position from mouse
	SetArrowCursorFromMouse()

	; Handle click based on current mode
	if (previewMode = "arrow") {
		SetArrowPoint()
	} else if (previewMode = "rectangle") {
		SetRectanglePoint()
	} else if (previewMode = "crop") {
		SetCropPoint()
	} else if (previewMode = "number") {
		AddNextNumber()
	}

	DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
}

; Handle WM_MOUSEMOVE - mouse movement in preview window
PreviewMouseMove(wParam, lParam, msg, hwnd) {
	global previewHwnd, previewMode

	if (hwnd != previewHwnd)
		return

	; Only track mouse in annotation/crop modes
	if (previewMode = "arrow" || previewMode = "rectangle" || previewMode = "number" || previewMode = "crop") {
		SetArrowCursorFromMouse()
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	}
}

; Handle WM_MOUSEWHEEL - mouse wheel to change size in annotation modes
PreviewMouseWheel(wParam, lParam, msg, hwnd) {
	global previewHwnd, previewMode

	if (hwnd != previewHwnd)
		return

	; Get wheel delta (positive = scroll up, negative = scroll down)
	wheelDelta := (wParam >> 16) & 0xFFFF
	if (wheelDelta > 32767)
		wheelDelta := wheelDelta - 65536

	; Scroll up = increase size, scroll down = decrease size
	if (previewMode = "arrow") {
		ChangeArrowSize(wheelDelta > 0 ? 1 : -1)
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	} else if (previewMode = "number") {
		ChangeNumberSize(wheelDelta > 0 ? 1 : -1)
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	} else if (previewMode = "rectangle") {
		ChangeRectangleSize(wheelDelta > 0 ? 1 : -1)
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	}
}

ShowImageWindow(tempFile, nW, nH, resizeBy = 1)
{
	global previewImagePath, previewImageWidth, previewImageHeight
	global previewPBitmap, previewHwnd, previewTempFile

	; Close existing preview window if already open
	if (previewHwnd) {
		; Destroy the window first
		Gui, ImageView:Destroy

		; Unregister message handlers
		OnMessage(0x000F, "ImageViewPaint", 0)
		OnMessage(0x0014, "ImageViewEraseBkgnd", 0)
		OnMessage(0x0201, "PreviewMouseDown", 0)
		OnMessage(0x0200, "PreviewMouseMove", 0)
		OnMessage(0x020A, "PreviewMouseWheel", 0)

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

	; Reset number counter for new preview
	global nextNumber
	nextNumber := 1

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
	Gui, ImageView:+Resize +HWNDpreviewHwnd
	Gui, ImageView:Color, 1e1e1e

	; Register message handlers
	OnMessage(0x000F, "ImageViewPaint")
	OnMessage(0x0014, "ImageViewEraseBkgnd")  ; Prevent background erase flicker
	OnMessage(0x0201, "PreviewMouseDown")      ; WM_LBUTTONDOWN
	OnMessage(0x0200, "PreviewMouseMove")      ; WM_MOUSEMOVE
	OnMessage(0x020A, "PreviewMouseWheel")     ; WM_MOUSEWHEEL

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

	; Unregister message handlers
	OnMessage(0x000F, "ImageViewPaint", 0)
	OnMessage(0x0014, "ImageViewEraseBkgnd", 0)
	OnMessage(0x0201, "PreviewMouseDown", 0)
	OnMessage(0x0200, "PreviewMouseMove", 0)
	OnMessage(0x020A, "PreviewMouseWheel", 0)

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

	; If in arrow mode, just exit to viewing mode (discard arrows)
	if (previewMode = "arrow") {
		ResetArrowState()
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
		return
	}

	; If in number mode, just exit to viewing mode (discard numbers)
	if (previewMode = "number") {
		ResetNumberState()
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
		return
	}

	; If in rectangle mode, just exit to viewing mode (discard rectangles)
	if (previewMode = "rectangle") {
		ResetRectangleState()
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
		return
	}

	; Save window position and size
	WinGetPos, winX, winY, winWidth, winHeight, Screenshot Preview
	IniWrite, %winWidth%, %A_ScriptDir%\settings.ini, PreviewWindow, Width
	IniWrite, %winHeight%, %A_ScriptDir%\settings.ini, PreviewWindow, Height
	IniWrite, %winX%, %A_ScriptDir%\settings.ini, PreviewWindow, X
	IniWrite, %winY%, %A_ScriptDir%\settings.ini, PreviewWindow, Y

	; Unregister message handlers
	OnMessage(0x000F, "ImageViewPaint", 0)
	OnMessage(0x0014, "ImageViewEraseBkgnd", 0)
	OnMessage(0x0201, "PreviewMouseDown", 0)
	OnMessage(0x0200, "PreviewMouseMove", 0)
	OnMessage(0x020A, "PreviewMouseWheel", 0)

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

; Enter arrow mode
a::
	global previewMode, previewHwnd, arrowSettingStart, arrows
	if (previewMode = "viewing") {
		previewMode := "arrow"
		arrowSettingStart := 0
		arrows := []
		SetArrowCursorFromMouse()
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	}
return

; Enter number mode
n::
	global previewMode, previewHwnd, numbers
	if (previewMode = "viewing") {
		previewMode := "number"
		numbers := []
		SetArrowCursorFromMouse()
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	}
return

; Enter rectangle mode
r::
	global previewMode, previewHwnd, rectangles, rectSettingStart
	if (previewMode = "viewing") {
		previewMode := "rectangle"
		rectSettingStart := 0
		rectangles := []
		SetArrowCursorFromMouse()
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	}
return

; Enter crop mode / Cycle arrow/number/rectangle color
c::
	global previewMode, previewHwnd, cropSettingStart
	if (previewMode = "viewing") {
		previewMode := "crop"
		cropSettingStart := 0
		SetArrowCursorFromMouse()
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	} else if (previewMode = "arrow") {
		CycleArrowColor()
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	} else if (previewMode = "number") {
		CycleNumberColor()
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	} else if (previewMode = "rectangle") {
		CycleRectangleColor()
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	}
return

; Movement - left (all modes: move cursor)
h::
Left::
	global previewMode, arrowMoveStep, previewHwnd
	if (previewMode = "crop" || previewMode = "arrow" || previewMode = "number" || previewMode = "rectangle") {
		MoveArrowCursor(-arrowMoveStep, 0)
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	}
return

; Movement - fast left (Shift)
+h::
+Left::
	global previewMode, arrowMoveStep, previewHwnd
	if (previewMode = "crop" || previewMode = "arrow" || previewMode = "number" || previewMode = "rectangle") {
		MoveArrowCursor(-arrowMoveStep * 5, 0)
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	}
return

; Movement - right (all modes: move cursor)
l::
Right::
	global previewMode, arrowMoveStep, previewHwnd
	if (previewMode = "crop" || previewMode = "arrow" || previewMode = "number" || previewMode = "rectangle") {
		MoveArrowCursor(arrowMoveStep, 0)
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	}
return

; Movement - fast right (Shift)
+l::
+Right::
	global previewMode, arrowMoveStep, previewHwnd
	if (previewMode = "crop" || previewMode = "arrow" || previewMode = "number" || previewMode = "rectangle") {
		MoveArrowCursor(arrowMoveStep * 5, 0)
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	}
return

; Movement - up (all modes: move cursor)
k::
Up::
	global previewMode, arrowMoveStep, previewHwnd
	if (previewMode = "crop" || previewMode = "arrow" || previewMode = "number" || previewMode = "rectangle") {
		MoveArrowCursor(0, -arrowMoveStep)
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	}
return

; Movement - fast up (Shift)
+k::
+Up::
	global previewMode, arrowMoveStep, previewHwnd
	if (previewMode = "crop" || previewMode = "arrow" || previewMode = "number" || previewMode = "rectangle") {
		MoveArrowCursor(0, -arrowMoveStep * 5)
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	}
return

; Movement - down (all modes: move cursor)
j::
Down::
	global previewMode, arrowMoveStep, previewHwnd
	if (previewMode = "crop" || previewMode = "arrow" || previewMode = "number" || previewMode = "rectangle") {
		MoveArrowCursor(0, arrowMoveStep)
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	}
return

; Movement - fast down (Shift)
+j::
+Down::
	global previewMode, arrowMoveStep, previewHwnd
	if (previewMode = "crop" || previewMode = "arrow" || previewMode = "number" || previewMode = "rectangle") {
		MoveArrowCursor(0, arrowMoveStep * 5)
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	}
return

; Apply (crop, arrows, numbers, or rectangles)
Enter::
	global previewMode, previewHwnd, arrowSettingStart, rectSettingStart
	if (previewMode = "crop") {
		ApplyCrop()
		previewMode := "viewing"
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	} else if (previewMode = "arrow") {
		; Finish in-progress arrow first if start point was set
		if (arrowSettingStart = 1)
			SetArrowPoint()
		ApplyArrows()
		previewMode := "viewing"
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	} else if (previewMode = "number") {
		ApplyNumbers()
		previewMode := "viewing"
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	} else if (previewMode = "rectangle") {
		; Finish in-progress rectangle first if first corner was set
		if (rectSettingStart = 1)
			SetRectanglePoint()
		ApplyRectangles()
		previewMode := "viewing"
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	}
return

; Set arrow/rectangle/crop point or place number (Space)
Space::
	global previewMode, previewHwnd
	if (previewMode = "arrow") {
		SetArrowPoint()
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	} else if (previewMode = "rectangle") {
		SetRectanglePoint()
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	} else if (previewMode = "crop") {
		SetCropPoint()
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	} else if (previewMode = "number") {
		AddNextNumber()
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	}
return

; Increase arrow/number/rectangle size
i::
	global previewMode, previewHwnd
	if (previewMode = "arrow") {
		ChangeArrowSize(1)
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	} else if (previewMode = "number") {
		ChangeNumberSize(1)
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	} else if (previewMode = "rectangle") {
		ChangeRectangleSize(1)
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	}
return

; Undo last arrow/number/rectangle
z::
	global previewMode, previewHwnd, arrows, numbers, rectangles
	if (previewMode = "arrow") {
		if (arrows.Length() > 0) {
			arrows.Pop()
			DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
		}
	} else if (previewMode = "number") {
		if (numbers.Length() > 0) {
			numbers.Pop()
			DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
		}
	} else if (previewMode = "rectangle") {
		if (rectangles.Length() > 0) {
			rectangles.Pop()
			DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
		}
	}
return

; Number keys 1-9 for placing numbers in number mode
1::
	global previewMode, previewHwnd
	if (previewMode = "number") {
		AddNumber(1)
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	}
return

2::
	global previewMode, previewHwnd
	if (previewMode = "number") {
		AddNumber(2)
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	}
return

3::
	global previewMode, previewHwnd
	if (previewMode = "number") {
		AddNumber(3)
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	}
return

4::
	global previewMode, previewHwnd
	if (previewMode = "number") {
		AddNumber(4)
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	}
return

5::
	global previewMode, previewHwnd
	if (previewMode = "number") {
		AddNumber(5)
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	}
return

6::
	global previewMode, previewHwnd
	if (previewMode = "number") {
		AddNumber(6)
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	}
return

7::
	global previewMode, previewHwnd
	if (previewMode = "number") {
		AddNumber(7)
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	}
return

8::
	global previewMode, previewHwnd
	if (previewMode = "number") {
		AddNumber(8)
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	}
return

9::
	global previewMode, previewHwnd
	if (previewMode = "number") {
		AddNumber(9)
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
	}
return

0::
	global previewMode, previewHwnd
	if (previewMode = "number") {
		AddNumber(10)
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

; Hotkey: u = upload (viewing) or decrease arrow/number/rectangle size
u::
	global previewPBitmap, previewMode, screenshotFolder, previewSavedFilePath, previewHwnd

	; In arrow mode, decrease arrow size
	if (previewMode = "arrow") {
		ChangeArrowSize(-1)
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
		return
	}

	; In number mode, decrease number size
	if (previewMode = "number") {
		ChangeNumberSize(-1)
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
		return
	}

	; In rectangle mode, decrease rectangle size
	if (previewMode = "rectangle") {
		ChangeRectangleSize(-1)
		DllCall("InvalidateRect", "ptr", previewHwnd, "ptr", 0, "int", 1)
		return
	}

	; Only work in viewing mode for upload
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

; Hotkey: Shift+U = open last uploaded URL in browser (viewing mode only)
+u::
	global previewMode, lastUploadedUrl
	if (previewMode = "viewing" && lastUploadedUrl != "") {
		Run, %lastUploadedUrl%
	} else if (previewMode = "viewing") {
		MsgBox, 48, No Upload, No image has been uploaded yet.
	}
return

; Hotkey: p = copy to clipboard (viewing mode only)
p::
	global previewPBitmap, previewMode

	; Only work in viewing mode
	if (previewMode != "viewing")
		return

	if (!previewPBitmap) {
		ToolTip, No screenshot to copy
		SetTimer, RemovePreviewToolTip, -2000
		return
	}

	hBitmap := Gdip_CreateHBITMAPFromBitmap(previewPBitmap, 0xFFFFFFFF)
	SetClipboardData(hBitmap)
	ToolTip, Copied to clipboard
	SetTimer, RemovePreviewToolTip, -2000
return

RemovePreviewToolTip:
	ToolTip
return

; Hotkey: F1 = show preview help window
F1::
	global previewHelpOpen
	if (previewHelpOpen = 1) {
		Gui, PreviewHelp:Destroy
		previewHelpOpen := 0
	} else {
		GoSub, ShowPreviewHelp
	}
return

ShowPreviewHelp:
	Gui, PreviewHelp:Destroy
	Gui, PreviewHelp:+AlwaysOnTop +ToolWindow
	Gui, PreviewHelp:Color, 1e1e1e
	Gui, PreviewHelp:Font, s11, Segoe UI

	; Column 1: VIEWING MODE
	Gui, PreviewHelp:Font, s11 cFFFFFF Bold, Segoe UI
	Gui, PreviewHelp:Add, Text, x15 y15, VIEWING
	Gui, PreviewHelp:Font, s10 Normal, Segoe UI
	Gui, PreviewHelp:Add, Text, x15 y+10 c808080, f
	Gui, PreviewHelp:Add, Text, x75 yp cE0E0E0, Save file
	Gui, PreviewHelp:Add, Text, x15 y+5 c808080, u
	Gui, PreviewHelp:Add, Text, x75 yp cE0E0E0, Upload
	Gui, PreviewHelp:Add, Text, x15 y+5 c808080, Shift+U
	Gui, PreviewHelp:Add, Text, x75 yp cE0E0E0, Open URL
	Gui, PreviewHelp:Add, Text, x15 y+5 c808080, p
	Gui, PreviewHelp:Add, Text, x75 yp cE0E0E0, Copy to clipboard
	Gui, PreviewHelp:Add, Text, x15 y+5 c808080, c
	Gui, PreviewHelp:Add, Text, x75 yp cE0E0E0, Crop mode
	Gui, PreviewHelp:Add, Text, x15 y+5 c808080, a
	Gui, PreviewHelp:Add, Text, x75 yp cE0E0E0, Arrow mode
	Gui, PreviewHelp:Add, Text, x15 y+5 c808080, n
	Gui, PreviewHelp:Add, Text, x75 yp cE0E0E0, Number mode
	Gui, PreviewHelp:Add, Text, x15 y+5 c808080, r
	Gui, PreviewHelp:Add, Text, x75 yp cE0E0E0, Rect mode
	Gui, PreviewHelp:Add, Text, x15 y+5 c808080, Esc
	Gui, PreviewHelp:Add, Text, x75 yp cE0E0E0, Close

	; Column 2: CROP MODE
	Gui, PreviewHelp:Font, s11 cFFFFFF Bold, Segoe UI
	Gui, PreviewHelp:Add, Text, x150 y15, CROP
	Gui, PreviewHelp:Font, s10 Normal, Segoe UI
	Gui, PreviewHelp:Add, Text, x150 y+10 c808080, hjkl
	Gui, PreviewHelp:Add, Text, x195 yp cE0E0E0, Shrink
	Gui, PreviewHelp:Add, Text, x150 y+5 c808080, Shift
	Gui, PreviewHelp:Add, Text, x195 yp cE0E0E0, Extend
	Gui, PreviewHelp:Add, Text, x150 y+5 c808080, Enter
	Gui, PreviewHelp:Add, Text, x195 yp cE0E0E0, Apply
	Gui, PreviewHelp:Add, Text, x150 y+5 c808080, Esc
	Gui, PreviewHelp:Add, Text, x195 yp cE0E0E0, Cancel

	; Column 3: ARROW MODE
	Gui, PreviewHelp:Font, s11 cFFFFFF Bold, Segoe UI
	Gui, PreviewHelp:Add, Text, x270 y15, ARROW
	Gui, PreviewHelp:Font, s10 Normal, Segoe UI
	Gui, PreviewHelp:Add, Text, x270 y+10 c808080, hjkl
	Gui, PreviewHelp:Add, Text, x320 yp cE0E0E0, Move
	Gui, PreviewHelp:Add, Text, x270 y+5 c808080, Space
	Gui, PreviewHelp:Add, Text, x320 yp cE0E0E0, Set point
	Gui, PreviewHelp:Add, Text, x270 y+5 c808080, c
	Gui, PreviewHelp:Add, Text, x320 yp cE0E0E0, Color
	Gui, PreviewHelp:Add, Text, x270 y+5 c808080, i / u
	Gui, PreviewHelp:Add, Text, x320 yp cE0E0E0, Size
	Gui, PreviewHelp:Add, Text, x270 y+5 c808080, z
	Gui, PreviewHelp:Add, Text, x320 yp cE0E0E0, Undo
	Gui, PreviewHelp:Add, Text, x270 y+5 c808080, Enter
	Gui, PreviewHelp:Add, Text, x320 yp cE0E0E0, Apply
	Gui, PreviewHelp:Add, Text, x270 y+5 c808080, Esc
	Gui, PreviewHelp:Add, Text, x320 yp cE0E0E0, Cancel

	; Column 4: NUMBER MODE
	Gui, PreviewHelp:Font, s11 cFFFFFF Bold, Segoe UI
	Gui, PreviewHelp:Add, Text, x390 y15, NUMBER
	Gui, PreviewHelp:Font, s10 Normal, Segoe UI
	Gui, PreviewHelp:Add, Text, x390 y+10 c808080, hjkl
	Gui, PreviewHelp:Add, Text, x440 yp cE0E0E0, Move
	Gui, PreviewHelp:Add, Text, x390 y+5 c808080, 1-0
	Gui, PreviewHelp:Add, Text, x440 yp cE0E0E0, Place 1-10
	Gui, PreviewHelp:Add, Text, x390 y+5 c808080, c
	Gui, PreviewHelp:Add, Text, x440 yp cE0E0E0, Color
	Gui, PreviewHelp:Add, Text, x390 y+5 c808080, i / u
	Gui, PreviewHelp:Add, Text, x440 yp cE0E0E0, Size
	Gui, PreviewHelp:Add, Text, x390 y+5 c808080, z
	Gui, PreviewHelp:Add, Text, x440 yp cE0E0E0, Undo
	Gui, PreviewHelp:Add, Text, x390 y+5 c808080, Enter
	Gui, PreviewHelp:Add, Text, x440 yp cE0E0E0, Apply
	Gui, PreviewHelp:Add, Text, x390 y+5 c808080, Esc
	Gui, PreviewHelp:Add, Text, x440 yp cE0E0E0, Cancel

	; Column 5: RECTANGLE MODE
	Gui, PreviewHelp:Font, s11 cFFFFFF Bold, Segoe UI
	Gui, PreviewHelp:Add, Text, x510 y15, RECT
	Gui, PreviewHelp:Font, s10 Normal, Segoe UI
	Gui, PreviewHelp:Add, Text, x510 y+10 c808080, hjkl
	Gui, PreviewHelp:Add, Text, x560 yp cE0E0E0, Move
	Gui, PreviewHelp:Add, Text, x510 y+5 c808080, Space
	Gui, PreviewHelp:Add, Text, x560 yp cE0E0E0, Set corner
	Gui, PreviewHelp:Add, Text, x510 y+5 c808080, c
	Gui, PreviewHelp:Add, Text, x560 yp cE0E0E0, Color
	Gui, PreviewHelp:Add, Text, x510 y+5 c808080, i / u
	Gui, PreviewHelp:Add, Text, x560 yp cE0E0E0, Size
	Gui, PreviewHelp:Add, Text, x510 y+5 c808080, z
	Gui, PreviewHelp:Add, Text, x560 yp cE0E0E0, Undo
	Gui, PreviewHelp:Add, Text, x510 y+5 c808080, Enter
	Gui, PreviewHelp:Add, Text, x560 yp cE0E0E0, Apply
	Gui, PreviewHelp:Add, Text, x510 y+5 c808080, Esc
	Gui, PreviewHelp:Add, Text, x560 yp cE0E0E0, Cancel

	; Footer
	Gui, PreviewHelp:Font, s9 c606060 Normal, Segoe UI
	Gui, PreviewHelp:Add, Text, x15 y+20, Press F1 or Esc to close
	Gui, PreviewHelp:Show, , Preview Shortcuts
	previewHelpOpen := 1
return

PreviewHelpGuiClose:
PreviewHelpGuiEscape:
	Gui, PreviewHelp:Destroy
	previewHelpOpen := 0
return
#If
