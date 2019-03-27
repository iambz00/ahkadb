class Run {
	__New() {
		this.bufferSize := 4096
		this.allocSize := 16 * this.bufferSize
		this.PtrAlloc()

		return this
	}
	__Delete() {
		this.PtrFree()
	}
	Free(ptr) {
		if(ptr)
			DllCall("HeapFree", "Ptr", DllCall("GetProcessHeap", "Ptr"), "UInt", 0, "Ptr", ptr)
	}
	PtrAlloc() {
		if(!this.ptr)
			this.ptr := DllCall("HeapAlloc", "Ptr", DllCall("GetProcessHeap", "Ptr")
								, "UInt", 0, "UInt", this.allocSize, "Ptr")
	}
	PtrExtend() {
		if(this.ptr)
			this.allocSize += 16 * this.bufferSize
			this.ptr := DllCall("HeapReAlloc", "Ptr", DllCall("GetProcessHeap", "Ptr")
								, "UInt", 0, "Ptr",this.ptr, "UInt", this.allocSize, "Ptr")
	}
	PtrFree() {
		if(this.ptr)
			DllCall("HeapFree", "Ptr", DllCall("GetProcessHeap", "Ptr"), "UInt", 0, "Ptr", this.ptr)
	}
	Run(cmd, dir:="", encoding:="") {
		DllCall( "CreatePipe",           PtrP,hStdOutRd, PtrP,hStdOutWr, Ptr,0, UInt,0 )
		DllCall( "SetHandleInformation", Ptr,hStdOutWr, UInt,1, UInt,1                 )

				VarSetCapacity( pi, (A_PtrSize == 4) ? 16 : 24,  0 )
		siSz := VarSetCapacity( si, (A_PtrSize == 4) ? 68 : 104, 0 )
		NumPut( siSz,      si,  0,                          "UInt" )
		NumPut( 0x100,     si,  (A_PtrSize == 4) ? 44 : 60, "UInt" )
		NumPut( hStdInRd,  si,  (A_PtrSize == 4) ? 56 : 80, "Ptr"  )
		NumPut( hStdOutWr, si,  (A_PtrSize == 4) ? 60 : 88, "Ptr"  )
		NumPut( hStdOutWr, si,  (A_PtrSize == 4) ? 64 : 96, "Ptr"  )

		If ( !DllCall( "CreateProcess", Ptr,0, Ptr,&cmd, Ptr,0, Ptr,0, Int,True, UInt,0x08000000
									  , Ptr,0, Ptr,dir?&dir:0, Ptr,&si, Ptr,&pi ) )
			Return ""
		  , DllCall( "CloseHandle", Ptr,hStdOutWr )
		  , DllCall( "CloseHandle", Ptr,hStdOutRd )

		DllCall( "CloseHandle", Ptr,hStdOutWr ) ; The write pipe must be closed before reading the stdout.

		bytesRead := 0

		While(DllCall("ReadFile", "Ptr",hStdOutRd, "Ptr",this.ptr + bytesRead
						, "UInt",this.bufferSize, "PtrP",nSize, "Ptr",0 ))
		{
			bytesRead += nSize
			if(bytesRead + this.bufferSize > this.allocSize) { ; Alloc size exceed
				this.PtrExtend()
			}
		}

		this.size := bytesRead

		DllCall( "GetExitCodeProcess", Ptr,NumGet(pi,0), UIntP, exitCode )
		DllCall( "CloseHandle",        Ptr,NumGet(pi,0)                  )
		DllCall( "CloseHandle",        Ptr,NumGet(pi,A_PtrSize)          )
		DllCall( "CloseHandle",        Ptr,hStdOutRd                     )

		Return this
	}
	GetText(encoding:="CP65001") {
		if(this.ptr) {
			text := StrGet(this.ptr, this.size, encoding)
			return text
		}
	}
	GetPtrRaw() {
		if(this.ptr) {
			return this.ptr
		}
	}
	GetPtr() {
		if(this.ptr) {
			retPtr := DllCall("HeapAlloc", "Ptr", DllCall("GetProcessHeap", "Ptr")
								, "UInt", 0, "UInt", this.size, "Ptr")
			DllCall("RtlMoveMemory", "Ptr", retPtr, "Ptr", this.ptr, "UInt", this.size)
			return retPtr
		}
	}
}
