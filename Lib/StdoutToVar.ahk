Run_GetPtr(sCmd, sDir:="") {
	DllCall( "CreatePipe",           PtrP,hStdOutRd, PtrP,hStdOutWr, Ptr,0, UInt,0 )
	DllCall( "SetHandleInformation", Ptr,hStdOutWr, UInt,1, UInt,1                 )

			VarSetCapacity( pi, (A_PtrSize == 4) ? 16 : 24,  0 )
	siSz := VarSetCapacity( si, (A_PtrSize == 4) ? 68 : 104, 0 )
	NumPut( siSz,      si,  0,                          "UInt" )
	NumPut( 0x100,     si,  (A_PtrSize == 4) ? 44 : 60, "UInt" )
	NumPut( hStdInRd,  si,  (A_PtrSize == 4) ? 56 : 80, "Ptr"  )
	NumPut( hStdOutWr, si,  (A_PtrSize == 4) ? 60 : 88, "Ptr"  )
	NumPut( hStdOutWr, si,  (A_PtrSize == 4) ? 64 : 96, "Ptr"  )

	If ( !DllCall( "CreateProcess", Ptr,0, Ptr,&sCmd, Ptr,0, Ptr,0, Int,True, UInt,0x08000000
								  , Ptr,0, Ptr,sDir?&sDir:0, Ptr,&si, Ptr,&pi ) )
		Return ""
	  , DllCall( "CloseHandle", Ptr,hStdOutWr )
	  , DllCall( "CloseHandle", Ptr,hStdOutRd )

	DllCall( "CloseHandle", Ptr,hStdOutWr ) ; The write pipe must be closed before reading the stdout.

	bufferSize := 4096

	output := { }	;ptr, size, exitCode, text(if encoding)
	output.ptr := DllCall("HeapAlloc", "Ptr", DllCall("GetProcessHeap", "Ptr"), "UInt", 0, "UInt", bufferSize * 10, "Ptr")
	output.alloc := DllCall("HeapSize", "Ptr", DllCall("GetProcessHeap", "Ptr"), "UInt", 0, "Ptr", output.ptr, "UInt")

	bytesRead := 0

	While(DllCall("ReadFile", "Ptr",hStdOutRd, "Ptr",output.ptr+bytesRead, "UInt",bufferSize, "PtrP",nSize, "Ptr",0 ))
	{
		bytesRead += nSize
		if(bytesRead + bufferSize > output.alloc) { ; Alloc size exceed
			output.alloc += 10 * bufferSize
			output.ptr := DllCall("HeapReAlloc", "Ptr", DllCall("GetProcessHeap", "Ptr")
							, "UInt", 0, "Ptr", output.ptr, "UInt", output.alloc, "Ptr")
		}
	}

	DllCall( "GetExitCodeProcess", Ptr,NumGet(pi,0), UIntP, exitCode )
    DllCall( "CloseHandle",        Ptr,NumGet(pi,0)                  )
    DllCall( "CloseHandle",        Ptr,NumGet(pi,A_PtrSize)          )
    DllCall( "CloseHandle",        Ptr,hStdOutRd                     )
	output.size := bytesRead
	output.exitCode := exitCode

	Return output
}

Run_GetPtr2(sCmd, ByRef hData, sDir:="", ByRef nExitCode:=0) {
	DllCall( "CreatePipe",           PtrP,hStdOutRd, PtrP,hStdOutWr, Ptr,0, UInt,0 )
	DllCall( "SetHandleInformation", Ptr,hStdOutWr, UInt,1, UInt,1                 )

			VarSetCapacity( pi, (A_PtrSize == 4) ? 16 : 24,  0 )
	siSz := VarSetCapacity( si, (A_PtrSize == 4) ? 68 : 104, 0 )
	NumPut( siSz,      si,  0,                          "UInt" )
	NumPut( 0x100,     si,  (A_PtrSize == 4) ? 44 : 60, "UInt" )
	NumPut( hStdInRd,  si,  (A_PtrSize == 4) ? 56 : 80, "Ptr"  )
	NumPut( hStdOutWr, si,  (A_PtrSize == 4) ? 60 : 88, "Ptr"  )
	NumPut( hStdOutWr, si,  (A_PtrSize == 4) ? 64 : 96, "Ptr"  )

	If ( !DllCall( "CreateProcess", Ptr,0, Ptr,&sCmd, Ptr,0, Ptr,0, Int,True, UInt,0x08000000
								  , Ptr,0, Ptr,sDir?&sDir:0, Ptr,&si, Ptr,&pi ) )
		Return ""
	  , DllCall( "CloseHandle", Ptr,hStdOutWr )
	  , DllCall( "CloseHandle", Ptr,hStdOutRd )

	DllCall( "CloseHandle", Ptr,hStdOutWr ) ; The write pipe must be closed before reading the stdout.

	hSize := DllCall( "HeapSize", Ptr, DllCall("GetProcessHeap", Ptr), UInt, 0, Ptr, hData, UInt)

	bufferSize := 4096
	bytesRead := 0

	While(DllCall("ReadFile", Ptr,hStdOutRd, Ptr,hData+bytesRead, UInt,bufferSize, PtrP,nSize, Ptr,0 ))
	{
		bytesRead += nSize
		if(bytesRead + bufferSize > hSize) { ; Alloc size exceed
			hData := DllCall("HeapReAlloc", "Ptr", DllCall("GetProcessHeap", "Ptr"), "UInt", 0, "Ptr", hData, "UInt", hSize + 10 * bufferSize, "Ptr")
			Break
		}
	}

	DllCall( "GetExitCodeProcess", Ptr,NumGet(pi,0), UIntP,nExitCode )
    DllCall( "CloseHandle",        Ptr,NumGet(pi,0)                  )
    DllCall( "CloseHandle",        Ptr,NumGet(pi,A_PtrSize)          )
    DllCall( "CloseHandle",        Ptr,hStdOutRd                     )

	Return bytesRead
}

; StdoutToVar for binary stdout
;
; by upne at 2019-03-26
;
; hData must be pre-allocated with HeapAlloc
StdoutToVar_Blob(sCmd, hData, sEncoding:=0, sDir:="", ByRef nExitCode:=0) {
	DllCall( "CreatePipe",           PtrP,hStdOutRd, PtrP,hStdOutWr, Ptr,0, UInt,0 )
	DllCall( "SetHandleInformation", Ptr,hStdOutWr, UInt,1, UInt,1                 )

			VarSetCapacity( pi, (A_PtrSize == 4) ? 16 : 24,  0 )
	siSz := VarSetCapacity( si, (A_PtrSize == 4) ? 68 : 104, 0 )
	NumPut( siSz,      si,  0,                          "UInt" )
	NumPut( 0x100,     si,  (A_PtrSize == 4) ? 44 : 60, "UInt" )
	NumPut( hStdInRd,  si,  (A_PtrSize == 4) ? 56 : 80, "Ptr"  )
	NumPut( hStdOutWr, si,  (A_PtrSize == 4) ? 60 : 88, "Ptr"  )
	NumPut( hStdOutWr, si,  (A_PtrSize == 4) ? 64 : 96, "Ptr"  )

	If ( !DllCall( "CreateProcess", Ptr,0, Ptr,&sCmd, Ptr,0, Ptr,0, Int,True, UInt,0x08000000
								  , Ptr,0, Ptr,sDir?&sDir:0, Ptr,&si, Ptr,&pi ) )
		Return ""
	  , DllCall( "CloseHandle", Ptr,hStdOutWr )
	  , DllCall( "CloseHandle", Ptr,hStdOutRd )

	DllCall( "CloseHandle", Ptr,hStdOutWr ) ; The write pipe must be closed before reading the stdout.

	bufferSize := 4096
	hPtr := hData

	While(DllCall("ReadFile", Ptr,hStdOutRd, Ptr, hPtr, UInt, bufferSize, PtrP, nSize, Ptr,0 ))
		hPtr += nSize
	bytes := hPtr - hData

	DllCall( "GetExitCodeProcess", Ptr,NumGet(pi,0), UIntP,nExitCode )
    DllCall( "CloseHandle",        Ptr,NumGet(pi,0)                  )
    DllCall( "CloseHandle",        Ptr,NumGet(pi,A_PtrSize)          )
    DllCall( "CloseHandle",        Ptr,hStdOutRd                     )

	Return bytes
}


; ----------------------------------------------------------------------------------------------------------------------
; Function .....: StdoutToVar_CreateProcess
; Description ..: Runs a command line program and returns its output.
; Parameters ...: sCmd      - Commandline to execute.
; ..............: sEncoding - Encoding used by the target process. Look at StrGet() for possible values.
; ..............: sDir      - Working directory.
; ..............: nExitCode - Process exit code, receive it as a byref parameter.
; Return .......: Command output as a string on success, empty string on error.
; AHK Version ..: AHK_L x32/64 Unicode/ANSI
; Author .......: Sean (http://goo.gl/o3VCO8), modified by nfl and by Cyruz
; License ......: WTFPL - http://www.wtfpl.net/txt/copying/
; Changelog ....: Feb. 20, 2007 - Sean version.
; ..............: Sep. 21, 2011 - nfl version.
; ..............: Nov. 27, 2013 - Cyruz version (code refactored and exit code).
; ..............: Mar. 09, 2014 - Removed input, doesn't seem reliable. Some code improvements.
; ..............: Mar. 16, 2014 - Added encoding parameter as pointed out by lexikos.
; ..............: Jun. 02, 2014 - Corrected exit code error.
; ----------------------------------------------------------------------------------------------------------------------
StdoutToVar_CreateProcess(sCmd, sEncoding:="CP0", sDir:="", ByRef nExitCode:=0) {
    DllCall( "CreatePipe",           PtrP,hStdOutRd, PtrP,hStdOutWr, Ptr,0, UInt,0 )
    DllCall( "SetHandleInformation", Ptr,hStdOutWr, UInt,1, UInt,1                 )

            VarSetCapacity( pi, (A_PtrSize == 4) ? 16 : 24,  0 )
    siSz := VarSetCapacity( si, (A_PtrSize == 4) ? 68 : 104, 0 )
    NumPut( siSz,      si,  0,                          "UInt" )
    NumPut( 0x100,     si,  (A_PtrSize == 4) ? 44 : 60, "UInt" )
    NumPut( hStdInRd,  si,  (A_PtrSize == 4) ? 56 : 80, "Ptr"  )
    NumPut( hStdOutWr, si,  (A_PtrSize == 4) ? 60 : 88, "Ptr"  )
    NumPut( hStdOutWr, si,  (A_PtrSize == 4) ? 64 : 96, "Ptr"  )

    If ( !DllCall( "CreateProcess", Ptr,0, Ptr,&sCmd, Ptr,0, Ptr,0, Int,True, UInt,0x08000000
                                  , Ptr,0, Ptr,sDir?&sDir:0, Ptr,&si, Ptr,&pi ) )
        Return ""
      , DllCall( "CloseHandle", Ptr,hStdOutWr )
      , DllCall( "CloseHandle", Ptr,hStdOutRd )

    DllCall( "CloseHandle", Ptr,hStdOutWr ) ; The write pipe must be closed before reading the stdout.
    VarSetCapacity(sTemp, 4095)
    While ( DllCall( "ReadFile", Ptr,hStdOutRd, Ptr,&sTemp, UInt,4095, PtrP,nSize, Ptr,0 ) )
        sOutput .= StrGet(&sTemp, nSize, sEncoding)

    DllCall( "GetExitCodeProcess", Ptr,NumGet(pi,0), UIntP,nExitCode )
    DllCall( "CloseHandle",        Ptr,NumGet(pi,0)                  )
    DllCall( "CloseHandle",        Ptr,NumGet(pi,A_PtrSize)          )
    DllCall( "CloseHandle",        Ptr,hStdOutRd                     )
    Return sOutput
}
