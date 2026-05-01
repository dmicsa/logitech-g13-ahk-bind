#Requires AutoHotkey v2.0
#SingleInstance Force

; Logitech G13 — Raw HID mapping for AutoHotkey v2.
; G13 VID: 046D  PID: C21C  (confirmed via Device Manager)
; After clearing LGS profiles, G-keys use vendor-specific HID (Usage Page 0xFF00).
; Joy* hotkeys will NOT fire — raw WM_INPUT is used instead.
; Run as Administrator if registration fails on startup.
;
; Hotkeys:
;   Ctrl+Alt+Shift+F10 — Reload script
;   Ctrl+Alt+Shift+F12 — Exit script

global CurrentMode := 1

; Repeat behavior (ms)
global InitialRepeatDelayMs := 350
global RepeatDelayMs := 90

; Stick thresholds for 0-255 axis values
global StickLow := 90
global StickHigh := 165

global HeldH := ""
global HeldV := ""
global PrevGKeyState := 0
global PrevSideBtn1Down := false
global PrevSideBtn2Down := false
global ActiveRepeats := Map()

; Map confirmed side-button bit IDs to slots.
; Button bit positions vary by firmware. These defaults prioritize byte8 bits.
global ExtraBtnBitMap := Map(
    "8_1", 1,
    "8_2", 2,
    "8_0", 1,
    "8_3", 2,
    "7_1", 1,
    "7_2", 2
)

; Register for raw HID input and wire up the WM_INPUT message handler.
RegisterRawHID()
OnMessage(0x00FF, WM_INPUT)
SetTimer(ProcessRepeats, 10)

ToolTip("G13 loaded — Mode " CurrentMode)
SetTimer(() => ToolTip(), -500)

; =============================================================
; HOW TO BIND EACH KEY
; All three binding maps (JoyBindings, JoyBtnBindings, GKeyBindings) support:
;
;   1) Plain string — typed as-is via Send():
;        "hello world"
;
;   2) AHK key name — send a keystroke (hold-to-repeat applies):
;        "{F5}"  "{Ctrl down}z{Ctrl up}"  "{Enter}"
;
;   3) AHK function — runs arbitrary code on each fire (including on repeat):
;        MyMacro  (reference to a named function defined in MACROS below)
;        () => SomeAction()   (inline lambda)
;
; Named macro functions go in the MACROS section at the bottom of this file.
; They receive no arguments and return nothing.
;
; Examples:
;   G1 in mode 1 → paste clipboard:    () => Send("{Ctrl down}v{Ctrl up}")
;   G2 in mode 1 → run Notepad:        () => Run("notepad.exe")
;   G3 in mode 1 → toggle a var:       MyToggleMacro
; =============================================================

; Thumbstick direction keys per mode: [Left, Right, Up, Down]
global JoyBindings := Map(
    1, [
        "jLeft1",   ; Left
        "jRight1",  ; Right
        "jUp1",     ; Up
        "jDown1"    ; Down
    ],
    2, [
        "jLeft2",   ; Left
        "jRight2",  ; Right
        "jUp2",     ; Up
        "jDown2"    ; Down
    ],
    3, [
        "jLeft3",   ; Left
        "jRight3",  ; Right
        "jUp3",     ; Up
        "jDown3"    ; Down
    ]
)

; Side buttons near the thumbstick, per mode: [Button1, Button2]
global JoyBtnBindings := Map(
    1, [
        "jB1_1",  ; Button 1
        "jB2_1"   ; Button 2
    ],
    2, [
        "jB1_2",  ; Button 1
        "jB2_2"   ; Button 2
    ],
    3, [
        "jB1_3",  ; Button 1
        "jB2_3"   ; Button 2
    ]
)

; 3 layers x 22 G-keys.
global GKeyBindings := Map(
    1, [
        YahooQuote, ; G1
        "B1-",  ; G2
        "C1-",  ; G3
        "D1-",  ; G4
        "E1-",  ; G5
        "F1-",  ; G6
        "G1-",  ; G7
        "H1-",  ; G8
        "I1-",  ; G9
        "J1-",  ; G10
        "K1-",  ; G11
        "L1-",  ; G12
        "M1-",  ; G13
        "N1-",  ; G14
        "O1-",  ; G15
        "P1-",  ; G16
        "Q1-",  ; G17
        "R1-",  ; G18
        "S1-",  ; G19
        "T1-",  ; G20 — SetMode(1)
        "U1-",  ; G21 — SetMode(2)
        "V1-"   ; G22 — SetMode(3)
    ],
    2, [
        "A2-",  ; G1
        "B2-",  ; G2
        "C2-",  ; G3
        "D2-",  ; G4
        "E2-",  ; G5
        "F2-",  ; G6
        "G2-",  ; G7
        "H2-",  ; G8
        "I2-",  ; G9
        "J2-",  ; G10
        "K2-",  ; G11
        "L2-",  ; G12
        "M2-",  ; G13
        "N2-",  ; G14
        "O2-",  ; G15
        "P2-",  ; G16
        "Q2-",  ; G17
        "R2-",  ; G18
        "S2-",  ; G19
        "T2-",  ; G20 — SetMode(1)
        "U2-",  ; G21 — SetMode(2)
        "V2-"   ; G22 — SetMode(3)
    ],
    3, [
        "A3-",  ; G1
        "B3-",  ; G2
        "C3-",  ; G3
        "D3-",  ; G4
        "E3-",  ; G5
        "F3-",  ; G6
        "G3-",  ; G7
        "H3-",  ; G8
        "I3-",  ; G9
        "J3-",  ; G10
        "K3-",  ; G11
        "L3-",  ; G12
        "M3-",  ; G13
        "N3-",  ; G14
        "O3-",  ; G15
        "P3-",  ; G16
        "Q3-",  ; G17
        "R3-",  ; G18
        "S3-",  ; G19
        "T3-",  ; G20 — SetMode(1)
        "U3-",  ; G21 — SetMode(2)
        "V3-"   ; G22 — SetMode(3)
    ]
)

; =============================================
; Raw HID registration
; G13 exposes G-keys as vendor-specific HID (Usage Page 0xFF00) once LGS profiles
; are cleared. RegisterRawInputDevices captures those reports via WM_INPUT.
; =============================================
RegisterRawHID() {
    ; RAWINPUTDEVICE layout: usUsagePage(2), usUsage(2), dwFlags(4), hwndTarget(ptr)
    RID_size := 8 + A_PtrSize
    rid := Buffer(RID_size, 0)
    NumPut("UShort", 0xFF00, rid, 0)  ; vendor-specific usage page (confirmed: UP:FF00_U:0000)
    NumPut("UShort", 0x0000, rid, 2)  ; Usage MUST be 0 when RIDEV_PAGEONLY is set
    ; RIDEV_INPUTSINK (0x100) | RIDEV_PAGEONLY (0x20) = all usages on page, even unfocused
    NumPut("UInt", 0x00000120, rid, 4)
    NumPut("Ptr", A_ScriptHwnd, rid, 8)

    ok := DllCall("RegisterRawInputDevices", "Ptr", rid.Ptr, "UInt", 1, "UInt", RID_size, "Int")
    if !ok {
        err := DllCall("GetLastError", "UInt")
        MsgBox("HID registration failed (Error " err "). Run script as Administrator.")
    }
}

; =============================================
; WM_INPUT handler — parses raw G-key bytes
; =============================================
WM_INPUT(wParam, lParam, *) {
    Critical

    ; RAWINPUTHEADER size: 24 bytes on 64-bit, 16 bytes on 32-bit
    headerSize := (A_PtrSize = 8) ? 24 : 16

    ; First call: query required buffer size
    sz := 0
    DllCall("GetRawInputData", "Ptr", lParam, "UInt", 0x10000003, "Ptr", 0, "UInt*", &sz, "UInt", headerSize, "Int")
    if sz = 0
        return

    buf := Buffer(sz, 0)
    DllCall("GetRawInputData", "Ptr", lParam, "UInt", 0x10000003, "Ptr", buf.Ptr, "UInt*", &sz, "UInt", headerSize,
        "Int")

    ; dwType at offset 0: 0=keyboard 1=mouse 2=HID — only process HID
    if NumGet(buf, 0, "UInt") != 2
        return

    ; RAWDATA section follows header: dwSizeHid(4) + dwCount(4) + bRawData[...]
    sizeHid := NumGet(buf, headerSize, "UInt")
    dataOff := headerSize + 8

    if sizeHid < 4
        return

    ; Collect raw bytes
    rawBytes := []
    loop sizeHid {
        b := NumGet(buf, dataOff + A_Index - 1, "UChar")
        rawBytes.Push(b)
    }

    ; G-key report layout (verified: G1 = bit 0 of byte 3):
    ;   Byte 1  = Report ID
    ;   Bytes 2-3 = thumbstick X, Y (0-255, center ~127)
    ;   Bytes 4-6 = G-key bitmask  (bit 0 = G1 ... bit 21 = G22)
    ;   Byte 7  = extra buttons (BD, L1-L4, M1-M3 area)
    ;   Byte 8  = LEFT, RIGHT, STICK-click and other controls
    stickX := rawBytes.Length >= 3 ? rawBytes[2] : 127
    stickY := rawBytes.Length >= 3 ? rawBytes[3] : 127

    gMask := rawBytes[4] | (rawBytes[5] << 8) | (rawBytes[6] << 16)

    ; Extra button bytes
    extraMask7 := rawBytes.Length >= 7 ? rawBytes[7] : 0
    extraMask8 := rawBytes.Length >= 8 ? rawBytes[8] : 0

    ; Edge-detect: fire only on key-down transition, not while held
    global PrevGKeyState
    oldMask := PrevGKeyState
    newlyPressed := gMask & ~oldMask
    releasedMask := oldMask & ~gMask

    PrevGKeyState := gMask

    if newlyPressed {
        loop 22 {
            if (newlyPressed >> (A_Index - 1)) & 1
                HandleGKeyDown(A_Index)
        }
    }
    if releasedMask {
        loop 22 {
            if (releasedMask >> (A_Index - 1)) & 1
                HandleGKeyUp(A_Index)
        }
    }

    ; Side buttons by mapped bit IDs
    sideBtn1Down := SideButtonIsDown(1, extraMask7, extraMask8)
    sideBtn2Down := SideButtonIsDown(2, extraMask7, extraMask8)

    global PrevSideBtn1Down, PrevSideBtn2Down
    if (sideBtn1Down && !PrevSideBtn1Down)
        HandleSideButtonDown(1)
    else if (!sideBtn1Down && PrevSideBtn1Down)
        HandleSideButtonUp(1)

    if (sideBtn2Down && !PrevSideBtn2Down)
        HandleSideButtonDown(2)
    else if (!sideBtn2Down && PrevSideBtn2Down)
        HandleSideButtonUp(2)

    PrevSideBtn1Down := sideBtn1Down
    PrevSideBtn2Down := sideBtn2Down

    HandleStick(stickX, stickY)
}

HandleGKeyDown(gKeyIndex) {
    global CurrentMode, GKeyBindings

    ; Reliable hardware mode selectors on G20/G21/G22.
    ; Use these instead of M1/M2/M3 when firmware does not expose M-key state.
    if (gKeyIndex = 20) {
        SetMode(1)
        return
    }
    if (gKeyIndex = 21) {
        SetMode(2)
        return
    }
    if (gKeyIndex = 22) {
        SetMode(3)
        return
    }

    action := GKeyBindings[CurrentMode][gKeyIndex]
    if (action = "")
        return

    StartRepeat("G" gKeyIndex, action)
}

HandleGKeyUp(gKeyIndex) {
    if (gKeyIndex = 20 || gKeyIndex = 21 || gKeyIndex = 22)
        return
    StopRepeat("G" gKeyIndex)
}

SetMode(modeNumber) {
    global CurrentMode
    CurrentMode := modeNumber
}

; -----------------------------
; Thumbstick — mode-aware, read from raw HID report
; Stick X/Y are bytes 2-3 (1-based), range 0-255, center ~127
; Deadzone from StickLow/StickHigh
; -----------------------------
HandleStick(sx, sy) {
    global HeldH, HeldV, CurrentMode, JoyBindings, StickLow, StickHigh

    keys := JoyBindings[CurrentMode]  ; [Left, Right, Up, Down]

    targetH := ""
    if (sx < StickLow)
        targetH := keys[1]
    else if (sx > StickHigh)
        targetH := keys[2]

    targetV := ""
    if (sy < StickLow)
        targetV := keys[3]
    else if (sy > StickHigh)
        targetV := keys[4]

    if (targetH != HeldH) {
        if (HeldH != "")
            StopRepeat("STICK_H")
        HeldH := targetH
        if (targetH != "")
            StartRepeat("STICK_H", targetH)
    }

    if (targetV != HeldV) {
        if (HeldV != "")
            StopRepeat("STICK_V")
        HeldV := targetV
        if (targetV != "")
            StartRepeat("STICK_V", targetV)
    }
}

ReleaseThumbstickKeys() {
    global HeldH, HeldV
    StopRepeat("STICK_H")
    StopRepeat("STICK_V")
    HeldH := ""
    HeldV := ""
}

HandleSideButtonDown(btnSlot) {
    global CurrentMode, JoyBtnBindings
    action := JoyBtnBindings[CurrentMode][btnSlot]
    if (action = "")
        return
    StartRepeat("B" btnSlot, action)
}

HandleSideButtonUp(btnSlot) {
    StopRepeat("B" btnSlot)
}

SideButtonIsDown(btnSlot, extraMask7, extraMask8) {
    global ExtraBtnBitMap
    for bitID, mappedSlot in ExtraBtnBitMap {
        if (mappedSlot != btnSlot)
            continue

        parts := StrSplit(bitID, "_")
        if (parts.Length != 2)
            continue

        byteId := parts[1]
        bitPos := Integer(parts[2])
        mask := (byteId = "7") ? extraMask7 : extraMask8
        if ((mask >> bitPos) & 1)
            return true
    }
    return false
}

StartRepeat(id, action) {
    global ActiveRepeats, InitialRepeatDelayMs
    if (action = "")
        return

    now := A_TickCount
    ActiveRepeats[id] := Map(
        "action", action,
        "nextTick", now + InitialRepeatDelayMs
    )

    ExecuteAction(action)
}

StopRepeat(id) {
    global ActiveRepeats
    if ActiveRepeats.Has(id)
        ActiveRepeats.Delete(id)
}

StopAllRepeats() {
    global ActiveRepeats
    ActiveRepeats := Map()
}

ProcessRepeats() {
    global ActiveRepeats, RepeatDelayMs

    now := A_TickCount
    for id, state in ActiveRepeats {
        if (now >= state["nextTick"]) {
            ExecuteAction(state["action"])
            state["nextTick"] := now + RepeatDelayMs
            ActiveRepeats[id] := state
        }
    }
}

ExecuteAction(action) {
    kind := Type(action)
    if (kind = "Func" || kind = "BoundFunc") {
        action.Call()
        return
    }
    Send(action)
}

; -----------------------------
; Controls
; -----------------------------
^!+F10:: Reload
^!+F12:: ExitApp

; Always release held keys when script exits/reloads.
OnExit((*) => (ReleaseThumbstickKeys(), StopAllRepeats()))

; =============================================================
; MACROS — write your per-key AHK scripts here.
; Reference any of these functions by name in GKeyBindings above.
; =============================================================

YahooQuote() {
    StopRepeat("G1")        ; one-shot — do not repeat while held
    Send("^c")
    Sleep(100)
    Run("https://finance.yahoo.com/quote/" . A_Clipboard)
}
