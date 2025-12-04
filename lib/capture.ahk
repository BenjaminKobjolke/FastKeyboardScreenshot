; capture.ahk - Core screen capture functions
; Based on: https://autohotkey.com/board/topic/121619-screencaptureahk-broken-capturescreen-function-win-81-x64/

;-----------------------------------------------------------------------------------------------------------
; CaptureScreen(aRect, bCursor, sFileTo, nQuality)
;
; 1) If the optional parameter bCursor is True, captures the cursor too.
; 2) If the optional parameter sFileTo is 0, set the image to Clipboard.
;    If it is omitted or "", saves to screen.bmp in the script folder,
;    otherwise to sFileTo which can be BMP/JPG/PNG/GIF/TIF.
; 3) The optional parameter nQuality is applicable only when sFileTo is JPG.
; 4) If aRect is 0/1/2/3, captures the entire desktop/active window/active client area/active monitor.
; 5) aRect can be comma delimited sequence of coordinates.
;-----------------------------------------------------------------------------------------------------------

CaptureScreen(aRect = 0, bCursor = False, saveToFile = 0, uploadAfterCapture = 0, editWithShareX = 0, ocrScreenshot = 0, nQuality = "", resizeBy = 1, unusedFolder = "", unusedPath = "", showWindow = 0)
{
    ; Access global variables directly
    global screenshotFolder, sharexPath, useInBuildFTP, ftpHost, ftpUser, ftpPass, ftpPath, ftpUrl, actionTooltipDuration, lastUploadedUrl, pendingOcrText, rapidOcr

    ; Clear any tooltip before capturing
    ToolTip,
    Sleep, 100

    ; Declare temp file variable at function scope
    tempFileForPreview := ""

    ; Add Gdip startup
    If !pToken := Gdip_Startup()
    {
        MsgBox, 48, Error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
        ExitApp
    }

	If !aRect
	{
		SysGet, nL, 76  ; virtual screen left & top
		SysGet, nT, 77
		SysGet, nW, 78	; virtual screen width and height
		SysGet, nH, 79
	}
	Else If aRect = 1
		WinGetPos, nL, nT, nW, nH, A
	Else If aRect = 2
	{
		WinGet, hWnd, ID, A
		VarSetCapacity(rt, 16, 0)
		DllCall("GetClientRect" , "ptr", hWnd, "ptr", &rt)
		DllCall("ClientToScreen", "ptr", hWnd, "ptr", &rt)
		nL := NumGet(rt, 0, "int")
		nT := NumGet(rt, 4, "int")
		nW := NumGet(rt, 8)
		nH := NumGet(rt,12)
	}
	Else If aRect = 3
	{
		VarSetCapacity(mi, 40, 0)
		DllCall("GetCursorPos", "int64P", pt), NumPut(40,mi,0,"uint")
		DllCall("GetMonitorInfo", "ptr", DllCall("MonitorFromPoint", "int64", pt, "Uint", 2, "ptr"), "ptr", &mi)
		nL := NumGet(mi, 4, "int")
		nT := NumGet(mi, 8, "int")
		nW := NumGet(mi,12, "int") - nL
		nH := NumGet(mi,16, "int") - nT
	}
	Else
	{
		StringSplit, rt, aRect, `,, %A_Space%%A_Tab%
		nL := rt1	; convert the Left,top, right, bottom into left, top, width, height
		nT := rt2
		nW := rt3 - rt1
		nH := rt4 - rt2
		znW := rt5
		znH := rt6
	}

	mDC := DllCall("CreateCompatibleDC", "ptr", 0, "ptr")
	hBM := CreateDIBSectionVariant(mDC, nW, nH)
	oBM := DllCall("SelectObject", "ptr", mDC, "ptr", hBM, "ptr")
	hDC := DllCall("GetDC", "ptr", 0, "ptr")
	DllCall("BitBlt", "ptr", mDC, "int", 0, "int", 0, "int", nW, "int", nH, "ptr", hDC, "int", nL, "int", nT, "Uint", 0x40CC0020)
	DllCall("ReleaseDC", "ptr", 0, "ptr", hDC)
	If bCursor
		CaptureCursor(mDC, nL, nT)
	DllCall("SelectObject", "ptr", mDC, "ptr", oBM)
	DllCall("DeleteDC", "ptr", mDC)
	If znW && znH
		hBM := Zoomer(hBM, nW, nH, znW, znH)


    ; Resize the screenshot
	if(resizeBy > 1) {
		pBitmap := Gdip_CreateBitmapFromHBITMAP(hBM)
		pBitmapResized := Gdip_ResizeBitmap(pBitmap, nW // resizeBy, nH // resizeBy)
		hBMResized := Gdip_CreateHBITMAPFromBitmap(pBitmapResized)

		; Replace the original hBM with the resized one
		DllCall("DeleteObject", "ptr", hBM)
		hBM := hBMResized

		; Free resources
		Gdip_DisposeImage(pBitmap)
		Gdip_DisposeImage(pBitmapResized)
	}

	; Create a copy of the bitmap for preview window before SetClipboardData deletes it
	if(showWindow = 1) {
		; Use GDI+ to create a copy of the HBITMAP
		pBitmapForPreview := Gdip_CreateBitmapFromHBITMAP(hBM)
		hBMCopy := Gdip_CreateHBITMAPFromBitmap(pBitmapForPreview)
		Gdip_DisposeImage(pBitmapForPreview)

		; Create unique temp filename with timestamp
		FormatTime, timestamp, , yyyyMMdd_HHmmss
		tempFileForPreview := A_Temp . "\FastKeyboardScreenshot_" . timestamp . ".bmp"

		; Save to temp file using the existing SaveHBITMAPToFile function
		SaveHBITMAPToFile(hBMCopy, tempFileForPreview)

		; Delete the copy bitmap handle
		DllCall("DeleteObject", "ptr", hBMCopy)
	}

	SetClipboardData(hBM)

	if(saveToFile = 1 || uploadAfterCapture = 1 || editWithShareX = 1 || ocrScreenshot = 1) {
		Sleep, 200
		FormatTime, currentDateTime, , yyyy_MM_dd_HH_mm_ss
		baseFilename := currentDateTime

		if(ocrScreenshot = 1) {
			; OCR mode: save as TXT
			filename := baseFilename . ".txt"
			fullFilename := screenshotFolder . "\" . filename

			; Save temp JPG for OCR processing
			tempJpgFilename := baseFilename . "_temp.jpg"
			Convert(0, tempJpgFilename, "", screenshotFolder)
			tempJpgPath := screenshotFolder . "\" . tempJpgFilename

			ToolTip, Running OCR...
			ocrText := rapidOcr.ocr(tempJpgPath)
			ToolTip

			; Delete temp JPG
			FileDelete, %tempJpgPath%

			; Save text to .txt file only if saving or uploading
			if(saveToFile = 1 || uploadAfterCapture = 1) {
				FileAppend, %ocrText%, %fullFilename%
			}
			clipboard := ocrText
		} else {
			; Normal mode: save as JPG
			filename := baseFilename . ".jpg"
			Convert(0, filename, "", screenshotFolder)
		}
	}

    if(uploadAfterCapture = 1) {
		fullFilename := screenshotFolder . "\" . filename

		if(useInBuildFTP = 1) {
			; Use built-in FTP upload
			ToolTip, Uploading...

			; Remote filename is path + filename
			remoteFile := ftpPath . filename

			; Upload via FTP
			if(FTPUpload(ftpHost, ftpUser, ftpPass, fullFilename, remoteFile)) {
				; Copy URL to clipboard
				finalUrl := ftpUrl . ftpPath . filename
				clipboard := finalUrl
				lastUploadedUrl := finalUrl

				; Show tooltip only if not showing preview window
				if(showWindow = 0) {
					ToolTip, Upload complete!`n%finalUrl%`n`nPress o to open in browser`nPress Esc to dismiss

					; Enable temporary hotkeys
					Hotkey, o, OpenLastUrl, On
					Hotkey, Escape, CancelActionTooltip, On

					; Set timer to disable hotkeys and clear tooltip
					SetTimer, ClearActionTooltip, -%actionTooltipDuration%
				} else {
					ToolTip
				}
			} else {
				ToolTip
				MsgBox, 16, Error, FTP upload failed.`n`nHost: %ftpHost%`nFile: %fullFilename%`nRemote: %remoteFile%
			}

			; Delete file if not saving
			if(saveToFile = 0) {
				FileDelete, %fullFilename%
			}
		} else {
			; Use ShareX
			if (sharexPath = "") {
				MsgBox, 16, Error, ShareX not found. Cannot upload screenshot.
			} else {
				ToolTip, Uploading screenshot with ShareX
				Sleep, 100
				RunWait, %sharexPath% "%fullFilename%"
				if(saveToFile = 0) {
					Sleep, 1000
					FileDelete, %fullFilename%
				}
			}
		}
	}

	if(editWithShareX = 1) {
		Sleep, 200
		fullFilename := screenshotFolder . "\" . filename

		; Check if ShareX was found
		if (sharexPath = "") {
			MsgBox, 16, Error, ShareX not found. Cannot edit screenshot.
		} else {
			RunWait, %sharexPath% -imageEditor "%fullFilename%"
			if(saveToFile = 0) {
				Sleep, 1000
				FileDelete, %fullFilename%
			}
		}
	}

	; OCR-only mode (no upload) - show tooltip for local file or on-demand creation
	if(ocrScreenshot = 1 && uploadAfterCapture = 0) {
		; Skip tooltip if window preview is shown
		if(showWindow = 0) {
			if(saveToFile = 1) {
				; File was saved, use it for 'o' hotkey
				lastUploadedUrl := fullFilename
				pendingOcrText := ""
			} else {
				; No file saved - store text for on-demand creation
				lastUploadedUrl := ""
				pendingOcrText := ocrText
			}

			ToolTip, OCR complete!`nText copied to clipboard`n`nPress o to open in editor`nPress Esc to dismiss
			Hotkey, o, OpenLastUrl, On
			Hotkey, Escape, CancelActionTooltip, On
			SetTimer, ClearActionTooltip, -%actionTooltipDuration%
		}
	}

	DllCall("DeleteObject", "ptr", hBM)
    ; Add Gdip shutdown at the end of the function
    Gdip_Shutdown(pToken)

	; Show window with content if requested (after Gdip_Shutdown)
	if(showWindow = 1) {
		if(ocrScreenshot = 1) {
			; Show text preview window for OCR
			ShowTextWindow(ocrText)
		} else if(FileExist(tempFileForPreview)) {
			ShowImageWindow(tempFileForPreview, nW, nH, resizeBy)
		} else {
			MsgBox, 16, Error, Failed to create preview.
		}
	}
}


Gdip_ResizeBitmap(pBitmap, newWidth, newHeight)
{
    pBitmapResized := Gdip_CreateBitmap(newWidth, newHeight)
    G := Gdip_GraphicsFromImage(pBitmapResized)
    Gdip_SetInterpolationMode(G, 7) ; High quality bicubic interpolation
    Gdip_DrawImage(G, pBitmap, 0, 0, newWidth, newHeight, 0, 0, Gdip_GetImageWidth(pBitmap), Gdip_GetImageHeight(pBitmap))
    Gdip_DeleteGraphics(G)
    return pBitmapResized
}


CaptureCursor(hDC, nL, nT)
{
	VarSetCapacity(mi, 32, 0), Numput(16+A_PtrSize, mi, 0, "uint")
	DllCall("GetCursorInfo", "ptr", &mi)
	bShow   := NumGet(mi, 4, "uint")
	hCursor := NumGet(mi, 8)
	xCursor := NumGet(mi,8+A_PtrSize, "int")
	yCursor := NumGet(mi,12+A_PtrSize, "int")

	DllCall("GetIconInfo", "ptr", hCursor, "ptr", &mi)
	xHotspot := NumGet(mi, 4, "uint")
	yHotspot := NumGet(mi, 8, "uint")
	hBMMask  := NumGet(mi,8+A_PtrSize)
	hBMColor := NumGet(mi,16+A_PtrSize)

	If bShow
		DllCall("DrawIcon", "ptr", hDC, "int", xCursor - xHotspot - nL, "int", yCursor - yHotspot - nT, "ptr", hCursor)
	If hBMMask
		DllCall("DeleteObject", "ptr", hBMMask)
	If hBMColor
		DllCall("DeleteObject", "ptr", hBMColor)
}

Zoomer(hBM, nW, nH, znW, znH)
{
	mDC1 := DllCall("CreateCompatibleDC", "ptr", 0, "ptr")
	mDC2 := DllCall("CreateCompatibleDC", "ptr", 0, "ptr")
	zhBM := CreateDIBSectionVariant(mDC2, znW, znH)
	oBM1 := DllCall("SelectObject", "ptr", mDC1, "ptr",  hBM, "ptr")
	oBM2 := DllCall("SelectObject", "ptr", mDC2, "ptr", zhBM, "ptr")
	DllCall("SetStretchBltMode", "ptr", mDC2, "int", 4)
	DllCall("StretchBlt", "ptr", mDC2, "int", 0, "int", 0, "int", znW, "int", znH, "ptr", mDC1, "int", 0, "int", 0, "int", nW, "int", nH, "Uint", 0x00CC0020)
	DllCall("SelectObject", "ptr", mDC1, "ptr", oBM1)
	DllCall("SelectObject", "ptr", mDC2, "ptr", oBM2)
	DllCall("DeleteDC", "ptr", mDC1)
	DllCall("DeleteDC", "ptr", mDC2)
	DllCall("DeleteObject", "ptr", hBM)
	Return zhBM
}

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

CreateDIBSectionVariant(hDC, nW, nH, bpp = 32, ByRef pBits = "")
{
	VarSetCapacity(bi, 40, 0)
	NumPut(40, bi, "uint")
	NumPut(nW, bi, 4, "int")
	NumPut(nH, bi, 8, "int")
	NumPut(bpp, NumPut(1, bi, 12, "UShort"), 0, "Ushort")
	Return DllCall("gdi32\CreateDIBSection", "ptr", hDC, "ptr", &bi, "Uint", 0, "UintP", pBits, "ptr", 0, "Uint", 0, "ptr")
}

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
