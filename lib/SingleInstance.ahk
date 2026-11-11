/*
    SingleInstance.ahk
    Library for managing single instance scripts
*/

; Close every other running instance of this script.
; Uses a posted WM_CLOSE, not COM: a COM call into a hung instance blocks forever,
; which made every restart hang too.
; shortcut: matches by script path, so the compiled exe and the .ahk source do not close each other; match on a shared window title if both must be exclusive.
CheckSingleInstance() {
    DetectHiddenWindows, On
    WinGet, idList, List, %A_ScriptFullPath% ahk_class AutoHotkey
    Loop, %idList% {
        thisId := idList%A_Index%
        if (thisId = A_ScriptHwnd)
            continue
        WinGet, oldPid, PID, ahk_id %thisId%
        PostMessage, 0x10, , , , ahk_id %thisId%  ; WM_CLOSE, lets OnExit cleanup run
        Process, WaitClose, %oldPid%, 2
        if (ErrorLevel) {  ; still alive (hung) - force-kill it and the children its OnExit would have closed (RapidOCR)
            for child in ComObjGet("winmgmts:").ExecQuery("Select ProcessId from Win32_Process where ParentProcessId=" . oldPid)
                Process, Close, % child.ProcessId
            Process, Close, %oldPid%
        }
    }
    DetectHiddenWindows, Off
}
