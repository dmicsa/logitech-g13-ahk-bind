# logitech-g13-ahk-bind

Raw HID binding script for the Logitech G13 gameboard, built with AutoHotkey v2.

Requires LGS profiles to be cleared so G-keys are exposed as vendor-specific HID (Usage Page `0xFF00`). Standard `Joy*` hotkeys do not work in this configuration — the script uses `WM_INPUT` instead.

**Run `G13Bind.ahk` as Administrator** if HID registration fails on startup.

---

## Hotkeys

| Hotkey | Action |
|---|---|
| `Ctrl+Alt+Shift+F10` | Reload script |
| `Ctrl+Alt+Shift+F12` | Exit script |

---

## Modes

Three layers are available, switched by hardware G-keys:

| G-key | Mode |
|---|---|
| G20 | Mode 1 |
| G21 | Mode 2 |
| G22 | Mode 3 |

---

## Bindings

All binding tables (`JoyBindings`, `JoyBtnBindings`, `GKeyBindings`) support three styles:

**1. Plain string** — typed via `Send()`, repeats while held:
```ahk
"hello world"
```

**2. AHK key name** — sends a keystroke, repeats while held:
```ahk
"{F5}"
"{Ctrl down}z{Ctrl up}"
```

**3. AHK function** — runs arbitrary code on each fire:
```ahk
() => Run("notepad.exe")   ; inline lambda
MyMacro                    ; named function defined in MACROS section
```

---

## Binding Tables

### GKeyBindings — 22 G-keys × 3 modes
Edit in `G13Script.ahk`. Each entry maps to one G-key in one mode.  
G20/G21/G22 are intercepted for mode switching — their binding table entries are ignored.

### JoyBindings — Thumbstick × 3 modes
Order: `[Left, Right, Up, Down]`

### JoyBtnBindings — Side buttons × 3 modes
Order: `[Button1, Button2]`

---

## Repeat Behavior

All controls use hold-to-repeat, matching standard keyboard behavior.

| Global | Default | Effect |
|---|---|---|
| `InitialRepeatDelayMs` | `350` | Delay before repeat starts (ms) |
| `RepeatDelayMs` | `90` | Interval between repeats (ms) |

---

## Thumbstick Deadzone

Raw axis range is 0–255, center ~127.

| Global | Default | Effect |
|---|---|---|
| `StickLow` | `90` | Below this = Left or Up |
| `StickHigh` | `165` | Above this = Right or Down |

---

## Side Button Bit Mapping

`ExtraBtnBitMap` maps raw HID byte/bit IDs to button slots 1 or 2.  
Format: `"byte_bit"` → slot. Defaults cover the most common G13 firmware variants.  
If a side button doesn't fire, add or adjust entries here.

```ahk
global ExtraBtnBitMap := Map(
    "8_1", 1,
    "8_2", 2,
    ...
)
```

---

## Macros

Named functions defined in the `MACROS` section at the bottom of `G13Script.ahk` can be referenced by name in any binding table:

```ahk
; In GKeyBindings:
OpenNotepad,   ; G1 — calls OpenNotepad() on press and each repeat

; In MACROS section:
OpenNotepad() {
    StopRepeat("G1")   ; optional: prevent repeat for one-shot actions
    Run("notepad.exe")
}
```
