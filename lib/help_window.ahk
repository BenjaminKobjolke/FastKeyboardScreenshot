; help_window.ahk - Help window with keyboard shortcuts

; Global variable to track if help window is open
helpWindowOpen := 0

; Toggle help window - show if closed, close if open
ToggleHelpWindow:
	if(helpWindowOpen = 1) {
		Gui, HelpWindow:Destroy
		helpWindowOpen := 0
	} else {
		GoSub, ShowHelpWindow
	}
return

; Show help window with keyboard shortcuts (3-column layout)
ShowHelpWindow:
	Gui, HelpWindow:Destroy
	Gui, HelpWindow:+AlwaysOnTop +ToolWindow
	Gui, HelpWindow:Font, s10, Consolas

	; Column 1: NAVIGATION
	Gui, HelpWindow:Add, Text, x10 y10, === NAVIGATION ===
	Gui, HelpWindow:Add, Text, x10 y+5, hjkl / Arrows   Move cursor
	Gui, HelpWindow:Add, Text, x10 y+5, Shift + above   Move slower

	; Column 2: ACTIONS
	Gui, HelpWindow:Add, Text, x220 y10, === ACTIONS ===
	Gui, HelpWindow:Add, Text, x220 y+5, Space          Confirm position
	Gui, HelpWindow:Add, Text, x220 y+5, a              Active window
	Gui, HelpWindow:Add, Text, x220 y+5, r              Same region again
	Gui, HelpWindow:Add, Text, x220 y+5, Alt+Shift+Q    Cancel

	; Column 3: MODIFIERS
	Gui, HelpWindow:Add, Text, x430 y10, === MODIFIERS ===
	Gui, HelpWindow:Add, Text, x430 y+5, d              Delayed (5s)
	Gui, HelpWindow:Add, Text, x430 y+5, 1 / 2 / 3      Resize 75/50/25`%
	Gui, HelpWindow:Add, Text, x430 y+5, f              Save to file
	Gui, HelpWindow:Add, Text, x430 y+5, m              Capture cursor
	Gui, HelpWindow:Add, Text, x430 y+5, w              Show in window
	Gui, HelpWindow:Add, Text, x430 y+5, u              Upload ShareX
	Gui, HelpWindow:Add, Text, x430 y+5, e              Edit ShareX
	Gui, HelpWindow:Add, Text, x430 y+5, o              OCR screenshot

	; Footer
	Gui, HelpWindow:Add, Text, x10 y+20, Press F1 or Esc to close
	Gui, HelpWindow:Show, , Keyboard Shortcuts
	helpWindowOpen := 1
return

HelpWindowGuiClose:
HelpWindowGuiEscape:
	Gui, HelpWindow:Destroy
	helpWindowOpen := 0
return
