; status_bar.ahk - Status bar drawing functions for preview window

; Draw status bar at bottom of window
DrawStatusBar(pGraphics, width, height) {
    global previewMode, arrowColorIndex, arrowColorNames, numberColorIndex, rectColorIndex

    ; Create font and brush - larger font for better visibility
    hFamily := Gdip_FontFamilyCreate("Segoe UI")
    hFont := Gdip_FontCreate(hFamily, 16, 0)
    pBrush := Gdip_BrushCreateSolid(0xFFE0E0E0)

    ; Status text based on mode
    if (previewMode = "viewing")
        text := "[Viewing]  a:arrow  n:number  r:rect  c:crop  f:save  p:copy  u:upload  Esc:close"
    else if (previewMode = "crop")
        text := "[Crop]  hjkl:adjust  Shift:extend  Enter:apply  Esc:cancel"
    else if (previewMode = "arrow")
        text := "[Arrow:" . arrowColorNames[arrowColorIndex+1] . "]  hjkl:move  Space:set  u/i:size  c:color  z:undo  Enter:apply  Esc:cancel"
    else if (previewMode = "number")
        text := "[Number:" . arrowColorNames[numberColorIndex+1] . "]  hjkl:move  1-0:place  u/i:size  c:color  z:undo  Enter:apply  Esc:cancel"
    else if (previewMode = "rectangle")
        text := "[Rect:" . arrowColorNames[rectColorIndex+1] . "]  hjkl:move  Space:set  u/i:size  c:color  z:undo  Enter:apply  Esc:cancel"

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
