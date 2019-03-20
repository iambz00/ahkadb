#NoEnv
#NoTrayIcon
#SingleInstance Force
SetWorkingDir, %A_ScriptDir%
CoordMode, Pixel, Screen
CoordMode, Mouse, Screen
Global hGui
Global hEditLog, hPic
Global pToken
Global l, t
Global adb
; GUI
Gui, MainWindow:New, hwndhGui MinSize ;, Resize
Gui, Font, S8, Malgun Gothic
Gui, Margin, 8, 8
; Build Gui
Gui, Add, GroupBox, Section x8 w320 h215, 설정
Gui, Add, Picture, xs+9 ys+16 w48 h48 gReloadScript hwndhPic
Gui, Add, Button, x+2 yp-1 w50 h50  gStart, ▶
Gui, Add, Button, x+1 w50 h50 gStop, ■
Gui, Add, Button, x+1 w50 h50 gGet, Get
Gui, Add, Button, x+1 w50 h50 gGet2, Get2
Gui, Add, Button, x+1 w50 h25 , 선택
Gui, Add, Button, xp y+0 w50 h25 , Report
Gui, Add, Edit, w303 xs+9 y+2 r10 HwndhEditLog ReadOnly vvEditLog
Gui, Add, Text, Section x8 ys+228 Section, 로그
Gui, Add, Picture, y+2 w320 h240 HwndhPic ReadOnly VvPic, 
Gui, Add, StatusBar
Gui, Show, y20
Hotkey, IfWinActive, ahk_id %hGui%
Hotkey, [, StartCapture
HotKey, ], EndCapture
HotKey, 1, StartDraw
HotKey, 2, EndDraw
pToken := Gdip_Startup()
adb := New ADB()
Return
ReloadScript:
	Gdip_Shutdown(pToken)
	Reload
Return
MainWindowGuiClose:
GuiClose:
	Gdip_Shutdown(pToken)
ExitApp
AppendText(hEdit, ptrText) {
	SendMessage, 0x000E, 0, 0,, ahk_id %hEdit% ;WM_GETTEXTLENGTH
	SendMessage, 0x00B1, ErrorLevel, ErrorLevel,, ahk_id %hEdit% ;EM_SETSEL
	SendMessage, 0x00C2, False, ptrText,, ahk_id %hEdit% ;EM_REPLACESEL
}
Logn(str := "", vargs*) {
	str := StrReplace(StrReplace(Format(str, vargs*), "`n", "`r`n"),"`r`r", "`r")
    AppendText(hEditLog, &str)
}
Log(str := "", vargs*) {
	Logn(str . "`r`n", vargs*)
}
StartCapture:
	Log(A_ThisLabel)
	MouseGetPos, l, t
Return
EndCapture:
	Log(A_ThisLabel)
	MouseGetPos, r, b
	w := (r>l)? (r-l) : (l-r)
	h := (b>t)? (b-t) : (t-b)
	pBitmap := Gdip_BitmapFromScreen(Format("{}|{}|{}|{}", l, t, w, h))
	hBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap)
	GuiControl,,%hPic%, *w%w% *h%h% HBITMAP:%hBitmap%
Return
StartDraw:
	Log(A_ThisLabel)
Return
EndDraw:
	Log(A_ThisLabel)
Return
#Include <ADB>
Stop:
	Log(A_ThisLabel)
	Log(adb.DisConnect())
Return
Start:
	Log(A_ThisLabel)
	Log(adb.Connect())
Return
Get:
	Log(A_ThisLabel)
	hBitmap := adb.ScreenCapHBitmap()
	Log(StrLen(hBitmap))
	GuiControl,,%hPic%, *w%w% *h%h% HBITMAP:%hBitmap%

Return
Get2:
Return
