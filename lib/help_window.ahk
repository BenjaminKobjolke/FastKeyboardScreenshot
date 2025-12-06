; help_window.ahk - Help window with keyboard shortcuts (dark theme)

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

; Show help window with keyboard shortcuts (dark theme)
ShowHelpWindow:
	Gui, HelpWindow:Destroy
	Gui, HelpWindow:+AlwaysOnTop +ToolWindow
	Gui, HelpWindow:Color, 1e1e1e
	Gui, HelpWindow:Font, s11, Segoe UI

	; Column 1: NAVIGATION
	Gui, HelpWindow:Font, s11 cFFFFFF Bold, Segoe UI
	Gui, HelpWindow:Add, Text, x15 y15, NAVIGATION
	Gui, HelpWindow:Font, s10 cE0E0E0 Normal, Segoe UI
	Gui, HelpWindow:Add, Text, x15 y+10 c808080, hjkl / Arrows
	Gui, HelpWindow:Add, Text, x+10 yp cE0E0E0, Move cursor
	Gui, HelpWindow:Add, Text, x15 y+5 c808080, Shift + above
	Gui, HelpWindow:Add, Text, x+10 yp cE0E0E0, Move slower

	; Column 2: ACTIONS
	Gui, HelpWindow:Font, s11 cFFFFFF Bold, Segoe UI
	Gui, HelpWindow:Add, Text, x200 y15, ACTIONS
	Gui, HelpWindow:Font, s10 cE0E0E0 Normal, Segoe UI
	Gui, HelpWindow:Add, Text, x200 y+10 c808080, Space
	Gui, HelpWindow:Add, Text, x+10 yp cE0E0E0, Confirm position
	Gui, HelpWindow:Add, Text, x200 y+5 c808080, a
	Gui, HelpWindow:Add, Text, x+10 yp cE0E0E0, Active window
	Gui, HelpWindow:Add, Text, x200 y+5 c808080, r
	Gui, HelpWindow:Add, Text, x+10 yp cE0E0E0, Same region again
	Gui, HelpWindow:Add, Text, x200 y+5 c808080, Alt+Shift+Q
	Gui, HelpWindow:Add, Text, x+10 yp cE0E0E0, Cancel

	; Column 3: MODIFIERS
	Gui, HelpWindow:Font, s11 cFFFFFF Bold, Segoe UI
	Gui, HelpWindow:Add, Text, x380 y15, MODIFIERS
	Gui, HelpWindow:Font, s10 cE0E0E0 Normal, Segoe UI
	Gui, HelpWindow:Add, Text, x380 y+10 c808080, d
	Gui, HelpWindow:Add, Text, x+10 yp cE0E0E0, Delayed (5s)
	Gui, HelpWindow:Add, Text, x380 y+5 c808080, 1 / 2 / 3
	Gui, HelpWindow:Add, Text, x+10 yp cE0E0E0, Resize 75/50/25`%
	Gui, HelpWindow:Add, Text, x380 y+5 c808080, f
	Gui, HelpWindow:Add, Text, x+10 yp cE0E0E0, Save to file
	Gui, HelpWindow:Add, Text, x380 y+5 c808080, m
	Gui, HelpWindow:Add, Text, x+10 yp cE0E0E0, Capture cursor
	Gui, HelpWindow:Add, Text, x380 y+5 c808080, w
	Gui, HelpWindow:Add, Text, x+10 yp cE0E0E0, Show in window
	Gui, HelpWindow:Add, Text, x380 y+5 c808080, u
	Gui, HelpWindow:Add, Text, x+10 yp cE0E0E0, Upload ShareX
	Gui, HelpWindow:Add, Text, x380 y+5 c808080, e
	Gui, HelpWindow:Add, Text, x+10 yp cE0E0E0, Edit ShareX
	Gui, HelpWindow:Add, Text, x380 y+5 c808080, o
	Gui, HelpWindow:Add, Text, x+10 yp cE0E0E0, OCR screenshot

	; Footer
	Gui, HelpWindow:Font, s9 c606060 Normal, Segoe UI
	Gui, HelpWindow:Add, Text, x15 y+20, Press F1 or Esc to close
	Gui, HelpWindow:Show, , Keyboard Shortcuts
	helpWindowOpen := 1
return

HelpWindowGuiClose:
HelpWindowGuiEscape:
	Gui, HelpWindow:Destroy
	helpWindowOpen := 0
return
