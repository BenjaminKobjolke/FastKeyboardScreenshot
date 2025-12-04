; ===============================================================================================================================
; Upload Files to FTP Server (Server, Username, Password, LocalFile, RemoteFile)
; ===============================================================================================================================

FTPUpload(srv, usr, pwd, lfile, rfile)
{
    static a := "AHK-FTP-UL"

    ; Load wininet.dll
    if !(m := DllCall("LoadLibrary", "str", "wininet.dll", "ptr"))
        return 0

    ; Open internet connection
    if !(h := DllCall("wininet\InternetOpen", "ptr", &a, "uint", 1, "ptr", 0, "ptr", 0, "uint", 0, "ptr")) {
        DllCall("FreeLibrary", "ptr", m)
        return 0
    }

    ; Connect to FTP server
    f := DllCall("wininet\InternetConnect", "ptr", h, "ptr", &srv, "ushort", 21, "ptr", &usr, "ptr", &pwd, "uint", 1, "uint", 0x08000000, "uptr", 0, "ptr")
    if (!f) {
        DllCall("wininet\InternetCloseHandle", "ptr", h)
        DllCall("FreeLibrary", "ptr", m)
        return 0
    }

    ; Upload file
    result := DllCall("wininet\FtpPutFile", "ptr", f, "ptr", &lfile, "ptr", &rfile, "uint", 0, "uptr", 0)

    ; Cleanup
    DllCall("wininet\InternetCloseHandle", "ptr", f)
    DllCall("wininet\InternetCloseHandle", "ptr", h)
    DllCall("FreeLibrary", "ptr", m)

    return result ? 1 : 0
}

; ===============================================================================================================================
