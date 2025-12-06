; rectangle.ahk - Rectangle drawing functions for preview window

; Draw a single rectangle outline
; Coordinates are in screen/display space
DrawRectangle(pGraphics, x1, y1, x2, y2, color, size) {
    ; Normalize coordinates (ensure x1,y1 is top-left)
    left := Min(x1, x2)
    top := Min(y1, y2)
    width := Abs(x2 - x1)
    height := Abs(y2 - y1)

    if (width < 1 || height < 1)
        return

    ; Draw rectangle outline
    pPen := Gdip_CreatePen(color, size)
    Gdip_DrawRectangle(pGraphics, pPen, left, top, width, height)
    Gdip_DeletePen(pPen)
}

; Draw all rectangles in the rectangles array (overlay, scaled to display)
DrawRectanglesOverlay(pGraphics, offsetX, offsetY, scaledWidth, scaledHeight) {
    global rectangles, previewImageWidth, previewImageHeight
    global arrowCursorX, arrowCursorY, rectSettingStart, rectStartX, rectStartY
    global arrowColors, rectColorIndex, rectSize, previewMode

    if (previewMode != "rectangle")
        return

    ; Calculate scale factor
    scaleX := scaledWidth / previewImageWidth
    scaleY := scaledHeight / previewImageHeight

    ; Calculate average scale for rectangle size (so preview matches saved result)
    avgScale := (scaleX + scaleY) / 2

    ; Draw all completed rectangles
    for index, rect in rectangles {
        sx1 := offsetX + rect.x1 * scaleX
        sy1 := offsetY + rect.y1 * scaleY
        sx2 := offsetX + rect.x2 * scaleX
        sy2 := offsetY + rect.y2 * scaleY
        scaledSize := Max(1, rect.size * avgScale)
        DrawRectangle(pGraphics, sx1, sy1, sx2, sy2, rect.color, scaledSize)
    }

    ; Draw in-progress rectangle (from start to cursor)
    if (rectSettingStart = 1) {
        sx1 := offsetX + rectStartX * scaleX
        sy1 := offsetY + rectStartY * scaleY
        sx2 := offsetX + arrowCursorX * scaleX
        sy2 := offsetY + arrowCursorY * scaleY
        scaledSize := Max(1, rectSize * avgScale)
        DrawRectangle(pGraphics, sx1, sy1, sx2, sy2, arrowColors[rectColorIndex+1], scaledSize)
    }

    ; Draw cursor crosshair (scaled to current rectangle size)
    cursorX := offsetX + arrowCursorX * scaleX
    cursorY := offsetY + arrowCursorY * scaleY
    scaledCursorSize := Max(10, rectSize * avgScale * 3)
    DrawRectangleCursor(pGraphics, cursorX, cursorY, scaledCursorSize)
}

; Draw crosshair cursor at position with size indication
DrawRectangleCursor(pGraphics, x, y, size) {
    global arrowColors, rectColorIndex

    ; Create pen for cursor (use current rectangle color)
    pPen := Gdip_CreatePen(arrowColors[rectColorIndex+1], 2)

    ; Draw crosshair scaled to rectangle size
    crossSize := size
    Gdip_DrawLine(pGraphics, pPen, x - crossSize, y, x + crossSize, y)
    Gdip_DrawLine(pGraphics, pPen, x, y - crossSize, x, y + crossSize)

    ; Draw small rectangle at center to indicate rectangle mode
    rectIndicator := Max(4, size / 3)
    Gdip_DrawRectangle(pGraphics, pPen, x - rectIndicator, y - rectIndicator, rectIndicator * 2, rectIndicator * 2)

    Gdip_DeletePen(pPen)
}

; Apply all rectangles permanently to the bitmap
ApplyRectangles() {
    global previewPBitmap, rectangles, previewSavedFilePath

    if (rectangles.Length() = 0)
        return

    ; Create graphics from bitmap
    pGraphics := Gdip_GraphicsFromImage(previewPBitmap)
    Gdip_SetSmoothingMode(pGraphics, 4)  ; AntiAlias

    ; Draw all rectangles directly to bitmap (in image space, no scaling)
    for index, rect in rectangles {
        DrawRectangle(pGraphics, rect.x1, rect.y1, rect.x2, rect.y2, rect.color, rect.size)
    }

    Gdip_DeleteGraphics(pGraphics)

    ; Reset saved file path since bitmap has changed
    previewSavedFilePath := ""

    ; Clear rectangles array
    rectangles := []
}

; Reset rectangle mode state
ResetRectangleState() {
    global previewMode, arrowCursorX, arrowCursorY, rectSettingStart
    global rectStartX, rectStartY, rectangles, previewImageWidth, previewImageHeight

    previewMode := "viewing"
    arrowCursorX := previewImageWidth // 2
    arrowCursorY := previewImageHeight // 2
    rectSettingStart := 0
    rectStartX := 0
    rectStartY := 0
    rectangles := []
}

; Set rectangle point (first or second corner)
SetRectanglePoint() {
    global rectSettingStart, rectStartX, rectStartY, arrowCursorX, arrowCursorY
    global rectangles, arrowColors, rectColorIndex, rectSize

    if (rectSettingStart = 0) {
        ; Setting first corner
        rectStartX := arrowCursorX
        rectStartY := arrowCursorY
        rectSettingStart := 1
    } else {
        ; Setting second corner - create rectangle
        rect := {x1: rectStartX, y1: rectStartY, x2: arrowCursorX, y2: arrowCursorY, color: arrowColors[rectColorIndex+1], size: rectSize}
        rectangles.Push(rect)
        rectSettingStart := 0
    }
}

; Cycle rectangle color
CycleRectangleColor() {
    global rectColorIndex, arrowColors

    rectColorIndex := Mod(rectColorIndex + 1, arrowColors.Length())

    ; Save to settings
    IniWrite, %rectColorIndex%, %A_ScriptDir%\settings.ini, Rectangle, ColorIndex
}

; Change rectangle size
ChangeRectangleSize(delta) {
    global rectSize

    rectSize := Max(1, Min(rectSize + delta, 20))

    ; Save to settings
    IniWrite, %rectSize%, %A_ScriptDir%\settings.ini, Rectangle, Size
}
