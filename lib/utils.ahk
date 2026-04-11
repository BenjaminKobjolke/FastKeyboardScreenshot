; utils.ahk - Utility functions

; Function to find ShareX.exe on the C drive
FindShareX()
{
    ; Check common installation locations first (for efficiency)
    commonPaths := ["C:\Program Files\ShareX\ShareX.exe", "C:\Program Files (x86)\ShareX\ShareX.exe"]

    For index, path in commonPaths
    {
        If FileExist(path)
            Return path
    }

    ; If not found in common locations, search C drive
    Loop, Files, C:\*ShareX*.exe, R
    {
        If InStr(A_LoopFileName, "ShareX.exe")
            Return A_LoopFilePath
    }

    ; Not found
    Return ""
}

; Handler for resolution changes - debounces WM_DISPLAYCHANGE messages
; Multiple messages can fire in rapid succession during DPI/resolution changes.
; Uses a one-shot timer so only the last message triggers the actual reload.
HandleResolutionChange() {
	SetTimer, DoResolutionReload, -500
	return
}
