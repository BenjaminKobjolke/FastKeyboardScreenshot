; crop.ahk - Crop mode functions for preview window

; Apply the current crop to the bitmap
ApplyCrop() {
    global previewPBitmap, previewImageWidth, previewImageHeight
    global cropLeft, cropTop, cropRight, cropBottom
    global previewSavedFilePath

    newWidth := previewImageWidth - cropLeft - cropRight
    newHeight := previewImageHeight - cropTop - cropBottom

    if (newWidth < 1 || newHeight < 1)
        return

    pBitmapCropped := Gdip_CloneBitmapArea(previewPBitmap, cropLeft, cropTop, newWidth, newHeight)
    Gdip_DisposeImage(previewPBitmap)

    previewPBitmap := pBitmapCropped
    previewImageWidth := newWidth
    previewImageHeight := newHeight

    cropLeft := 0
    cropTop := 0
    cropRight := 0
    cropBottom := 0

    ; Reset saved file path since bitmap has changed
    previewSavedFilePath := ""
}

; Draw darkened overlay on areas being cropped
DrawCropOverlay(pGraphics, offsetX, offsetY, scaledWidth, scaledHeight) {
    global cropLeft, cropTop, cropRight, cropBottom
    global previewImageWidth, previewImageHeight

    ; Calculate scale factor
    scaleX := scaledWidth / previewImageWidth
    scaleY := scaledHeight / previewImageHeight

    ; Create semi-transparent brush (ARGB: ~67% opacity black)
    pBrush := Gdip_BrushCreateSolid(0xAA000000)

    ; Calculate scaled crop dimensions
    sLeft := cropLeft * scaleX
    sTop := cropTop * scaleY
    sRight := cropRight * scaleX
    sBottom := cropBottom * scaleY

    ; Draw 4 overlay rectangles for cropped edges
    ; Left edge
    if (cropLeft > 0)
        Gdip_FillRectangle(pGraphics, pBrush, offsetX, offsetY, sLeft, scaledHeight)
    ; Right edge
    if (cropRight > 0)
        Gdip_FillRectangle(pGraphics, pBrush, offsetX + scaledWidth - sRight, offsetY, sRight, scaledHeight)
    ; Top edge (between left and right crops)
    if (cropTop > 0)
        Gdip_FillRectangle(pGraphics, pBrush, offsetX + sLeft, offsetY, scaledWidth - sLeft - sRight, sTop)
    ; Bottom edge (between left and right crops)
    if (cropBottom > 0)
        Gdip_FillRectangle(pGraphics, pBrush, offsetX + sLeft, offsetY + scaledHeight - sBottom, scaledWidth - sLeft - sRight, sBottom)

    Gdip_DeleteBrush(pBrush)
}

; Draw status bar at bottom of window
DrawStatusBar(pGraphics, width, height) {
    global previewMode

    ; Create font and brush - larger font for better visibility
    hFamily := Gdip_FontFamilyCreate("Segoe UI")
    hFont := Gdip_FontCreate(hFamily, 16, 0)
    pBrush := Gdip_BrushCreateSolid(0xFFE0E0E0)

    ; Status text based on mode
    if (previewMode = "viewing")
        text := "[Viewing]  c:crop  f:save  Esc:close"
    else
        text := "[Crop]  hjkl:adjust  Enter:apply  Esc:cancel"

    ; Create string format (centered)
    hFormat := Gdip_StringFormatCreate(0)
    Gdip_SetStringFormatAlign(hFormat, 1)  ; Center

    ; Create rect for text (bottom 40px)
    VarSetCapacity(RectF, 16)
    NumPut(0, RectF, 0, "float")
    NumPut(height - 35, RectF, 4, "float")
    NumPut(width, RectF, 8, "float")
    NumPut(40, RectF, 12, "float")

    ; Draw text
    Gdip_DrawString(pGraphics, text, hFont, hFormat, pBrush, RectF)

    ; Cleanup
    Gdip_DeleteBrush(pBrush)
    Gdip_DeleteStringFormat(hFormat)
    Gdip_DeleteFont(hFont)
    Gdip_DeleteFontFamily(hFamily)
}

; Draw resolution status bar at top of window
DrawTopStatusBar(pGraphics, width) {
    global previewImageWidth, previewImageHeight

    hFamily := Gdip_FontFamilyCreate("Segoe UI")
    hFont := Gdip_FontCreate(hFamily, 14, 0)
    pBrush := Gdip_BrushCreateSolid(0xFFE0E0E0)

    text := previewImageWidth . " x " . previewImageHeight

    hFormat := Gdip_StringFormatCreate(0)
    Gdip_SetStringFormatAlign(hFormat, 1)  ; Center

    ; Top 25px area
    VarSetCapacity(RectF, 16)
    NumPut(0, RectF, 0, "float")
    NumPut(5, RectF, 4, "float")
    NumPut(width, RectF, 8, "float")
    NumPut(25, RectF, 12, "float")

    Gdip_DrawString(pGraphics, text, hFont, hFormat, pBrush, RectF)

    Gdip_DeleteBrush(pBrush)
    Gdip_DeleteStringFormat(hFormat)
    Gdip_DeleteFont(hFont)
    Gdip_DeleteFontFamily(hFamily)
}

; Adjust crop edge with bounds validation
AdjustCropEdge(edge, delta) {
    global cropLeft, cropTop, cropRight, cropBottom
    global previewImageWidth, previewImageHeight

    if (edge = "left") {
        cropLeft := Max(0, Min(cropLeft + delta, previewImageWidth - cropRight - 10))
    } else if (edge = "right") {
        cropRight := Max(0, Min(cropRight + delta, previewImageWidth - cropLeft - 10))
    } else if (edge = "top") {
        cropTop := Max(0, Min(cropTop + delta, previewImageHeight - cropBottom - 10))
    } else if (edge = "bottom") {
        cropBottom := Max(0, Min(cropBottom + delta, previewImageHeight - cropTop - 10))
    }
}

; Reset crop state
ResetCropState() {
    global previewMode, cropLeft, cropTop, cropRight, cropBottom
    previewMode := "viewing"
    cropLeft := 0
    cropTop := 0
    cropRight := 0
    cropBottom := 0
}
