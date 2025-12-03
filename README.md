# Keyboard Screenshot

Create a screenshot by selecting a region with the keyboard and copy it to the clipboard

![Demo](image/demo.gif)

## How to use

- Press Alt Shift Q to start
- Move the mouse cursor with the arrow keys or hjkl to the start position
- Press space
- Move the mouse cursor to the end position
- Press space

Your screenshot will be copied to the clipboard

Hold down shift while moving the cursor to decrease the speed.

## Requirements & Install

- You have AHK/AHK_L --> use KeyboardScreenshot.ahk
- You don't have AHK/AHK_L --> use KeyboardScreenshot.exe from Releases
- run install.bat

## Updates

#### Screenshot the same region again

after you created at least one screenshot you can do the following

- Press Alt Shift Q to start
- activate any of the additional features, like resizing or saving to file
- press r

Your screenshot will be copied to the clipboard (using the same region as your last screenshot)

#### Screenshot with delay (useful for dropdown menus)

- Press Alt Shift Q to start
- Press D to enable delay
- Move to the start position and press space
- Move to the end position and press space
- The screenshot will be automatically taken after 5 seconds

This can also be combined with the "same region" feature:

- Press Alt Shift Q to start
- Press D to enable delay
- Press F1 to take a screenshot of the same region as last time
- The screenshot will be automatically taken after 5 seconds

#### Screenshot scale

Press 1,2,3 during screenshot process to scale the final output by 0.75, 0.5 or 0.25

#### Capture mouse cursor

Press m during the screenshot process to toggle mouse cursor capture on/off.
When enabled, the mouse cursor will be included in the screenshot.
The screenshot will also be copied to the clipboard as usual.

#### Show screenshot in window

Press w during the screenshot process to toggle window preview on/off.
When enabled, the screenshot will be displayed in a preview window after capture.
Press ESC or click the X button to close the preview window.
The screenshot will also be copied to the clipboard as usual.

#### Capture active window

Press a during the screenshot process to capture the active window immediately.
This skips the manual region selection and captures the entire active window.
All modifiers (resize, save to file, cursor capture, etc.) are respected.
The screenshot will also be copied to the clipboard as usual.

#### Show keyboard shortcuts

Press F1 during the screenshot process to display a help window with all available keyboard shortcuts.
Press F1 again or Esc to close the help window.

#### Save screenshot to file

Press f during the screenshot process to save the screenshot to a file.
By default, screenshots are saved in the subfolder "screenshots" relative to the script directory.
You can change this location in the settings.ini file by modifying the ScreenshotFolder value.
See settings_example.ini for an example configuration.
The screenshot will also be copied to the clipboard as usual.

#### Upload with sharex

Press u during the screenshot process to upload the screenshot to imgur using sharex.
It will also be copied to the clipboard as usual.
Note that you need to have sharex installed and configured for this to work.
Currently te path is fixed to `C:\Program Files\ShareX\ShareX.exe`

#### edit with sharex

Press e during the screenshot process to edit the screenshot with sharex.
It will also be copied to the clipboard as usual.
Note that you need to have sharex installed and configured for this to work.
Currently te path is fixed to `C:\Program Files\ShareX\ShareX.exe`

#### ocr

Press o during the screenshot process to run ocr on the screenshot.
The text will be copied to the clipboard and not the image.

## Licence

GPL 2.0

## Original code

I found the code that this tool is based on here:

[Autohotkey Forum](https://www.autohotkey.com/boards/viewtopic.php?style=19&t=96159)
