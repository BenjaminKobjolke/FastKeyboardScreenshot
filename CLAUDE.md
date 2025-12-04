# Claude Development Notes

## AutoHotkey Auto-Execute Section Rules

**IMPORTANT:** In AHK, the auto-execute section runs from the top of the script until it hits a `return`, `Exit`, hotkey, or hotstring.

### File Structure

```
FastKeyboardScreenshot.ahk
├── #Include config.ahk
├── #Include lib/utils.ahk
├── #Include lib/gui.ahk
├── #Include lib/capture.ahk        ← FUNCTIONS ONLY (before return)
├── #Include lib/FTP_Upload.ahk     ← FUNCTIONS ONLY (before return)
├── ... auto-execute code ...
├── return                          ← END OF AUTO-EXECUTE
├── #Include lib/help_window.ahk    ← Can have labels/hotkeys (after return)
├── #Include lib/screenshot.ahk     ← Can have labels/hotkeys (after return)
├── #Include lib/hotkeys.ahk        ← Can have labels/hotkeys (after return)
└── Labels (Reload:, Exit:, etc.)
```

### Rules

1. **Files included BEFORE `return`:** Functions only, NO labels or hotkeys
2. **Files included AFTER `return`:** Can contain labels and hotkeys
3. **Labels in main file:** Must be placed AFTER the `return` statement

### Common Mistake

Adding labels to `lib/capture.ahk` or other files included before `return` will break the script - hotkeys stop working, arrow keys don't respond, etc.

### Solution

Always add new labels to:
- `FastKeyboardScreenshot.ahk` (after line 84 `return`)
- Or to files included after the `return` (help_window.ahk, screenshot.ahk, hotkeys.ahk)
