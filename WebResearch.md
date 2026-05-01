# Logitech G13 + AutoHotkey Web Research

## High-value references

1. <https://www.autohotkey.com/docs/v2/Hotkeys.htm>
2. <https://www.autohotkey.com/docs/v2/lib/GetKeyState.htm>
3. <https://www.autohotkey.com/docs/v2/misc/RemapController.htm>
4. <https://www.autohotkey.com/docs/v2/scripts/index.htm#ControllerTest>
5. <https://www.autohotkey.com/docs/v1/KeyList.htm#Controller>
6. <https://www.autohotkey.com/docs/v1/misc/RemapController.htm>
7. <https://www.usb.org/hid>
8. <https://en.wikipedia.org/wiki/USB_human_interface_device_class>

## What matters for G13

- G13 keys can appear as keyboard inputs and/or joystick buttons depending on Logitech driver behavior.
- Thumbstick support depends on whether Windows exposes JoyX/JoyY for the device.
- AutoHotkey controller test script is the first required check before mapping.
- Logitech software can intercept input; close it while testing if AHK hotkeys do not fire.

## Fast test flow

1. Run AHK controller test script.
2. Confirm Joy button numbers and JoyX/JoyY movement.
3. Run G13Script.ahk.
4. Press F8 for live axis values and tune deadzone if needed.
5. If game input does not work, run AutoHotkey as administrator.
