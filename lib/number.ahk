; number.ahk - Number annotation functions for preview window

; Draw all numbers in the numbers array (overlay, scaled to display)
DrawNumbersOverlay(pGraphics, offsetX, offsetY, scaledWidth, scaledHeight) {
    global numbers, previewImageWidth, previewImageHeight
    global arrowCursorX, arrowCursorY, arrowColors, numberColorIndex, numberSize, previewMode

    if (previewMode != "number")
        return

    ; Calculate scale factor
    scaleX := scaledWidth / previewImageWidth
    scaleY := scaledHeight / previewImageHeight
    avgScale := (scaleX + scaleY) / 2

    ; Draw all placed numbers
    for index, num in numbers {
        sx := offsetX + num.x * scaleX
        sy := offsetY + num.y * scaleY
        scaledSize := Max(12, num.size * avgScale)
        DrawNumberCircle(pGraphics, sx, sy, num.num, num.color, scaledSize)
    }

    ; Draw cursor crosshair (scaled to current number size)
    cursorX := offsetX + arrowCursorX * scaleX
    cursorY := offsetY + arrowCursorY * scaleY
    scaledCursorSize := Max(12, numberSize * avgScale)
    DrawNumberCursor(pGraphics, cursorX, cursorY, scaledCursorSize)
}

; Draw a single numbered circle
DrawNumberCircle(pGraphics, x, y, num, color, size) {
    ; Draw filled circle
    pBrush := Gdip_BrushCreateSolid(color)
    Gdip_FillEllipse(pGraphics, pBrush, x - size/2, y - size/2, size, size)
    Gdip_DeleteBrush(pBrush)

    ; Draw white text number centered
    pBrushText := Gdip_BrushCreateSolid(0xFFFFFFFF)

    ; Calculate font size based on circle size
    fontSize := size * 0.55

    ; Create font
    hFamily := Gdip_FontFamilyCreate("Arial")
    hFont := Gdip_FontCreate(hFamily, fontSize, 1)  ; 1 = Bold

    ; Create string format for centering horizontally
    hFormat := Gdip_StringFormatCreate(0)
    Gdip_SetStringFormatAlign(hFormat, 1)  ; Center horizontally

    ; Create rect for text positioning (offset Y slightly to center vertically)
    yOffset := size * 0.15
    VarSetCapacity(RC, 16, 0)
    NumPut(x - size/2, RC, 0, "float")
    NumPut(y - size/2 + yOffset, RC, 4, "float")
    NumPut(size, RC, 8, "float")
    NumPut(size, RC, 12, "float")

    ; Draw the number
    Gdip_DrawString(pGraphics, num, hFont, hFormat, pBrushText, RC)

    ; Cleanup
    Gdip_DeleteBrush(pBrushText)
    Gdip_DeleteFont(hFont)
    Gdip_DeleteFontFamily(hFamily)
    Gdip_DeleteStringFormat(hFormat)
}

; Draw crosshair cursor at position with size indication
DrawNumberCursor(pGraphics, x, y, size) {
    global arrowColors, numberColorIndex

    ; Create pen for cursor (use current number color)
    pPen := Gdip_CreatePen(arrowColors[numberColorIndex+1], 2)

    ; Draw crosshair extending beyond the circle size
    crossSize := size / 2 + 10
    Gdip_DrawLine(pGraphics, pPen, x - crossSize, y, x + crossSize, y)
    Gdip_DrawLine(pGraphics, pPen, x, y - crossSize, x, y + crossSize)

    ; Draw circle at center matching the number circle size
    circleRadius := size / 2
    Gdip_DrawEllipse(pGraphics, pPen, x - circleRadius, y - circleRadius, circleRadius * 2, circleRadius * 2)

    Gdip_DeletePen(pPen)
}

; Apply all numbers permanently to the bitmap
ApplyNumbers() {
    global previewPBitmap, numbers, previewSavedFilePath

    if (numbers.Length() = 0)
        return

    ; Create graphics from bitmap
    pGraphics := Gdip_GraphicsFromImage(previewPBitmap)
    Gdip_SetSmoothingMode(pGraphics, 4)  ; AntiAlias
    Gdip_SetTextRenderingHint(pGraphics, 4)  ; AntiAlias text

    ; Draw all numbers directly to bitmap (in image space, no scaling)
    for index, num in numbers {
        DrawNumberCircle(pGraphics, num.x, num.y, num.num, num.color, num.size)
    }

    Gdip_DeleteGraphics(pGraphics)

    ; Reset saved file path since bitmap has changed
    previewSavedFilePath := ""

    ; Clear numbers array
    numbers := []
}

; Reset number mode state
ResetNumberState() {
    global previewMode, arrowCursorX, arrowCursorY, numbers, previewImageWidth, previewImageHeight

    previewMode := "viewing"
    arrowCursorX := previewImageWidth // 2
    arrowCursorY := previewImageHeight // 2
    numbers := []
}

; Add number at current cursor position
AddNumber(num) {
    global arrowCursorX, arrowCursorY, numbers, arrowColors, numberColorIndex, numberSize

    number := {x: arrowCursorX, y: arrowCursorY, num: num, color: arrowColors[numberColorIndex+1], size: numberSize}
    numbers.Push(number)
}

; Cycle number color
CycleNumberColor() {
    global numberColorIndex, arrowColors

    numberColorIndex := Mod(numberColorIndex + 1, arrowColors.Length())

    ; Save to settings
    IniWrite, %numberColorIndex%, %A_ScriptDir%\settings.ini, Number, ColorIndex
}

; Change number size
ChangeNumberSize(delta) {
    global numberSize

    numberSize := Max(12, Min(numberSize + delta * 2, 60))

    ; Save to settings
    IniWrite, %numberSize%, %A_ScriptDir%\settings.ini, Number, Size
}
