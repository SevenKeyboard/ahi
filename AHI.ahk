#Requires AutoHotkey v1.1.35+
#Include "%A_ScriptDir%"
#Include ".\vendor\CLR.ahk" ;  Tested with https://github.com/Lexikos/CLR.ahk/blob/v1.2/CLR.ahk
;==============================================================
; AHI — AutoHotInterception wrapper and input device management helpers
;
; GitHub: https://github.com/SevenKeyboard/ahi
; Original Author: Clive Galway (2018)
; Maintainer: SevenKeyboard Ltd. (2026)
; License: MIT License (see LICENSE for copyright notice)
;
; Documentation / References:
;   AutoHotInterception/AHK v1/Lib/AutoHotInterception.ahk
;     https://github.com/evilC/AutoHotInterception/blob/master/AHK%20v1/Lib/AutoHotInterception.ahk
;==============================================================
class VersionManager_AHI
{
    static _ := VersionManager_AHI._init()
    _init()    {
        global
        AHI_VERSION := "1.0.0"
    }
}
class AHI
{
    static _contextManagers := {}, enabled := false
    init()    {
        bitness := A_PtrSize == 8 ? "x64" : "x86"
        dllName := "interception.dll"
        dllFile := A_ScriptDir "\dll\" bitness "\" dllName
        if (!fileExist(dllFile))
            return false 
        hModule := dllCall("Kernel32.dll\LoadLibrary", "Str",dllFile, "Ptr")
        if (hModule == 0)
            return false
        dllCall("Kernel32.dll\FreeLibrary", "Ptr",hModule, "Int")
        dllName := "AutoHotInterception.dll"
        dllFile := A_ScriptDir "\dll\" dllName
        if (!fileExist(dllFile))
            return false
        asm := CLR_LoadLibrary(dllFile)
        try    {
            this.instance := asm.createInstance("AutoHotInterception.Manager")
        }  catch  {
            return false
        }
        if (this.instance.okCheck() !== "OK")
            return false
        return this.enabled := true
    }
    getInstance()    {
        return this.instance
    }
    ;--------------- Input Synthesis ---------------
    sendKeyEvent(id, code, state)    {
        this.instance.sendKeyEvent(id, code, state)
    }
    sendMouseButtonEvent(id, btn, state)    {
        this.instance.sendMouseButtonEvent(id, btn, state)
    }
    sendMouseButtonEventAbsolute(id, btn, state, x, y)    {
        this.instance.sendMouseButtonEventAbsolute(id, btn, state, x, y)
    }
    sendMouseMove(id, x, y)    {
        this.instance.sendMouseMove(id, x, y)
    }
    sendMouseMoveRelative(id, x, y)    {
        this.instance.sendMouseMoveRelative(id, x, y)
    }
    sendMouseMoveAbsolute(id, x, y)    {
        this.instance.sendMouseMoveAbsolute(id, x, y)
    }
    setState(state)    {
        this.instance.setState(state)
    }
    moveCursor(x, y, cm := "Screen", mouseId := -1)    {
        if (mouseId == -1)
            mouseId := 11 ;  Use 1st found mouse
        oldMode := A_CoordModeMouse
        coordMode Mouse, % cm
        loop    {
            mouseGetPos cx, cy
            dx := this.getDirection(cx, x)
            dy := this.getDirection(cy, y)
            if (dx == 0 && dy == 0)
                break
            this.sendMouseMove(mouseId, dx, dy)
        }
        coordMode Mouse, % oldMode
    }
    getDirection(cp, dp)    {
        d := dp - cp
        if (d > 0)
            return 1
        if (d < 0)
            return -1
        return 0
    }
    ;--------------- Querying ---------------
    getDeviceId(isMouse, vid, pid, instance := 1)    {
        static devType := {0: "Keyboard", 1: "Mouse"}
        dev := this.instance.getDeviceId(isMouse, vid, pid, instance)
        if (dev == 0)    {
            msgBox % "Could not get " devType[isMouse] " with VID " vid ", PID " pid ", Instance " instance
            ExitApp
        }
        return dev
    }

    getDeviceIdFromHandle(isMouse, handle, instance := 1)    {
        static devType := {0: "Keyboard", 1: "Mouse"}
        dev := this.instance.getDeviceIdFromHandle(isMouse, handle, instance)
        if (dev == 0)    {
            msgBox % "Could not get " devType[isMouse] " with Handle " handle ", Instance " instance
            ExitApp
        }
        return dev
    }
    getKeyboardId(vid, pid, instance := 1)    {
        return this.getDeviceId(false, vid, pid, instance)
    }
    getMouseId(vid, pid, instance := 1)    {
        return this.getDeviceId(true, vid, pid, instance)
    }
    getKeyboardIdFromHandle(handle, instance := 1)    {
        return this.getDeviceIdFromHandle(false, handle, instance)
    }
    getMouseIdFromHandle(handle, instance := 1)    {
        return this.getDeviceIdFromHandle(true, handle, instance)
    }
    getDeviceList()    {
        deviceList := {}
        arr := this.instance.getDeviceList()
        for v in arr    {
            deviceList[v.id] := {id:v.id, vid:v.vid, pid:v.pid, isMouse:v.isMouse, handle:v.handle}
        }
        return deviceList
    }
    ;--------------- Subscription Mode ---------------
    subscribeKey(id, code, block, callback, concurrent := false)    {
        this.instance.subscribeKey(id, code, block, callback, concurrent)
    }
    unsubscribeKey(id, code)    {
        this.instance.unsubscribeKey(id, code)
    }
    subscribeKeyboard(id, block, callback, concurrent := false)    {
        this.instance.subscribeKeyboard(id, block, callback, concurrent)
    }
    unsubscribeKeyboard(id)    {
        this.instance.unsubscribeKeyboard(id)
    }
    subscribeMouseButton(id, btn, block, callback, concurrent := false)    {
        this.instance.subscribeMouseButton(id, btn, block, callback, concurrent)
    }
    unsubscribeMouseButton(id, btn)    {
        this.instance.unsubscribeMouseButton(id, btn)
    }
    subscribeMouseButtons(id, block, callback, concurrent := false)    {
        this.instance.subscribeMouseButtons(id, block, callback, concurrent)
    }
    unsubscribeMouseButtons(id)    {
        this.instance.unsubscribeMouseButtons(id)
    }
    subscribeMouseMove(id, block, callback, concurrent := false)    {
        this.instance.subscribeMouseMove(id, block, callback, concurrent)
    }
    unsubscribeMouseMove(id)    {
        this.instance.unsubscribeMouseMove(id)
    }
    subscribeMouseMoveRelative(id, block, callback, concurrent := false)    {
        this.instance.subscribeMouseMoveRelative(id, block, callback, concurrent)
    }
    unsubscribeMouseMoveRelative(id)    {
        this.instance.unsubscribeMouseMoveRelative(id)
    }
    subscribeMouseMoveAbsolute(id, block, callback, concurrent := false)    {
        this.instance.subscribeMouseMoveAbsolute(id, block, callback, concurrent)
    }
    unsubscribeMouseMoveAbsolute(id)    {
        this.instance.unsubscribeMouseMoveAbsolute(id)
    }
    ;--------------- Context Mode ---------------
    createContextManager(id)    { ; Creates a context class to make it easy to turn on/off the hotkeys
        if (this._contextManagers.hasKey(id))
            return this._contextManagers[id]
        cm := new this.contextManager(this, id)
        this._contextManagers[id] := cm
        return cm
    }
    removeContextManager(id)    {
        if (!this._contextManagers.hasKey(id))
            return
        this._contextManagers[id].remove()
        this._contextManagers.delete(id)
    }
    class ContextManager ;  Helper class for dealing with context mode
    {
        isActive := 0
        __new(parent, id)    {
            this.parent := parent
            this.id := id
            result := this.parent.instance.setContextCallback(id, this.OnContextCallback.bind(this))
        }
        onContextCallback(state)    {
            sleep 0
            this.isActive := state
        }
        remove()    {
            this.parent.instance.removeContextCallback(this.id)
        }
    }
}