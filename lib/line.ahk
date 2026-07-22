; line.ahk - Line drawing functions for preview window

; Draw a single straight line
; Coordinates are in screen/display space
DrawStraightLine(pGraphics, x1, y1, x2, y2, color, size) {
    pPen := Gdip_CreatePen(color, size)
    Gdip_DrawLine(pGraphics, pPen, x1, y1, x2, y2)
    Gdip_DeletePen(pPen)
}

; Snap line endpoint to nearest 45-degree angle from start point
SnapLineEndpoint(x1, y1, ByRef x2, ByRef y2) {
    global previewImageWidth, previewImageHeight

    dx := x2 - x1
    dy := y2 - y1
    if (dx = 0 && dy = 0)
        return

    angle := DllCall("msvcrt\atan2", "Double", dy, "Double", dx, "CDECL Double")
    step := 3.14159265358979 / 4
    angle := Round(angle / step) * step
    len := Sqrt(dx * dx + dy * dy)

    x2 := Round(x1 + len * Cos(angle))
    y2 := Round(y1 + len * Sin(angle))

    ; Keep endpoint inside image bounds
    x2 := Max(0, Min(x2, previewImageWidth - 1))
    y2 := Max(0, Min(y2, previewImageHeight - 1))
}

; Draw all lines in the lines array (overlay, scaled to display)
DrawLinesOverlay(pGraphics, offsetX, offsetY, scaledWidth, scaledHeight) {
    global lines, previewImageWidth, previewImageHeight
    global arrowCursorX, arrowCursorY, lineSettingStart, lineStartX, lineStartY
    global arrowColors, lineColorIndex, lineSize, previewMode

    if (previewMode != "line")
        return

    ; Calculate scale factor
    scaleX := scaledWidth / previewImageWidth
    scaleY := scaledHeight / previewImageHeight

    ; Calculate average scale for line size (so preview matches saved result)
    avgScale := (scaleX + scaleY) / 2

    ; Draw all completed lines
    for index, line in lines {
        sx1 := offsetX + line.x1 * scaleX
        sy1 := offsetY + line.y1 * scaleY
        sx2 := offsetX + line.x2 * scaleX
        sy2 := offsetY + line.y2 * scaleY
        scaledSize := Max(1, line.size * avgScale)
        DrawStraightLine(pGraphics, sx1, sy1, sx2, sy2, line.color, scaledSize)
    }

    ; Draw in-progress line (from start to cursor, snapped to 45° if Shift held)
    if (lineSettingStart = 1) {
        endX := arrowCursorX
        endY := arrowCursorY
        if (GetKeyState("Shift", "P"))
            SnapLineEndpoint(lineStartX, lineStartY, endX, endY)
        sx1 := offsetX + lineStartX * scaleX
        sy1 := offsetY + lineStartY * scaleY
        sx2 := offsetX + endX * scaleX
        sy2 := offsetY + endY * scaleY
        scaledSize := Max(1, lineSize * avgScale)
        DrawStraightLine(pGraphics, sx1, sy1, sx2, sy2, arrowColors[lineColorIndex+1], scaledSize)
    }

    ; Draw cursor crosshair (scaled to current line size)
    cursorX := offsetX + arrowCursorX * scaleX
    cursorY := offsetY + arrowCursorY * scaleY
    scaledCursorSize := Max(10, lineSize * avgScale * 3)
    DrawLineCursor(pGraphics, cursorX, cursorY, scaledCursorSize)
}

; Draw crosshair cursor at position with size indication
DrawLineCursor(pGraphics, x, y, size) {
    global arrowColors, lineColorIndex

    ; Create pen for cursor (use current line color)
    pPen := Gdip_CreatePen(arrowColors[lineColorIndex+1], 2)

    ; Draw crosshair scaled to line size
    crossSize := size
    Gdip_DrawLine(pGraphics, pPen, x - crossSize, y, x + crossSize, y)
    Gdip_DrawLine(pGraphics, pPen, x, y - crossSize, x, y + crossSize)

    ; Draw small diagonal line at center to indicate line mode
    lineIndicator := Max(4, size / 3)
    Gdip_DrawLine(pGraphics, pPen, x - lineIndicator, y + lineIndicator, x + lineIndicator, y - lineIndicator)

    Gdip_DeletePen(pPen)
}

; Apply all lines permanently to the bitmap
ApplyLines() {
    global previewPBitmap, lines, previewSavedFilePath

    if (lines.Length() = 0)
        return

    ; Create graphics from bitmap
    pGraphics := Gdip_GraphicsFromImage(previewPBitmap)
    Gdip_SetSmoothingMode(pGraphics, 4)  ; AntiAlias

    ; Draw all lines directly to bitmap (in image space, no scaling)
    for index, line in lines {
        DrawStraightLine(pGraphics, line.x1, line.y1, line.x2, line.y2, line.color, line.size)
    }

    Gdip_DeleteGraphics(pGraphics)

    ; Reset saved file path since bitmap has changed
    previewSavedFilePath := ""

    ; Clear lines array
    lines := []
}

; Reset line mode state
ResetLineState() {
    global previewMode, arrowCursorX, arrowCursorY, lineSettingStart
    global lineStartX, lineStartY, lines, previewImageWidth, previewImageHeight

    previewMode := "viewing"
    arrowCursorX := previewImageWidth // 2
    arrowCursorY := previewImageHeight // 2
    lineSettingStart := 0
    lineStartX := 0
    lineStartY := 0
    lines := []
}

; Set line point (start or end)
SetLinePoint() {
    global lineSettingStart, lineStartX, lineStartY, arrowCursorX, arrowCursorY
    global lines, arrowColors, lineColorIndex, lineSize

    if (lineSettingStart = 0) {
        ; Setting start point
        lineStartX := arrowCursorX
        lineStartY := arrowCursorY
        lineSettingStart := 1
    } else {
        ; Setting end point - create line (snapped to 45° if Shift held)
        endX := arrowCursorX
        endY := arrowCursorY
        if (GetKeyState("Shift", "P"))
            SnapLineEndpoint(lineStartX, lineStartY, endX, endY)
        line := {x1: lineStartX, y1: lineStartY, x2: endX, y2: endY, color: arrowColors[lineColorIndex+1], size: lineSize}
        lines.Push(line)
        lineSettingStart := 0
    }
}

; Commit current segment and continue drawing from its endpoint (multiline)
CommitLineAndContinue() {
    global lineSettingStart, lineStartX, lineStartY, arrowCursorX, arrowCursorY
    global lines, arrowColors, lineColorIndex, lineSize

    if (lineSettingStart != 1)
        return

    endX := arrowCursorX
    endY := arrowCursorY
    if (GetKeyState("Shift", "P"))
        SnapLineEndpoint(lineStartX, lineStartY, endX, endY)

    ; Skip zero-length segments (e.g. key auto-repeat without cursor movement)
    if (endX = lineStartX && endY = lineStartY)
        return

    line := {x1: lineStartX, y1: lineStartY, x2: endX, y2: endY, color: arrowColors[lineColorIndex+1], size: lineSize}
    lines.Push(line)

    ; Next segment starts where this one ended
    lineStartX := endX
    lineStartY := endY
    lineSettingStart := 1
}

; Cycle line color
CycleLineColor() {
    global lineColorIndex, arrowColors, settingsFile

    lineColorIndex := Mod(lineColorIndex + 1, arrowColors.Length())

    ; Save to settings
    IniWrite, %lineColorIndex%, %settingsFile%, Line, ColorIndex
}

; Change line size
ChangeLineSize(delta) {
    global lineSize, settingsFile

    lineSize := Max(1, Min(lineSize + delta, 20))

    ; Save to settings
    IniWrite, %lineSize%, %settingsFile%, Line, Size
}
