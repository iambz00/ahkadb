class ADB {
	__DeviceAddress := "127.0.0.1:62001"	; Default
	__ADB_Path := "Lib\adb.exe"
	__Codepage := "CP65001"

	__New(adbpath := "") {
		this.connected := 0
		if(adbpath)
			this.__ADB_Path := adbpath
		Log(this.__ADB_Path)
	}

	Connect(addr := "") {
		if(!addr)
			addr := this.__DeviceAddress
		else
			this.__DeviceAddress := addr
		out := this.ADBcmd("connect", addr)
		Log("[{}()] {}", A_ThisFunc, out)
		this.serialno := serialno1
		return serialno1
	}

	DisConnect() {
		out := this.ADBcmd("disconnect")
		Log("[{}()] {}", A_ThisFunc, out)
		return out
	}

	ReConnect() {
		out := this.ADBcmd("reconnect")
		Log("[{}()] {}", A_ThisFunc, out)
		return out
	}
	ScreenCap(sOut) {
		adbcmd := this.__ADB_Path . " exec-out screencap -p"
		VarSetCapacity(sOut, 1048576)
		nSize := StdoutToVar_Blob(adbcmd, sOut, 0)

	h := FileOpen("res.png", "w")
	h.RawWrite(&sOut, nSize)
	h.Close()

		return nSize
	}
	ScreenCapHBitmap() {
		adbcmd := this.__ADB_Path . " exec-out screencap -p"

		;VarSetCapacity(sOut, 1048576)
		nSize := StdoutToVar_Blob(adbcmd, sOut, 0)

		; Gdip create hBitmap from stream
;		hData := DllCall("HeapAlloc", "ptr", DllCall("GetProcessHeap", "ptr"), "uint", 0, "UInt", 2048000, "ptr")

;		DllCall("RtlMoveMemory", Ptr, hData, Ptr, &bOutput, UInt, nSize)
		rc3 := DllCall("ole32\CreateStreamOnHGlobal", Ptr, &sOut, Int, 1, PtrP, pStream)
		gst3 := DllCall("gdiplus\GdipCreateBitmapFromStream", Ptr, pStream, PtrP, pBitmap)       
		gst4 := DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", Ptr, pBitmap, PtrP, hBitmap, UInt, 8)
		DllCall("gdiplus\GdipDisposeImage", UInt, pBitmap)

;		DllCall("HeapFree", "ptr", DllCall("GetProcessHeap", "ptr"), "uint", 0, "ptr", hData)

		return hBitmap
	}
	Tap(x, y) {
		Log("[{}()] ({}, {})", A_ThisFunc, x, y)
		this.ADBcmd("shell input tap", x, y)
	}

	Swipe(x1, y1, x2, y2, delay) {
		Log("[{}()] ({}, {}) -> ({}, {}) {}ms", A_ThisFunc, x1, y1, x2, y2, delay)
		this.ADBcmd("shell input swipe", x1, y1, x2, y2, delay)
	}

	ADBcmd(params*) {
		for i, param in params
			cmd .= " " . param
		adbcmd := this.__ADB_Path . cmd
		;n := StdoutToVar_Blob(adbcmd, output, "CP65001",, exitCode)
		;VarSetCapacity(output, 4096)
		output := DllCall("HeapAlloc", "ptr", DllCall("GetProcessHeap", "ptr"), "uint", 0, "UInt", 4096, "ptr")
		n := Run_GetPtr2(adbcmd, output,, exitCode)
		nExitCode := exitCode
		Log("exit code: {}", exitCode)
		return StrGet(output, n, "CP65001")
	}

}

class NoxADB extends ADB {
	__DeviceAddress := "127.0.0.1:62001"	; Nox VM1 default
	__New() {
		RegRead, noxfullpath, HKCR, Nox\Shell\Open\Command
		RegExMatch(noxfullpath, "(.*)\\Nox.exe", noxpath)
		base.__New(noxpath1 . "\nox_adb.exe")
	}
}