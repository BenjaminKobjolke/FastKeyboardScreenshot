# Preview Window Documentation

## Overview
The preview window displays captured screenshots and provides editing capabilities including cropping, arrow annotations, numbered callouts, and rectangle highlights.

## Files
| File | Purpose |
|------|---------|
| `lib/preview_window.ahk` | Main preview window code (GUI, hotkeys, paint handler) |
| `lib/crop.ahk` | Crop mode functions (overlay, crop logic) |
| `lib/arrow.ahk` | Arrow mode functions (drawing, cursor, apply) |
| `lib/number.ahk` | Number mode functions (circle annotations) |
| `lib/rectangle.ahk` | Rectangle mode functions (outline drawing) |
| `lib/status_bar.ahk` | Status bar rendering for all modes |
| `lib/image.ahk` | Image saving functions (SaveGdipBitmap, etc.) |

## Features

### Viewing Mode
- Display screenshot with aspect ratio preservation
- Dark theme (background: `#1e1e1e`)
- Resizable window (position/size saved to settings.ini)
- Double-buffered rendering (flicker-free)
- Press `F1` for help overlay

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

### Arrow Mode
- Press `a` to enter arrow mode
- Cursor starts at mouse position
- Move cursor with `hjkl` or arrow keys (Shift for 5x speed)
- Press `Space` to set start point, move, `Space` again for end point
- Press `c` to cycle colors (red/blue/green/yellow/black)
- Press `i`/`u` to increase/decrease arrow size
- Press `z` to undo last arrow
- Press `Enter` to apply arrows (completes in-progress arrow first)
- Press `Esc` to cancel and discard arrows
- Settings saved: `arrowColorIndex`, `arrowSize`

### Number Mode
- Press `n` to enter number mode
- Cursor starts at mouse position
- Move cursor with `hjkl` or arrow keys (Shift for 5x speed)
- Press `1-9` to place numbers 1-9, `0` for number 10
- Press `c` to cycle colors (shares arrow color palette)
- Press `i`/`u` to increase/decrease circle size
- Press `z` to undo last number
- Press `Enter` to apply numbers to image
- Press `Esc` to cancel and discard numbers
- Settings saved: `numberColorIndex`, `numberSize`

### Rectangle Mode
- Press `r` to enter rectangle mode
- Cursor starts at mouse position
- Move cursor with `hjkl` or arrow keys (Shift for 5x speed)
- Press `Space` to set first corner, move, `Space` again for opposite corner
- Press `c` to cycle colors (red/blue/green/yellow/black)
- Press `i`/`u` to increase/decrease line thickness
- Press `z` to undo last rectangle
- Press `Enter` to apply rectangles to image
- Press `Esc` to cancel and discard rectangles
- Settings saved: `rectColorIndex`, `rectSize`

### Hotkeys (when preview window is active)
| Key | Mode | Action |
|-----|------|--------|
| `F1` | All | Toggle help window |
| `f` | Viewing | Save to file (overwrites if already saved) |
| `p` | Viewing | Copy screenshot to clipboard |
| `u` | Viewing | Upload to FTP/ShareX |
| `Shift+U` | Viewing | Open last uploaded URL |
| `c` | Viewing | Enter crop mode |
| `a` | Viewing | Enter arrow mode |
| `n` | Viewing | Enter number mode |
| `r` | Viewing | Enter rectangle mode |
| `hjkl` / Arrows | Crop | Shrink from edge |
| `Shift` + above | Crop | Extend edge |
| `hjkl` / Arrows | Arrow/Number/Rect | Move cursor |
| `Shift` + above | Arrow/Number/Rect | Move cursor faster (5x) |
| `Space` | Arrow/Rect | Set start/end point or corner |
| `1-9`, `0` | Number | Place number 1-10 |
| `c` | Arrow/Number/Rect | Cycle color |
| `i` | Arrow/Number/Rect | Increase size |
| `u` | Arrow/Number/Rect | Decrease size |
| `z` | Arrow/Number/Rect | Undo last annotation |
| `Enter` | Crop/Arrow/Number/Rect | Apply changes |
| `Esc` | Any | Cancel mode / Close window |

## Status Bar
Bottom of window shows current mode and available actions:
- Viewing: `[Viewing]  a:arrow  n:number  r:rect  c:crop  f:save  p:copy  u:upload  Esc:close`
- Crop: `[Crop]  hjkl:adjust  Shift:extend  Enter:apply  Esc:cancel`
- Arrow: `[Arrow:Red]  hjkl:move  Space:set  u/i:size  c:color  z:undo  Enter:apply  Esc:cancel`
- Number: `[Number:Red]  hjkl:move  1-0:place  u/i:size  c:color  z:undo  Enter:apply  Esc:cancel`
- Rectangle: `[Rect:Red]  hjkl:move  Space:set  u/i:size  c:color  z:undo  Enter:apply  Esc:cancel`

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

; Mode state
previewMode := "viewing"      ; "viewing", "crop", "arrow", "number", or "rectangle"

; Crop mode state
cropLeft := 0
cropTop := 0
cropRight := 0
cropBottom := 0
cropStep := 10                ; Pixels per keypress

; Arrow mode state
arrowCursorX := 0             ; Shared with number mode
arrowCursorY := 0
arrowStartX := 0
arrowStartY := 0
arrowSettingStart := 0        ; 0 = not setting, 1 = setting start point
arrowSize := 3                ; Saved to settings.ini
arrowColorIndex := 0          ; Saved to settings.ini
arrowColors := [0xFFFF0000, 0xFF0000FF, 0xFF00FF00, 0xFFFFFF00, 0xFF000000]
arrowColorNames := ["Red", "Blue", "Green", "Yellow", "Black"]
arrows := []                  ; Array of {x1, y1, x2, y2, color, size}
arrowMoveStep := 10           ; Pixels per keypress

; Number mode state
numbers := []                 ; Array of {x, y, num, color, size}
numberSize := 24              ; Saved to settings.ini
numberColorIndex := 0         ; Saved to settings.ini (shares arrowColors palette)

; Rectangle mode state
rectangles := []              ; Array of {x1, y1, x2, y2, color, size}
rectSize := 3                 ; Saved to settings.ini
rectColorIndex := 0           ; Saved to settings.ini (shares arrowColors palette)
rectSettingStart := 0         ; 0 = not setting, 1 = setting first corner
rectStartX := 0
rectStartY := 0
```

## Key Functions

### preview_window.ahk
- `ShowImageWindow(tempFile, nW, nH, resizeBy)` - Opens preview window
- `ImageViewPaint()` - WM_PAINT handler with double-buffering
- `ImageViewEraseBkgnd()` - Prevents background erase flicker

### crop.ahk
- `ApplyCrop()` - Applies crop using Gdip_CloneBitmapArea
- `DrawCropOverlay(pGraphics, offsetX, offsetY, scaledWidth, scaledHeight)` - Draws dark overlay
- `AdjustCropEdge(edge, delta)` - Adjusts crop with bounds validation
- `ResetCropState()` - Resets to viewing mode

### arrow.ahk
- `DrawArrow(pGraphics, x1, y1, x2, y2, color, size)` - Draws arrow with head
- `DrawArrowsOverlay(pGraphics, offsetX, offsetY, scaledWidth, scaledHeight)` - Draws all arrows + cursor
- `DrawArrowCursor(pGraphics, x, y)` - Draws crosshair cursor
- `ApplyArrows()` - Permanently applies arrows to bitmap
- `ResetArrowState()` - Resets to viewing mode
- `MoveArrowCursor(dx, dy)` - Moves cursor with bounds checking
- `MoveMouseToArrowCursor()` - Syncs mouse to arrow cursor position
- `SetArrowCursorFromMouse()` - Syncs arrow cursor to mouse position
- `SetArrowPoint()` - Sets start or end point
- `CycleArrowColor()` - Cycles color and saves to settings
- `ChangeArrowSize(delta)` - Changes size and saves to settings

### number.ahk
- `DrawNumberCircle(pGraphics, x, y, num, color, size)` - Draws filled circle with number
- `DrawNumbersOverlay(pGraphics, offsetX, offsetY, scaledWidth, scaledHeight)` - Draws all numbers + cursor
- `DrawNumberCursor(pGraphics, x, y, size)` - Draws crosshair cursor with size indication
- `ApplyNumbers()` - Permanently applies numbers to bitmap
- `ResetNumberState()` - Resets to viewing mode
- `AddNumber(num)` - Adds number at cursor position
- `CycleNumberColor()` - Cycles color and saves to settings
- `ChangeNumberSize(delta)` - Changes size and saves to settings

### rectangle.ahk
- `DrawRectangle(pGraphics, x1, y1, x2, y2, color, size)` - Draws rectangle outline
- `DrawRectanglesOverlay(pGraphics, offsetX, offsetY, scaledWidth, scaledHeight)` - Draws all rectangles + cursor
- `DrawRectangleCursor(pGraphics, x, y, size)` - Draws crosshair cursor with size indication
- `ApplyRectangles()` - Permanently applies rectangles to bitmap
- `ResetRectangleState()` - Resets to viewing mode
- `SetRectanglePoint()` - Sets first or second corner
- `CycleRectangleColor()` - Cycles color and saves to settings
- `ChangeRectangleSize(delta)` - Changes size and saves to settings

### status_bar.ahk
- `DrawStatusBar(pGraphics, width, height)` - Draws mode-specific status bar
- `DrawTopStatusBar(pGraphics, width)` - Draws image dimensions

### image.ahk
- `SaveGdipBitmap(pBitmap, filePath, quality)` - Saves GDI+ bitmap to JPG/PNG/BMP
- `UploadFile(fullFilePath, showTooltip)` - Uploads via FTP or ShareX

## Settings (settings.ini)
```ini
[PreviewWindow]
Width=800
Height=600
X=100
Y=100

[Arrow]
ColorIndex=0    ; 0=Red, 1=Blue, 2=Green, 3=Yellow, 4=Black
Size=3          ; Arrow pen width (1-20)

[Number]
ColorIndex=0    ; 0=Red, 1=Blue, 2=Green, 3=Yellow, 4=Black
Size=24         ; Circle diameter (12-60)

[Rectangle]
ColorIndex=0    ; 0=Red, 1=Blue, 2=Green, 3=Yellow, 4=Black
Size=3          ; Line thickness (1-20)
```

## Technical Notes

### GDI+ Lifecycle
- GDI+ is initialized once at script startup (`pGdipToken` in main file)
- Preview window reuses global GDI+ token
- Bitmap disposed on window close, GDI+ stays running

### Double Buffering
- `ImageViewPaint()` creates off-screen bitmap for flicker-free rendering
- `ImageViewEraseBkgnd()` returns 1 to prevent Windows background erase
- All drawing done to buffer, then BitBlt to screen

### Coordinate Systems
- **Image space**: Original bitmap coordinates (0 to previewImageWidth/Height)
- **Client space**: Window client area (affected by window size)
- **Screen space**: Desktop coordinates (for mouse positioning)
- Arrow/number cursor stored in image space, scaled for display
- `SetArrowCursorFromMouse()` and `MoveMouseToArrowCursor()` convert between spaces

### Overlay Scaling
Arrow and number sizes are scaled in overlay to match saved result:
```ahk
avgScale := (scaleX + scaleY) / 2
scaledSize := Max(1, arrow.size * avgScale)
```

### Adding New Annotation Modes
To add a new annotation mode (e.g., rectangles, text):
1. Create `lib/newmode.ahk` with functions:
   - `DrawNewModeOverlay(pGraphics, offsetX, offsetY, scaledWidth, scaledHeight)`
   - `ApplyNewMode()` - applies to bitmap
   - `ResetNewModeState()`
2. Add global variables in `FastKeyboardScreenshot.ahk`
3. Add `#Include %A_ScriptDir%\lib\newmode.ahk` (before `return`)
4. Update `ImageViewPaint()` to call overlay function
5. Add hotkey to enter mode in preview_window.ahk
6. Update movement/apply/cancel hotkeys to handle new mode
7. Update `lib/status_bar.ahk` with new mode status
8. Load/save settings if needed

## Future Improvements
- [ ] Add zoom in/out functionality
- [ ] Add undo for annotations
- [ ] Add text annotation mode
- [ ] Add rectangle/ellipse annotation mode
- [ ] Add copy to clipboard hotkey
- [ ] Add rotation support
- [ ] Allow changing color/size of existing annotations before applying
