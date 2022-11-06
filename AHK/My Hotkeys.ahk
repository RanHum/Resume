#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
#SingleInstance Force
#Persistent
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#Include %A_ScriptDir%\TrayIcon.ahk

SetTitleMatchMode 2
AutoTrim Off

; non-destructive clipboard getter
ClipGet() {
	ClipSaved := ClipboardAll, Clipboard := ""
	Send ^c
	ClipWait 1
	ClipNew := Clipboard, Clipboard := ClipSaved, ClipSaved := ""
	Return ClipNew
}

; window-mouse backup-restore
WMBackup:
	MouseGetPos mouse_x_backup, mouse_y_backup
	WinGet, active_id_backup, ID, A
	Return
WMRestore:
	MouseMove mouse_x_backup - 8, mouse_y_backup - 8, 0
	WinActivate ahk_id %active_id_backup%
	Return

; system-wide send text to firefox
#s::
	Clip := Trim(ClipGet(), " `t`r`n")
	if StrLen(Clip) {
		if !WinActive("ahk_exe firefox.exe") {
			WinActivate ahk_exe firefox.exe
		}
		KeyWait LWin
		Send ^t%Clip%{Enter}
	}
	Return
#!s::
	if !WinActive("ahk_exe firefox.exe") {
		WinActivate ahk_exe firefox.exe
	}
	KeyWait LWin
	KeyWait LAlt
	Send ^t
	Return

#Space::Send {Media_Play_Pause}
	Return

ScrollLock::Send {AltDown}{Tab}{AltUp}
	Return

; change keyboard layout
CapsLock::Send {AltDown}{Shift}{AltUp}
	Return

; QTRANSLATE to the left side of keyboard
!CapsLock::
	KeyWait CapsLock
	KeyWait Alt
	Send {Pause}
	Return

#CapsLock::
	KeyWait CapsLock
	KeyWait LWin
	Send !{Pause}
	Return
; QTRANSLATE end

#w::Run bingweather:
	Return

; #Home::
; 	TrayIcon_Button("Shadowsocks.exe", "R")
; 	WinActivate ahk_exe Shadowsocks.exe
; 	Return

; shadowsocks pac/system-wide modes
ShadowsocksMenu:
	Gosub WMBackup
	Send #bshad{AppsKey}{Up}
	Sleep 10
	Return
#PgUp::
	Gosub ShadowsocksMenu
	Send {Down}{Right}{Down 2}{Enter}
	Gosub WMRestore
	Return
#PgDn::
	Gosub ShadowsocksMenu
	Send {Down}{Right}{Down}{Enter}
	Gosub WMRestore
	Return

; import selected v2ray link and connect to it
#Ins::
	tool := """C:\Users\Ranhum\Desktop\Project GFW\V2ray\V2ray for iKuuu\V2RayTools.py"""
	link := Trim(ClipGet(), " `t`r`n")
	Run python %tool% connect %link%
	Return

; turn off the monitors
#Esc::
	KeyWait Esc
	KeyWait LWin
	SendMessage,0x112,0xF170,2,,Program Manager
	; Note for the above: Use -1 in place of 2 to turn the monitor on.
	; Use 1 in place of 2 to activate the monitor's low-power mode.
	Return

; escape as window close for various software
#IfWinActive ahk_exe freearc.exe
	Esc::
		If WinActive("ahk_exe freearc.exe", , "| Creating ")
			WinClose
		Return
#IfWinActive ahk_exe IDMan.exe
	Esc::
		If WinActive("ahk_exe IDMan.exe", "IDM DwnlProgress Window")
			WinMinimize
		Else
			WinClose
		Return
#IfWinActive ahk_exe qbittorrent.exe
	Esc::WinClose
#IfWinActive ahk_exe onenote.exe
	Esc::WinClose
#IfWinActive ahk_exe zoom.exe
	Esc::WinClose
#IfWinActive ahk_exe notepad.exe
	Esc::WinClose
#IfWinActive Weather
	Esc::
		if WinActive("ahk_exe ApplicationFrameHost.exe") {
			WinClose
		}
		Return
; #IfWinActive ahk_exe teamviewer.exe
; 	Esc::WinClose
; 		Return
#IfWinActive ahk_exe cmd.exe
	Esc::WinClose
		Return
	PgUp::Send {WheelUp 4}
		Return
	PgDn::Send {WheelDown 4}
		Return
#IfWinActive

#IfWinActive ahk_exe firefox.exe
	; idm as firefox download manager
	^j::TrayIcon_Button("IDMan.exe", "L")
	; ^j::Send #bidownload{Enter}
		Return
	; go to the second suggest in awesomebar
	+Enter::
	!Enter::Send {Down}{Enter}
		Return
#IfWinActive

#IfWinActive ahk_exe sumatrapdf.exe
	; Speeding up scrolling
	; s::Send {WheelUp}
	; Return
	; d::Send {WheelDown}
	; Return
; 	; show/hide scrollbars
; 	ScrollLock::Send {F10}{Down 2}{Right}{Up 3}{Enter}
; 		Return
; 	$Space::
; 		If WinActive(,,"Поиск")
; 			Send {Down 15}
; 		Else
; 			Send {Space}
; 		Return
; 	+Space::Send {Up 15}
; 		Return
#IfWinActive

; current folder from dopus to everything
#IfWinActive ahk_exe dopus.exe
	#F1::
		Send {Esc}^l
		Clip := ClipGet()
		Send {Esc}!{F1}
		WinWaitActive ahk_exe everything.exe
		Send "%Clip%"{Space}
		Return
#IfWinActive

#IfWinActive ahk_exe everything.exe
	; open parent in everything closes window
	+Enter::
		Send +{Enter}
		WinWaitNotActive ahk_exe everything.exe
		WinClose
		Return

	^+Enter::Send +{Enter}
		Return

	; focus search field and change keys layout
	Pause::
		Send {F3}
		; Sleep 20
		Send {Pause}
		Return

	; search executables
	^l::
		Send {Home}ext:exe{Space}{End}
		Return

	; search in selected folder
	F1::
		Clip := ClipGet()
		Send {F3}"%Clip%"{Right}{Space}
		Return
#IfWinActive