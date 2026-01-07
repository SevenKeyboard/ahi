#Requires AutoHotkey v2.0.0+
#Include "%A_ScriptDir%"
#Include ".\vendor\CLR.ahk" ;  Tested with https://github.com/Lexikos/CLR.ahk/blob/v2.0/CLR.ahk
;==============================================================
; AHI — AutoHotInterception wrapper and input device management helpers
;
; GitHub: https://github.com/SevenKeyboard/ahi
; Original Author: Clive Galway (2018)
; Maintainer: SevenKeyboard Ltd. (2026)
; License: MIT License (see LICENSE for copyright notice)
;
; Documentation / References:
;   AutoHotInterception/AHK v2/Lib/AutoHotInterception.ahk
;     https://github.com/evilC/AutoHotInterception/blob/master/AHK%20v2/Lib/AutoHotInterception.ahk
;==============================================================
class VersionManager_AHI
{
    static _ := this._init()
    static _init()    {
        global
        AHI_VERSION := "1.0.0"
    }
}
class AHI
{
    static _contextManagers := map(), enabled := false
    static init()    {
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
    static getinstance()    {
        return this.instance
    }
    ;--------------- Input Synthesis ---------------
    static sendKeyEvent(id, code, state)    {
        this.instance.sendKeyEvent(id, code, state)
    }
    static sendMouseButtonEvent(id, btn, state)    {
        this.instance.sendMouseButtonEvent(id, btn, state)
    }
    static sendMouseButtonEventAbsolute(id, btn, state, x, y)    {
        this.instance.sendMouseButtonEventAbsolute(id, btn, state, x, y)
    }
    static sendMouseMove(id, x, y)    {
        this.instance.sendMouseMove(id, x, y)
    }
    static sendMouseMoveRelative(id, x, y)    {
        this.instance.sendMouseMoveRelative(id, x, y)
    }
    static sendMouseMoveAbsolute(id, x, y)    {
        this.instance.sendMouseMoveAbsolute(id, x, y)
    }
    static setState(state)    {
        this.instance.setState(state)
    }
    static moveCursor(x, y, cm := "Screen", mouseId := -1)    {
        if (mouseId == -1)
            mouseId := 11 ;  Use 1st found mouse
        oldMode := A_CoordModeMouse
        coordMode("Mouse", cm)
        loop    {
            mouseGetPos(&cx, &cy)
            dx := this.getDirection(cx, x)
            dy := this.getDirection(cy, y)
            if (dx == 0 && dy == 0)
                break
            this.sendMouseMove(mouseId, dx, dy)
        }
        coordMode("Mouse", oldMode)
    }
    static getDirection(cp, dp)    {
        d := dp - cp
        if (d > 0)
            return 1
        if (d < 0)
            return -1
        return 0
    }
    ;--------------- Querying ---------------
    static getDeviceId(isMouse, vid, pid, instance := 1)    {
        static devType := map(0, "Keyboard", 1, "Mouse")
        dev := this.instance.getDeviceId(isMouse, vid, pid, instance)
        if (dev == 0)    {
            msgBox("Could not get " devType[isMouse] " with VID " vid ", PID " pid ", instance " instance)
            ExitApp
        }
        return dev
    }
    static getDeviceIdFromHandle(isMouse, handle, instance := 1)    {
        static devType := map(0, "Keyboard", 1, "Mouse")
        dev := this.instance.getDeviceIdFromHandle(isMouse, handle, instance)
        if (dev == 0)    {
            msgBox("Could not get " devType[isMouse] " with Handle " handle ", instance " instance)
            ExitApp
        }
        return dev
    }
    static getKeyboardId(vid, pid, instance := 1)    {
        return this.getDeviceId(false, vid, pid, instance)
    }
    static getMouseId(vid, pid, instance := 1)    {
        return this.getDeviceId(true, vid, pid, instance)
    }
    static getKeyboardIdFromHandle(handle, instance := 1)    {
        return this.getDeviceIdFromHandle(false, handle, instance)
    }
    static getMouseIdFromHandle(handle, instance := 1)    {
        return this.getDeviceIdFromHandle(true, handle, instance)
    }
    static getDeviceList()    {
        deviceList := map()
        arr := this.instance.getDeviceList()
        for v in arr    {
            deviceList[v.id] := {id:v.id, vid:v.vid, pid:v.pid, isMouse:v.isMouse, handle:v.handle}
        }
        return deviceList
    }
    ;--------------- Subscription Mode ---------------
    static subscribeKey(id, code, block, callback, concurrent := false)    {
        this.instance.subscribeKey(id, code, block, callback, concurrent)
    }
    static unsubscribeKey(id, code)    {
        this.instance.unsubscribeKey(id, code)
    }
    static subscribeKeyboard(id, block, callback, concurrent := false)    {
        this.instance.subscribeKeyboard(id, block, callback, concurrent)
    }
    static unsubscribeKeyboard(id)    {
        this.instance.unsubscribeKeyboard(id)
    }
    static subscribeMouseButton(id, btn, block, callback, concurrent := false)    {
        this.instance.subscribeMouseButton(id, btn, block, callback, concurrent)
    }
    static unsubscribeMouseButton(id, btn)    {
        this.instance.unsubscribeMouseButton(id, btn)
    }
    static subscribeMouseButtons(id, block, callback, concurrent := false)    {
        this.instance.subscribeMouseButtons(id, block, callback, concurrent)
    }
    static unsubscribeMouseButtons(id)    {
        this.instance.unsubscribeMouseButtons(id)
    }
    static subscribeMouseMove(id, block, callback, concurrent := false)    {
        this.instance.subscribeMouseMove(id, block, callback, concurrent)
    }
    static unsubscribeMouseMove(id)    {
        this.instance.unsubscribeMouseMove(id)
    }
    static subscribeMouseMoveRelative(id, block, callback, concurrent := false)    {
        this.instance.subscribeMouseMoveRelative(id, block, callback, concurrent)
    }
    static unsubscribeMouseMoveRelative(id)    {
        this.instance.unsubscribeMouseMoveRelative(id)
    }
    static subscribeMouseMoveAbsolute(id, block, callback, concurrent := false)    {
        this.instance.subscribeMouseMoveAbsolute(id, block, callback, concurrent)
    }
    static unsubscribeMouseMoveAbsolute(id)    {
        this.instance.unsubscribeMouseMoveAbsolute(id)
    }
    ;--------------- Context Mode ---------------
    static createContextManager(id)    { ;  Creates a context class to make it easy to turn on/off the hotkeys
        if (this._contextManagers.has(id))
            return this._contextManagers[id]
        cm := this.contextManager(this, id)
        this._contextManagers[id] := cm
        return cm
    }
    static removeContextManager(id)    {
        if (!this._contextManagers.has(id))
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
            result := this.parent.instance.setContextCallback(id, this.onContextCallback.bind(this))
        }
        onContextCallback(state)    {
            sleep(0)
            this.isActive := state
        }
        remove()    {
            this.parent.instance.removeContextCallback(this.id)
        }
    }
}