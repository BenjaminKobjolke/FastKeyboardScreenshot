/*
    SingleInstance.ahk
    Library for managing single instance scripts using COM objects
*/

/*
    ObjRegisterActive(Object, CLSID, Flags:=0)
    
        Registers an object as the active object for a given class ID.
        Requires AutoHotkey v1.1.17+; may crash earlier versions.
    
    Object:
            Any AutoHotkey object.
    CLSID:
            A GUID or ProgID of your own making.
            Pass an empty string to revoke (unregister) the object.
    Flags:
            One of the following values:
              0 (ACTIVEOBJECT_STRONG)
              1 (ACTIVEOBJECT_WEAK)
            Defaults to 0.
    
    Related:
        http://goo.gl/KJS4Dp - RegisterActiveObject
        http://goo.gl/no6XAS - ProgID
        http://goo.gl/obfmDc - CreateGUID()
*/
ObjRegisterActive(Object, CLSID, Flags:=0) {
    static cookieJar := {}
    if (!CLSID) {
        if (cookie := cookieJar.Remove(Object)) != ""
            DllCall("oleaut32\RevokeActiveObject", "uint", cookie, "ptr", 0)
        return
    }
    if cookieJar[Object]
        throw Exception("Object is already registered", -1)
    VarSetCapacity(_clsid, 16, 0)
    if (hr := DllCall("ole32\CLSIDFromString", "wstr", CLSID, "ptr", &_clsid)) < 0
        throw Exception("Invalid CLSID", -1, CLSID)
    hr := DllCall("oleaut32\RegisterActiveObject"
        , "ptr", &Object, "ptr", &_clsid, "uint", Flags, "uint*", cookie
        , "uint")
    if hr < 0
        throw Exception(format("Error 0x{:x}", hr), -1)
    cookieJar[Object] := cookie
}

CheckSingleInstance(GUID, ObjectClass) {
    ; Try to close existing instance via COM
    oldFound := false
    try {
        scriptObj := ComObjActive(GUID)
        if (scriptObj.IsActive() = 1) {
            oldFound := true
            try scriptObj.Quit()
        }
    } catch {
    }
    scriptObj := ""  ; Release COM reference

    if (oldFound) {
        ; Wait up to 2s for old instance to exit, checking by hidden window
        DetectHiddenWindows, On
        attempts := 0
        otherExists := false
        while (attempts < 20) {
            otherExists := false
            WinGet, idList, List, %A_ScriptFullPath% ahk_class AutoHotkey
            Loop, %idList% {
                thisId := idList%A_Index%
                if (thisId = A_ScriptHwnd)
                    continue
                otherExists := true
                break
            }
            if (!otherExists)
                break
            Sleep, 100
            attempts++
        }
        ; Force-kill if still alive
        if (otherExists) {
            WinGet, idList, List, %A_ScriptFullPath% ahk_class AutoHotkey
            Loop, %idList% {
                thisId := idList%A_Index%
                if (thisId = A_ScriptHwnd)
                    continue
                WinGet, oldPid, PID, ahk_id %thisId%
                Process, Close, %oldPid%
                Process, WaitClose, %oldPid%, 2
            }
        }
        DetectHiddenWindows, Off
    }

    ; Register ourselves as the active instance
    global ActiveObject := new %ObjectClass%()
    ObjRegisterActive(ActiveObject, GUID)
}
