; gui.ahk - Mouse hint and preview rectangle GUI functions

MouseHintUpdate() {
    CoordMode, Mouse, Screen
    width := 50
	Gui, mousehint: -Caption +ToolWindow +AlwaysOnTop +Lastfound
    Gui, mousehint: Color, Yellow
    Gui, mousehint:Show, NoActivate w%width% h%width%, MouseSpot

    WinSet, Trans, 100, MouseSpot
    WinSet, Region, 0-0 W%width% H%width% E, MouseSpot

    offset := width / 2
    MouseGetPos, MX, MY
	WinMove, MouseSpot,,  MX - offset, MY - offset
}

PreviewUpdate(x, y, w, h) {
	Gui, preview: +E0x80000 -Caption +ToolWindow +AlwaysOnTop +Lastfound +HWNDgSecond
	WinSet, Transcolor, E0x80000 20
	Gui, preview:Show, x%x% y%y% w%w% h%h%
}

PreviewDestroy() {
	Gui, preview:Destroy
}

MouseHintDestroy() {
	Gui, mousehint:Destroy
}

DestroyGuis() {
	SetTimer, MouseHintTimer, Off
	PreviewDestroy()
	MouseHintDestroy()
}
