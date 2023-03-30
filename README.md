# Keyboard Screenshot

Create a screenshot by selecting a region with the keyboard and copy it to the clipboard

![Demo](image/demo.gif)

## How to use

- Press Alt Shift Q to start
- Move the mouse cursor with the arrow keys to the start position
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

### 2022

#### Screenshot the same region again

after you created at least one screenshot you can do the following

- Press Alt Shift Q to start
- F1

Your screenshot will be copied to the clipboard (using the same region as your last screenshot)

### 2023

#### Screenshot with delay (useful for dropdown menus)

- Press Alt Shift Q to start
- Press D to enable delay
- Move to the start position (you have 3 seconds)
- Move to the end position (you have 3 seconds)
- The screenshot will be automatically taken

#### Screenshot scale

Press 1,2,3 during screenshot process to scale the final output by 0.75, 0.5 or 0.25

#### Save screenshot to file

Press f during the screenshot process to save the screenshot to a file in the subfolder screenshots.
It will also be copied to the clipboard as usual.

## Licence

GPL 2.0

## Original code

I found the code that this tool is based on here:

[Autohotkey Forum](https://www.autohotkey.com/boards/viewtopic.php?style=19&t=96159)
