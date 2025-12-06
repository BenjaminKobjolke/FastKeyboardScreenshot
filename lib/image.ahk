; image.ahk - Image manipulation and saving functions

; Save a GDI+ bitmap directly to file (JPG/PNG/BMP supported)
; Uses 64-bit aware struct sizes (works on both 32/64-bit systems)
SaveGdipBitmap(pBitmap, filePath, quality = 75) {
    SplitPath, filePath, , , sExtTo

    ; Get encoders with proper 64-bit struct sizes
    DllCall("gdiplus\GdipGetImageEncodersSize", "UintP", nCount, "UintP", nSize)
    VarSetCapacity(ci, nSize, 0)
    DllCall("gdiplus\GdipGetImageEncoders", "Uint", nCount, "Uint", nSize, "ptr", &ci)

    ; Find matching encoder (64-bit aware struct size)
    struct_size := 48 + 7*A_PtrSize
    offset := 32 + 3*A_PtrSize
    pCodec := &ci - struct_size

    Loop, % nCount
    {
        pCodec += struct_size
        codecExt := StrGet(NumGet(offset + pCodec), "utf-16")
        if InStr(codecExt, "." . sExtTo)
            break
    }

    if (pCodec >= &ci + nSize)
        return -3  ; No encoder found

    ; Set JPEG quality if applicable
    pParam := 0
    if (InStr(".JPG.JPEG.JPE.JFIF", "." . sExtTo) && quality != "") {
        DllCall("gdiplus\GdipGetEncoderParameterListSize", "ptr", pBitmap, "ptr", pCodec, "UintP", nParamSize)
        VarSetCapacity(pi, nParamSize, 0)
        param_struct := 24 + A_PtrSize
        DllCall("gdiplus\GdipGetEncoderParameterList", "ptr", pBitmap, "ptr", pCodec, "Uint", nParamSize, "ptr", &pi)
        Loop, % NumGet(pi, 0, "uint")
        {
            if (NumGet(pi, param_struct*(A_Index-1)+16+A_PtrSize, "uint") = 1
                && NumGet(pi, param_struct*(A_Index-1)+20+A_PtrSize, "uint") = 6) {
                pParam := &pi + param_struct*(A_Index-1)
                NumPut(quality, NumGet(NumPut(4, NumPut(1, pParam+0, "uint")+16+A_PtrSize, "uint")), "uint")
                break
            }
        }
    }

    ; Save the image
    result := DllCall("gdiplus\GdipSaveImageToFile", "ptr", pBitmap, "wstr", filePath, "ptr", pCodec, "ptr", pParam)
    return result
}

; Resize a GDI+ bitmap
Gdip_ResizeBitmap(pBitmap, newWidth, newHeight)
{
    pBitmapResized := Gdip_CreateBitmap(newWidth, newHeight)
    G := Gdip_GraphicsFromImage(pBitmapResized)
    Gdip_SetInterpolationMode(G, 7) ; High quality bicubic interpolation
    Gdip_DrawImage(G, pBitmap, 0, 0, newWidth, newHeight, 0, 0, Gdip_GetImageWidth(pBitmap), Gdip_GetImageHeight(pBitmap))
    Gdip_DeleteGraphics(G)
    return pBitmapResized
}

; Convert/save image from clipboard or file to various formats
Convert(sFileFr = "", sFileTo = "", nQuality = "", screenshotFolder = "")
{
	If (sFileTo = "")
		sFileTo := A_ScriptDir . "\screen.bmp"

	SplitPath, sFileTo, , sDirTo, sExtTo, sNameTo
	sDirTo := screenshotFolder

	if (!FileExist(sDirTo))
	{
	   FileCreateDir, %sDirTo%
	}

	If Not hGdiPlus := DllCall("LoadLibrary", "str", "gdiplus.dll", "ptr")
		Return	sFileFr+0 ? SaveHBITMAPToFile(sFileFr, sDirTo (sDirTo = "" ? "" : "\") sNameTo ".bmp") : ""
	VarSetCapacity(si, 16, 0), si := Chr(1)
	DllCall("gdiplus\GdiplusStartup", "UintP", pToken, "ptr", &si, "ptr", 0)

	If !sFileFr
	{
		DllCall("OpenClipboard", "ptr", 0)
		If	(DllCall("IsClipboardFormatAvailable", "Uint", 2) && (hBM:=DllCall("GetClipboardData", "Uint", 2, "ptr")))
			DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "ptr", hBM, "ptr", 0, "ptr*", pImage)
		DllCall("CloseClipboard")
	}
	Else If	sFileFr Is Integer
		DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "ptr", sFileFr, "ptr", 0, "ptr*", pImage)
	Else	DllCall("gdiplus\GdipLoadImageFromFile", "wstr", sFileFr, "ptr*", pImage)
	DllCall("gdiplus\GdipGetImageEncodersSize", "UintP", nCount, "UintP", nSize)
	VarSetCapacity(ci,nSize,0)
	DllCall("gdiplus\GdipGetImageEncoders", "Uint", nCount, "Uint", nSize, "ptr", &ci)
	struct_size := 48+7*A_PtrSize, offset := 32 + 3*A_PtrSize, pCodec := &ci - struct_size
	Loop, %	nCount
		If InStr(StrGet(Numget(offset + (pCodec+=struct_size)), "utf-16") , "." . sExtTo)
			break

	If (InStr(".JPG.JPEG.JPE.JFIF", "." . sExtTo) && nQuality<>"" && pImage && pCodec < &ci + nSize)
	{
		DllCall("gdiplus\GdipGetEncoderParameterListSize", "ptr", pImage, "ptr", pCodec, "UintP", nCount)
		VarSetCapacity(pi,nCount,0), struct_size := 24 + A_PtrSize
		DllCall("gdiplus\GdipGetEncoderParameterList", "ptr", pImage, "ptr", pCodec, "Uint", nCount, "ptr", &pi)
		Loop, %	NumGet(pi,0,"uint")
			If (NumGet(pi,struct_size*(A_Index-1)+16+A_PtrSize,"uint")=1 && NumGet(pi,struct_size*(A_Index-1)+20+A_PtrSize,"uint")=6)
			{
				pParam := &pi+struct_size*(A_Index-1)
				NumPut(nQuality,NumGet(NumPut(4,NumPut(1,pParam+0,"uint")+16+A_PtrSize,"uint")),"uint")
				Break
			}
	}

	filePath = %sDirTo%\%sFileTo%

	If pImage
		pCodec < &ci + nSize	? DllCall("gdiplus\GdipSaveImageToFile", "ptr", pImage, "wstr", filePath, "ptr", pCodec, "ptr", pParam) : DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "ptr", pImage, "ptr*", hBitmap, "Uint", 0) . SetClipboardData(hBitmap), DllCall("gdiplus\GdipDisposeImage", "ptr", pImage)

	DllCall("gdiplus\GdiplusShutdown" , "Uint", pToken)
	DllCall("FreeLibrary", "ptr", hGdiPlus)
}

; Create a DIB section
CreateDIBSectionVariant(hDC, nW, nH, bpp = 32, ByRef pBits = "")
{
	VarSetCapacity(bi, 40, 0)
	NumPut(40, bi, "uint")
	NumPut(nW, bi, 4, "int")
	NumPut(nH, bi, 8, "int")
	NumPut(bpp, NumPut(1, bi, 12, "UShort"), 0, "Ushort")
	Return DllCall("gdi32\CreateDIBSection", "ptr", hDC, "ptr", &bi, "Uint", 0, "UintP", pBits, "ptr", 0, "Uint", 0, "ptr")
}

; Save HBITMAP to BMP file
SaveHBITMAPToFile(hBitmap, sFile)
{
	VarSetCapacity(oi,104,0)
	DllCall("GetObject", "ptr", hBitmap, "int", 64+5*A_PtrSize, "ptr", &oi)
	fObj := FileOpen(sFile, "w")
	fObj.WriteShort(0x4D42)
	fObj.WriteInt(54+NumGet(oi,36+2*A_PtrSize,"uint"))
	fObj.WriteInt64(54<<32)
	fObj.RawWrite(&oi + 16 + 2*A_PtrSize, 40)
	fObj.RawWrite(NumGet(oi, 16+A_PtrSize), NumGet(oi,36+2*A_PtrSize,"uint"))
	fObj.Close()
}

; Put bitmap on clipboard
SetClipboardData(hBitmap)
{
	VarSetCapacity(oi,104,0)
	DllCall("GetObject", "ptr", hBitmap, "int", 64+5*A_PtrSize, "ptr", &oi)
	sz := NumGet(oi,36+2*A_PtrSize,"uint")
	hDIB :=	DllCall("GlobalAlloc", "Uint", 2, "Uptr", 40+sz, "ptr")
	pDIB := DllCall("GlobalLock", "ptr", hDIB, "ptr")
	DllCall("RtlMoveMemory", "ptr", pDIB, "ptr", &oi + 16 + 2*A_PtrSize, "Uptr", 40)
	DllCall("RtlMoveMemory", "ptr", pDIB+40, "ptr", NumGet(oi, 16+A_PtrSize), "Uptr", sz)
	DllCall("GlobalUnlock", "ptr", hDIB)
	DllCall("DeleteObject", "ptr", hBitmap)
	DllCall("OpenClipboard", "ptr", 0)
	DllCall("EmptyClipboard")
	DllCall("SetClipboardData", "Uint", 8, "ptr", hDIB)
	DllCall("CloseClipboard")
}

; Upload a file via FTP or ShareX
; Returns: 1 on success, 0 on failure
UploadFile(fullFilePath, showTooltip := 1) {
    global useInBuildFTP, ftpHost, ftpUser, ftpPass, ftpPath, ftpUrl, sharexPath, lastUploadedUrl

    ; Extract filename from path
    SplitPath, fullFilePath, filename

    if (useInBuildFTP = 1) {
        if (showTooltip)
            ToolTip, Uploading...

        remoteFile := ftpPath . filename
        if (FTPUpload(ftpHost, ftpUser, ftpPass, fullFilePath, remoteFile)) {
            finalUrl := ftpUrl . ftpPath . filename
            clipboard := finalUrl
            lastUploadedUrl := finalUrl
            if (showTooltip) {
                ToolTip, Upload complete!`n%finalUrl%
                Sleep, 2000
                ToolTip
            }
            return 1
        } else {
            if (showTooltip)
                ToolTip
            MsgBox, 16, Error, FTP upload failed.`n`nHost: %ftpHost%`nFile: %fullFilePath%`nRemote: %remoteFile%
            return 0
        }
    } else {
        if (sharexPath = "") {
            MsgBox, 16, Error, ShareX not found. Cannot upload.
            return 0
        }
        if (showTooltip)
            ToolTip, Uploading with ShareX...
        RunWait, %sharexPath% "%fullFilePath%"
        if (showTooltip)
            ToolTip
        return 1
    }
}
