; arrow.ahk - Arrow drawing functions for preview window

; Draw a single arrow with head
; Coordinates are in screen/display space
DrawArrow(pGraphics, x1, y1, x2, y2, color, size) {
    ; Draw line
    pPen := Gdip_CreatePen(color, size)
    Gdip_DrawLine(pGraphics, pPen, x1, y1, x2, y2)

    ; Calculate arrow head
    dx := x2 - x1
    dy := y2 - y1
    length := Sqrt(dx*dx + dy*dy)

    if (length < 1) {
        Gdip_DeletePen(pPen)
        return
    }

    ; Normalize direction
    dx := dx / length
    dy := dy / length

    ; Arrow head parameters
    headLength := size * 5
    headAngle := 0.5  ; ~30 degrees

    ; Calculate arrow head points using rotation
    cosA := Cos(headAngle)
    sinA := Sin(headAngle)

    ; First head line (rotated one way)
    hx1 := x2 - headLength * (dx * cosA + dy * sinA)
    hy1 := y2 - headLength * (-dx * sinA + dy * cosA)

    ; Second head line (rotated other way)
    hx2 := x2 - headLength * (dx * cosA - dy * sinA)
    hy2 := y2 - headLength * (dx * sinA + dy * cosA)

    ; Draw arrow head
    Gdip_DrawLine(pGraphics, pPen, x2, y2, hx1, hy1)
    Gdip_DrawLine(pGraphics, pPen, x2, y2, hx2, hy2)

    Gdip_DeletePen(pPen)
}

; Draw all arrows in the arrows array (overlay, scaled to display)
DrawArrowsOverlay(pGraphics, offsetX, offsetY, scaledWidth, scaledHeight) {
    global arrows, previewImageWidth, previewImageHeight
    global arrowCursorX, arrowCursorY, arrowSettingStart, arrowStartX, arrowStartY
    global arrowColors, arrowColorIndex, arrowSize, previewMode

    if (previewMode != "arrow")
        return

    ; Calculate scale factor
    scaleX := scaledWidth / previewImageWidth
    scaleY := scaledHeight / previewImageHeight

    ; Calculate average scale for arrow size (so preview matches saved result)
    avgScale := (scaleX + scaleY) / 2

    ; Draw all completed arrows
    for index, arrow in arrows {
        sx1 := offsetX + arrow.x1 * scaleX
        sy1 := offsetY + arrow.y1 * scaleY
        sx2 := offsetX + arrow.x2 * scaleX
        sy2 := offsetY + arrow.y2 * scaleY
        scaledSize := Max(1, arrow.size * avgScale)
        DrawArrow(pGraphics, sx1, sy1, sx2, sy2, arrow.color, scaledSize)
    }

    ; Draw in-progress arrow (from start to cursor)
    if (arrowSettingStart = 1) {
        sx1 := offsetX + arrowStartX * scaleX
        sy1 := offsetY + arrowStartY * scaleY
        sx2 := offsetX + arrowCursorX * scaleX
        sy2 := offsetY + arrowCursorY * scaleY
        scaledSize := Max(1, arrowSize * avgScale)
        DrawArrow(pGraphics, sx1, sy1, sx2, sy2, arrowColors[arrowColorIndex+1], scaledSize)
    }

    ; Draw cursor crosshair (scaled to current arrow size)
    cursorX := offsetX + arrowCursorX * scaleX
    cursorY := offsetY + arrowCursorY * scaleY
    scaledCursorSize := Max(10, arrowSize * avgScale * 3)
    DrawArrowCursor(pGraphics, cursorX, cursorY, scaledCursorSize)
}

; Draw crosshair cursor at position with size indication
DrawArrowCursor(pGraphics, x, y, size) {
    global arrowColors, arrowColorIndex

    ; Create pen for cursor (use current arrow color)
    pPen := Gdip_CreatePen(arrowColors[arrowColorIndex+1], 2)

    ; Draw crosshair scaled to arrow size
    crossSize := size
    Gdip_DrawLine(pGraphics, pPen, x - crossSize, y, x + crossSize, y)
    Gdip_DrawLine(pGraphics, pPen, x, y - crossSize, x, y + crossSize)

    ; Draw circle at center scaled to arrow size
    circleRadius := Max(3, size / 3)
    Gdip_DrawEllipse(pGraphics, pPen, x - circleRadius, y - circleRadius, circleRadius * 2, circleRadius * 2)

    Gdip_DeletePen(pPen)
}

; Apply all arrows permanently to the bitmap
ApplyArrows() {
    global previewPBitmap, arrows, previewSavedFilePath

    if (arrows.Length() = 0)
        return

    ; Create graphics from bitmap
    pGraphics := Gdip_GraphicsFromImage(previewPBitmap)
    Gdip_SetSmoothingMode(pGraphics, 4)  ; AntiAlias

    ; Draw all arrows directly to bitmap (in image space, no scaling)
    for index, arrow in arrows {
        DrawArrow(pGraphics, arrow.x1, arrow.y1, arrow.x2, arrow.y2, arrow.color, arrow.size)
    }

    Gdip_DeleteGraphics(pGraphics)

    ; Reset saved file path since bitmap has changed
    previewSavedFilePath := ""

    ; Clear arrows array
    arrows := []
}

; Reset arrow mode state
ResetArrowState() {
    global previewMode, arrowCursorX, arrowCursorY, arrowSettingStart
    global arrowStartX, arrowStartY, arrows, previewImageWidth, previewImageHeight

    previewMode := "viewing"
    arrowCursorX := previewImageWidth // 2
    arrowCursorY := previewImageHeight // 2
    arrowSettingStart := 0
    arrowStartX := 0
    arrowStartY := 0
    arrows := []
}

; Move arrow cursor with bounds checking
MoveArrowCursor(dx, dy) {
    global arrowCursorX, arrowCursorY, previewImageWidth, previewImageHeight

    arrowCursorX := Max(0, Min(arrowCursorX + dx, previewImageWidth - 1))
    arrowCursorY := Max(0, Min(arrowCursorY + dy, previewImageHeight - 1))

    ; Move mouse cursor to follow
    MoveMouseToArrowCursor()
}

; Move mouse cursor to match the arrow cursor position
MoveMouseToArrowCursor() {
    global previewHwnd, arrowCursorX, arrowCursorY
    global previewImageWidth, previewImageHeight

    if (!previewHwnd)
        return

    ; Get window client area position
    VarSetCapacity(rect, 16, 0)
    DllCall("GetClientRect", "ptr", previewHwnd, "ptr", &rect)
    clientWidth := NumGet(rect, 8, "int")
    clientHeight := NumGet(rect, 12, "int")

    ; Calculate image display area (same logic as ImageViewPaint)
    topBarHeight := 30
    bottomBarHeight := 45
    availHeight := clientHeight - topBarHeight - bottomBarHeight

    ; Calculate aspect ratio and scaling
    imageAspect := previewImageWidth / previewImageHeight
    availAspect := clientWidth / availHeight

    if (imageAspect > availAspect) {
        ; Image is wider - fit to width
        scaledWidth := clientWidth
        scaledHeight := clientWidth / imageAspect
        offsetX := 0
        offsetY := topBarHeight + (availHeight - scaledHeight) / 2
    } else {
        ; Image is taller - fit to height
        scaledHeight := availHeight
        scaledWidth := availHeight * imageAspect
        offsetX := (clientWidth - scaledWidth) / 2
        offsetY := topBarHeight
    }

    ; Calculate scale factor
    scaleX := scaledWidth / previewImageWidth
    scaleY := scaledHeight / previewImageHeight

    ; Convert arrow cursor to client coordinates
    clientX := Floor(offsetX + arrowCursorX * scaleX)
    clientY := Floor(offsetY + arrowCursorY * scaleY)

    ; Convert client coordinates to screen coordinates
    VarSetCapacity(pt, 8, 0)
    NumPut(clientX, pt, 0, "int")
    NumPut(clientY, pt, 4, "int")
    DllCall("ClientToScreen", "ptr", previewHwnd, "ptr", &pt)
    screenX := NumGet(pt, 0, "int")
    screenY := NumGet(pt, 4, "int")

    ; Move mouse cursor
    MouseMove, %screenX%, %screenY%, 0
}

; Set arrow cursor position from current mouse position
SetArrowCursorFromMouse() {
    global previewHwnd, arrowCursorX, arrowCursorY
    global previewImageWidth, previewImageHeight

    if (!previewHwnd)
        return

    ; Get current mouse position
    MouseGetPos, mouseX, mouseY

    ; Convert screen coordinates to client coordinates
    VarSetCapacity(pt, 8, 0)
    NumPut(mouseX, pt, 0, "int")
    NumPut(mouseY, pt, 4, "int")
    DllCall("ScreenToClient", "ptr", previewHwnd, "ptr", &pt)
    clientX := NumGet(pt, 0, "int")
    clientY := NumGet(pt, 4, "int")

    ; Get window client area dimensions
    VarSetCapacity(rect, 16, 0)
    DllCall("GetClientRect", "ptr", previewHwnd, "ptr", &rect)
    clientWidth := NumGet(rect, 8, "int")
    clientHeight := NumGet(rect, 12, "int")

    ; Calculate image display area (same logic as ImageViewPaint)
    topBarHeight := 30
    bottomBarHeight := 45
    availHeight := clientHeight - topBarHeight - bottomBarHeight

    ; Calculate aspect ratio and scaling
    imageAspect := previewImageWidth / previewImageHeight
    availAspect := clientWidth / availHeight

    if (imageAspect > availAspect) {
        ; Image is wider - fit to width
        scaledWidth := clientWidth
        scaledHeight := clientWidth / imageAspect
        offsetX := 0
        offsetY := topBarHeight + (availHeight - scaledHeight) / 2
    } else {
        ; Image is taller - fit to height
        scaledHeight := availHeight
        scaledWidth := availHeight * imageAspect
        offsetX := (clientWidth - scaledWidth) / 2
        offsetY := topBarHeight
    }

    ; Calculate scale factor
    scaleX := scaledWidth / previewImageWidth
    scaleY := scaledHeight / previewImageHeight

    ; Convert client coordinates to image coordinates
    imageX := (clientX - offsetX) / scaleX
    imageY := (clientY - offsetY) / scaleY

    ; Clamp to image bounds
    arrowCursorX := Max(0, Min(Floor(imageX), previewImageWidth - 1))
    arrowCursorY := Max(0, Min(Floor(imageY), previewImageHeight - 1))
}

; Set arrow point (start or end)
SetArrowPoint() {
    global arrowSettingStart, arrowStartX, arrowStartY, arrowCursorX, arrowCursorY
    global arrows, arrowColors, arrowColorIndex, arrowSize

    if (arrowSettingStart = 0) {
        ; Setting start point
        arrowStartX := arrowCursorX
        arrowStartY := arrowCursorY
        arrowSettingStart := 1
    } else {
        ; Setting end point - create arrow
        arrow := {x1: arrowStartX, y1: arrowStartY, x2: arrowCursorX, y2: arrowCursorY, color: arrowColors[arrowColorIndex+1], size: arrowSize}
        arrows.Push(arrow)
        arrowSettingStart := 0
    }
}

; Cycle arrow color
CycleArrowColor() {
    global arrowColorIndex, arrowColors

    arrowColorIndex := Mod(arrowColorIndex + 1, arrowColors.Length())

    ; Save to settings
    IniWrite, %arrowColorIndex%, %A_ScriptDir%\settings.ini, Arrow, ColorIndex
}

; Change arrow size
ChangeArrowSize(delta) {
    global arrowSize

    arrowSize := Max(1, Min(arrowSize + delta, 20))

    ; Save to settings
    IniWrite, %arrowSize%, %A_ScriptDir%\settings.ini, Arrow, Size
}
