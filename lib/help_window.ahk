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

; Show help window with keyboard shortcuts
ShowHelpWindow:
	Gui, HelpWindow:Destroy
	Gui, HelpWindow:+AlwaysOnTop +ToolWindow
	Gui, HelpWindow:Font, s10, Consolas
	Gui, HelpWindow:Add, Text, , === NAVIGATION ===
	Gui, HelpWindow:Add, Text, , Arrow keys / hjkl    Move cursor
	Gui, HelpWindow:Add, Text, , Shift + above        Move slower
	Gui, HelpWindow:Add, Text, ,
	Gui, HelpWindow:Add, Text, , === ACTIONS ===
	Gui, HelpWindow:Add, Text, , Space                Confirm position
	Gui, HelpWindow:Add, Text, , a                    Capture active window
	Gui, HelpWindow:Add, Text, , r                    Same region again
	Gui, HelpWindow:Add, Text, , Alt+Shift+Q          Cancel
	Gui, HelpWindow:Add, Text, ,
	Gui, HelpWindow:Add, Text, , === MODIFIERS ===
	Gui, HelpWindow:Add, Text, , d                    Delayed screenshot (5s)
	Gui, HelpWindow:Add, Text, , 1 / 2 / 3            Resize 75`% / 50`% / 25`%
	Gui, HelpWindow:Add, Text, , f                    Save to file
	Gui, HelpWindow:Add, Text, , m                    Capture mouse cursor
	Gui, HelpWindow:Add, Text, , w                    Show in window
	Gui, HelpWindow:Add, Text, , u                    Upload with ShareX
	Gui, HelpWindow:Add, Text, , e                    Edit with ShareX
	Gui, HelpWindow:Add, Text, , o                    OCR screenshot
	Gui, HelpWindow:Add, Text, ,
	Gui, HelpWindow:Add, Text, , Press F1 or Esc to close
	Gui, HelpWindow:Show, , Keyboard Shortcuts
	helpWindowOpen := 1
return

HelpWindowGuiClose:
HelpWindowGuiEscape:
	Gui, HelpWindow:Destroy
	helpWindowOpen := 0
return
