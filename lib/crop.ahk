; crop.ahk - Crop mode functions for preview window (two-corner selection)

; Apply the current crop to the bitmap
ApplyCrop() {
    global previewPBitmap, previewImageWidth, previewImageHeight
    global cropStartX, cropStartY, cropSettingStart
    global arrowCursorX, arrowCursorY
    global previewSavedFilePath

    ; Need first corner set (cropSettingStart = 1)
    if (cropSettingStart != 1)
        return

    ; Use current cursor position as second corner (matches what's displayed)
    ; Normalize coordinates (top-left to bottom-right)
    x1 := Min(cropStartX, arrowCursorX)
    y1 := Min(cropStartY, arrowCursorY)
    x2 := Max(cropStartX, arrowCursorX)
    y2 := Max(cropStartY, arrowCursorY)

    newWidth := x2 - x1
    newHeight := y2 - y1

    if (newWidth < 1 || newHeight < 1)
        return

    pBitmapCropped := Gdip_CloneBitmapArea(previewPBitmap, x1, y1, newWidth, newHeight)
    Gdip_DisposeImage(previewPBitmap)

    previewPBitmap := pBitmapCropped
    previewImageWidth := newWidth
    previewImageHeight := newHeight

    ; Reset crop state
    cropSettingStart := 0
    cropStartX := 0
    cropStartY := 0
    cropEndX := 0
    cropEndY := 0

    ; Reset saved file path since bitmap has changed
    previewSavedFilePath := ""
}

; Draw crop overlay with cursor and selection rectangle
DrawCropOverlay(pGraphics, offsetX, offsetY, scaledWidth, scaledHeight) {
    global cropStartX, cropStartY, cropEndX, cropEndY, cropSettingStart
    global previewImageWidth, previewImageHeight
    global arrowCursorX, arrowCursorY

    ; Calculate scale factor
    scaleX := scaledWidth / previewImageWidth
    scaleY := scaledHeight / previewImageHeight

    ; Draw cursor crosshair
    cursorScreenX := offsetX + arrowCursorX * scaleX
    cursorScreenY := offsetY + arrowCursorY * scaleY
    DrawCropCursor(pGraphics, cursorScreenX, cursorScreenY)

    ; If first corner is set, draw selection preview
    if (cropSettingStart = 1) {
        ; Scale the corner coordinates
        sx1 := offsetX + cropStartX * scaleX
        sy1 := offsetY + cropStartY * scaleY
        sx2 := cursorScreenX
        sy2 := cursorScreenY

        ; Normalize for drawing
        drawX := Min(sx1, sx2)
        drawY := Min(sy1, sy2)
        drawW := Abs(sx2 - sx1)
        drawH := Abs(sy2 - sy1)

        ; Draw darkened overlay outside selection
        pBrushDark := Gdip_BrushCreateSolid(0xAA000000)

        ; Top region
        if (drawY > offsetY)
            Gdip_FillRectangle(pGraphics, pBrushDark, offsetX, offsetY, scaledWidth, drawY - offsetY)
        ; Bottom region
        bottomY := drawY + drawH
        if (bottomY < offsetY + scaledHeight)
            Gdip_FillRectangle(pGraphics, pBrushDark, offsetX, bottomY, scaledWidth, offsetY + scaledHeight - bottomY)
        ; Left region (between top and bottom)
        if (drawX > offsetX)
            Gdip_FillRectangle(pGraphics, pBrushDark, offsetX, drawY, drawX - offsetX, drawH)
        ; Right region (between top and bottom)
        rightX := drawX + drawW
        if (rightX < offsetX + scaledWidth)
            Gdip_FillRectangle(pGraphics, pBrushDark, rightX, drawY, offsetX + scaledWidth - rightX, drawH)

        Gdip_DeleteBrush(pBrushDark)

        ; Draw selection rectangle outline
        pPen := Gdip_CreatePen(0xFFFFFFFF, 2)
        Gdip_DrawRectangle(pGraphics, pPen, drawX, drawY, drawW, drawH)
        Gdip_DeletePen(pPen)

        ; Draw dashed inner line for visibility
        pPenDash := Gdip_CreatePen(0xFF000000, 1)
        Gdip_DrawRectangle(pGraphics, pPenDash, drawX + 1, drawY + 1, drawW - 2, drawH - 2)
        Gdip_DeletePen(pPenDash)
    }
}

; Draw crop cursor (crosshair)
DrawCropCursor(pGraphics, x, y) {
    cursorSize := 15
    pPenWhite := Gdip_CreatePen(0xFFFFFFFF, 2)
    pPenBlack := Gdip_CreatePen(0xFF000000, 1)

    ; Horizontal line
    Gdip_DrawLine(pGraphics, pPenWhite, x - cursorSize, y, x + cursorSize, y)
    Gdip_DrawLine(pGraphics, pPenBlack, x - cursorSize, y - 1, x + cursorSize, y - 1)
    ; Vertical line
    Gdip_DrawLine(pGraphics, pPenWhite, x, y - cursorSize, x, y + cursorSize)
    Gdip_DrawLine(pGraphics, pPenBlack, x - 1, y - cursorSize, x - 1, y + cursorSize)

    Gdip_DeletePen(pPenWhite)
    Gdip_DeletePen(pPenBlack)
}

; Set crop corner point (called on Space or mouse click)
SetCropPoint() {
    global cropSettingStart, cropStartX, cropStartY, cropEndX, cropEndY
    global arrowCursorX, arrowCursorY

    if (cropSettingStart = 0) {
        ; Set first corner
        cropStartX := arrowCursorX
        cropStartY := arrowCursorY
        cropSettingStart := 1
    } else {
        ; Set second corner (crop region complete)
        cropEndX := arrowCursorX
        cropEndY := arrowCursorY
        ; Keep cropSettingStart = 1 to indicate region is ready for Apply
    }
}

; Reset crop state
ResetCropState() {
    global previewMode, cropSettingStart, cropStartX, cropStartY, cropEndX, cropEndY
    global arrowCursorX, arrowCursorY, previewImageWidth, previewImageHeight

    previewMode := "viewing"
    cropSettingStart := 0
    cropStartX := 0
    cropStartY := 0
    cropEndX := 0
    cropEndY := 0

    ; Reset cursor to center
    arrowCursorX := previewImageWidth // 2
    arrowCursorY := previewImageHeight // 2
}
