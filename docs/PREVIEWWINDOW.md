# Preview Window Documentation

## Overview
The preview window displays captured screenshots and allows viewing, cropping, and saving.

## Files
| File | Purpose |
|------|---------|
| `lib/preview_window.ahk` | Main preview window code (GUI, hotkeys, paint handler) |
| `lib/crop.ahk` | Crop mode functions (overlay, status bar, crop logic) |
| `lib/image.ahk` | Image saving functions (SaveGdipBitmap, etc.) |

## Features

### Viewing Mode
- Display screenshot with aspect ratio preservation
- Dark theme (background: `#1e1e1e`)
- Resizable window (position/size saved to settings.ini)
- Always on top

### Crop Mode
- Press `c` to enter crop mode
- Adjust crop edges with `hjkl` or arrow keys:
  - `h` / `Left` - shrink from left
  - `l` / `Right` - shrink from right
  - `k` / `Up` - shrink from top
  - `j` / `Down` - shrink from bottom
- Hold `Shift` + direction key to extend (reverse direction)
- Press `Enter` to apply crop
- Press `Esc` to cancel and return to viewing mode
- Visual overlay darkens areas to be cropped

### Hotkeys (when preview window is active)
| Key | Action |
|-----|--------|
| `c` | Enter crop mode |
| `h` / `Left` | Crop: shrink from left |
| `l` / `Right` | Crop: shrink from right |
| `k` / `Up` | Crop: shrink from top |
| `j` / `Down` | Crop: shrink from bottom |
| `Shift` + direction | Crop: extend (reverse direction) |
| `Enter` | Apply crop |
| `f` | Save to file (overwrites if already saved) |
| `Esc` | Exit crop mode / Close window |

## Status Bar
Bottom of window shows current mode and available actions:
- Viewing: `[Viewing]  c:crop  f:save  Esc:close`
- Crop: `[Crop]  hjkl:adjust  Enter:apply  Esc:cancel`

## Global Variables
```ahk
; Preview window state (FastKeyboardScreenshot.ahk)
previewImagePath := ""
previewImageWidth := 0
previewImageHeight := 0
previewPBitmap := 0           ; GDI+ bitmap handle
previewHwnd := 0              ; Window handle
previewTempFile := ""         ; Temp file path
previewSavedFilePath := ""    ; Saved file path for overwrite

; Crop mode state
previewMode := "viewing" ; "viewing" or "crop"
cropLeft := 0
cropTop := 0
cropRight := 0
cropBottom := 0
cropStep := 10           ; Pixels per keypress
```

## Key Functions

### preview_window.ahk
- `ShowImageWindow(tempFile, nW, nH, resizeBy)` - Opens preview window
- `ImageViewPaint()` - WM_PAINT handler for custom rendering

### crop.ahk
- `ApplyCrop()` - Applies crop using Gdip_CloneBitmapArea
- `DrawCropOverlay(pGraphics, offsetX, offsetY, scaledWidth, scaledHeight)` - Draws dark overlay
- `DrawStatusBar(pGraphics, width, height)` - Draws mode indicator
- `AdjustCropEdge(edge, delta)` - Adjusts crop with bounds validation
- `ResetCropState()` - Resets to viewing mode

### image.ahk
- `SaveGdipBitmap(pBitmap, filePath, quality)` - Saves GDI+ bitmap to JPG/PNG/BMP

## Settings (settings.ini)
```ini
[PreviewWindow]
Width=800
Height=600
X=100
Y=100
```

## Technical Notes

### GDI+ Lifecycle
- GDI+ is initialized once at script startup (`pGdipToken` in main file)
- Preview window reuses global GDI+ token
- Bitmap disposed on window close, GDI+ stays running

### Crop Coordinates
- Stored in image space (not screen space)
- Scaled for display overlay rendering
- Minimum 10px remaining after crop (bounds validation)

## Future Improvements
- [ ] Add zoom in/out functionality
- [ ] Add undo for crop
- [ ] Support multiple crop operations before applying
- [ ] Add copy to clipboard hotkey
- [ ] Add rotation support
