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
