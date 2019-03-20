class ADB {
	_ADB_DeviceAddress := "127.0.0.1:62001"	; Nox VM
	_ADB_Path := "Lib\adb.exe"
	_Codepage := "CP65001"

	__New(adbpath := "") {
		this.connected := 0
		if(adbpath)
			this._ADB_Path := adbpath
	}

	Connect(addr := "") {
		if(!addr)
			addr := this._ADB_DeviceAddress
		return this.ADBcmd("connect", addr)
	}

	DisConnect() {
		return this.ADBcmd("disconnect")
	}

	ScreenCap(ByRef output) {
		fullcmd := this._ADB_Path . " exec-out screencap -p"
		RunWait, % fullcmd,, Hide,, output, oSize	; AutoHotKey+ Only
		return oSize
	}

	ScreenCapHBitmap() {
		adbcmd := this._ADB_Path . " exec-out screencap -p"
		RunWait, % adbcmd,, Hide,, cap, nSize	; AutoHotKey+ Only

		Log("adb screencap {} bytes png", nSize)

		; Gdip create hBitmap from stream
		hData := DllCall("GlobalAlloc", UInt,2, UInt, nSize )
		pData := DllCall("GlobalLock",  UInt, hData, Ptr )
		DllCall( "RtlMoveMemory", Ptr, pData, Ptr, &cap, UInt,nSize )
		DllCall( "GlobalUnlock", UInt,hData )
		rc3 := DllCall("ole32\CreateStreamOnHGlobal", ptr, hData, int, 1, ptrP, pStream)

		gst3 := DllCall("gdiplus\GdipCreateBitmapFromStream", ptr, pStream, ptrP, pBitmap)       

		gst4 := DllCall( "gdiplus\GdipCreateHBITMAPFromBitmap", Ptr,pBitmap, PtrP, hBitmap, UInt,8 )
	 
		DllCall( "gdiplus\GdipDisposeImage", UInt,pBitmap )

		return hBitmap
	}

	ADBcmd(params*) {
		for i, param in params
			cmd .= " " . param
		adbcmd := this._ADB_Path . cmd
		RunWait, % adbcmd,, Hide,, output, oSize	; AutoHotKey+ Only
		return StrGet(&output, this._Codepage)
	}

}
