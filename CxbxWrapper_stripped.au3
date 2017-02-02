Global Const $CB_ERR = -1
Global Const $CBS_AUTOHSCROLL = 0x40
Global Const $CBS_DROPDOWNLIST = 0x3
Global Const $CB_GETCOUNT = 0x146
Global Const $CB_GETLBTEXT = 0x148
Global Const $CB_GETLBTEXTLEN = 0x149
Global Const $ES_AUTOVSCROLL = 64
Global Const $ES_WANTRETURN = 4096
Global Const $GUI_EVENT_CLOSE = -3
Global Const $GUI_CHECKED = 1
Global Const $GUI_UNCHECKED = 4
Global Const $GUI_ENABLE = 64
Global Const $GUI_DISABLE = 128
Global Const $WS_MINIMIZEBOX = 0x00020000
Global Const $WS_GROUP = 0x00020000
Global Const $WS_SYSMENU = 0x00080000
Global Const $WS_VSCROLL = 0x00200000
Global Const $STR_NOCASESENSEBASIC = 2
Global Const $STR_STRIPLEADING = 1
Global Const $STR_STRIPTRAILING = 2
Global Const $STR_ENTIRESPLIT = 1
Global Const $STR_NOCOUNT = 2
Global Const $UBOUND_DIMENSIONS = 0
Global Const $UBOUND_ROWS = 1
Global Const $UBOUND_COLUMNS = 2
Global Const $OPEN_EXISTING = 3
Global Const $GENERIC_READ = 0x80000000
Global Const $FLTA_FILESFOLDERS = 0
Global Const $FLTAR_FILESFOLDERS = 0
Global Const $FLTAR_NORECUR = 0
Global Const $FLTAR_NOSORT = 0
Global Const $FLTAR_RELPATH = 1
Global Const $SE_PRIVILEGE_ENABLED = 0x00000002
Global Enum $SECURITYANONYMOUS = 0, $SECURITYIDENTIFICATION, $SECURITYIMPERSONATION, $SECURITYDELEGATION
Global Const $TOKEN_QUERY = 0x00000008
Global Const $TOKEN_ADJUST_PRIVILEGES = 0x00000020
Func _WinAPI_GetLastError(Const $_iCurrentError = @error, Const $_iCurrentExtended = @extended)
Local $aResult = DllCall("kernel32.dll", "dword", "GetLastError")
Return SetError($_iCurrentError, $_iCurrentExtended, $aResult[0])
EndFunc
Func _Security__AdjustTokenPrivileges($hToken, $bDisableAll, $tNewState, $iBufferLen, $tPrevState = 0, $pRequired = 0)
Local $aCall = DllCall("advapi32.dll", "bool", "AdjustTokenPrivileges", "handle", $hToken, "bool", $bDisableAll, "struct*", $tNewState, "dword", $iBufferLen, "struct*", $tPrevState, "struct*", $pRequired)
If @error Then Return SetError(@error, @extended, False)
Return Not($aCall[0] = 0)
EndFunc
Func _Security__ImpersonateSelf($iLevel = $SECURITYIMPERSONATION)
Local $aCall = DllCall("advapi32.dll", "bool", "ImpersonateSelf", "int", $iLevel)
If @error Then Return SetError(@error, @extended, False)
Return Not($aCall[0] = 0)
EndFunc
Func _Security__LookupPrivilegeValue($sSystem, $sName)
Local $aCall = DllCall("advapi32.dll", "bool", "LookupPrivilegeValueW", "wstr", $sSystem, "wstr", $sName, "int64*", 0)
If @error Or Not $aCall[0] Then Return SetError(@error, @extended, 0)
Return $aCall[3]
EndFunc
Func _Security__OpenThreadToken($iAccess, $hThread = 0, $bOpenAsSelf = False)
If $hThread = 0 Then
Local $aResult = DllCall("kernel32.dll", "handle", "GetCurrentThread")
If @error Then Return SetError(@error + 10, @extended, 0)
$hThread = $aResult[0]
EndIf
Local $aCall = DllCall("advapi32.dll", "bool", "OpenThreadToken", "handle", $hThread, "dword", $iAccess, "bool", $bOpenAsSelf, "handle*", 0)
If @error Or Not $aCall[0] Then Return SetError(@error, @extended, 0)
Return $aCall[4]
EndFunc
Func _Security__OpenThreadTokenEx($iAccess, $hThread = 0, $bOpenAsSelf = False)
Local $hToken = _Security__OpenThreadToken($iAccess, $hThread, $bOpenAsSelf)
If $hToken = 0 Then
Local Const $ERROR_NO_TOKEN = 1008
If _WinAPI_GetLastError() <> $ERROR_NO_TOKEN Then Return SetError(20, _WinAPI_GetLastError(), 0)
If Not _Security__ImpersonateSelf() Then Return SetError(@error + 10, _WinAPI_GetLastError(), 0)
$hToken = _Security__OpenThreadToken($iAccess, $hThread, $bOpenAsSelf)
If $hToken = 0 Then Return SetError(@error, _WinAPI_GetLastError(), 0)
EndIf
Return $hToken
EndFunc
Func _Security__SetPrivilege($hToken, $sPrivilege, $bEnable)
Local $iLUID = _Security__LookupPrivilegeValue("", $sPrivilege)
If $iLUID = 0 Then Return SetError(@error + 10, @extended, False)
Local Const $tagTOKEN_PRIVILEGES = "dword Count;align 4;int64 LUID;dword Attributes"
Local $tCurrState = DllStructCreate($tagTOKEN_PRIVILEGES)
Local $iCurrState = DllStructGetSize($tCurrState)
Local $tPrevState = DllStructCreate($tagTOKEN_PRIVILEGES)
Local $iPrevState = DllStructGetSize($tPrevState)
Local $tRequired = DllStructCreate("int Data")
DllStructSetData($tCurrState, "Count", 1)
DllStructSetData($tCurrState, "LUID", $iLUID)
If Not _Security__AdjustTokenPrivileges($hToken, False, $tCurrState, $iCurrState, $tPrevState, $tRequired) Then Return SetError(2, @error, False)
DllStructSetData($tPrevState, "Count", 1)
DllStructSetData($tPrevState, "LUID", $iLUID)
Local $iAttributes = DllStructGetData($tPrevState, "Attributes")
If $bEnable Then
$iAttributes = BitOR($iAttributes, $SE_PRIVILEGE_ENABLED)
Else
$iAttributes = BitAND($iAttributes, BitNOT($SE_PRIVILEGE_ENABLED))
EndIf
DllStructSetData($tPrevState, "Attributes", $iAttributes)
If Not _Security__AdjustTokenPrivileges($hToken, False, $tPrevState, $iPrevState, $tCurrState, $tRequired) Then Return SetError(3, @error, False)
Return True
EndFunc
Func _SendMessage($hWnd, $iMsg, $wParam = 0, $lParam = 0, $iReturn = 0, $wParamType = "wparam", $lParamType = "lparam", $sReturnType = "lresult")
Local $aResult = DllCall("user32.dll", $sReturnType, "SendMessageW", "hwnd", $hWnd, "uint", $iMsg, $wParamType, $wParam, $lParamType, $lParam)
If @error Then Return SetError(@error, @extended, "")
If $iReturn >= 0 And $iReturn <= 4 Then Return $aResult[$iReturn]
Return $aResult
EndFunc
Global Const $tagRECT = "struct;long Left;long Top;long Right;long Bottom;endstruct"
Global Const $tagREBARBANDINFO = "uint cbSize;uint fMask;uint fStyle;dword clrFore;dword clrBack;ptr lpText;uint cch;" & "int iImage;hwnd hwndChild;uint cxMinChild;uint cyMinChild;uint cx;handle hbmBack;uint wID;uint cyChild;uint cyMaxChild;" & "uint cyIntegral;uint cxIdeal;lparam lParam;uint cxHeader" &((@OSVersion = "WIN_XP") ? "" : ";" & $tagRECT & ";uint uChevronState")
Global Const $HGDI_ERROR = Ptr(-1)
Global Const $INVALID_HANDLE_VALUE = Ptr(-1)
Global Const $KF_EXTENDED = 0x0100
Global Const $KF_ALTDOWN = 0x2000
Global Const $KF_UP = 0x8000
Global Const $LLKHF_EXTENDED = BitShift($KF_EXTENDED, 8)
Global Const $LLKHF_ALTDOWN = BitShift($KF_ALTDOWN, 8)
Global Const $LLKHF_UP = BitShift($KF_UP, 8)
Func _WinAPI_CloseHandle($hObject)
Local $aResult = DllCall("kernel32.dll", "bool", "CloseHandle", "handle", $hObject)
If @error Then Return SetError(@error, @extended, False)
Return $aResult[0]
EndFunc
Func _WinAPI_OpenProcess($iAccess, $bInherit, $iPID, $bDebugPriv = False)
Local $aResult = DllCall("kernel32.dll", "handle", "OpenProcess", "dword", $iAccess, "bool", $bInherit, "dword", $iPID)
If @error Then Return SetError(@error, @extended, 0)
If $aResult[0] Then Return $aResult[0]
If Not $bDebugPriv Then Return SetError(100, 0, 0)
Local $hToken = _Security__OpenThreadTokenEx(BitOR($TOKEN_ADJUST_PRIVILEGES, $TOKEN_QUERY))
If @error Then Return SetError(@error + 10, @extended, 0)
_Security__SetPrivilege($hToken, "SeDebugPrivilege", True)
Local $iError = @error
Local $iExtended = @extended
Local $iRet = 0
If Not @error Then
$aResult = DllCall("kernel32.dll", "handle", "OpenProcess", "dword", $iAccess, "bool", $bInherit, "dword", $iPID)
$iError = @error
$iExtended = @extended
If $aResult[0] Then $iRet = $aResult[0]
_Security__SetPrivilege($hToken, "SeDebugPrivilege", False)
If @error Then
$iError = @error + 20
$iExtended = @extended
EndIf
Else
$iError = @error + 30
EndIf
_WinAPI_CloseHandle($hToken)
Return SetError($iError, $iExtended, $iRet)
EndFunc
Func _WinAPI_PathFindOnPath(Const $sFilePath, $aExtraPaths = "", Const $sPathDelimiter = @LF)
Local $iExtraCount = 0
If IsString($aExtraPaths) Then
If StringLen($aExtraPaths) Then
$aExtraPaths = StringSplit($aExtraPaths, $sPathDelimiter, $STR_ENTIRESPLIT + $STR_NOCOUNT)
$iExtraCount = UBound($aExtraPaths, $UBOUND_ROWS)
EndIf
ElseIf IsArray($aExtraPaths) Then
$iExtraCount = UBound($aExtraPaths)
EndIf
Local $tPaths, $tPathPtrs
If $iExtraCount Then
Local $tagStruct = ""
For $path In $aExtraPaths
$tagStruct &= "wchar[" & StringLen($path) + 1 & "];"
Next
$tPaths = DllStructCreate($tagStruct)
$tPathPtrs = DllStructCreate("ptr[" & $iExtraCount + 1 & "]")
For $i = 1 To $iExtraCount
DllStructSetData($tPaths, $i, $aExtraPaths[$i - 1])
DllStructSetData($tPathPtrs, 1, DllStructGetPtr($tPaths, $i), $i)
Next
DllStructSetData($tPathPtrs, 1, Ptr(0), $iExtraCount + 1)
EndIf
Local $aResult = DllCall("shlwapi.dll", "bool", "PathFindOnPathW", "wstr", $sFilePath, "struct*", $tPathPtrs)
If @error Or Not $aResult[0] Then Return SetError(@error + 10, @extended, $sFilePath)
Return $aResult[1]
EndFunc
Global Const $tagOSVERSIONINFO = 'struct;dword OSVersionInfoSize;dword MajorVersion;dword MinorVersion;dword BuildNumber;dword PlatformId;wchar CSDVersion[128];endstruct'
Global Const $__WINVER = __WINVER()
Func __Inc(ByRef $aData, $iIncrement = 100)
Select
Case UBound($aData, $UBOUND_COLUMNS)
If $iIncrement < 0 Then
ReDim $aData[$aData[0][0] + 1][UBound($aData, $UBOUND_COLUMNS)]
Else
$aData[0][0] += 1
If $aData[0][0] > UBound($aData) - 1 Then
ReDim $aData[$aData[0][0] + $iIncrement][UBound($aData, $UBOUND_COLUMNS)]
EndIf
EndIf
Case UBound($aData, $UBOUND_ROWS)
If $iIncrement < 0 Then
ReDim $aData[$aData[0] + 1]
Else
$aData[0] += 1
If $aData[0] > UBound($aData) - 1 Then
ReDim $aData[$aData[0] + $iIncrement]
EndIf
EndIf
Case Else
Return 0
EndSelect
Return 1
EndFunc
Func __Iif($bTest, $vTrue, $vFalse)
Return $bTest ? $vTrue : $vFalse
EndFunc
Func __WINVER()
Local $tOSVI = DllStructCreate($tagOSVERSIONINFO)
DllStructSetData($tOSVI, 1, DllStructGetSize($tOSVI))
Local $aRet = DllCall('kernel32.dll', 'bool', 'GetVersionExW', 'struct*', $tOSVI)
If @error Or Not $aRet[0] Then Return SetError(@error, @extended, 0)
Return BitOR(BitShift(DllStructGetData($tOSVI, 2), -8), DllStructGetData($tOSVI, 3))
EndFunc
Func _WinAPI_StrFormatByteSize($iSize)
Local $aRet = DllCall('shlwapi.dll', 'ptr', 'StrFormatByteSizeW', 'int64', $iSize, 'wstr', '', 'uint', 1024)
If @error Or Not $aRet[0] Then Return SetError(@error + 10, @extended, '')
Return $aRet[2]
EndFunc
Func _WinAPI_CreateFileEx($sFilePath, $iCreation, $iAccess = 0, $iShare = 0, $iFlagsAndAttributes = 0, $tSecurity = 0, $hTemplate = 0)
Local $aRet = DllCall('kernel32.dll', 'handle', 'CreateFileW', 'wstr', $sFilePath, 'dword', $iAccess, 'dword', $iShare, 'struct*', $tSecurity, 'dword', $iCreation, 'dword', $iFlagsAndAttributes, 'handle', $hTemplate)
If @error Then Return SetError(@error, @extended, 0)
If $aRet[0] = Ptr(-1) Then Return SetError(10, _WinAPI_GetLastError(), 0)
Return $aRet[0]
EndFunc
Func _WinAPI_FileInUse($sFilePath)
Local $hFile = _WinAPI_CreateFileEx($sFilePath, $OPEN_EXISTING, $GENERIC_READ)
If @error Then
If @extended = 32 Then Return 1
Return SetError(@error, @extended, 0)
EndIf
DllCall("kernel32.dll", "bool", "CloseHandle", "handle", $hFile)
Return 0
EndFunc
Func _WinAPI_Wow64EnableWow64FsRedirection($bEnable)
Local $aRet = DllCall('kernel32.dll', 'boolean', 'Wow64EnableWow64FsRedirection', 'boolean', $bEnable)
If @error Then Return SetError(@error, @extended, 0)
Return $aRet[0]
EndFunc
Global Const $tagPROCESSENTRY32 = 'dword Size;dword Usage;dword ProcessID;ulong_ptr DefaultHeapID;dword ModuleID;dword Threads;dword ParentProcessID;long PriClassBase;dword Flags;wchar ExeFile[260]'
Func _WinAPI_EnumChildProcess($iPID = 0)
If Not $iPID Then $iPID = @AutoItPID
Local $hSnapshot = DllCall('kernel32.dll', 'handle', 'CreateToolhelp32Snapshot', 'dword', 0x00000002, 'dword', 0)
If @error Or($hSnapshot[0] = Ptr(-1)) Then Return SetError(@error + 10, @extended, 0)
Local $tPROCESSENTRY32 = DllStructCreate($tagPROCESSENTRY32)
Local $aResult[101][2] = [[0]]
$hSnapshot = $hSnapshot[0]
DllStructSetData($tPROCESSENTRY32, 'Size', DllStructGetSize($tPROCESSENTRY32))
Local $aRet = DllCall('kernel32.dll', 'bool', 'Process32FirstW', 'handle', $hSnapshot, 'struct*', $tPROCESSENTRY32)
Local $iError = @error
While(Not @error) And($aRet[0])
If DllStructGetData($tPROCESSENTRY32, 'ParentProcessID') = $iPID Then
__Inc($aResult)
$aResult[$aResult[0][0]][0] = DllStructGetData($tPROCESSENTRY32, 'ProcessID')
$aResult[$aResult[0][0]][1] = DllStructGetData($tPROCESSENTRY32, 'ExeFile')
EndIf
$aRet = DllCall('kernel32.dll', 'bool', 'Process32NextW', 'handle', $hSnapshot, 'struct*', $tPROCESSENTRY32)
$iError = @error
WEnd
DllCall("kernel32.dll", "bool", "CloseHandle", "handle", $hSnapshot)
If Not $aResult[0][0] Then Return SetError($iError + 20, 0, 0)
__Inc($aResult, -1)
Return $aResult
EndFunc
Func _WinAPI_GetExitCodeProcess($hProcess)
Local $aRet = DllCall('kernel32.dll', 'bool', 'GetExitCodeProcess', 'handle', $hProcess, 'dword*', 0)
If @error Or Not $aRet[0] Then Return SetError(@error, @extended, 0)
Return $aRet[2]
EndFunc
Func _WinAPI_GetModuleFileNameEx($hProcess, $hModule = 0)
Local $aRet = DllCall(@SystemDir & '\psapi.dll', 'dword', 'GetModuleFileNameExW', 'handle', $hProcess, 'handle', $hModule, 'wstr', '', 'int', 4096)
If @error Or Not $aRet[0] Then Return SetError(@error + 10, @extended, '')
Return $aRet[3]
EndFunc
Func _WinAPI_GetParentProcess($iPID = 0)
If Not $iPID Then $iPID = @AutoItPID
Local $hSnapshot = DllCall('kernel32.dll', 'handle', 'CreateToolhelp32Snapshot', 'dword', 0x00000002, 'dword', 0)
If @error Or Not $hSnapshot[0] Then Return SetError(@error + 10, @extended, 0)
Local $tPROCESSENTRY32 = DllStructCreate($tagPROCESSENTRY32)
Local $iResult = 0
$hSnapshot = $hSnapshot[0]
DllStructSetData($tPROCESSENTRY32, 'Size', DllStructGetSize($tPROCESSENTRY32))
Local $aRet = DllCall('kernel32.dll', 'bool', 'Process32FirstW', 'handle', $hSnapshot, 'struct*', $tPROCESSENTRY32)
Local $iError = @error
While(Not @error) And($aRet[0])
If DllStructGetData($tPROCESSENTRY32, 'ProcessID') = $iPID Then
$iResult = DllStructGetData($tPROCESSENTRY32, 'ParentProcessID')
ExitLoop
EndIf
$aRet = DllCall('kernel32.dll', 'bool', 'Process32NextW', 'handle', $hSnapshot, 'struct*', $tPROCESSENTRY32)
$iError = @error
WEnd
DllCall("kernel32.dll", "bool", "CloseHandle", "handle", $hSnapshot)
If Not $iResult Then Return SetError($iError, 0, 0)
Return $iResult
EndFunc
Func _WinAPI_GetProcessFileName($iPID = 0)
If Not $iPID Then $iPID = @AutoItPID
Local $hProcess = DllCall('kernel32.dll', 'handle', 'OpenProcess', 'dword', __Iif($__WINVER < 0x0600, 0x00000410, 0x00001010), 'bool', 0, 'dword', $iPID)
If @error Or Not $hProcess[0] Then Return SetError(@error + 20, @extended, '')
Local $sPath = _WinAPI_GetModuleFileNameEx($hProcess[0])
Local $iError = @error
DllCall("kernel32.dll", "bool", "CloseHandle", "handle", $hProcess[0])
If $iError Then Return SetError(@error, 0, '')
Return $sPath
EndFunc
Func _WinAPI_GetProcessName($iPID = 0)
If Not $iPID Then $iPID = @AutoItPID
Local $hSnapshot = DllCall('kernel32.dll', 'handle', 'CreateToolhelp32Snapshot', 'dword', 0x00000002, 'dword', 0)
If @error Or Not $hSnapshot[0] Then Return SetError(@error + 20, @extended, '')
$hSnapshot = $hSnapshot[0]
Local $tPROCESSENTRY32 = DllStructCreate($tagPROCESSENTRY32)
DllStructSetData($tPROCESSENTRY32, 'Size', DllStructGetSize($tPROCESSENTRY32))
Local $aRet = DllCall('kernel32.dll', 'bool', 'Process32FirstW', 'handle', $hSnapshot, 'struct*', $tPROCESSENTRY32)
Local $iError = @error
While(Not @error) And($aRet[0])
If DllStructGetData($tPROCESSENTRY32, 'ProcessID') = $iPID Then
ExitLoop
EndIf
$aRet = DllCall('kernel32.dll', 'bool', 'Process32NextW', 'handle', $hSnapshot, 'struct*', $tPROCESSENTRY32)
$iError = @error
WEnd
DllCall("kernel32.dll", "bool", "CloseHandle", "handle", $hSnapshot)
If $iError Then Return SetError($iError, 0, '')
If Not $aRet[0] Then SetError(10, 0, '')
Return DllStructGetData($tPROCESSENTRY32, 'ExeFile')
EndFunc
Func _ArrayConcatenate(ByRef $aArrayTarget, Const ByRef $aArraySource, $iStart = 0)
If $iStart = Default Then $iStart = 0
If Not IsArray($aArrayTarget) Then Return SetError(1, 0, -1)
If Not IsArray($aArraySource) Then Return SetError(2, 0, -1)
Local $iDim_Total_Tgt = UBound($aArrayTarget, $UBOUND_DIMENSIONS)
Local $iDim_Total_Src = UBound($aArraySource, $UBOUND_DIMENSIONS)
Local $iDim_1_Tgt = UBound($aArrayTarget, $UBOUND_ROWS)
Local $iDim_1_Src = UBound($aArraySource, $UBOUND_ROWS)
If $iStart < 0 Or $iStart > $iDim_1_Src - 1 Then Return SetError(6, 0, -1)
Switch $iDim_Total_Tgt
Case 1
If $iDim_Total_Src <> 1 Then Return SetError(4, 0, -1)
ReDim $aArrayTarget[$iDim_1_Tgt + $iDim_1_Src - $iStart]
For $i = $iStart To $iDim_1_Src - 1
$aArrayTarget[$iDim_1_Tgt + $i - $iStart] = $aArraySource[$i]
Next
Case 2
If $iDim_Total_Src <> 2 Then Return SetError(4, 0, -1)
Local $iDim_2_Tgt = UBound($aArrayTarget, $UBOUND_COLUMNS)
If UBound($aArraySource, $UBOUND_COLUMNS) <> $iDim_2_Tgt Then Return SetError(5, 0, -1)
ReDim $aArrayTarget[$iDim_1_Tgt + $iDim_1_Src - $iStart][$iDim_2_Tgt]
For $i = $iStart To $iDim_1_Src - 1
For $j = 0 To $iDim_2_Tgt - 1
$aArrayTarget[$iDim_1_Tgt + $i - $iStart][$j] = $aArraySource[$i][$j]
Next
Next
Case Else
Return SetError(3, 0, -1)
EndSwitch
Return UBound($aArrayTarget, $UBOUND_ROWS)
EndFunc
Func __ArrayDualPivotSort(ByRef $aArray, $iPivot_Left, $iPivot_Right, $bLeftMost = True)
If $iPivot_Left > $iPivot_Right Then Return
Local $iLength = $iPivot_Right - $iPivot_Left + 1
Local $i, $j, $k, $iAi, $iAk, $iA1, $iA2, $iLast
If $iLength < 45 Then
If $bLeftMost Then
$i = $iPivot_Left
While $i < $iPivot_Right
$j = $i
$iAi = $aArray[$i + 1]
While $iAi < $aArray[$j]
$aArray[$j + 1] = $aArray[$j]
$j -= 1
If $j + 1 = $iPivot_Left Then ExitLoop
WEnd
$aArray[$j + 1] = $iAi
$i += 1
WEnd
Else
While 1
If $iPivot_Left >= $iPivot_Right Then Return 1
$iPivot_Left += 1
If $aArray[$iPivot_Left] < $aArray[$iPivot_Left - 1] Then ExitLoop
WEnd
While 1
$k = $iPivot_Left
$iPivot_Left += 1
If $iPivot_Left > $iPivot_Right Then ExitLoop
$iA1 = $aArray[$k]
$iA2 = $aArray[$iPivot_Left]
If $iA1 < $iA2 Then
$iA2 = $iA1
$iA1 = $aArray[$iPivot_Left]
EndIf
$k -= 1
While $iA1 < $aArray[$k]
$aArray[$k + 2] = $aArray[$k]
$k -= 1
WEnd
$aArray[$k + 2] = $iA1
While $iA2 < $aArray[$k]
$aArray[$k + 1] = $aArray[$k]
$k -= 1
WEnd
$aArray[$k + 1] = $iA2
$iPivot_Left += 1
WEnd
$iLast = $aArray[$iPivot_Right]
$iPivot_Right -= 1
While $iLast < $aArray[$iPivot_Right]
$aArray[$iPivot_Right + 1] = $aArray[$iPivot_Right]
$iPivot_Right -= 1
WEnd
$aArray[$iPivot_Right + 1] = $iLast
EndIf
Return 1
EndIf
Local $iSeventh = BitShift($iLength, 3) + BitShift($iLength, 6) + 1
Local $iE1, $iE2, $iE3, $iE4, $iE5, $t
$iE3 = Ceiling(($iPivot_Left + $iPivot_Right) / 2)
$iE2 = $iE3 - $iSeventh
$iE1 = $iE2 - $iSeventh
$iE4 = $iE3 + $iSeventh
$iE5 = $iE4 + $iSeventh
If $aArray[$iE2] < $aArray[$iE1] Then
$t = $aArray[$iE2]
$aArray[$iE2] = $aArray[$iE1]
$aArray[$iE1] = $t
EndIf
If $aArray[$iE3] < $aArray[$iE2] Then
$t = $aArray[$iE3]
$aArray[$iE3] = $aArray[$iE2]
$aArray[$iE2] = $t
If $t < $aArray[$iE1] Then
$aArray[$iE2] = $aArray[$iE1]
$aArray[$iE1] = $t
EndIf
EndIf
If $aArray[$iE4] < $aArray[$iE3] Then
$t = $aArray[$iE4]
$aArray[$iE4] = $aArray[$iE3]
$aArray[$iE3] = $t
If $t < $aArray[$iE2] Then
$aArray[$iE3] = $aArray[$iE2]
$aArray[$iE2] = $t
If $t < $aArray[$iE1] Then
$aArray[$iE2] = $aArray[$iE1]
$aArray[$iE1] = $t
EndIf
EndIf
EndIf
If $aArray[$iE5] < $aArray[$iE4] Then
$t = $aArray[$iE5]
$aArray[$iE5] = $aArray[$iE4]
$aArray[$iE4] = $t
If $t < $aArray[$iE3] Then
$aArray[$iE4] = $aArray[$iE3]
$aArray[$iE3] = $t
If $t < $aArray[$iE2] Then
$aArray[$iE3] = $aArray[$iE2]
$aArray[$iE2] = $t
If $t < $aArray[$iE1] Then
$aArray[$iE2] = $aArray[$iE1]
$aArray[$iE1] = $t
EndIf
EndIf
EndIf
EndIf
Local $iLess = $iPivot_Left
Local $iGreater = $iPivot_Right
If(($aArray[$iE1] <> $aArray[$iE2]) And($aArray[$iE2] <> $aArray[$iE3]) And($aArray[$iE3] <> $aArray[$iE4]) And($aArray[$iE4] <> $aArray[$iE5])) Then
Local $iPivot_1 = $aArray[$iE2]
Local $iPivot_2 = $aArray[$iE4]
$aArray[$iE2] = $aArray[$iPivot_Left]
$aArray[$iE4] = $aArray[$iPivot_Right]
Do
$iLess += 1
Until $aArray[$iLess] >= $iPivot_1
Do
$iGreater -= 1
Until $aArray[$iGreater] <= $iPivot_2
$k = $iLess
While $k <= $iGreater
$iAk = $aArray[$k]
If $iAk < $iPivot_1 Then
$aArray[$k] = $aArray[$iLess]
$aArray[$iLess] = $iAk
$iLess += 1
ElseIf $iAk > $iPivot_2 Then
While $aArray[$iGreater] > $iPivot_2
$iGreater -= 1
If $iGreater + 1 = $k Then ExitLoop 2
WEnd
If $aArray[$iGreater] < $iPivot_1 Then
$aArray[$k] = $aArray[$iLess]
$aArray[$iLess] = $aArray[$iGreater]
$iLess += 1
Else
$aArray[$k] = $aArray[$iGreater]
EndIf
$aArray[$iGreater] = $iAk
$iGreater -= 1
EndIf
$k += 1
WEnd
$aArray[$iPivot_Left] = $aArray[$iLess - 1]
$aArray[$iLess - 1] = $iPivot_1
$aArray[$iPivot_Right] = $aArray[$iGreater + 1]
$aArray[$iGreater + 1] = $iPivot_2
__ArrayDualPivotSort($aArray, $iPivot_Left, $iLess - 2, True)
__ArrayDualPivotSort($aArray, $iGreater + 2, $iPivot_Right, False)
If($iLess < $iE1) And($iE5 < $iGreater) Then
While $aArray[$iLess] = $iPivot_1
$iLess += 1
WEnd
While $aArray[$iGreater] = $iPivot_2
$iGreater -= 1
WEnd
$k = $iLess
While $k <= $iGreater
$iAk = $aArray[$k]
If $iAk = $iPivot_1 Then
$aArray[$k] = $aArray[$iLess]
$aArray[$iLess] = $iAk
$iLess += 1
ElseIf $iAk = $iPivot_2 Then
While $aArray[$iGreater] = $iPivot_2
$iGreater -= 1
If $iGreater + 1 = $k Then ExitLoop 2
WEnd
If $aArray[$iGreater] = $iPivot_1 Then
$aArray[$k] = $aArray[$iLess]
$aArray[$iLess] = $iPivot_1
$iLess += 1
Else
$aArray[$k] = $aArray[$iGreater]
EndIf
$aArray[$iGreater] = $iAk
$iGreater -= 1
EndIf
$k += 1
WEnd
EndIf
__ArrayDualPivotSort($aArray, $iLess, $iGreater, False)
Else
Local $iPivot = $aArray[$iE3]
$k = $iLess
While $k <= $iGreater
If $aArray[$k] = $iPivot Then
$k += 1
ContinueLoop
EndIf
$iAk = $aArray[$k]
If $iAk < $iPivot Then
$aArray[$k] = $aArray[$iLess]
$aArray[$iLess] = $iAk
$iLess += 1
Else
While $aArray[$iGreater] > $iPivot
$iGreater -= 1
WEnd
If $aArray[$iGreater] < $iPivot Then
$aArray[$k] = $aArray[$iLess]
$aArray[$iLess] = $aArray[$iGreater]
$iLess += 1
Else
$aArray[$k] = $iPivot
EndIf
$aArray[$iGreater] = $iAk
$iGreater -= 1
EndIf
$k += 1
WEnd
__ArrayDualPivotSort($aArray, $iPivot_Left, $iLess - 1, True)
__ArrayDualPivotSort($aArray, $iGreater + 1, $iPivot_Right, False)
EndIf
EndFunc
Func _ArrayToString(Const ByRef $aArray, $sDelim_Col = "|", $iStart_Row = -1, $iEnd_Row = -1, $sDelim_Row = @CRLF, $iStart_Col = -1, $iEnd_Col = -1)
If $sDelim_Col = Default Then $sDelim_Col = "|"
If $sDelim_Row = Default Then $sDelim_Row = @CRLF
If $iStart_Row = Default Then $iStart_Row = -1
If $iEnd_Row = Default Then $iEnd_Row = -1
If $iStart_Col = Default Then $iStart_Col = -1
If $iEnd_Col = Default Then $iEnd_Col = -1
If Not IsArray($aArray) Then Return SetError(1, 0, -1)
Local $iDim_1 = UBound($aArray, $UBOUND_ROWS) - 1
If $iStart_Row = -1 Then $iStart_Row = 0
If $iEnd_Row = -1 Then $iEnd_Row = $iDim_1
If $iStart_Row < -1 Or $iEnd_Row < -1 Then Return SetError(3, 0, -1)
If $iStart_Row > $iDim_1 Or $iEnd_Row > $iDim_1 Then Return SetError(3, 0, "")
If $iStart_Row > $iEnd_Row Then Return SetError(4, 0, -1)
Local $sRet = ""
Switch UBound($aArray, $UBOUND_DIMENSIONS)
Case 1
For $i = $iStart_Row To $iEnd_Row
$sRet &= $aArray[$i] & $sDelim_Col
Next
Return StringTrimRight($sRet, StringLen($sDelim_Col))
Case 2
Local $iDim_2 = UBound($aArray, $UBOUND_COLUMNS) - 1
If $iStart_Col = -1 Then $iStart_Col = 0
If $iEnd_Col = -1 Then $iEnd_Col = $iDim_2
If $iStart_Col < -1 Or $iEnd_Col < -1 Then Return SetError(5, 0, -1)
If $iStart_Col > $iDim_2 Or $iEnd_Col > $iDim_2 Then Return SetError(5, 0, -1)
If $iStart_Col > $iEnd_Col Then Return SetError(6, 0, -1)
For $i = $iStart_Row To $iEnd_Row
For $j = $iStart_Col To $iEnd_Col
$sRet &= $aArray[$i][$j] & $sDelim_Col
Next
$sRet = StringTrimRight($sRet, StringLen($sDelim_Col)) & $sDelim_Row
Next
Return StringTrimRight($sRet, StringLen($sDelim_Row))
Case Else
Return SetError(2, 0, -1)
EndSwitch
Return 1
EndFunc
Func _FileListToArray($sFilePath, $sFilter = "*", $iFlag = $FLTA_FILESFOLDERS, $bReturnPath = False)
Local $sDelimiter = "|", $sFileList = "", $sFileName = "", $sFullPath = ""
$sFilePath = StringRegExpReplace($sFilePath, "[\\/]+$", "") & "\"
If $iFlag = Default Then $iFlag = $FLTA_FILESFOLDERS
If $bReturnPath Then $sFullPath = $sFilePath
If $sFilter = Default Then $sFilter = "*"
If Not FileExists($sFilePath) Then Return SetError(1, 0, 0)
If StringRegExp($sFilter, "[\\/:><\|]|(?s)^\s*$") Then Return SetError(2, 0, 0)
If Not($iFlag = 0 Or $iFlag = 1 Or $iFlag = 2) Then Return SetError(3, 0, 0)
Local $hSearch = FileFindFirstFile($sFilePath & $sFilter)
If @error Then Return SetError(4, 0, 0)
While 1
$sFileName = FileFindNextFile($hSearch)
If @error Then ExitLoop
If($iFlag + @extended = 2) Then ContinueLoop
$sFileList &= $sDelimiter & $sFullPath & $sFileName
WEnd
FileClose($hSearch)
If $sFileList = "" Then Return SetError(4, 0, 0)
Return StringSplit(StringTrimLeft($sFileList, 1), $sDelimiter)
EndFunc
Func _FileListToArrayRec($sFilePath, $sMask = "*", $iReturn = $FLTAR_FILESFOLDERS, $iRecur = $FLTAR_NORECUR, $iSort = $FLTAR_NOSORT, $iReturnPath = $FLTAR_RELPATH)
If Not FileExists($sFilePath) Then Return SetError(1, 1, "")
If $sMask = Default Then $sMask = "*"
If $iReturn = Default Then $iReturn = $FLTAR_FILESFOLDERS
If $iRecur = Default Then $iRecur = $FLTAR_NORECUR
If $iSort = Default Then $iSort = $FLTAR_NOSORT
If $iReturnPath = Default Then $iReturnPath = $FLTAR_RELPATH
If $iRecur > 1 Or Not IsInt($iRecur) Then Return SetError(1, 6, "")
Local $bLongPath = False
If StringLeft($sFilePath, 4) == "\\?\" Then
$bLongPath = True
EndIf
Local $sFolderSlash = ""
If StringRight($sFilePath, 1) = "\" Then
$sFolderSlash = "\"
Else
$sFilePath = $sFilePath & "\"
EndIf
Local $asFolderSearchList[100] = [1]
$asFolderSearchList[1] = $sFilePath
Local $iHide_HS = 0, $sHide_HS = ""
If BitAND($iReturn, 4) Then
$iHide_HS += 2
$sHide_HS &= "H"
$iReturn -= 4
EndIf
If BitAND($iReturn, 8) Then
$iHide_HS += 4
$sHide_HS &= "S"
$iReturn -= 8
EndIf
Local $iHide_Link = 0
If BitAND($iReturn, 16) Then
$iHide_Link = 0x400
$iReturn -= 16
EndIf
Local $iMaxLevel = 0
If $iRecur < 0 Then
StringReplace($sFilePath, "\", "", 0, $STR_NOCASESENSEBASIC)
$iMaxLevel = @extended - $iRecur
EndIf
Local $sExclude_List = "", $sExclude_List_Folder = "", $sInclude_List = "*"
Local $aMaskSplit = StringSplit($sMask, "|")
Switch $aMaskSplit[0]
Case 3
$sExclude_List_Folder = $aMaskSplit[3]
ContinueCase
Case 2
$sExclude_List = $aMaskSplit[2]
ContinueCase
Case 1
$sInclude_List = $aMaskSplit[1]
EndSwitch
Local $sInclude_File_Mask = ".+"
If $sInclude_List <> "*" Then
If Not __FLTAR_ListToMask($sInclude_File_Mask, $sInclude_List) Then Return SetError(1, 2, "")
EndIf
Local $sInclude_Folder_Mask = ".+"
Switch $iReturn
Case 0
Switch $iRecur
Case 0
$sInclude_Folder_Mask = $sInclude_File_Mask
EndSwitch
Case 2
$sInclude_Folder_Mask = $sInclude_File_Mask
EndSwitch
Local $sExclude_File_Mask = ":"
If $sExclude_List <> "" Then
If Not __FLTAR_ListToMask($sExclude_File_Mask, $sExclude_List) Then Return SetError(1, 3, "")
EndIf
Local $sExclude_Folder_Mask = ":"
If $iRecur Then
If $sExclude_List_Folder Then
If Not __FLTAR_ListToMask($sExclude_Folder_Mask, $sExclude_List_Folder) Then Return SetError(1, 4, "")
EndIf
If $iReturn = 2 Then
$sExclude_Folder_Mask = $sExclude_File_Mask
EndIf
Else
$sExclude_Folder_Mask = $sExclude_File_Mask
EndIf
If Not($iReturn = 0 Or $iReturn = 1 Or $iReturn = 2) Then Return SetError(1, 5, "")
If Not($iSort = 0 Or $iSort = 1 Or $iSort = 2) Then Return SetError(1, 7, "")
If Not($iReturnPath = 0 Or $iReturnPath = 1 Or $iReturnPath = 2) Then Return SetError(1, 8, "")
If $iHide_Link Then
Local $tFile_Data = DllStructCreate("struct;align 4;dword FileAttributes;uint64 CreationTime;uint64 LastAccessTime;uint64 LastWriteTime;" & "dword FileSizeHigh;dword FileSizeLow;dword Reserved0;dword Reserved1;wchar FileName[260];wchar AlternateFileName[14];endstruct")
Local $hDLL = DllOpen('kernel32.dll'), $aDLL_Ret
EndIf
Local $asReturnList[100] = [0]
Local $asFileMatchList = $asReturnList, $asRootFileMatchList = $asReturnList, $asFolderMatchList = $asReturnList
Local $bFolder = False, $hSearch = 0, $sCurrentPath = "", $sName = "", $sRetPath = ""
Local $iAttribs = 0, $sAttribs = ''
Local $asFolderFileSectionList[100][2] = [[0, 0]]
While $asFolderSearchList[0] > 0
$sCurrentPath = $asFolderSearchList[$asFolderSearchList[0]]
$asFolderSearchList[0] -= 1
Switch $iReturnPath
Case 1
$sRetPath = StringReplace($sCurrentPath, $sFilePath, "")
Case 2
If $bLongPath Then
$sRetPath = StringTrimLeft($sCurrentPath, 4)
Else
$sRetPath = $sCurrentPath
EndIf
EndSwitch
If $iHide_Link Then
$aDLL_Ret = DllCall($hDLL, 'handle', 'FindFirstFileW', 'wstr', $sCurrentPath & "*", 'struct*', $tFile_Data)
If @error Or Not $aDLL_Ret[0] Then
ContinueLoop
EndIf
$hSearch = $aDLL_Ret[0]
Else
$hSearch = FileFindFirstFile($sCurrentPath & "*")
If $hSearch = -1 Then
ContinueLoop
EndIf
EndIf
If $iReturn = 0 And $iSort And $iReturnPath Then
__FLTAR_AddToList($asFolderFileSectionList, $sRetPath, $asFileMatchList[0] + 1)
EndIf
$sAttribs = ''
While 1
If $iHide_Link Then
$aDLL_Ret = DllCall($hDLL, 'int', 'FindNextFileW', 'handle', $hSearch, 'struct*', $tFile_Data)
If @error Or Not $aDLL_Ret[0] Then
ExitLoop
EndIf
$sName = DllStructGetData($tFile_Data, "FileName")
If $sName = ".." Then
ContinueLoop
EndIf
$iAttribs = DllStructGetData($tFile_Data, "FileAttributes")
If $iHide_HS And BitAND($iAttribs, $iHide_HS) Then
ContinueLoop
EndIf
If BitAND($iAttribs, $iHide_Link) Then
ContinueLoop
EndIf
$bFolder = False
If BitAND($iAttribs, 16) Then
$bFolder = True
EndIf
Else
$bFolder = False
$sName = FileFindNextFile($hSearch, 1)
If @error Then
ExitLoop
EndIf
$sAttribs = @extended
If StringInStr($sAttribs, "D") Then
$bFolder = True
EndIf
If StringRegExp($sAttribs, "[" & $sHide_HS & "]") Then
ContinueLoop
EndIf
EndIf
If $bFolder Then
Select
Case $iRecur < 0
StringReplace($sCurrentPath, "\", "", 0, $STR_NOCASESENSEBASIC)
If @extended < $iMaxLevel Then
ContinueCase
EndIf
Case $iRecur = 1
If Not StringRegExp($sName, $sExclude_Folder_Mask) Then
__FLTAR_AddToList($asFolderSearchList, $sCurrentPath & $sName & "\")
EndIf
EndSelect
EndIf
If $iSort Then
If $bFolder Then
If StringRegExp($sName, $sInclude_Folder_Mask) And Not StringRegExp($sName, $sExclude_Folder_Mask) Then
__FLTAR_AddToList($asFolderMatchList, $sRetPath & $sName & $sFolderSlash)
EndIf
Else
If StringRegExp($sName, $sInclude_File_Mask) And Not StringRegExp($sName, $sExclude_File_Mask) Then
If $sCurrentPath = $sFilePath Then
__FLTAR_AddToList($asRootFileMatchList, $sRetPath & $sName)
Else
__FLTAR_AddToList($asFileMatchList, $sRetPath & $sName)
EndIf
EndIf
EndIf
Else
If $bFolder Then
If $iReturn <> 1 And StringRegExp($sName, $sInclude_Folder_Mask) And Not StringRegExp($sName, $sExclude_Folder_Mask) Then
__FLTAR_AddToList($asReturnList, $sRetPath & $sName & $sFolderSlash)
EndIf
Else
If $iReturn <> 2 And StringRegExp($sName, $sInclude_File_Mask) And Not StringRegExp($sName, $sExclude_File_Mask) Then
__FLTAR_AddToList($asReturnList, $sRetPath & $sName)
EndIf
EndIf
EndIf
WEnd
If $iHide_Link Then
DllCall($hDLL, 'int', 'FindClose', 'ptr', $hSearch)
Else
FileClose($hSearch)
EndIf
WEnd
If $iHide_Link Then
DllClose($hDLL)
EndIf
If $iSort Then
Switch $iReturn
Case 2
If $asFolderMatchList[0] = 0 Then Return SetError(1, 9, "")
ReDim $asFolderMatchList[$asFolderMatchList[0] + 1]
$asReturnList = $asFolderMatchList
__ArrayDualPivotSort($asReturnList, 1, $asReturnList[0])
Case 1
If $asRootFileMatchList[0] = 0 And $asFileMatchList[0] = 0 Then Return SetError(1, 9, "")
If $iReturnPath = 0 Then
__FLTAR_AddFileLists($asReturnList, $asRootFileMatchList, $asFileMatchList)
__ArrayDualPivotSort($asReturnList, 1, $asReturnList[0])
Else
__FLTAR_AddFileLists($asReturnList, $asRootFileMatchList, $asFileMatchList, 1)
EndIf
Case 0
If $asRootFileMatchList[0] = 0 And $asFolderMatchList[0] = 0 Then Return SetError(1, 9, "")
If $iReturnPath = 0 Then
__FLTAR_AddFileLists($asReturnList, $asRootFileMatchList, $asFileMatchList)
$asReturnList[0] += $asFolderMatchList[0]
ReDim $asFolderMatchList[$asFolderMatchList[0] + 1]
_ArrayConcatenate($asReturnList, $asFolderMatchList, 1)
__ArrayDualPivotSort($asReturnList, 1, $asReturnList[0])
Else
Local $asReturnList[$asFileMatchList[0] + $asRootFileMatchList[0] + $asFolderMatchList[0] + 1]
$asReturnList[0] = $asFileMatchList[0] + $asRootFileMatchList[0] + $asFolderMatchList[0]
__ArrayDualPivotSort($asRootFileMatchList, 1, $asRootFileMatchList[0])
For $i = 1 To $asRootFileMatchList[0]
$asReturnList[$i] = $asRootFileMatchList[$i]
Next
Local $iNextInsertionIndex = $asRootFileMatchList[0] + 1
__ArrayDualPivotSort($asFolderMatchList, 1, $asFolderMatchList[0])
Local $sFolderToFind = ""
For $i = 1 To $asFolderMatchList[0]
$asReturnList[$iNextInsertionIndex] = $asFolderMatchList[$i]
$iNextInsertionIndex += 1
If $sFolderSlash Then
$sFolderToFind = $asFolderMatchList[$i]
Else
$sFolderToFind = $asFolderMatchList[$i] & "\"
EndIf
Local $iFileSectionEndIndex = 0, $iFileSectionStartIndex = 0
For $j = 1 To $asFolderFileSectionList[0][0]
If $sFolderToFind = $asFolderFileSectionList[$j][0] Then
$iFileSectionStartIndex = $asFolderFileSectionList[$j][1]
If $j = $asFolderFileSectionList[0][0] Then
$iFileSectionEndIndex = $asFileMatchList[0]
Else
$iFileSectionEndIndex = $asFolderFileSectionList[$j + 1][1] - 1
EndIf
If $iSort = 1 Then
__ArrayDualPivotSort($asFileMatchList, $iFileSectionStartIndex, $iFileSectionEndIndex)
EndIf
For $k = $iFileSectionStartIndex To $iFileSectionEndIndex
$asReturnList[$iNextInsertionIndex] = $asFileMatchList[$k]
$iNextInsertionIndex += 1
Next
ExitLoop
EndIf
Next
Next
EndIf
EndSwitch
Else
If $asReturnList[0] = 0 Then Return SetError(1, 9, "")
ReDim $asReturnList[$asReturnList[0] + 1]
EndIf
Return $asReturnList
EndFunc
Func __FLTAR_AddFileLists(ByRef $asTarget, $asSource_1, $asSource_2, $iSort = 0)
ReDim $asSource_1[$asSource_1[0] + 1]
If $iSort = 1 Then __ArrayDualPivotSort($asSource_1, 1, $asSource_1[0])
$asTarget = $asSource_1
$asTarget[0] += $asSource_2[0]
ReDim $asSource_2[$asSource_2[0] + 1]
If $iSort = 1 Then __ArrayDualPivotSort($asSource_2, 1, $asSource_2[0])
_ArrayConcatenate($asTarget, $asSource_2, 1)
EndFunc
Func __FLTAR_AddToList(ByRef $aList, $vValue_0, $vValue_1 = -1)
If $vValue_1 = -1 Then
$aList[0] += 1
If UBound($aList) <= $aList[0] Then ReDim $aList[UBound($aList) * 2]
$aList[$aList[0]] = $vValue_0
Else
$aList[0][0] += 1
If UBound($aList) <= $aList[0][0] Then ReDim $aList[UBound($aList) * 2][2]
$aList[$aList[0][0]][0] = $vValue_0
$aList[$aList[0][0]][1] = $vValue_1
EndIf
EndFunc
Func __FLTAR_ListToMask(ByRef $sMask, $sList)
If StringRegExp($sList, "\\|/|:|\<|\>|\|") Then Return 0
$sList = StringReplace(StringStripWS(StringRegExpReplace($sList, "\s*;\s*", ";"), $STR_STRIPLEADING + $STR_STRIPTRAILING), ";", "|")
$sList = StringReplace(StringReplace(StringRegExpReplace($sList, "[][$^.{}()+\-]", "\\$0"), "?", "."), "*", ".*?")
$sMask = "(?i)^(" & $sList & ")\z"
Return 1
EndFunc
Global Const $PROCESS_QUERY_INFORMATION = 0x00000400
Func _GUICtrlComboBox_GetCount($hWnd)
If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
Return _SendMessage($hWnd, $CB_GETCOUNT)
EndFunc
Func _GUICtrlComboBox_GetLBText($hWnd, $iIndex, ByRef $sText)
If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
Local $iLen = _GUICtrlComboBox_GetLBTextLen($hWnd, $iIndex)
Local $tBuffer = DllStructCreate("wchar Text[" & $iLen + 1 & "]")
Local $iRet = _SendMessage($hWnd, $CB_GETLBTEXT, $iIndex, $tBuffer, 0, "wparam", "struct*")
If($iRet == $CB_ERR) Then Return SetError($CB_ERR, $CB_ERR, $CB_ERR)
$sText = DllStructGetData($tBuffer, "Text")
Return $iRet
EndFunc
Func _GUICtrlComboBox_GetLBTextLen($hWnd, $iIndex)
If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
Return _SendMessage($hWnd, $CB_GETLBTEXTLEN, $iIndex)
EndFunc
Func _GUICtrlComboBox_GetList($hWnd)
If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
Local $sDelimiter = Opt("GUIDataSeparatorChar")
Local $sResult = "", $sItem
For $i = 0 To _GUICtrlComboBox_GetCount($hWnd) - 1
_GUICtrlComboBox_GetLBText($hWnd, $i, $sItem)
$sResult &= $sItem & $sDelimiter
Next
Return StringTrimRight($sResult, StringLen($sDelimiter))
EndFunc
Func _GUICtrlComboBox_GetListArray($hWnd)
If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
Local $sDelimiter = Opt("GUIDataSeparatorChar")
Return StringSplit(_GUICtrlComboBox_GetList($hWnd), $sDelimiter)
EndFunc
Global Const $MEM_COMMIT = 0x00001000
Global Const $PAGE_EXECUTE_READWRITE = 0x00000040
Global Const $MEM_RELEASE = 0x00008000
Func _MemVirtualAlloc($pAddress, $iSize, $iAllocation, $iProtect)
Local $aResult = DllCall("kernel32.dll", "ptr", "VirtualAlloc", "ptr", $pAddress, "ulong_ptr", $iSize, "dword", $iAllocation, "dword", $iProtect)
If @error Then Return SetError(@error, @extended, 0)
Return $aResult[0]
EndFunc
Func _MemVirtualFree($pAddress, $iSize, $iFreeType)
Local $aResult = DllCall("kernel32.dll", "bool", "VirtualFree", "ptr", $pAddress, "ulong_ptr", $iSize, "dword", $iFreeType)
If @error Then Return SetError(@error, @extended, False)
Return $aResult[0]
EndFunc
Func _DateAdd($sType, $iNumber, $sDate)
Local $asTimePart[4]
Local $asDatePart[4]
Local $iJulianDate
$sType = StringLeft($sType, 1)
If StringInStr("D,M,Y,w,h,n,s", $sType) = 0 Or $sType = "" Then
Return SetError(1, 0, 0)
EndIf
If Not StringIsInt($iNumber) Then
Return SetError(2, 0, 0)
EndIf
If Not _DateIsValid($sDate) Then
Return SetError(3, 0, 0)
EndIf
_DateTimeSplit($sDate, $asDatePart, $asTimePart)
If $sType = "d" Or $sType = "w" Then
If $sType = "w" Then $iNumber = $iNumber * 7
$iJulianDate = _DateToDayValue($asDatePart[1], $asDatePart[2], $asDatePart[3]) + $iNumber
_DayValueToDate($iJulianDate, $asDatePart[1], $asDatePart[2], $asDatePart[3])
EndIf
If $sType = "m" Then
$asDatePart[2] = $asDatePart[2] + $iNumber
While $asDatePart[2] > 12
$asDatePart[2] = $asDatePart[2] - 12
$asDatePart[1] = $asDatePart[1] + 1
WEnd
While $asDatePart[2] < 1
$asDatePart[2] = $asDatePart[2] + 12
$asDatePart[1] = $asDatePart[1] - 1
WEnd
EndIf
If $sType = "y" Then
$asDatePart[1] = $asDatePart[1] + $iNumber
EndIf
If $sType = "h" Or $sType = "n" Or $sType = "s" Then
Local $iTimeVal = _TimeToTicks($asTimePart[1], $asTimePart[2], $asTimePart[3]) / 1000
If $sType = "h" Then $iTimeVal = $iTimeVal + $iNumber * 3600
If $sType = "n" Then $iTimeVal = $iTimeVal + $iNumber * 60
If $sType = "s" Then $iTimeVal = $iTimeVal + $iNumber
Local $iDay2Add = Int($iTimeVal /(24 * 60 * 60))
$iTimeVal = $iTimeVal - $iDay2Add * 24 * 60 * 60
If $iTimeVal < 0 Then
$iDay2Add = $iDay2Add - 1
$iTimeVal = $iTimeVal + 24 * 60 * 60
EndIf
$iJulianDate = _DateToDayValue($asDatePart[1], $asDatePart[2], $asDatePart[3]) + $iDay2Add
_DayValueToDate($iJulianDate, $asDatePart[1], $asDatePart[2], $asDatePart[3])
_TicksToTime($iTimeVal * 1000, $asTimePart[1], $asTimePart[2], $asTimePart[3])
EndIf
Local $iNumDays = _DaysInMonth($asDatePart[1])
If $iNumDays[$asDatePart[2]] < $asDatePart[3] Then $asDatePart[3] = $iNumDays[$asDatePart[2]]
$sDate = $asDatePart[1] & '/' & StringRight("0" & $asDatePart[2], 2) & '/' & StringRight("0" & $asDatePart[3], 2)
If $asTimePart[0] > 0 Then
If $asTimePart[0] > 2 Then
$sDate = $sDate & " " & StringRight("0" & $asTimePart[1], 2) & ':' & StringRight("0" & $asTimePart[2], 2) & ':' & StringRight("0" & $asTimePart[3], 2)
Else
$sDate = $sDate & " " & StringRight("0" & $asTimePart[1], 2) & ':' & StringRight("0" & $asTimePart[2], 2)
EndIf
EndIf
Return $sDate
EndFunc
Func _DateIsLeapYear($iYear)
If StringIsInt($iYear) Then
Select
Case Mod($iYear, 4) = 0 And Mod($iYear, 100) <> 0
Return 1
Case Mod($iYear, 400) = 0
Return 1
Case Else
Return 0
EndSelect
EndIf
Return SetError(1, 0, 0)
EndFunc
Func _DateIsValid($sDate)
Local $asDatePart[4], $asTimePart[4]
_DateTimeSplit($sDate, $asDatePart, $asTimePart)
If Not StringIsInt($asDatePart[1]) Then Return 0
If Not StringIsInt($asDatePart[2]) Then Return 0
If Not StringIsInt($asDatePart[3]) Then Return 0
$asDatePart[1] = Int($asDatePart[1])
$asDatePart[2] = Int($asDatePart[2])
$asDatePart[3] = Int($asDatePart[3])
Local $iNumDays = _DaysInMonth($asDatePart[1])
If $asDatePart[1] < 1000 Or $asDatePart[1] > 2999 Then Return 0
If $asDatePart[2] < 1 Or $asDatePart[2] > 12 Then Return 0
If $asDatePart[3] < 1 Or $asDatePart[3] > $iNumDays[$asDatePart[2]] Then Return 0
If $asTimePart[0] < 1 Then Return 1
If $asTimePart[0] < 2 Then Return 0
If $asTimePart[0] = 2 Then $asTimePart[3] = "00"
If Not StringIsInt($asTimePart[1]) Then Return 0
If Not StringIsInt($asTimePart[2]) Then Return 0
If Not StringIsInt($asTimePart[3]) Then Return 0
$asTimePart[1] = Int($asTimePart[1])
$asTimePart[2] = Int($asTimePart[2])
$asTimePart[3] = Int($asTimePart[3])
If $asTimePart[1] < 0 Or $asTimePart[1] > 23 Then Return 0
If $asTimePart[2] < 0 Or $asTimePart[2] > 59 Then Return 0
If $asTimePart[3] < 0 Or $asTimePart[3] > 59 Then Return 0
Return 1
EndFunc
Func _DateTimeSplit($sDate, ByRef $aDatePart, ByRef $iTimePart)
Local $sDateTime = StringSplit($sDate, " T")
If $sDateTime[0] > 0 Then $aDatePart = StringSplit($sDateTime[1], "/-.")
If $sDateTime[0] > 1 Then
$iTimePart = StringSplit($sDateTime[2], ":")
If UBound($iTimePart) < 4 Then ReDim $iTimePart[4]
Else
Dim $iTimePart[4]
EndIf
If UBound($aDatePart) < 4 Then ReDim $aDatePart[4]
For $x = 1 To 3
If StringIsInt($aDatePart[$x]) Then
$aDatePart[$x] = Int($aDatePart[$x])
Else
$aDatePart[$x] = -1
EndIf
If StringIsInt($iTimePart[$x]) Then
$iTimePart[$x] = Int($iTimePart[$x])
Else
$iTimePart[$x] = 0
EndIf
Next
Return 1
EndFunc
Func _DateToDayValue($iYear, $iMonth, $iDay)
If Not _DateIsValid(StringFormat("%04d/%02d/%02d", $iYear, $iMonth, $iDay)) Then
Return SetError(1, 0, "")
EndIf
If $iMonth < 3 Then
$iMonth = $iMonth + 12
$iYear = $iYear - 1
EndIf
Local $i_FactorA = Int($iYear / 100)
Local $i_FactorB = Int($i_FactorA / 4)
Local $i_FactorC = 2 - $i_FactorA + $i_FactorB
Local $i_FactorE = Int(1461 *($iYear + 4716) / 4)
Local $i_FactorF = Int(153 *($iMonth + 1) / 5)
Local $iJulianDate = $i_FactorC + $iDay + $i_FactorE + $i_FactorF - 1524.5
Return $iJulianDate
EndFunc
Func _DayValueToDate($iJulianDate, ByRef $iYear, ByRef $iMonth, ByRef $iDay)
If $iJulianDate < 0 Or Not IsNumber($iJulianDate) Then
Return SetError(1, 0, 0)
EndIf
Local $i_FactorZ = Int($iJulianDate + 0.5)
Local $i_FactorW = Int(($i_FactorZ - 1867216.25) / 36524.25)
Local $i_FactorX = Int($i_FactorW / 4)
Local $i_FactorA = $i_FactorZ + 1 + $i_FactorW - $i_FactorX
Local $i_FactorB = $i_FactorA + 1524
Local $i_FactorC = Int(($i_FactorB - 122.1) / 365.25)
Local $i_FactorD = Int(365.25 * $i_FactorC)
Local $i_FactorE = Int(($i_FactorB - $i_FactorD) / 30.6001)
Local $i_FactorF = Int(30.6001 * $i_FactorE)
$iDay = $i_FactorB - $i_FactorD - $i_FactorF
If $i_FactorE - 1 < 13 Then
$iMonth = $i_FactorE - 1
Else
$iMonth = $i_FactorE - 13
EndIf
If $iMonth < 3 Then
$iYear = $i_FactorC - 4715
Else
$iYear = $i_FactorC - 4716
EndIf
$iYear = StringFormat("%04d", $iYear)
$iMonth = StringFormat("%02d", $iMonth)
$iDay = StringFormat("%02d", $iDay)
Return $iYear & "/" & $iMonth & "/" & $iDay
EndFunc
Func _TicksToTime($iTicks, ByRef $iHours, ByRef $iMins, ByRef $iSecs)
If Number($iTicks) > 0 Then
$iTicks = Int($iTicks / 1000)
$iHours = Int($iTicks / 3600)
$iTicks = Mod($iTicks, 3600)
$iMins = Int($iTicks / 60)
$iSecs = Mod($iTicks, 60)
Return 1
ElseIf Number($iTicks) = 0 Then
$iHours = 0
$iTicks = 0
$iMins = 0
$iSecs = 0
Return 1
Else
Return SetError(1, 0, 0)
EndIf
EndFunc
Func _TimeToTicks($iHours = @HOUR, $iMins = @MIN, $iSecs = @SEC)
If StringIsInt($iHours) And StringIsInt($iMins) And StringIsInt($iSecs) Then
Local $iTicks = 1000 *((3600 * $iHours) +(60 * $iMins) + $iSecs)
Return $iTicks
Else
Return SetError(1, 0, 0)
EndIf
EndFunc
Func _DaysInMonth($iYear)
Local $aDays = [12, 31,(_DateIsLeapYear($iYear) ? 29 : 28), 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
Return $aDays
EndFunc
Global $_SHA1_CodeBuffer, $_SHA1_CodeBufferMemory
Global $_SHA1_InitOffset, $_SHA1_InputOffset, $_SHA1_ResultOffset
Global $_HASH_SHA1[4] = [20, 96, '_SHA1_', '_SHA1_']
Func _SHA1_Exit()
$_SHA1_CodeBuffer = 0
_MemVirtualFree($_SHA1_CodeBufferMemory, 0, $MEM_RELEASE)
EndFunc
Func _SHA1_Startup()
If Not IsDllStruct($_SHA1_CodeBuffer) Then
If @AutoItX64 Then
Local $Code = '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'
$Code &= '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'
$Code &= 'DmS+eJvrDS1JAUBMSIUZ/3RGFN1BifUpyo/G4Tn7dgTt/fe39vGKZ9iG6mqCOIAB7kgp3+iUQAKDDP5Adcgs+s8G4SAw9ugd6nH/rEYqdbqSRyiT8PhIGInXVgjOU99k6ow6IEkF+H92fgePQVjQ4D91R4FmMLLtzED5PuLNyOlE8/noyN98qpBUYCsa+D935MZEQ8A6g8F3XmxBZzJUUAeDJv4BMl5Y3yAww72k0SgpxbJm6DLvkHfrN/D+iGaisHrxNN4BNG0uCgsa6chRkyN9rnhAkKFuWI8d0gQDtSNFZ/SFyQYJq82ePIsU4BkI/ty6YJgRDHZUMrWGhlFeqMcIx+/w8OFj0qSJUN0k/iTyAa3NV7+AkpFWBlPGUzRSy/dC8WEewdP/ROpHxffZ6tIPIdFdDAEJHvgBOEKIDAN2c4o8QbjHSPEaY7iHdQvgKcAx0tR+eCotwqQf9tn2rftAr/bDATC6OFEPhZPPDUDmxwIURpcZBJAWnRTEF6izBekD9sIBwcnzSKuRKppsHFOgiIPiBAF0H8YHwgEahHM4KhrovSUAsENYifaShnrGNw/I9NU4coEsLbgB+gNAawnTFAg3wxIEXqdJde0eXzDGA36NewEfsjfp91ohZscHjefqAkIBqelYoCMQgRIEF0LpURaJD1dZMhIvUiRTgtXRSkVicZIOokromUSzgosjcelAJhtWZJnPBtZAo8H88wqkX17DEETQMqpjhgAA'
Else
Local $Code = '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'
$Code &= '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'
$Code &= 'h+EDc6TrdBYMX17DV3cQiDAPYrbSDGmNswOZrQh0AwgKKapJCgp19j+S/BBDQIOqX8MAAA=='
EndIf
Local $Opcode = _SHA1_CodeDecompress($Code)
$_SHA1_InitOffset =(StringInStr($Opcode, "89DB") - 3) / 2
$_SHA1_InputOffset =(StringInStr($Opcode, "87DB") - 3) / 2
$_SHA1_ResultOffset =(StringInStr($Opcode, "09DB") - 3) / 2
$Opcode = Binary($Opcode)
$_SHA1_CodeBufferMemory = _MemVirtualAlloc(0, BinaryLen($Opcode), $MEM_COMMIT, $PAGE_EXECUTE_READWRITE)
$_SHA1_CodeBuffer = DllStructCreate("byte[" & BinaryLen($Opcode) & "]", $_SHA1_CodeBufferMemory)
DllStructSetData($_SHA1_CodeBuffer, 1, $Opcode)
OnAutoItExitRegister("_SHA1_Exit")
EndIf
EndFunc
Func _SHA1Init()
If Not IsDllStruct($_SHA1_CodeBuffer) Then _SHA1_Startup()
Local $Context = DllStructCreate("byte[" & $_HASH_SHA1[1] & "]")
DllCall("user32.dll", "none", "CallWindowProc", "ptr", DllStructGetPtr($_SHA1_CodeBuffer) + $_SHA1_InitOffset, "ptr", DllStructGetPtr($Context), "int", 0, "int", 0, "int", 0)
Return $Context
EndFunc
Func _SHA1Input(ByRef $Context, $Data)
If Not IsDllStruct($_SHA1_CodeBuffer) Then _SHA1_Startup()
If Not IsDllStruct($Context) Then Return SetError(1, 0, 0)
$Data = Binary($Data)
Local $InputLen = BinaryLen($Data)
Local $Input = DllStructCreate("byte[" & $InputLen & "]")
DllStructSetData($Input, 1, $Data)
DllCall("user32.dll", "none", "CallWindowProc", "ptr", DllStructGetPtr($_SHA1_CodeBuffer) + $_SHA1_InputOffset, "ptr", DllStructGetPtr($Context), "ptr", DllStructGetPtr($Input), "uint", $InputLen, "int", 0)
EndFunc
Func _SHA1Result(ByRef $Context)
If Not IsDllStruct($_SHA1_CodeBuffer) Then _SHA1_Startup()
If Not IsDllStruct($Context) Then Return SetError(1, 0, "")
Local $Digest = DllStructCreate("byte[" & $_HASH_SHA1[0] & "]")
DllCall("user32.dll", "none", "CallWindowProc", "ptr", DllStructGetPtr($_SHA1_CodeBuffer) + $_SHA1_ResultOffset, "ptr", DllStructGetPtr($Context), "ptr", DllStructGetPtr($Digest), "int", 0, "int", 0)
Return DllStructGetData($Digest, 1)
EndFunc
Func _SHA1($Data)
Local $Context = _SHA1Init()
_SHA1Input($Context, $Data)
Return _SHA1Result($Context)
EndFunc
Func _SHA1_CodeDecompress($Code)
If @AutoItX64 Then
Local $Opcode = '0x89C04150535657524889CE4889D7FCB28031DBA4B302E87500000073F631C9E86C000000731D31C0E8630000007324B302FFC1B010E85600000010C073F77544AAEBD3E85600000029D97510E84B000000EB2CACD1E8745711C9EB1D91FFC8C1E008ACE8340000003D007D0000730A80FC05730783F87F7704FFC1FFC141904489C0B301564889FE4829C6F3A45EEB8600D275078A1648FFC610D2C331C9FFC1E8EBFFFFFF11C9E8E4FFFFFF72F2C35A4829D7975F5E5B4158C389D24883EC08C70100000000C64104004883C408C389F64156415541544D89CC555756534C89C34883EC20410FB64104418800418B3183FE010F84AB00000073434863D24D89C54889CE488D3C114839FE0F84A50100000FB62E4883C601E8C601000083ED2B4080FD5077E2480FBEED0FB6042884C00FBED078D3C1E20241885500EB7383FE020F841C01000031C083FE03740F4883C4205B5E5F5D415C415D415EC34863D24D89C54889CE488D3C114839FE0F84CA0000000FB62E4883C601E86401000083ED2B4080FD5077E2480FBEED0FB6042884C078D683E03F410845004983C501E964FFFFFF4863D24D89C54889CE488D3C114839FE0F84E00000000FB62E4883C601E81D01000083ED2B4080FD5077E2480FBEED0FB6042884C00FBED078D389D04D8D7501C1E20483E03041885501C1F804410845004839FE747B0FB62E4883C601E8DD00000083ED2B4080FD5077E6480FBEED0FB6042884C00FBED078D789D0C1E2064D8D6E0183E03C41885601C1F8024108064839FE0F8536FFFFFF41C7042403000000410FB6450041884424044489E84883C42029D85B5E5F5D415C415D415EC34863D24889CE4D89C6488D3C114839FE758541C7042402000000410FB60641884424044489F04883C42029D85B5E5F5D415C415D415EC341C7042401000000410FB6450041884424044489E829D8E998FEFFFF41C7042400000000410FB6450041884424044489E829D8E97CFEFFFF56574889CF4889D64C89C1FCF3A45F5EC3E8500000003EFFFFFF3F3435363738393A3B3C3DFFFFFFFEFFFFFF000102030405060708090A0B0C0D0E0F10111213141516171819FFFFFFFFFFFF1A1B1C1D1E1F202122232425262728292A2B2C2D2E2F3031323358C3'
Else
Local $Opcode = '0x89C0608B7424248B7C2428FCB28031DBA4B302E86D00000073F631C9E864000000731C31C0E85B0000007323B30241B010E84F00000010C073F7753FAAEBD4E84D00000029D97510E842000000EB28ACD1E8744D11C9EB1C9148C1E008ACE82C0000003D007D0000730A80FC05730683F87F770241419589E8B3015689FE29C6F3A45EEB8E00D275058A164610D2C331C941E8EEFFFFFF11C9E8E7FFFFFF72F2C32B7C2428897C241C61C389D28B442404C70000000000C6400400C2100089F65557565383EC1C8B6C243C8B5424388B5C24308B7424340FB6450488028B550083FA010F84A1000000733F8B5424388D34338954240C39F30F848B0100000FB63B83C301E8CD0100008D57D580FA5077E50FBED20FB6041084C00FBED078D78B44240CC1E2028810EB6B83FA020F841201000031C083FA03740A83C41C5B5E5F5DC210008B4C24388D3433894C240C39F30F84CD0000000FB63B83C301E8740100008D57D580FA5077E50FBED20FB6041084C078DA8B54240C83E03F080283C2018954240CE96CFFFFFF8B4424388D34338944240C39F30F84D00000000FB63B83C301E82E0100008D57D580FA5077E50FBED20FB6141084D20FBEC278D78B4C240C89C283E230C1FA04C1E004081189CF83C70188410139F374750FB60383C3018844240CE8EC0000000FB654240C83EA2B80FA5077E00FBED20FB6141084D20FBEC278D289C283E23CC1FA02C1E006081739F38D57018954240C8847010F8533FFFFFFC74500030000008B4C240C0FB60188450489C82B44243883C41C5B5E5F5DC210008D34338B7C243839F3758BC74500020000000FB60788450489F82B44243883C41C5B5E5F5DC210008B54240CC74500010000000FB60288450489D02B442438E9B1FEFFFFC7450000000000EB9956578B7C240C8B7424108B4C241485C9742FFC83F9087227F7C7010000007402A449F7C702000000740566A583E90289CAC1E902F3A589D183E103F3A4EB02F3A45F5EC3E8500000003EFFFFFF3F3435363738393A3B3C3DFFFFFFFEFFFFFF000102030405060708090A0B0C0D0E0F10111213141516171819FFFFFFFFFFFF1A1B1C1D1E1F202122232425262728292A2B2C2D2E2F3031323358C3'
EndIf
Local $AP_Decompress =(StringInStr($Opcode, "89C0") - 3) / 2
Local $B64D_Init =(StringInStr($Opcode, "89D2") - 3) / 2
Local $B64D_DecodeData =(StringInStr($Opcode, "89F6") - 3) / 2
$Opcode = Binary($Opcode)
Local $CodeBufferMemory = _MemVirtualAlloc(0, BinaryLen($Opcode), $MEM_COMMIT, $PAGE_EXECUTE_READWRITE)
Local $CodeBuffer = DllStructCreate("byte[" & BinaryLen($Opcode) & "]", $CodeBufferMemory)
DllStructSetData($CodeBuffer, 1, $Opcode)
Local $B64D_State = DllStructCreate("byte[16]")
Local $Length = StringLen($Code)
Local $Output = DllStructCreate("byte[" & $Length & "]")
DllCall("user32.dll", "none", "CallWindowProc", "ptr", DllStructGetPtr($CodeBuffer) + $B64D_Init, "ptr", DllStructGetPtr($B64D_State), "int", 0, "int", 0, "int", 0)
DllCall("user32.dll", "int", "CallWindowProc", "ptr", DllStructGetPtr($CodeBuffer) + $B64D_DecodeData, "str", $Code, "uint", $Length, "ptr", DllStructGetPtr($Output), "ptr", DllStructGetPtr($B64D_State))
Local $ResultLen = DllStructGetData(DllStructCreate("uint", DllStructGetPtr($Output)), 1)
Local $Result = DllStructCreate("byte[" &($ResultLen + 16) & "]")
Local $Ret = DllCall("user32.dll", "uint", "CallWindowProc", "ptr", DllStructGetPtr($CodeBuffer) + $AP_Decompress, "ptr", DllStructGetPtr($Output) + 4, "ptr", DllStructGetPtr($Result), "int", 0, "int", 0)
_MemVirtualFree($CodeBufferMemory, 0, $MEM_RELEASE)
Return BinaryMid(DllStructGetData($Result, 1), 1, $Ret[0])
EndFunc
Global Const $INTERNET_DEFAULT_PORT = 0
Global Const $ICU_ESCAPE = 0x80000000
Global Const $WINHTTP_FLAG_ASYNC = 0x10000000
Global Const $WINHTTP_FLAG_ESCAPE_DISABLE = 0x00000040
Global Const $WINHTTP_FLAG_SECURE = 0x00800000
Global Const $WINHTTP_ACCESS_TYPE_NO_PROXY = 1
Global Const $WINHTTP_NO_PROXY_NAME = ""
Global Const $WINHTTP_NO_PROXY_BYPASS = ""
Global Const $WINHTTP_NO_REFERER = ""
Global Const $WINHTTP_DEFAULT_ACCEPT_TYPES = 0
Global Const $WINHTTP_NO_ADDITIONAL_HEADERS = ""
Global Const $WINHTTP_NO_REQUEST_DATA = ""
Global Const $WINHTTP_HEADER_NAME_BY_INDEX = ""
Global Const $WINHTTP_NO_HEADER_INDEX = 0
Global Const $WINHTTP_OPTION_CALLBACK = 1
Global Const $WINHTTP_OPTION_RESOLVE_TIMEOUT = 2
Global Const $WINHTTP_OPTION_CONNECT_TIMEOUT = 3
Global Const $WINHTTP_OPTION_CONNECT_RETRIES = 4
Global Const $WINHTTP_OPTION_SEND_TIMEOUT = 5
Global Const $WINHTTP_OPTION_RECEIVE_TIMEOUT = 6
Global Const $WINHTTP_OPTION_RECEIVE_RESPONSE_TIMEOUT = 7
Global Const $WINHTTP_OPTION_HANDLE_TYPE = 9
Global Const $WINHTTP_OPTION_READ_BUFFER_SIZE = 12
Global Const $WINHTTP_OPTION_WRITE_BUFFER_SIZE = 13
Global Const $WINHTTP_OPTION_PARENT_HANDLE = 21
Global Const $WINHTTP_OPTION_EXTENDED_ERROR = 24
Global Const $WINHTTP_OPTION_SECURITY_FLAGS = 31
Global Const $WINHTTP_OPTION_URL = 34
Global Const $WINHTTP_OPTION_SECURITY_KEY_BITNESS = 36
Global Const $WINHTTP_OPTION_PROXY = 38
Global Const $WINHTTP_OPTION_USER_AGENT = 41
Global Const $WINHTTP_OPTION_CONTEXT_VALUE = 45
Global Const $WINHTTP_OPTION_CLIENT_CERT_CONTEXT = 47
Global Const $WINHTTP_OPTION_REQUEST_PRIORITY = 58
Global Const $WINHTTP_OPTION_HTTP_VERSION = 59
Global Const $WINHTTP_OPTION_DISABLE_FEATURE = 63
Global Const $WINHTTP_OPTION_CODEPAGE = 68
Global Const $WINHTTP_OPTION_MAX_CONNS_PER_SERVER = 73
Global Const $WINHTTP_OPTION_MAX_CONNS_PER_1_0_SERVER = 74
Global Const $WINHTTP_OPTION_AUTOLOGON_POLICY = 77
Global Const $WINHTTP_OPTION_SERVER_CERT_CONTEXT = 78
Global Const $WINHTTP_OPTION_ENABLE_FEATURE = 79
Global Const $WINHTTP_OPTION_WORKER_THREAD_COUNT = 80
Global Const $WINHTTP_OPTION_PASSPORT_COBRANDING_TEXT = 81
Global Const $WINHTTP_OPTION_PASSPORT_COBRANDING_URL = 82
Global Const $WINHTTP_OPTION_CONFIGURE_PASSPORT_AUTH = 83
Global Const $WINHTTP_OPTION_SECURE_PROTOCOLS = 84
Global Const $WINHTTP_OPTION_ENABLETRACING = 85
Global Const $WINHTTP_OPTION_PASSPORT_SIGN_OUT = 86
Global Const $WINHTTP_OPTION_REDIRECT_POLICY = 88
Global Const $WINHTTP_OPTION_MAX_HTTP_AUTOMATIC_REDIRECTS = 89
Global Const $WINHTTP_OPTION_MAX_HTTP_STATUS_CONTINUE = 90
Global Const $WINHTTP_OPTION_MAX_RESPONSE_HEADER_SIZE = 91
Global Const $WINHTTP_OPTION_MAX_RESPONSE_DRAIN_SIZE = 92
Global Const $WINHTTP_OPTION_CONNECTION_INFO = 93
Global Const $WINHTTP_OPTION_SPN = 96
Global Const $WINHTTP_OPTION_GLOBAL_PROXY_CREDS = 97
Global Const $WINHTTP_OPTION_GLOBAL_SERVER_CREDS = 98
Global Const $WINHTTP_OPTION_REJECT_USERPWD_IN_URL = 100
Global Const $WINHTTP_OPTION_USE_GLOBAL_SERVER_CREDENTIALS = 101
Global Const $WINHTTP_OPTION_UNSAFE_HEADER_PARSING = 110
Global Const $WINHTTP_OPTION_DECOMPRESSION = 118
Global Const $WINHTTP_OPTION_USERNAME = 0x1000
Global Const $WINHTTP_OPTION_PASSWORD = 0x1001
Global Const $WINHTTP_OPTION_PROXY_USERNAME = 0x1002
Global Const $WINHTTP_OPTION_PROXY_PASSWORD = 0x1003
Global Const $WINHTTP_DECOMPRESSION_FLAG_ALL = 0x00000003
Global Const $WINHTTP_AUTOLOGON_SECURITY_LEVEL_MEDIUM = 0
Global Const $WINHTTP_AUTOLOGON_SECURITY_LEVEL_LOW = 1
Global Const $WINHTTP_AUTOLOGON_SECURITY_LEVEL_HIGH = 2
Global Const $SECURITY_FLAG_IGNORE_UNKNOWN_CA = 0x00000100
Global Const $SECURITY_FLAG_IGNORE_CERT_DATE_INVALID = 0x00002000
Global Const $SECURITY_FLAG_IGNORE_CERT_CN_INVALID = 0x00001000
Global Const $SECURITY_FLAG_IGNORE_CERT_WRONG_USAGE = 0x00000200
Global Const $WINHTTP_QUERY_CONTENT_TYPE = 1
Global Const $WINHTTP_QUERY_RAW_HEADERS_CRLF = 22
Global Const $hWINHTTPDLL__WINHTTP = DllOpen("winhttp.dll")
DllOpen("winhttp.dll")
Func _WinHttpCloseHandle($hInternet)
Local $aCall = DllCall($hWINHTTPDLL__WINHTTP, "bool", "WinHttpCloseHandle", "handle", $hInternet)
If @error Or Not $aCall[0] Then Return SetError(1, 0, 0)
Return 1
EndFunc
Func _WinHttpConnect($hSession, $sServerName, $iServerPort = Default)
Local $aURL = _WinHttpCrackUrl($sServerName), $iScheme = 0
If @error Then
__WinHttpDefault($iServerPort, $INTERNET_DEFAULT_PORT)
Else
$sServerName = $aURL[2]
$iServerPort = $aURL[3]
$iScheme = $aURL[1]
EndIf
Local $aCall = DllCall($hWINHTTPDLL__WINHTTP, "handle", "WinHttpConnect", "handle", $hSession, "wstr", $sServerName, "dword", $iServerPort, "dword", 0)
If @error Or Not $aCall[0] Then Return SetError(1, 0, 0)
_WinHttpSetOption($aCall[0], $WINHTTP_OPTION_CONTEXT_VALUE, $iScheme)
Return $aCall[0]
EndFunc
Func _WinHttpCrackUrl($sURL, $iFlag = Default)
__WinHttpDefault($iFlag, $ICU_ESCAPE)
Local $tURL_COMPONENTS = DllStructCreate("dword StructSize;" & "ptr SchemeName;" & "dword SchemeNameLength;" & "int Scheme;" & "ptr HostName;" & "dword HostNameLength;" & "word Port;" & "ptr UserName;" & "dword UserNameLength;" & "ptr Password;" & "dword PasswordLength;" & "ptr UrlPath;" & "dword UrlPathLength;" & "ptr ExtraInfo;" & "dword ExtraInfoLength")
DllStructSetData($tURL_COMPONENTS, 1, DllStructGetSize($tURL_COMPONENTS))
Local $tBuffers[6]
Local $iURLLen = StringLen($sURL)
For $i = 0 To 5
$tBuffers[$i] = DllStructCreate("wchar[" & $iURLLen + 1 & "]")
Next
DllStructSetData($tURL_COMPONENTS, "SchemeNameLength", $iURLLen)
DllStructSetData($tURL_COMPONENTS, "SchemeName", DllStructGetPtr($tBuffers[0]))
DllStructSetData($tURL_COMPONENTS, "HostNameLength", $iURLLen)
DllStructSetData($tURL_COMPONENTS, "HostName", DllStructGetPtr($tBuffers[1]))
DllStructSetData($tURL_COMPONENTS, "UserNameLength", $iURLLen)
DllStructSetData($tURL_COMPONENTS, "UserName", DllStructGetPtr($tBuffers[2]))
DllStructSetData($tURL_COMPONENTS, "PasswordLength", $iURLLen)
DllStructSetData($tURL_COMPONENTS, "Password", DllStructGetPtr($tBuffers[3]))
DllStructSetData($tURL_COMPONENTS, "UrlPathLength", $iURLLen)
DllStructSetData($tURL_COMPONENTS, "UrlPath", DllStructGetPtr($tBuffers[4]))
DllStructSetData($tURL_COMPONENTS, "ExtraInfoLength", $iURLLen)
DllStructSetData($tURL_COMPONENTS, "ExtraInfo", DllStructGetPtr($tBuffers[5]))
Local $aCall = DllCall($hWINHTTPDLL__WINHTTP, "bool", "WinHttpCrackUrl", "wstr", $sURL, "dword", $iURLLen, "dword", $iFlag, "struct*", $tURL_COMPONENTS)
If @error Or Not $aCall[0] Then Return SetError(1, 0, 0)
Local $aRet[8] = [DllStructGetData($tBuffers[0], 1), DllStructGetData($tURL_COMPONENTS, "Scheme"), DllStructGetData($tBuffers[1], 1), DllStructGetData($tURL_COMPONENTS, "Port"), DllStructGetData($tBuffers[2], 1), DllStructGetData($tBuffers[3], 1), DllStructGetData($tBuffers[4], 1), DllStructGetData($tBuffers[5], 1)]
Return $aRet
EndFunc
Func _WinHttpOpen($sUserAgent = Default, $iAccessType = Default, $sProxyName = Default, $sProxyBypass = Default, $iFlag = Default)
__WinHttpDefault($sUserAgent, __WinHttpUA())
__WinHttpDefault($iAccessType, $WINHTTP_ACCESS_TYPE_NO_PROXY)
__WinHttpDefault($sProxyName, $WINHTTP_NO_PROXY_NAME)
__WinHttpDefault($sProxyBypass, $WINHTTP_NO_PROXY_BYPASS)
__WinHttpDefault($iFlag, 0)
Local $aCall = DllCall($hWINHTTPDLL__WINHTTP, "handle", "WinHttpOpen", "wstr", $sUserAgent, "dword", $iAccessType, "wstr", $sProxyName, "wstr", $sProxyBypass, "dword", $iFlag)
If @error Or Not $aCall[0] Then Return SetError(1, 0, 0)
If $iFlag = $WINHTTP_FLAG_ASYNC Then _WinHttpSetOption($aCall[0], $WINHTTP_OPTION_CONTEXT_VALUE, $WINHTTP_FLAG_ASYNC)
Return $aCall[0]
EndFunc
Func _WinHttpOpenRequest($hConnect, $sVerb = Default, $sObjectName = Default, $sVersion = Default, $sReferrer = Default, $sAcceptTypes = Default, $iFlags = Default)
__WinHttpDefault($sVerb, "GET")
__WinHttpDefault($sObjectName, "")
__WinHttpDefault($sVersion, "HTTP/1.1")
__WinHttpDefault($sReferrer, $WINHTTP_NO_REFERER)
__WinHttpDefault($iFlags, $WINHTTP_FLAG_ESCAPE_DISABLE)
Local $pAcceptTypes
If $sAcceptTypes = Default Or Number($sAcceptTypes) = -1 Then
$pAcceptTypes = $WINHTTP_DEFAULT_ACCEPT_TYPES
Else
Local $aTypes = StringSplit($sAcceptTypes, ",", 2)
Local $tAcceptTypes = DllStructCreate("ptr[" & UBound($aTypes) + 1 & "]")
Local $tType[UBound($aTypes)]
For $i = 0 To UBound($aTypes) - 1
$tType[$i] = DllStructCreate("wchar[" & StringLen($aTypes[$i]) + 1 & "]")
DllStructSetData($tType[$i], 1, $aTypes[$i])
DllStructSetData($tAcceptTypes, 1, DllStructGetPtr($tType[$i]), $i + 1)
Next
$pAcceptTypes = DllStructGetPtr($tAcceptTypes)
EndIf
Local $aCall = DllCall($hWINHTTPDLL__WINHTTP, "handle", "WinHttpOpenRequest", "handle", $hConnect, "wstr", StringUpper($sVerb), "wstr", $sObjectName, "wstr", StringUpper($sVersion), "wstr", $sReferrer, "ptr", $pAcceptTypes, "dword", $iFlags)
If @error Or Not $aCall[0] Then Return SetError(1, 0, 0)
Return $aCall[0]
EndFunc
Func _WinHttpQueryDataAvailable($hRequest)
Local $sReadType = "dword*"
If BitAND(_WinHttpQueryOption(_WinHttpQueryOption(_WinHttpQueryOption($hRequest, $WINHTTP_OPTION_PARENT_HANDLE), $WINHTTP_OPTION_PARENT_HANDLE), $WINHTTP_OPTION_CONTEXT_VALUE), $WINHTTP_FLAG_ASYNC) Then $sReadType = "ptr"
Local $aCall = DllCall($hWINHTTPDLL__WINHTTP, "bool", "WinHttpQueryDataAvailable", "handle", $hRequest, $sReadType, 0)
If @error Then Return SetError(1, 0, 0)
Return SetExtended($aCall[2], $aCall[0])
EndFunc
Func _WinHttpQueryHeaders($hRequest, $iInfoLevel = Default, $sName = Default, $iIndex = Default)
__WinHttpDefault($iInfoLevel, $WINHTTP_QUERY_RAW_HEADERS_CRLF)
__WinHttpDefault($sName, $WINHTTP_HEADER_NAME_BY_INDEX)
__WinHttpDefault($iIndex, $WINHTTP_NO_HEADER_INDEX)
Local $aCall = DllCall($hWINHTTPDLL__WINHTTP, "bool", "WinHttpQueryHeaders", "handle", $hRequest, "dword", $iInfoLevel, "wstr", $sName, "wstr", "", "dword*", 65536, "dword*", $iIndex)
If @error Or Not $aCall[0] Then Return SetError(1, 0, "")
Return SetExtended($aCall[6], $aCall[4])
EndFunc
Func _WinHttpQueryOption($hInternet, $iOption)
Local $aCall = DllCall($hWINHTTPDLL__WINHTTP, "bool", "WinHttpQueryOption", "handle", $hInternet, "dword", $iOption, "ptr", 0, "dword*", 0)
If @error Or $aCall[0] Then Return SetError(1, 0, "")
Local $iSize = $aCall[4]
Local $tBuffer
Switch $iOption
Case $WINHTTP_OPTION_CONNECTION_INFO, $WINHTTP_OPTION_PASSWORD, $WINHTTP_OPTION_PROXY_PASSWORD, $WINHTTP_OPTION_PROXY_USERNAME, $WINHTTP_OPTION_URL, $WINHTTP_OPTION_USERNAME, $WINHTTP_OPTION_USER_AGENT, $WINHTTP_OPTION_PASSPORT_COBRANDING_TEXT, $WINHTTP_OPTION_PASSPORT_COBRANDING_URL
$tBuffer = DllStructCreate("wchar[" & $iSize + 1 & "]")
Case $WINHTTP_OPTION_PARENT_HANDLE, $WINHTTP_OPTION_CALLBACK, $WINHTTP_OPTION_SERVER_CERT_CONTEXT
$tBuffer = DllStructCreate("ptr")
Case $WINHTTP_OPTION_CONNECT_TIMEOUT, $WINHTTP_AUTOLOGON_SECURITY_LEVEL_HIGH, $WINHTTP_AUTOLOGON_SECURITY_LEVEL_LOW, $WINHTTP_AUTOLOGON_SECURITY_LEVEL_MEDIUM, $WINHTTP_OPTION_CONFIGURE_PASSPORT_AUTH, $WINHTTP_OPTION_CONNECT_RETRIES, $WINHTTP_OPTION_EXTENDED_ERROR, $WINHTTP_OPTION_HANDLE_TYPE, $WINHTTP_OPTION_MAX_CONNS_PER_1_0_SERVER, $WINHTTP_OPTION_MAX_CONNS_PER_SERVER, $WINHTTP_OPTION_MAX_HTTP_AUTOMATIC_REDIRECTS, $WINHTTP_OPTION_RECEIVE_RESPONSE_TIMEOUT, $WINHTTP_OPTION_RECEIVE_TIMEOUT, $WINHTTP_OPTION_RESOLVE_TIMEOUT, $WINHTTP_OPTION_SECURITY_FLAGS, $WINHTTP_OPTION_SECURITY_KEY_BITNESS, $WINHTTP_OPTION_SEND_TIMEOUT
$tBuffer = DllStructCreate("int")
Case $WINHTTP_OPTION_CONTEXT_VALUE
$tBuffer = DllStructCreate("dword_ptr")
Case Else
$tBuffer = DllStructCreate("byte[" & $iSize & "]")
EndSwitch
$aCall = DllCall($hWINHTTPDLL__WINHTTP, "bool", "WinHttpQueryOption", "handle", $hInternet, "dword", $iOption, "struct*", $tBuffer, "dword*", $iSize)
If @error Or Not $aCall[0] Then Return SetError(2, 0, "")
Return DllStructGetData($tBuffer, 1)
EndFunc
Func _WinHttpReadData($hRequest, $iMode = Default, $iNumberOfBytesToRead = Default, $pBuffer = Default)
__WinHttpDefault($iMode, 0)
__WinHttpDefault($iNumberOfBytesToRead, 8192)
Local $tBuffer, $vOutOnError = ""
If $iMode = 2 Then $vOutOnError = Binary($vOutOnError)
Switch $iMode
Case 1, 2
If $pBuffer And $pBuffer <> Default Then
$tBuffer = DllStructCreate("byte[" & $iNumberOfBytesToRead & "]", $pBuffer)
Else
$tBuffer = DllStructCreate("byte[" & $iNumberOfBytesToRead & "]")
EndIf
Case Else
$iMode = 0
If $pBuffer And $pBuffer <> Default Then
$tBuffer = DllStructCreate("char[" & $iNumberOfBytesToRead & "]", $pBuffer)
Else
$tBuffer = DllStructCreate("char[" & $iNumberOfBytesToRead & "]")
EndIf
EndSwitch
Local $sReadType = "dword*"
If BitAND(_WinHttpQueryOption(_WinHttpQueryOption(_WinHttpQueryOption($hRequest, $WINHTTP_OPTION_PARENT_HANDLE), $WINHTTP_OPTION_PARENT_HANDLE), $WINHTTP_OPTION_CONTEXT_VALUE), $WINHTTP_FLAG_ASYNC) Then $sReadType = "ptr"
Local $aCall = DllCall($hWINHTTPDLL__WINHTTP, "bool", "WinHttpReadData", "handle", $hRequest, "struct*", $tBuffer, "dword", $iNumberOfBytesToRead, $sReadType, 0)
If @error Or Not $aCall[0] Then Return SetError(1, 0, "")
If Not $aCall[4] Then Return SetError(-1, 0, $vOutOnError)
If $aCall[4] < $iNumberOfBytesToRead Then
Switch $iMode
Case 0
Return SetExtended($aCall[4], StringLeft(DllStructGetData($tBuffer, 1), $aCall[4]))
Case 1
Return SetExtended($aCall[4], BinaryToString(BinaryMid(DllStructGetData($tBuffer, 1), 1, $aCall[4]), 4))
Case 2
Return SetExtended($aCall[4], BinaryMid(DllStructGetData($tBuffer, 1), 1, $aCall[4]))
EndSwitch
Else
Switch $iMode
Case 0, 2
Return SetExtended($aCall[4], DllStructGetData($tBuffer, 1))
Case 1
Return SetExtended($aCall[4], BinaryToString(DllStructGetData($tBuffer, 1), 4))
EndSwitch
EndIf
EndFunc
Func _WinHttpReceiveResponse($hRequest)
Local $aCall = DllCall($hWINHTTPDLL__WINHTTP, "bool", "WinHttpReceiveResponse", "handle", $hRequest, "ptr", 0)
If @error Or Not $aCall[0] Then Return SetError(1, 0, 0)
Return 1
EndFunc
Func _WinHttpSendRequest($hRequest, $sHeaders = Default, $vOptional = Default, $iTotalLength = Default, $iContext = Default)
__WinHttpDefault($sHeaders, $WINHTTP_NO_ADDITIONAL_HEADERS)
__WinHttpDefault($vOptional, $WINHTTP_NO_REQUEST_DATA)
__WinHttpDefault($iTotalLength, 0)
__WinHttpDefault($iContext, 0)
Local $pOptional = 0, $iOptionalLength = 0
If @NumParams > 2 Then
Local $tOptional
$iOptionalLength = BinaryLen($vOptional)
$tOptional = DllStructCreate("byte[" & $iOptionalLength & "]")
If $iOptionalLength Then $pOptional = DllStructGetPtr($tOptional)
DllStructSetData($tOptional, 1, $vOptional)
EndIf
If Not $iTotalLength Or $iTotalLength < $iOptionalLength Then $iTotalLength += $iOptionalLength
Local $aCall = DllCall($hWINHTTPDLL__WINHTTP, "bool", "WinHttpSendRequest", "handle", $hRequest, "wstr", $sHeaders, "dword", 0, "ptr", $pOptional, "dword", $iOptionalLength, "dword", $iTotalLength, "dword_ptr", $iContext)
If @error Or Not $aCall[0] Then Return SetError(1, 0, 0)
Return 1
EndFunc
Func _WinHttpSetOption($hInternet, $iOption, $vSetting, $iSize = Default)
If $iSize = Default Then $iSize = -1
If IsBinary($vSetting) Then
$iSize = DllStructCreate("byte[" & BinaryLen($vSetting) & "]")
DllStructSetData($iSize, 1, $vSetting)
$vSetting = $iSize
$iSize = DllStructGetSize($vSetting)
EndIf
Local $sType
Switch $iOption
Case $WINHTTP_OPTION_AUTOLOGON_POLICY, $WINHTTP_OPTION_CODEPAGE, $WINHTTP_OPTION_CONFIGURE_PASSPORT_AUTH, $WINHTTP_OPTION_CONNECT_RETRIES, $WINHTTP_OPTION_CONNECT_TIMEOUT, $WINHTTP_OPTION_DISABLE_FEATURE, $WINHTTP_OPTION_ENABLE_FEATURE, $WINHTTP_OPTION_ENABLETRACING, $WINHTTP_OPTION_MAX_CONNS_PER_1_0_SERVER, $WINHTTP_OPTION_MAX_CONNS_PER_SERVER, $WINHTTP_OPTION_MAX_HTTP_AUTOMATIC_REDIRECTS, $WINHTTP_OPTION_MAX_HTTP_STATUS_CONTINUE, $WINHTTP_OPTION_MAX_RESPONSE_DRAIN_SIZE, $WINHTTP_OPTION_MAX_RESPONSE_HEADER_SIZE, $WINHTTP_OPTION_READ_BUFFER_SIZE, $WINHTTP_OPTION_RECEIVE_TIMEOUT, $WINHTTP_OPTION_RECEIVE_RESPONSE_TIMEOUT, $WINHTTP_OPTION_REDIRECT_POLICY, $WINHTTP_OPTION_REJECT_USERPWD_IN_URL, $WINHTTP_OPTION_REQUEST_PRIORITY, $WINHTTP_OPTION_RESOLVE_TIMEOUT, $WINHTTP_OPTION_SECURE_PROTOCOLS, $WINHTTP_OPTION_SECURITY_FLAGS, $WINHTTP_OPTION_SECURITY_KEY_BITNESS, $WINHTTP_OPTION_SEND_TIMEOUT, $WINHTTP_OPTION_SPN, $WINHTTP_OPTION_USE_GLOBAL_SERVER_CREDENTIALS, $WINHTTP_OPTION_WORKER_THREAD_COUNT, $WINHTTP_OPTION_WRITE_BUFFER_SIZE, $WINHTTP_OPTION_DECOMPRESSION, $WINHTTP_OPTION_UNSAFE_HEADER_PARSING
$sType = "dword*"
$iSize = 4
Case $WINHTTP_OPTION_CALLBACK, $WINHTTP_OPTION_PASSPORT_SIGN_OUT
$sType = "ptr*"
$iSize = 4
If @AutoItX64 Then $iSize = 8
If Not IsPtr($vSetting) Then Return SetError(3, 0, 0)
Case $WINHTTP_OPTION_CONTEXT_VALUE
$sType = "dword_ptr*"
$iSize = 4
If @AutoItX64 Then $iSize = 8
Case $WINHTTP_OPTION_PASSWORD, $WINHTTP_OPTION_PROXY_PASSWORD, $WINHTTP_OPTION_PROXY_USERNAME, $WINHTTP_OPTION_USER_AGENT, $WINHTTP_OPTION_USERNAME
$sType = "wstr"
If(IsDllStruct($vSetting) Or IsPtr($vSetting)) Then Return SetError(3, 0, 0)
If $iSize < 1 Then $iSize = StringLen($vSetting)
Case $WINHTTP_OPTION_CLIENT_CERT_CONTEXT, $WINHTTP_OPTION_GLOBAL_PROXY_CREDS, $WINHTTP_OPTION_GLOBAL_SERVER_CREDS, $WINHTTP_OPTION_HTTP_VERSION, $WINHTTP_OPTION_PROXY
$sType = "ptr"
If Not(IsDllStruct($vSetting) Or IsPtr($vSetting)) Then Return SetError(3, 0, 0)
Case Else
Return SetError(1, 0, 0)
EndSwitch
If $iSize < 1 Then
If IsDllStruct($vSetting) Then
$iSize = DllStructGetSize($vSetting)
Else
Return SetError(2, 0, 0)
EndIf
EndIf
Local $aCall
If IsDllStruct($vSetting) Then
$aCall = DllCall($hWINHTTPDLL__WINHTTP, "bool", "WinHttpSetOption", "handle", $hInternet, "dword", $iOption, $sType, DllStructGetPtr($vSetting), "dword", $iSize)
Else
$aCall = DllCall($hWINHTTPDLL__WINHTTP, "bool", "WinHttpSetOption", "handle", $hInternet, "dword", $iOption, $sType, $vSetting, "dword", $iSize)
EndIf
If @error Or Not $aCall[0] Then Return SetError(4, 0, 0)
Return 1
EndFunc
Func _WinHttpSimpleReadData($hRequest, $iMode = Default)
If $iMode = Default Then
$iMode = 0
If __WinHttpCharSet(_WinHttpQueryHeaders($hRequest, $WINHTTP_QUERY_CONTENT_TYPE)) = 65001 Then $iMode = 1
Else
__WinHttpDefault($iMode, 0)
EndIf
If $iMode > 2 Or $iMode < 0 Then Return SetError(1, 0, '')
Local $vData = Binary('')
If _WinHttpQueryDataAvailable($hRequest) Then
Do
$vData &= _WinHttpReadData($hRequest, 2)
Until @error
Switch $iMode
Case 0
Return BinaryToString($vData)
Case 1
Return BinaryToString($vData, 4)
Case Else
Return $vData
EndSwitch
EndIf
Return SetError(2, 0, $vData)
EndFunc
Func _WinHttpSimpleSendSSLRequest($hConnect, $sType = Default, $sPath = Default, $sReferrer = Default, $sDta = Default, $sHeader = Default, $iIgnoreAllCertErrors = 0)
__WinHttpDefault($sType, "GET")
__WinHttpDefault($sPath, "")
__WinHttpDefault($sReferrer, $WINHTTP_NO_REFERER)
__WinHttpDefault($sDta, $WINHTTP_NO_REQUEST_DATA)
__WinHttpDefault($sHeader, $WINHTTP_NO_ADDITIONAL_HEADERS)
Local $hRequest = _WinHttpOpenRequest($hConnect, $sType, $sPath, Default, $sReferrer, Default, BitOR($WINHTTP_FLAG_SECURE, $WINHTTP_FLAG_ESCAPE_DISABLE))
If Not $hRequest Then Return SetError(1, @error, 0)
If $iIgnoreAllCertErrors Then _WinHttpSetOption($hRequest, $WINHTTP_OPTION_SECURITY_FLAGS, BitOR($SECURITY_FLAG_IGNORE_UNKNOWN_CA, $SECURITY_FLAG_IGNORE_CERT_DATE_INVALID, $SECURITY_FLAG_IGNORE_CERT_CN_INVALID, $SECURITY_FLAG_IGNORE_CERT_WRONG_USAGE))
If $sType = "POST" And $sHeader = $WINHTTP_NO_ADDITIONAL_HEADERS Then $sHeader = "Content-Type: application/x-www-form-urlencoded" & @CRLF
_WinHttpSetOption($hRequest, $WINHTTP_OPTION_DECOMPRESSION, $WINHTTP_DECOMPRESSION_FLAG_ALL)
_WinHttpSetOption($hRequest, $WINHTTP_OPTION_UNSAFE_HEADER_PARSING, 1)
_WinHttpSendRequest($hRequest, $sHeader, $sDta)
If @error Then Return SetError(2, 0 * _WinHttpCloseHandle($hRequest), 0)
_WinHttpReceiveResponse($hRequest)
If @error Then Return SetError(3, 0 * _WinHttpCloseHandle($hRequest), 0)
Return $hRequest
EndFunc
Func __WinHttpCharSet($sContentType)
Local $aContentType = StringRegExp($sContentType, "(?i).*?\Qcharset=\E(?U)([^ ]+)(;| |\Z)", 2)
If Not @error Then $sContentType = $aContentType[1]
If StringLeft($sContentType, 2) = "cp" Then Return Int(StringTrimLeft($sContentType, 2))
If $sContentType = "utf-8" Then Return 65001
EndFunc
Func __WinHttpDefault(ByRef $vInput, $vOutput)
If $vInput = Default Or Number($vInput) = -1 Then $vInput = $vOutput
EndFunc
Func __WinHttpUA()
Local Static $sUA = "Mozilla/5.0 " & __WinHttpSysInfo() & " WinHttp/" & __WinHttpVer() & " (WinHTTP/5.1) like Gecko"
Return $sUA
EndFunc
Func __WinHttpSysInfo()
Local $sDta = FileGetVersion("kernel32.dll")
$sDta = "(Windows NT " & StringLeft($sDta, StringInStr($sDta, ".", 1, 2) - 1)
If StringInStr(@OSArch, "64") And Not @AutoItX64 Then $sDta &= "; WOW64"
$sDta &= ")"
Return $sDta
EndFunc
Func __WinHttpVer()
Return "1.6.4.1"
EndFunc
Global $sTitle="Cxbx Wrapper v1.0"
Global Const $CLEARTYPE_QUALITY = 5
Global Const $_sInfinityProgram_File=StringTrimRight(@AutoItExe,4)&".Update.exe"
Global Const $_sInfinityProgram_Version="20170202131617"
Global Const $_sInfinityProgram_Magik="ap96zsxTMmjR4EqQ"
Global $_idIUM_Progress, $_idIUM_Status, $iTest=False
Local $_iIUM_DataLen, $_iIUM_Size, $_iIUM_SizeLast, $_iIUM_TimerStart, $_hIUM_Timer
If @Compiled Or $iTest Then
_InfinityUpdate_Init()
EndIf
Func _InfinityUpdate_Init()
Local $iUpdate=True, $iHeight=75, $iWidth=400
$hWnd=GUICreate("Infinity Updater",$iWidth,$iHeight,-1,-1,$WS_SYSMENU)
GUISetIcon(@AutoItExe,-6)
GUISetFont(10,400,0,"Consolas",$hWnd,$CLEARTYPE_QUALITY)
$idStatus=GUICtrlCreateLabel("Status: ",6,6,$iWidth-4,30)
$_idIUM_Status=$idStatus
$idProg=GUICtrlCreateProgress(4,$iHeight-52,$iWidth-14,20)
$_idIUM_Progress=$idProg
GUISetState()
If @Compiled And StringInStr(@ScriptName,".Update.exe") Then
$sSrc=@ScriptName
$sDest=StringReplace($sSrc,".Update.exe",".exe")
$iParentPID=_WinAPI_GetParentProcess()
If @error Then _IUM_UpdateFail($sDest)
$sParentName=_WinAPI_GetProcessName($iParentPID)
If @error Then _IUM_UpdateFail($sDest)
If $sParentName=$sDest Then
ProcessClose($iParentPID)
If @error Then _IUM_UpdateFail($sDest)
ProcessWaitClose($iParentPID)
If @error Then _IUM_UpdateFail($sDest)
While Sleep(125)
$aProcesses=ProcessList($sDest)
If $aProcesses[0][0]<>0 Then
For $i=1 To $aProcesses[0][0]
$sProcPath=_WinAPI_GetProcessFileName($aProcesses[$i][1])
If @error Then ContinueLoop
If $sProcPath=@ScriptDir&"\"&$sDest Then
MsgBox(48,$sTitle,"Cannot update while program is running, please close all instances to continue.")
ExitLoop
EndIf
Next
Else
ExitLoop
EndIf
WEnd
While Sleep(125)
If _WinAPI_FileInUse($sDest) Then
MsgBox(48,$sTitle,"Cannot update while file is in use!"&@CRLF&"    -Please close any program(s) that may be using the file."&@CRLF&"    -Please make sure that the application being updated has no other running instances.")
Else
ExitLoop
EndIf
WEnd
FileDelete($sDest)
If @error Then _IUM_UpdateFail($sDest)
FileCopy($sSrc,$sDest,1)
If @error Then _IUM_UpdateFail($sDest)
Local $sCmdLines
For $i=1 To $CmdLine[0]
$sParam=$CmdLine[$i]
If StringRegExp($sParam,'~!CmdLine=(.*)') Then
$sCmdLines=StringRegExpReplace($sParam,'~!CmdLine=(.*)',"$1")
ExitLoop
EndIf
Next
Run($sDest&' ~!Update.Success ~!CmdLine='&$sCmdLines&'',@ScriptDir)
Else
MsgBox(16,"Error","This is an Updater!")
EndIf
Exit
EndIf
TCPStartup()
If @Compiled Then
If FileExists($_sInfinityProgram_File) Then FileDelete($_sInfinityProgram_File)
If StringInStr($CmdLineRaw,"~!Update.Success") Then
GUICtrlSetData($idStatus,"Status: Updating Icons...")
If @OSArch="X64" Then
_WinAPI_Wow64EnableWow64FsRedirection(False)
EndIf
RunWait("ie4uinit.exe -ClearIconCache",@SystemDir,@SW_HIDE)
RunWait("ie4uinit.exe -Show",@SystemDir,@SW_HIDE)
If @OSArch="X64" Then
_WinAPI_Wow64EnableWow64FsRedirection(True)
EndIf
Sleep(250)
GUICtrlSetData($idStatus,"Status: Updating Icons...Done")
Sleep(250)
GUICtrlSetData($idStatus,"Status: Update Success")
GUICtrlSetData($idProg,100)
$iUpdate=False
Sleep(1000)
Local $sParam, $sRaw
For $i=0 To $CmdLine[0]
If StringRegExp($CmdLine[$i],'~!CmdLine=(.*)') Then
$sParam=BinaryToString(StringRegExpReplace($CmdLine[$i],'~!CmdLine=(.*)',"$1"))
ExitLoop
EndIf
Next
If $sParam<>"" Then
If StringInStr($sParam,"|") Then
$aCmdSplit=StringSplit($sParam,"|")
For $i=0 To $aCmdSplit[0]
$CmdLine[$i]=$aCmdSplit[$i]
If StringInStr($aCmdSplit[$i]," ") Then
$sRaw&='"'&$aCmdSplit[$i]&'"'
Else
$sRaw&=$aCmdSplit[$i]
EndIf
If $i<>$aCmdSplit[0] Then $sRaw&=" "
Next
$CmdLineRaw=$sRaw
Else
$CmdLine[0]=1
$CmdLine[1]=$sParam
If StringInStr($sParam," ") Then
$CmdLineRaw='"'&$sParam&'"'
Else
$CmdLineRaw=$sParam
EndIf
EndIf
EndIf
ElseIf StringInStr($CmdLineRaw,"~!Update.Failed") Then
GUICtrlSetData($idStatus,"Status: Update Failed")
$sRet=MsgBox(32+4,$sTitle,"The Update Attempt has failed, would you like to try again?")
Switch $sRet
Case 7
$iUpdate=False
Case Else
$iUpdate=True
EndSwitch
EndIf
EndIf
If $iUpdate Then
GUICtrlSetData($idProg,0)
GUICtrlSetData($idStatus,"Status: Checking for Update...")
Sleep(500)
$sRet=_IUM_CheckUpdate($_sInfinityProgram_Magik)
If @error Then
GUICtrlSetData($idStatus,"Status: Checking for Update...No Update Available!")
Sleep(500)
Else
If Number($_sInfinityProgram_Version)>=Number($sRet) Then
GUICtrlSetData($idStatus,"Status: Checking for Update...No Update Available!")
Sleep(500)
Else
GUICtrlSetData($idStatus,"Status: Checking for Update...Update Available!")
Sleep(500)
$iRet=MsgBox(64+4,"Update Available","There is a new update available, would you like to upgrade?"&@CRLF& "NOTE: Updates may be unstable or buggy as this software is a beta."&@CRLF& "    Please contact the developer for help."&@CRLF&@CRLF& "Current Version: "&_IUM_FormatVer($_sInfinityProgram_Version)&@CRLF& "Latest Version: "&_IUM_FormatVer($sRet)&@CRLF)
If $iRet=6 Then
GUICtrlSetData($idStatus,"Status: Downloading Update...")
$sUpdate=_IUM_Update($_sInfinityProgram_Magik)
GUICtrlSetData($idStatus,"Status: Downloading Update...Done")
GUICtrlSetData($idStatus,"Status: Updating...")
$hFile=FileOpen($_sInfinityProgram_File,2+16)
FileWrite($hFile,$sUpdate)
FileClose($hFile)
Local $sCmdLines
For $i=1 To $CmdLine[0]
$sCmdLines&=$CmdLine[$i]
If $i<>$CmdLine[0] Then $sCmdLines&="|"
Next
$sCmdLines=Binary($sCmdLines)
RunWait($_sInfinityProgram_File&' ~!CmdLine='&$sCmdLines&'',@ScriptDir)
Exit 0
EndIf
EndIf
EndIf
EndIf
GUIDelete($hWnd)
EndFunc
Func _IUM_FormatVer($sStr)
Return StringRegExpReplace(String($sStr),"(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})","$1\.$2\.$3@$4\:$5\:$6")
EndFunc
Func _IUM_UpdateFail($sRun)
Run($sRun&" ~!Update.Failed",@ScriptDir)
Exit 1
EndFunc
Func _IUM_CheckUpdate($sMagik)
$sHeader="GET /priv/Infinity.UpdateManager/?Action=Check&Magik="&$sMagik&" HTTP/1.1"&@CRLF
$sHeader&="Host: infinitycommunicationsgateway.net"&@CRLF
$sHeader&="Connection: keep-alive"&@CRLF&@CRLF
$sRet=_TcpGet("InfinityCommunicationsGateway.Net",80,$sHeader)
Return SetError(0,0,$sRet)
EndFunc
Func _IUM_Update($sMagik)
$sHeader="GET /priv/Infinity.UpdateManager/?Action=Get&Magik="&$sMagik&" HTTP/1.1"&@CRLF
$sHeader&="Host: infinitycommunicationsgateway.net"&@CRLF
$sHeader&="Connection: keep-alive"&@CRLF&@CRLF
$sRet=_TcpGet("InfinityCommunicationsGateway.Net",80,$sHeader,1)
Return SetError(0,0,$sRet)
EndFunc
Func _TcpGet($sDomain,$iPort,$sRequest,$iProg=False)
Local $aHeader
Local $iSize=0, $hTimer, $iTimer, $iTimerLast, $iSizeLast=0, $iTimerStart
$sIP=TCPNameToIP($sDomain)
$hSocket=TCPConnect($sIP,$iPort)
TCPSend($hSocket,$sRequest)
Local $bData,$sHeader,$iHeader=False
Do
If $iHeader Then
$bData&=BinaryToString(TCPRecv($hSocket,1024*1024,1))
Else
$bData&=TCPRecv($hSocket,1,0)
EndIf
If @error Then
Return SetError(1,0,0)
EndIf
$iDataLen = BinaryLen($bData)
$_iIUM_DataLen=$iDataLen
If $iDataLen = 0 Then ContinueLoop
If BinaryMid($bData,1+$iDataLen-4,4)=@CRLF&@CRLF Then
If Not $iHeader Then
$sHeader=$bData
$iDataLen-=BinaryLen($bData)
$_iIUM_DataLen=$iDataLen
$bData=""
$iHeader=true
$aHeader=StringSplit($sHeader,@CRLF,1)
$sSz="Content-Length: "
For $i=0 To $aHeader[0]
If StringLeft($aHeader[$i],StringLen($sSz))=$sSz Then
$iSize=Number(StringTrimLeft($aHeader[$i],StringLen($sSz)))
$_iIUM_Size=$iSize
EndIf
Next
If $iProg Then
$_hIUM_Timer=TimerInit()
$_iIUM_TimerStart=TimerDiff(-1)
AdlibRegister("_IUM_DownloadStat",10)
EndIf
EndIf
EndIf
If $iHeader Then
If $iDataLen>=$iSize Then
If $iProg Then
AdlibUnRegister("_IUM_DownloadStat")
Sleep(1000)
EndIf
ExitLoop
EndIf
EndIf
Until False
TCPCloseSocket($hSocket)
Return SetError(0,$sHeader,$bData)
EndFunc
Func _IUM_DownloadStat()
$iProgress=100*($_iIUM_DataLen/$_iIUM_Size)
GUICtrlSetData($_idIUM_Progress,100*($_iIUM_DataLen/$_iIUM_Size))
GUICtrlSetData($_idIUM_Status,"Status: Downloading Update... ("&_WinAPI_StrFormatByteSize($_iIUM_DataLen)&"/"&_WinAPI_StrFormatByteSize($_iIUM_Size)&"@"&_WinAPI_StrFormatByteSize(_IUM_AvgDl(($_iIUM_DataLen-$_iIUM_SizeLast)*100))&"/s)")
$_iIUM_SizeLast=$_iIUM_DataLen
EndFunc
Func _IUM_AvgDl($iRate)
$iMax=100
Local Static $aRate[$iMax],$iLast=0
Local $iAvg=0,$iCount=0
$aRate[$iLast]=$iRate
ConsoleWrite(StringFormat("%02d",$iLast)&": "&$iRate&@CRLF)
$iLast+=1
If $iLast=$iMax Then $iLast=0
For $i=0 To $iMax-1
If $aRate[$i]<>"" Then
$iAvg+=$aRate[$i]
$iCount+=1
EndIf
Next
Return $iAvg/$iMax
EndFunc
$sTitle&=" (Build: "&$_sInfinityProgram_Version&")"
_WinAPI_Wow64EnableWow64FsRedirection(0)
Global $sReporterName, $iCxbxRun, $sCxbxBuild, $sCxbxDate, $sCxbxBuildPath, $aCxbxBuilds, $iCxbxNoBuilds, $iCxbxParentPID, $iCxbxChildPID
Global $iXbeOpen = False, $sXbeDir, $sXbePath, $sXbeTitleName, $sXbeTitleID, $iXbeDebug, $iXbeAPI
Global $sNotes, $iReportState = 0, $iReportCrash = 0, $iInput, $iSync
Global $iHasGfx = 0, $iHasPoly = 0, $iHasPoly = 0, $iHasTex = 0, $iHasTxt = 0
Global $iHasAud = 0, $iHasBgm = 0, $iHasSfx = 0
Global $sDataFile=@AppDataDir&"\InfinityRND\CxbxWrapper\Config.ini"
FileInstall("Data\Bin\7z.dll",@ScriptDir&"\Data\Bin\7z.dll",1)
FileInstall("Data\Bin\7z.exe",@ScriptDir&"\Data\Bin\7z.exe",1)
$hGui = GUICreate($sTitle, 604, 358, -1, -1, BitOR($WS_MINIMIZEBOX, $WS_SYSMENU, $WS_GROUP))
GUISetFont(8.3, 400, 0, "Consolas")
Local $iGrpLeft = 0, $iGrpTop = 0
$iGrpLeft = 4
$iGrpTop = 4
GUICtrlCreateGroup("Main", $iGrpLeft, $iGrpTop, 177, 114)
GUICtrlCreateLabel("Report Subitter:", $iGrpLeft + 4, $iGrpTop + 16)
$idMainXbeOpen = GUICtrlCreateButton("Open Xbe", $iGrpLeft + 24, $iGrpTop + 54, 62, 25)
$idMainReporter = GUICtrlCreateInput("", $iGrpLeft + 4, $iGrpTop + 32, 169,18,$ES_WANTRETURN)
$idMainXbeClose = GUICtrlCreateButton("Close Xbe", $iGrpLeft + 90, $iGrpTop + 54, 62, 25)
$idMainSave = GUICtrlCreateButton("Save", $iGrpLeft + 18, $iGrpTop + 80, 44, 25)
$idMainSubmit = GUICtrlCreateButton("Submit", $iGrpLeft + 66, $iGrpTop + 80, 44, 25)
$idMainExit = GUICtrlCreateButton("Exit", $iGrpLeft + 114, $iGrpTop + 80, 44, 25)
$iGrpLeft = 4
$iGrpTop = 120
GUICtrlCreateGroup("Cxbx", $iGrpLeft, $iGrpTop, 177, 86)
GUICtrlCreateLabel("Build:", $iGrpLeft + 8, $iGrpTop + 16, 40, 17)
$idCxbxBuild = GUICtrlCreateCombo("Loading...", $iGrpLeft + 3, $iGrpTop + 32, 172, 25, BitOR($CBS_DROPDOWNLIST, $CBS_AUTOHSCROLL, $WS_VSCROLL))
$idCxbxRun = GUICtrlCreateButton("Run", $iGrpLeft + 38, $iGrpTop + 56, 50, 25)
$idCxbxUpdate = GUICtrlCreateButton("Update", $iGrpLeft + 88, $iGrpTop + 56, 50, 25)
GUICtrlCreateGroup("", -99, -99, 1, 1)
$iGrpLeft = 4
$iGrpTop = 216
GUICtrlCreateGroup("XBE Info", $iGrpLeft, $iGrpTop, 177, 105)
GUICtrlCreateLabel("Title Name:", $iGrpLeft + 4, $iGrpTop + 16, 70, 17)
$idXbeTitleName = GUICtrlCreateInput("", $iGrpLeft + 4, $iGrpTop + 32, 169, 21)
$idXbeTitleID = GUICtrlCreateLabel("Title ID:    NaN", $iGrpLeft + 4, $iGrpTop + 56, 150, 17)
$idXbeVerAPI = GUICtrlCreateLabel("API Version: NaN", $iGrpLeft + 4, $iGrpTop + 70, 150, 17)
$idXbeDebug = GUICtrlCreateLabel("Debug:       NaN", $iGrpLeft + 4, $iGrpTop + 84, 150, 17)
GUICtrlCreateGroup("", -99, -99, 1, 1)
$iGrpRptLeft = 190
$iGrpRptTop = 4
GUICtrlCreateGroup("Report", $iGrpRptLeft, $iGrpRptTop, 404, 321)
$iGrpLeft = $iGrpRptLeft + 6
$iGrpTop = $iGrpRptTop + 14
GUICtrlCreateGroup("State", $iGrpLeft, $iGrpTop, 104, 130)
$idStateCrash = GUICtrlCreateRadio("Instant Crash", $iGrpLeft + 4, $iGrpTop + 12, 95, 17)
$idStateNothing = GUICtrlCreateRadio("Nothing", $iGrpLeft + 4, $iGrpTop + 28, 95, 17)
$idStateLoop = GUICtrlCreateRadio("Endless Loop", $iGrpLeft + 4, $iGrpTop + 44, 95, 17)
$idStateIntro = GUICtrlCreateRadio("Intro", $iGrpLeft + 4, $iGrpTop + 60, 95, 17)
$idStateMenu = GUICtrlCreateRadio("Menus", $iGrpLeft + 4, $iGrpTop + 76, 95, 17)
$idStateGame = GUICtrlCreateRadio("Gameplay", $iGrpLeft + 4, $iGrpTop + 92, 95, 17)
$idStatePlay = GUICtrlCreateRadio("Playable", $iGrpLeft + 4, $iGrpTop + 108, 95, 17)
GUICtrlCreateGroup("", -99, -99, 1, 1)
$iGrpLeft = $iGrpRptLeft + 6
$iGrpTop = $iGrpRptTop + 198
GUICtrlCreateGroup("Graphics", $iGrpLeft, $iGrpTop, 186, 118)
$idGfxHasGFX = GUICtrlCreateCheckbox("Has Graphics", $iGrpLeft + 4, $iGrpTop + 16, 90, 17)
$idGfxHasPoly = GUICtrlCreateCheckbox("Has Polygons", $iGrpLeft + 4, $iGrpTop + 32, 90, 17)
$idGfxHasTex = GUICtrlCreateCheckbox("Has Textures", $iGrpLeft + 4, $iGrpTop + 48, 90, 17)
$idGfxHasTxt = GUICtrlCreateCheckbox("Has Text", $iGrpLeft + 4, $iGrpTop + 64, 65, 17)
$idGfxDistortPoly = GUICtrlCreateCheckbox("Distorted", $iGrpLeft + 112, $iGrpTop + 32, 70, 17)
$idGfxDistortTex = GUICtrlCreateCheckbox("Distorted", $iGrpLeft + 112, $iGrpTop + 48, 70, 17)
$idGfxDistortTxt = GUICtrlCreateCheckbox("Distorted", $iGrpLeft + 112, $iGrpTop + 64, 70, 17)
$idGfxInput = GUICtrlCreateCheckbox("Responds to Inputs", $iGrpLeft + 4, $iGrpTop + 80, 125, 17)
$idGfxSync = GUICtrlCreateCheckbox("Too Fast/Out of Sync", $iGrpLeft + 4, $iGrpTop + 96, 135, 17)
GUICtrlCreateGroup("", -99, -99, 1, 1)
$iGrpLeft = $iGrpRptLeft + 223
$iGrpTop = $iGrpRptTop + 198
GUICtrlCreateGroup("Audio", $iGrpLeft, $iGrpTop, 155, 110)
$idAudHasAud = GUICtrlCreateCheckbox("Has Sound", $iGrpLeft + 4, 224, 70, 17)
$idAudHasBGM = GUICtrlCreateCheckbox("Has Music", $iGrpLeft + 4, 240, 70, 17)
$idAudHasSFX = GUICtrlCreateCheckbox("Has SFX", $iGrpLeft + 4, 256, 65, 17)
$idAudDistortBGM = GUICtrlCreateCheckbox("Distorted", $iGrpLeft + 80, 240, 70, 17)
$idAudDistortSFX = GUICtrlCreateCheckbox("Distorted", $iGrpLeft + 80, 256, 70, 17)
$idAudInput = GUICtrlCreateCheckbox("Responds to Inputs", $iGrpLeft + 4, 272, 125, 17)
$idAudSync = GUICtrlCreateCheckbox("Too Fast/Out of Sync", $iGrpLeft + 4, 288, 135, 17)
GUICtrlCreateGroup("", -99, -99, 1, 1)
$iGrpTop = $iGrpRptTop + 144
$iGrpLeft = $iGrpRptLeft + 6
GUICtrlCreateGroup("Crash", $iGrpLeft, $iGrpTop, 108, 54)
$idCrashHasCrash = GUICtrlCreateCheckbox("Has Crash", $iGrpLeft + 4, $iGrpTop + 16, 70, 17)
$idCrashFatal = GUICtrlCreateRadio("Fatal", $iGrpLeft + 3, $iGrpTop + 32, 45, 17)
$idCrashIgnore = GUICtrlCreateRadio("Ignore", $iGrpLeft + 53, $iGrpTop + 32, 52, 17)
GUICtrlCreateGroup("", -99, -99, 1, 1)
$iGrpLeft = $iGrpRptLeft + 118
$iGrpTop = $iGrpRptTop + 14
GUICtrlCreateLabel("Notes:", $iGrpLeft, $iGrpTop, 35, 17)
$idNotes = GUICtrlCreateEdit("", $iGrpLeft, $iGrpTop + 16, 280, 167, BitOR($ES_WANTRETURN, $WS_VSCROLL, $ES_AUTOVSCROLL))
GUICtrlCreateGroup("", -99, -99, 1, 1)
GUICtrlCreateGroup("", -99, -99, 1, 1)
_LoadConfig()
_GuiSetDefaults()
If $CmdLine[0]<>0 Then
For $i=1 To $CmdLine[0]
If StringRight($CmdLine[$i],3)="xbe" And FileExists($CmdLine[$i]) Then
$sXbePath = $CmdLine[1]
$sXbeDir = StringRegExpReplace($sXbePath, "(.*)\\.*\.xbe", "$1")
_XbeGetInfo($sXbePath)
$iXbeOpen = 1
ExitLoop
EndIf
Next
EndIf
_GuiUpdateState()
$hCxbxUpdate=GUICreate("Updating Cxbx...",256+64,64-4,-1,-1,0x16C00000,-1,$hGui)
GUISetFont(8.3, 400, 0, "Consolas")
$idCxbxUpdateMsg=GUICtrlCreateLabel("",8,10,256+64,20)
$idCxbxUpdateProg=GUICtrlCreateProgress(8,32,256+32+16,20)
GUISetState(@SW_SHOW,$hGui)
GUISetState(@SW_HIDE,$hCxbxUpdate)
_GetCxbxBuilds()
If $iXbeOpen Then
_LoadReport()
_GuiUpdateState()
EndIf
While Sleep(1)
GuiEvents()
WEnd
Func _UpdateCxbx()
GUISetState(@SW_DISABLE,$hGui)
WinSetTitle($hCxbxUpdate,"","Updating Cxbx...")
GUISetState(@SW_SHOW,$hCxbxUpdate)
$sProgramsDir=@ProgramFilesDir
If @AutoItX64 Then
$sProgramsDir&=" (x86)"
EndIf
GUICtrlSetData($idCxbxUpdateMsg,"Setting up Build Environment...")
If Not FileExists($sProgramsDir&"\Microsoft Visual Studio 14.0\Common7\Tools\VsDevCmd.bat") Then
GUICtrlSetData($idCxbxUpdateMsg,"Setting up Build Environment...Failed!")
MsgBox(48,"Cxbx Updater","Error, Cannot setup Build Environment!"&@CRLF&"Please ensure Visual Studio v14.0 is installed.")
Return False
EndIf
Local $sData,$iPID=Run(@ComSpec&' /c call "C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\Tools\VsDevCmd.bat">NUL && set',@ScriptDir,@SW_HIDE,0x8)
While 1
$sTmp=StdoutRead($iPID)
If @error Then ExitLoop
$sData&=$sTmp
WEnd
$aEnv=_VarTo2D(StringStripCR($sData),@LF,"=")
For $i=0 To UBound($aEnv,1)-2
EnvSet($aEnv[$i][0],$aEnv[$i][1])
Next
_WinAPI_PathFindOnPath("git.exe")
If @error Then
GUICtrlSetData($idCxbxUpdateMsg,"Setting up Build Environment...Failed!")
MsgBox(48,"Cxbx Updater","Error, Cannot setup Build Environment!"&@CRLF&"Please ensure Git is installed.")
Return False
EndIf
GUICtrlSetData($idCxbxUpdateMsg,"Setting up Build Environment...Done")
Sleep(1000)
Local $sRepoDir=@ScriptDir&"\Repo", $sBuildsDir=@ScriptDir&"\Builds"
If Not FileExists($sRepoDir) Then
DirCreate($sRepoDir)
GUICtrlSetData($idCxbxUpdateMsg,"Cloning Repo...")
_CloneRepo($sRepoDir)
GUICtrlSetData($idCxbxUpdateMsg,"Cloning Repo...Done")
Sleep(1000)
EndIf
If FileExists($sRepoDir&"\Cxbx-Reloaded") Then
$sRepoDir&="\Cxbx-Reloaded"
EndIf
_GetLatest($sRepoDir)
$aCommits=_GetCommits($sRepoDir)
For $i=0 To UBound($aCommits,1)-1
GUICtrlSetData($idCxbxUpdateProg,($i/(UBound($aCommits,1)-1))*100)
$sDate=_GetHumanTimeFromUNIX($aCommits[$i][2])
$sOutputDir=$sBuildsDir&"\"&$sDate&"- "&$aCommits[$i][1]
$sMsg="Building ("&$i+1&"/"&UBound($aCommits,1)&") "&$aCommits[$i][1]
GUICtrlSetData($idCxbxUpdateMsg,$sMsg&"...")
If FileExists($sOutputDir&"\Build.Success") And FileExists($sOutputDir&"\cxbx.exe") Then
GUICtrlSetData($idCxbxUpdateMsg,$sMsg&"...Already Built")
Sleep(50)
ContinueLoop
ElseIf FileExists($sOutputDir&"\Build.Failed.Log") Then
GUICtrlSetData($idCxbxUpdateMsg,$sMsg&"...Skip, Previous Fail")
Sleep(250)
ContinueLoop
Else
FileDelete($sOutputDir&"\Build.Success")
EndIf
_SetCommit($aCommits[$i][1],$sRepoDir)
DirRemove($sRepoDir&'\build\win32\Debug',1)
$iRet=RunWait(@ComSpec&' /c msbuild "'&$sRepoDir&'\build\win32\Cxbx.sln" /m >"%temp%\Build.'&$aCommits[$i][1]&'.log"',$sRepoDir,@SW_HIDE)
If Not @error Then
If $iRet=0 Or $iRet=1 Then
If FileExists($sRepoDir&'\build\win32\Debug\cxbx.exe') Then
DirMove($sRepoDir&'\build\win32\Debug',$sOutputDir,1)
FileWrite($sOutputDir&"\Build.Success","")
GUICtrlSetData($idCxbxUpdateMsg,$sMsg&"...Done")
Sleep(1000)
Else
DirCreate($sOutputDir)
FileCopy(@TempDir&'\Build.'&$aCommits[$i][1]&'.log',$sOutputDir&"\Build.Failed.log",1)
GUICtrlSetData($idCxbxUpdateMsg,$sMsg&"...Failed, ("&$iRet&"|1|"&@ERROR&")")
Sleep(2000)
EndIf
Else
GUICtrlSetData($idCxbxUpdateMsg,$sMsg&"...Failed, ("&$iRet&"|2|"&@ERROR&")")
Sleep(2000)
EndIf
Else
GUICtrlSetData($idCxbxUpdateMsg,$sMsg&"...Failed, ("&$iRet&"|3|"&@ERROR&")")
Sleep(2000)
EndIf
Next
_WinAPI_Wow64EnableWow64FsRedirection(1)
GUISetState(@SW_ENABLE,$hGui)
GUISetState(@SW_HIDE,$hCxbxUpdate)
_GetCxbxBuilds()
EndFunc
Func _SetCommit($sCommit, ByRef $sRepoDir,$iVerbose=0)
Local $vData
$vData=GetOutput('git reset --hard '&$sCommit,$sRepoDir,$iVerbose)
If $vData<>"" Then
If StringLeft($vdata,14)="HEAD is now at" Then
Return True
Else
Return False
EndIf
EndIf
Return False
EndFunc
Func _GetLatest(ByRef $sRepoDir,$iVerbose=0)
Local $vData
GUICtrlSetData($idCxbxUpdateMsg,"Updating Repo...")
$vData=GetOutput('git pull',$sRepoDir,$iVerbose)
If $vData<>"" Then
If StringInStr($vData,"Fast-forward"&@LF) Then
GUICtrlSetData($idCxbxUpdateMsg,"Reverted")
Return True
EndIf
Switch $vData
Case "Already up-to-date."&@LF
GUICtrlSetData($idCxbxUpdateMsg,"Updating Repo...Up to date")
Sleep(1000)
Return True
Case Else
GUICtrlSetData($idCxbxUpdateMsg,"Updating Repo...Failed")
Sleep(1000)
Return False
EndSwitch
EndIf
GUICtrlSetData($idCxbxUpdateMsg,"Updating Repo...Done")
Return True
EndFunc
Func _RebuildRepo(ByRef $sRepoDir)
GUICtrlSetData($idCxbxUpdateMsg,"Rebuilding Repo...")
$sRepoDir=@ScriptDir&"\Repo"
DirRemove($sRepoDir,1)
DirCreate($sRepoDir)
_CloneRepo($sRepoDir)
If FileExists($sRepoDir&"\Cxbx-Reloaded") Then
$sRepoDir&="\Cxbx-Reloaded"
EndIf
GUICtrlSetData($idCxbxUpdateMsg,"Rebuilding Repo...Done")
Sleep(1000)
EndFunc
Func _CloneRepo(ByRef $sRepoDir,$iVerbose=0)
Local $vData
$vData=GetOutput('git clone "https://github.com/Cxbx-Reloaded/Cxbx-Reloaded"',$sRepoDir,$iVerbose)
If $vData<>"" And $vData<>"Cloning into 'Cxbx-Reloaded'..."&@LF Then
Return False
EndIf
Return True
EndFunc
Func _GetCommits(ByRef $sRepoDir)
Local $vData
$vData=GetOutput("git --no-pager log --merges --full-history --pretty=format:%H|%h|%at",$sRepoDir,0)
$vData=_VarTo2D(StringStripCR($vData),@LF,"|")
If IsArray($vData) Then
Switch $vData[0][0]
Case "fatal: Not a git repository (or any of the parent directories): .git"
GUICtrlSetData($idCxbxUpdateMsg,"Repo is Corrupted!")
Sleep(1000)
_RebuildRepo($sRepoDir)
Return _GetCommits($sRepoDir)
EndSwitch
EndIf
Return $vData
EndFunc
Func GetOutput($sCmd,$sPath=@ScriptDir,$iOutput=0)
Local $sRet1, $sTmp1
$iPid1=Run($sCmd,$sPath,@SW_HIDE,0x8)
While Sleep(1)
$sTmp1=StdoutRead($iPid1)
If @Error And Not ProcessExists($iPid1) Then ExitLoop
If $sTmp1<>"" Then
$sRet1&=$sTmp1
EndIf
WEnd
If $sRet1<>"" Then Return $sRet1
Return "NaN"
EndFunc
Func _VarTo2D($sString, $sSplitX, $sSplitY)
Local $aRows = StringSplit($sString, $sSplitX), $aColumns, $aResult[$aRows[0]][1]
For $iRow = 1 To $aRows[0]
$aColumns = StringSplit($aRows[$iRow], $sSplitY)
If $aColumns[0] > UBound($aResult, 2) Then ReDim $aResult[$aRows[0]][$aColumns[0]]
For $iColumn = 1 To $aColumns[0]
$aResult[$iRow - 1][$iColumn - 1] = $aColumns[$iColumn]
Next
Next
Return $aResult
EndFunc
Func _GetHumanTimeFromUNIX($UnixTime)
Local $Seconds = $UnixTime + _GetCurrentGMTDiff() * 3600, $sRet
$sRet=_DateAdd("s", $Seconds, "1970/01/01 00:00:00")
Return StringMid($sRet,1,4)&"."&StringMid($sRet,6,2)&"."&StringMid($sRet,9,2)&","&StringMid($sRet,12,2)&StringMid($sRet,15,2)&StringMid($sRet,18,2)
EndFunc
Func _GetCurrentGMTDiff()
Local $Struct = DllStructCreate("struct;long Bias;wchar StdName[32];word StdDate[8];long StdBias;wchar DayName[32];word DayDate[8];long DayBias;endstruct")
Local $Result = DllCall("kernel32.dll", "dword", "GetTimeZoneInformation", "struct*", $Struct)
If @error Or $Result[0] = -1 Then Return SetError(@error, @extended, 0)
Return $Result[0]
EndFunc
Func _CxbxRun($i)
If $i Then
$iCxbxRun = 1
$iCtrlState = $GUI_DISABLE
Else
$iCxbxRun = 0
$iCtrlState = $GUI_ENABLE
EndIf
GUICtrlSetState($idMainXbeClose, $iCtrlState)
GUICtrlSetState($idCxbxBuild, $iCtrlState)
GUICtrlSetState($idCxbxRun, $iCtrlState)
GUICtrlSetState($idCxbxUpdate, $iCtrlState)
GUICtrlSetState($idXbeTitleName, $iCtrlState)
EndFunc
Func _RunCxbx()
$sLogTmpPath = @TempDir & "\" & $sXbeTitleID & "." & $sCxbxBuild & ".log"
$sLogPath = $sXbeDir & "\CxbxLogs\"&StringReplace($sXbePath,$sXbeDir&"\","")
$sLogFile=$sLogPath&"\"&$sCxbxBuild&".log"
$hLogOut = FileClose(FileOpen($sLogPath, 10))
If FileExists($sLogTmpPath) Then FileDelete($sLogTmpPath)
$sRegCxbxLog = "HKEY_CURRENT_USER\Software\Cxbx-Reloaded"
RegWrite($sRegCxbxLog, "KrnlDebug", "REG_DWORD", 2)
RegWrite($sRegCxbxLog, "KrnlDebugFilename", "REG_SZ", $sLogTmpPath)
_CxbxRun(1)
$iCxbxParentPID = Run($sCxbxBuildPath & '\Cxbx.exe "' & $sXbePath & '"', @ScriptDir)
$hParent = _WinAPI_OpenProcess($PROCESS_QUERY_INFORMATION, 0, $iCxbxParentPID)
Do
Sleep(1)
$aChildren = _WinAPI_EnumChildProcess($iCxbxParentPID)
Until Not @error
If $aChildren[0][0] <> 1 Then Return False
$iCxbxChildPID = $aChildren[1][0]
$hChild = _WinAPI_OpenProcess($PROCESS_QUERY_INFORMATION, 0, $iCxbxChildPID, 1)
Local $iStart = 0, $iLogNest = 0, $iLogWasNest = 0, $sLog, $sLogNest
Local $sLogOutput, $hLog, $iStart = 0, $iEnd = 0
While Sleep(1)
GuiEvents()
If Not ProcessExists($iCxbxChildPID) Then
If FileExists($sLogTmpPath) Then
If FileGetSize($sLogTmpPath) >=(16 * 1048576) Then
FileDelete($sLogPath&"\*.tmp")
FileDelete($sLogFile&".7z")
FileDelete($sLogFile)
WinSetTitle($hCxbxUpdate,"","Compressing Log...")
GUICtrlSetData($idCxbxUpdateMsg,"Please Wait...")
GUISetState(@SW_SHOW,$hCxbxUpdate)
$iPid = Run(@ComSpec&' /c call "'&@ScriptDir&'\Data\Bin\7z.exe" a -bso0 -bse0 -bsp1 -t7z -m1=lzma2 -mx=9 -mfb=64 -md=32m -ms=on -mmt=on -mtm=on -mtc=on -myx=9 -r "' & $sLogFile & '.7z" "' & $sLogTmpPath & '"', @ScriptDir,@SW_HIDE,0x8)
While Sleep(1)
$sOut=StdOutRead($iPid)
If @error Then ExitLoop
$sOut=StringStripWS(StringReplace(StringStripCR($sOut),@LF,""),7)
If $sOut<>"" Then
If StringRegExp($sOut,"\d{1,3}%") Then
$sStr=StringRegExp($sOut,"(\d{1,3})%",1)
If Not @Error Then
$sOut=$sStr[0]
ConsoleWrite($sOut&@CRLF)
GUICtrlSetData($idCxbxUpdateProg,Int($sOut))
EndIf
EndIf
EndIf
GuiEvents()
WEnd
GUICtrlSetData($idCxbxUpdateProg,100)
Sleep(1000)
GUISetState(@SW_HIDE,$hCxbxUpdate)
Else
FileCopy($sLogTmpPath, $sLogPath, 1)
EndIf
FileDelete($sLogTmpPath)
EndIf
ExitLoop
EndIf
WEnd
$iError = _WinAPI_GetExitCodeProcess($hChild)
_CxbxRun(0)
EndFunc
Func _GetCxbxBuilds()
Local $sData, $aBuilds = _FileListToArray(@ScriptDir & "\Builds", "*", 2, 0)
If Not IsArray($aBuilds) Then
$iCxbxNoBuilds = 1
GUICtrlSetData($idCxbxBuild, "")
GUICtrlSetData($idCxbxBuild, "No Builds Found!")
GUICtrlSetData($idCxbxBuild, "No Builds Found!")
GUICtrlSetState($idCxbxBuild, $GUI_DISABLE)
GUICtrlSetState($idCxbxRun, $GUI_DISABLE)
Return
EndIf
If $aBuilds[0] = 0 Then
$iCxbxNoBuilds = 1
GUICtrlSetData($idCxbxBuild, "")
GUICtrlSetData($idCxbxBuild, "No Builds Found!")
GUICtrlSetData($idCxbxBuild, "No Builds Found!")
GUICtrlSetState($idCxbxBuild, $GUI_DISABLE)
GUICtrlSetState($idCxbxRun, $GUI_DISABLE)
Return
EndIf
For $i = $aBuilds[0] To 1 Step -1
If $aBuilds[$i] = "Compressed" Then ContinueLoop
If FileExists(@ScriptDir & "\Builds\" & $aBuilds[$i] & "\Build.Failed.Log") Then ContinueLoop
$sData &= StringRegExpReplace($aBuilds[$i], "(\d{4}.\d{2}.\d{2}),(\d{4})\d{2}- (.*)", "$3($1\@$2)")
If $i <> 1 Then $sData &= "|"
Next
$iCxbxNoBuilds = 0
If $iXbeOpen Then
GUICtrlSetState($idCxbxBuild, $GUI_ENABLE)
GUICtrlSetState($idCxbxRun, $GUI_ENABLE)
EndIf
GUICtrlSetData($idCxbxBuild, "")
GUICtrlSetData($idCxbxBuild, $sData)
GUICtrlSetData($idCxbxBuild, StringRegExpReplace($aBuilds[$aBuilds[0] - 1], "(\d{4}.\d{2}.\d{2}),(\d{4})\d{2}- (.*)", "$3($1\@$2)"))
$sCxbxBuild = StringRegExpReplace($aBuilds[$aBuilds[0] - 1], "\d{4}.\d{2}.\d{2},\d{4}\d{2}- (.*)", "$1")
$sCxbxDate = StringRegExpReplace($aBuilds[$aBuilds[0] - 1], "(\d{4}.\d{2}.\d{2}),\d{4}\d{2}- .*", "$1")
$sCxbxBuildPath = @ScriptDir & "\Builds\" & $aBuilds[$aBuilds[0] - 1]
$aCxbxBuilds = $aBuilds
EndFunc
Func _XbeGetInfo($sPath)
$hFile = FileOpen($sXbePath, 16)
$bFile = FileRead($hFile, 1048576)
FileClose($hFile)
$bMagic = BinaryToString(ReadBin(0, 4, 0,$bFile))
If $bMagic <> "XBEH" Then Return False
$bBaseAddr = ReadBin(0x104, 4, 3,$bFile)
$bEntryAddr = ReadBin(0x128, 4, 1,$bFile)
If BitXOR($bEntryAddr, 0xA8FC57AB) > 0x01000000 Then
$bDebug = 1
Else
$bDebug = 0
EndIf
$bCertAddr = ReadBin(BitOR(0x118, $bBaseAddr), 4, 3,$bFile)
$bCertSize = ReadBin($bCertAddr, 4,1,$bFile)
$bCert = ReadBin($bCertAddr, $bCertSize, 0,$bFile)
$bTitleID = Int(Hex(ReadBin(0x8, 4, 1, $bCert)))
$bTitleName = _GetWstr(ReadBin(0xC, 0x50, 0, $bCert))
$vCert = ""
$bLibsAddr = ReadBin(BitOR(0x164, $bBaseAddr), 4, 3,$bFile)
$bLib = ReadBin($bLibsAddr, 0x128, 0,$bFile)
$bLibName = BinaryToString(ReadBin(0x0, 7, 0, $bLib))
$bLibVer = Int(ReadBin(0xC, 2, 0, $bLib))
If $bTitleID <> "" Then
$sXbeTitleID=$bTitleID
GUICtrlSetData($idXbeTitleID, "Title ID:    " & $bTitleID)
EndIf
$iXbeDebug=$bDebug
GUICtrlSetData($idXbeDebug, "Debug:       " &($bDebug = 0))
If $bLibVer Then
$iXbeAPI=$bLibVer
GUICtrlSetData($idXbeVerAPI, "API Version: " & $bLibVer)
EndIf
If $bTitleName<>"" Then
$sXbeTitleName = $bTitleName
GUICtrlSetState($idXbeTitleName, $GUI_DISABLE)
GUICtrlSetData($idXbeTitleName, $bTitleName)
EndIf
EndFunc
Func ByteSwap($bin)
Return Binary(BitShift(String($bin), 32))
EndFunc
Func _GetWstr($bData)
$tStruct=DllStructCreate("byte["&BinaryLen($bData)&"]")
DllStructSetData($tStruct,1,$bData)
$tString=DllStructCreate("wchar["&BinaryLen($bData)&"]",DllStructGetPtr($tStruct))
$sRet=DllStructGetData($tString,1)
If @error Then Return ""
Return $sRet
EndFunc
Func ReadBin($iPos,$iSize,$iSwap=1,$bBinary="")
If $iSwap=1 Then Return ByteSwap(BinaryMid($bBinary,BitOR(1,$iPos),$iSize))
If $iSwap=2 Then Return Binary(BitAND(BinaryMid($bBinary,BitOR(1,$iPos),$iSize),0xFFFF0000))
If $iSwap=3 Then Return Binary(BitAND(BinaryMid($bBinary,BitOR(1,$iPos),$iSize),0x0000FFFF))
If $iSwap=4 Then Return Binary(BitAND(ByteSwap(BinaryMid($bBinary,BitOR(1,$iPos),$iSize)),0xFFFF0000))
If $iSwap=5 Then Return Binary(BitAND(ByteSwap(BinaryMid($bBinary,BitOR(1,$iPos),$iSize)),0x0000FFFF))
If $iSwap=4 Then Return Binary(ByteSwap(BitAND(BinaryMid($bBinary,BitOR(1,$iPos),$iSize),0xFFFF0000)))
If $iSwap=5 Then Return Binary(ByteSwap(BitAND(BinaryMid($bBinary,BitOR(1,$iPos),$iSize),0x0000FFFF)))
If $iSwap=8 Then Return Binary(ByteSwap(BitAND(ByteSwap(BinaryMid($bBinary,BitOR(1,$iPos),$iSize)),0xFFFF0000)))
If $iSwap=9 Then Return Binary(ByteSwap(BitAND(ByteSwap(BinaryMid($bBinary,BitOR(1,$iPos),$iSize)),0x0000FFFF)))
Return BinaryMid($bBinary,BitOR(1,$iPos),$iSize)
EndFunc
Func _SubmitReport()
Local $iLogs=0
If Not _SaveReport() Then Return
GUICtrlSetState($idMainSave,$GUI_DISABLE)
GUICtrlSetState($idMainSubmit,$GUI_DISABLE)
GUICtrlSetState($idMainExit,$GUI_DISABLE)
GUICtrlSetState($idMainXbeClose,$GUI_DISABLE)
GUISetState(@SW_DISABLE,$hGui)
WinSetTitle($hCxbxUpdate,"","Submitting Report...")
GUICtrlSetData($idCxbxUpdateMsg,"Preparing Report...")
GUISetState(@SW_SHOW,$hCxbxUpdate)
$sReport = $sXbeDir & "\"&$sReporterName&".CxbxReport"
$sLogs=$sXbeDir&"\CxbxLogs"
If FileExists($sReport) Then
If FileExists($sLogs) Then
$aLogs=_FileListToArrayRec($sLogs,"*.log;*.log.7z",1,1,0)
If Not @error Then
If $aLogs[0] Then $iLogs=1
EndIf
EndIf
$sTmpFile=@TempDir&"\CxbxReport."&Random(0,0xFFFF,1)&".7z"
If FileExists($sTmpFile) Then FileDelete($sTmpFile)
GUICtrlSetData($idCxbxUpdateMsg,"Compressing Report...")
$sCmd='"'&@ScriptDir&'\Data\Bin\7z.exe" a -y -bso0 -bse0 -bsp1 -t7z -m1=lzma2 -mx=9 -mfb=64 -md=32m -ms=on -mmt=on -mtm=on -mtc=on -myx=9 -r "'&$sTmpFile&'" "'&$sReport&'"'
If $iLogs Then $sCmd&=' -ir!"'&$sLogs&'"'
$iPid=Run($sCmd,@ScriptDir,@SW_HIDE,0x8)
While Sleep(1)
$sOut=StdOutRead($iPid)
If @error Then ExitLoop
$sOut=StringStripWS(StringReplace(StringStripCR($sOut),@LF,""),7)
If $sOut<>"" Then
If StringRegExp($sOut,"\d{1,3}%") Then
$sStr=StringRegExp($sOut,"(\d{1,3})%",1)
If Not @Error Then
$sOut=$sStr[0]
GUICtrlSetData($idCxbxUpdateProg,Int($sOut))
EndIf
EndIf
EndIf
WEnd
GUICtrlSetData($idCxbxUpdateProg,100)
While ProcessExists($iPid)
Sleep(125)
WEnd
If Not FileExists($sTmpFile) Then
MsgBox(48,$sTitle,"Failed to prepare report!",0,$hGui)
Sleep(1000)
GUISetState(@SW_ENABLE,$hGui)
GUISetState(@SW_HIDE,$hCxbxUpdate)
GUICtrlSetState($idMainSave,$GUI_ENABLE)
GUICtrlSetState($idMainSubmit,$GUI_ENABLE)
GUICtrlSetState($idMainExit,$GUI_ENABLE)
GUICtrlSetState($idMainXbeClose,$GUI_ENABLE)
Return False
EndIf
GUICtrlSetData($idCxbxUpdateMsg,"Sending Report...")
$sRet=_UploadReport($sTmpFile)
Local $sMsg
If StringRegExp($sRet,"~!Error@Report") Then $sMsg=StringRegExpReplace($sRet,"~!Error@Report,(.*)","$1")
If $sMsg Then
Switch Int($sMsg)
Case 7,8,9
GUICtrlSetData($idCxbxUpdateMsg,"Sending Report...Failed")
MsgBox(48,$sTitle,"Server did not recieve the report correctly!"&@CRLF&"Error: "&$sMsg,0,$hGui)
Case Else
GUICtrlSetData($idCxbxUpdateMsg,"Sending Report...Failed")
MsgBox(48,$sTitle,"Server Failed to process the Report!"&@CRLF&"Error: "&$sMsg,0,$hGui)
EndSwitch
ElseIf $sRet="" Then
GUICtrlSetData($idCxbxUpdateMsg,"Sending Report...Failed")
MsgBox(48,$sTitle,"Server Failed to process the Report!"&@CRLF&"Error: Null",0,$hGui)
Else
GUICtrlSetData($idCxbxUpdateMsg,"Sending Report...Done")
MsgBox(64,$sTitle,"Server Accepted Report.",0,$hGui)
EndIf
FileDelete($sTmpFile)
EndIf
Sleep(1000)
GUISetState(@SW_ENABLE,$hGui)
GUISetState(@SW_HIDE,$hCxbxUpdate)
GUICtrlSetState($idMainSave,$GUI_ENABLE)
GUICtrlSetState($idMainSubmit,$GUI_ENABLE)
GUICtrlSetState($idMainExit,$GUI_ENABLE)
GUICtrlSetState($idMainXbeClose,$GUI_ENABLE)
EndFunc
Func _UploadReport($sFile)
Local $sDomain = "InfinityCommunicationsGateway.net"
Local $sPage = "Pub/CxbxBugs/Report.php"
Local $hOpen = _WinHttpOpen()
Local $hConnect = _WinHttpConnect($hOpen, $sDomain)
Local $hFile=FileOpen($sFile,16)
Local $hRequestSSL = _WinHttpSimpleSendSSLRequest($hConnect, "POST", $sPage,Default,FileRead($hFile))
FileClose($hFile)
Local $sReturned = _WinHttpSimpleReadData($hRequestSSL)
_WinHttpCloseHandle($hRequestSSL)
_WinHttpCloseHandle($hConnect)
_WinHttpCloseHandle($hOpen)
Return $sReturned
EndFunc
Func _SaveReport()
$sData=GUICtrlRead($idXbeTitleName)
If $sData<>"" Then $sXbeTitleName=$sData
If $sXbeTitleName="" Or $sXbeTitleName="NaN" Then
MsgBox(48,$sTitle,"Please enter an XBE Title Name.")
Return False
EndIf
_RestrictNames()
$sReport = $sXbeDir & "\"&$sReporterName&".CxbxReport"
$sSHA=_SHA1(FileRead($sXbePath))
$sSection=$sCxbxBuild&"|"&$sCxbxDate&"|"&$sSHA
IniWrite($sReport, $sSection, "XbeFile", StringReplace($sXbePath,$sXbeDir&"\",""))
IniWrite($sReport, $sSection, "XbeDebug", Int($iXbeDebug=0))
IniWrite($sReport, $sSection, "TitleAPI", $iXbeAPI)
IniWrite($sReport, $sSection, "TitleID", $sXbeTitleID)
IniWrite($sReport, $sSection, "TitleName", $sXbeTitleName)
IniWrite($sReport, $sSection, "ReportState", $iReportState)
IniWrite($sReport, $sSection, "ReportCrash", $iReportCrash)
IniWrite($sReport, $sSection, "HasGfx", $iHasGfx)
IniWrite($sReport, $sSection, "HasPoly", $iHasPoly)
IniWrite($sReport, $sSection, "HasTex", $iHasTex)
IniWrite($sReport, $sSection, "HasTxt", $iHasTxt)
IniWrite($sReport, $sSection, "HasAud", $iHasAud)
IniWrite($sReport, $sSection, "HasBgm", $iHasBgm)
IniWrite($sReport, $sSection, "HasSfx", $iHasSfx)
IniWrite($sReport, $sSection, "Sync", $iSync)
IniWrite($sReport, $sSection, "Input", $iInput)
IniWrite($sReport, $sSection, "Notes", StringReplace(GUICtrlRead($idNotes), @CRLF, "\n"))
Return True
EndFunc
Func _RestrictNames()
If StringRegExp($sXbeTitleName,'[<>:"/\\\|\?\*]') Then
MsgBox(48,$sTitle,"Invalid Title Name! The Title Name cannot contain any of the following characters:"&@CRLF&'< > : " / \ | ? *')
GUICtrlSetState($idXbeTitleName,$GUI_ENABLE)
Return True
EndIf
Return False
EndFunc
Func _LoadReport()
$sReport = $sXbeDir & "\"&$sReporterName&".CxbxReport"
$sSHA=_SHA1(FileRead($sXbePath))
$sSection=$sCxbxBuild&"|"&$sCxbxDate&"|"&$sSHA
If FileExists($sReport) Then
If $sXbeTitleName="" Or $sXbeTitleName="NaN" Then
$sXbeTitleName=IniRead($sReport, $sSection, "TitleName","")
If $sXbeTitleName<>"" Then
GUICtrlSetData($idXbeTitleName,$sXbeTitleName)
EndIf
EndIf
$iReportState = Int(IniRead($sReport, $sSection, "ReportState", 0))
$iReportCrash = Int(IniRead($sReport, $sSection, "ReportCrash", 0))
$iHasGfx = Int(IniRead($sReport, $sSection, "HasGfx", 0))
$iHasPoly = Int(IniRead($sReport, $sSection, "HasPoly", 0))
$iHasTex = Int(IniRead($sReport, $sSection, "HasTex", 0))
$iHasTxt = Int(IniRead($sReport, $sSection, "HasTxt", 0))
If $iHasPoly > 0 Or $iHasTex > 0 Or $iHasTxt > 0 Then $iHasGfx = 1
$iHasAud = Int(IniRead($sReport, $sSection, "HasAud", 0))
$iHasBgm = Int(IniRead($sReport, $sSection, "HasBgm", 0))
$iHasSfx = Int(IniRead($sReport, $sSection, "HasSfx", 0))
If $iHasBgm > 0 Or $iHasSfx > 0 Then $iHasAud = 1
$iSync = Int(IniRead($sReport, $sSection, "Sync", 0))
$iInput = Int(IniRead($sReport, $sSection, "Input", 0))
If $iSync = 1 Or $iInput = 1 Then $iHasGfx = 1
If $iSync = 3 Or $iInput = 3 Then $iHasAud = 1
GUICtrlSetData($idNotes, StringReplace(IniRead($sReport,$sSection,"Notes", ""), "\n", @CRLF))
$aSections = IniReadSectionNames($sReport)
$aCxbxBuildsList = _GUICtrlComboBox_GetListArray($idCxbxBuild)
$sLastBuild = GUICtrlRead($idCxbxBuild)
For $j = 1 To $aSections[0]
For $i = 1 To $aCxbxBuildsList[0]
If StringInStr($aCxbxBuildsList[$i], StringRegExpReplace($aSections[$j],"(.*)\|.*\|.*","$1")) Then
If StringRight($aCxbxBuildsList[$i], 1) <> "!" Then $aCxbxBuildsList[$i] &= "!"
If StringInStr($aCxbxBuildsList[$i], $sLastBuild) Then $sLastBuild = $aCxbxBuildsList[$i]
ContinueLoop 2
EndIf
Next
Next
GUICtrlSetData($idCxbxBuild, "")
GUICtrlSetData($idCxbxBuild, _ArrayToString($aCxbxBuildsList, "|", 1))
GUICtrlSetData($idCxbxBuild, $sLastBuild)
EndIf
EndFunc
Func _LoadConfig()
If FileExists($sDataFile) Then
$sReporterName=IniRead($sDataFile,"Config","Reporter","")
If $sReporterName<>"" Then GUICtrlSetData($idMainReporter,$sReporterName)
EndIf
EndFunc
Func GuiEvents()
$nMsg = GUIGetMsg(1)
If $nMsg[1]=$hGui Then
Switch $nMsg[0]
Case $GUI_EVENT_CLOSE, $idMainExit
If $iCxbxRun Then
ProcessClose($iCxbxChildPID)
ProcessClose($iCxbxParentPID)
EndIf
Exit
Case $idMainReporter
$sReporterName=GUICtrlRead($idMainReporter)
If StringRegExp($sReporterName,'[<>:"/\\\|\?\*]') Then
MsgBox(48,$sTitle,'Invalid Reporter Name, you cannot use any of the following characters:'&@CRLF&'\ / : * ? " < > |')
$sReporterName=""
Return
EndIf
If $sReporterName<>"" Then
$iRet=MsgBox(36,$sTitle,"Would you like to save your name for later?")
If $iRet=6 Then
FileClose(FileOpen($sDataFile,10))
IniWrite($sDataFile,"Config","Reporter",$sReporterName)
EndIf
EndIf
Case $idMainSubmit
_SubmitReport()
Case $idMainSave
If $sReporterName="" Then
MsgBox(48,$sTitle,"Please Enter a Reporter Name")
Return
EndIf
_SaveReport()
Case $idCxbxRun
_RunCxbx()
Case $idXbeTitleName
$sData=GUICtrlRead($nMsg[0])
If $sData<>"" Then $sXbeTitleName=$sData
_GuiUpdateState()
Case $idCxbxBuild
$sData = GUICtrlRead($idCxbxBuild)
$sBuild = StringRegExpReplace($sData, "(.*)\(.*", "$1")
$sDate = StringRegExpReplace($sData, ".*\((\d{4}\.\d{2}\.\d{2}).*", "$1")
For $i = 1 To $aCxbxBuilds[0]
If StringInStr($aCxbxBuilds[$i], $sBuild) Then
$sCxbxBuild = $sBuild
$sCxbxDate = $sDate
$sCxbxBuildPath = @ScriptDir & "\Builds\" & $aCxbxBuilds[$i]
ExitLoop
EndIf
Next
_LoadReport()
_GuiUpdateState()
Case $idCxbxUpdate
_UpdateCxbx()
Case $idMainXbeOpen
$sXbePath = FileOpenDialog($sTitle, -1, "Xbox Executable (*.xbe)", 3)
If $sXbePath = "" Then Return
$sXbeDir = StringRegExpReplace($sXbePath, "(.*)\\.*\.xbe", "$1")
_XbeGetInfo($sXbePath)
$iXbeOpen = 1
_LoadReport()
_GuiUpdateState()
Case $idGfxInput
If BitAND(GUICtrlRead($nMsg[0]), $GUI_CHECKED) = $GUI_CHECKED Then
$iInput += 1
Else
$iInput -= 1
EndIf
_GuiUpdateState()
Case $idGfxSync
If BitAND(GUICtrlRead($nMsg[0]), $GUI_CHECKED) = $GUI_CHECKED Then
$iSync += 1
Else
$iSync -= 1
EndIf
_GuiUpdateState()
Case $idAudInput
If BitAND(GUICtrlRead($nMsg[0]), $GUI_CHECKED) = $GUI_CHECKED Then
$iInput += 2
Else
$iInput -= 2
EndIf
_GuiUpdateState()
Case $idAudSync
If BitAND(GUICtrlRead($nMsg[0]), $GUI_CHECKED) = $GUI_CHECKED Then
$iSync += 2
GUICtrlSetState($nMsg, $GUI_UNCHECKED)
Else
$iSync -= 2
EndIf
_GuiUpdateState()
Case $idMainXbeClose
GUICtrlSetState($idXbeTitleName, $GUI_ENABLE)
GUICtrlSetData($idXbeTitleName, "")
GUICtrlSetData($idXbeTitleID, "Title ID:    NaN")
GUICtrlSetData($idXbeVerAPI, "API Version: NaN")
GUICtrlSetData($idXbeDebug, "Debug:       NaN")
$sXbePath = ""
$sXbeDir = ""
$sXbeTitleID = ""
$sXbeTitleName = ""
$iXbeOpen = 0
_GuiUpdateState()
Case $idStateCrash
$iReportState = 1
_GuiUpdateState()
Case $idStateNothing
$iReportState = 2
_GuiUpdateState()
Case $idStateLoop
$iReportState = 3
_GuiUpdateState()
Case $idStateIntro
$iReportState = 4
_GuiUpdateState()
Case $idStateMenu
$iReportState = 5
_GuiUpdateState()
Case $idStateGame
$iReportState = 6
_GuiUpdateState()
Case $idStatePlay
$iReportState = 7
_GuiUpdateState()
Case $idCrashHasCrash
If BitAND(GUICtrlRead($nMsg[0]), $GUI_CHECKED) = $GUI_CHECKED Then
$iReportCrash = 1
GUICtrlSetState($idCrashFatal, $GUI_UNCHECKED)
GUICtrlSetState($idCrashIgnore, $GUI_UNCHECKED)
Else
$iReportCrash = 0
EndIf
_GuiUpdateState()
Case $idCrashFatal
$iReportCrash = 2
_GuiUpdateState()
Case $idCrashIgnore
$iReportCrash = 3
_GuiUpdateState()
Case $idGfxHasGFX
If BitAND(GUICtrlRead($nMsg[0]),$GUI_CHECKED) = $GUI_CHECKED Then
$iHasGfx = 1
GUICtrlSetState($idGfxHasPoly, $GUI_UNCHECKED)
GUICtrlSetState($idGfxDistortPoly, $GUI_UNCHECKED)
GUICtrlSetState($idGfxHasTex, $GUI_UNCHECKED)
GUICtrlSetState($idGfxDistortTex, $GUI_UNCHECKED)
GUICtrlSetState($idGfxHasTxt, $GUI_UNCHECKED)
GUICtrlSetState($idGfxDistortTxt, $GUI_UNCHECKED)
GUICtrlSetState($idGfxInput, $GUI_UNCHECKED)
GUICtrlSetState($idGfxSync, $GUI_UNCHECKED)
Else
$iHasGfx = 0
EndIf
_GuiUpdateState()
Case $idGfxHasPoly
If BitAND(GUICtrlRead($nMsg[0]), $GUI_CHECKED) = $GUI_CHECKED Then
$iHasPoly = 1
GUICtrlSetState($idGfxDistortPoly, $GUI_UNCHECKED)
Else
$iHasPoly = 0
EndIf
_GuiUpdateState()
Case $idGfxDistortPoly
If BitAND(GUICtrlRead($nMsg[0]), $GUI_CHECKED) = $GUI_CHECKED Then
$iHasPoly = 2
Else
$iHasPoly = 1
EndIf
_GuiUpdateState()
Case $idGfxHasTex
If BitAND(GUICtrlRead($nMsg[0]), $GUI_CHECKED) = $GUI_CHECKED Then
$iHasTex = 1
GUICtrlSetState($idGfxDistortTex, $GUI_UNCHECKED)
Else
$iHasTex = 0
EndIf
_GuiUpdateState()
Case $idGfxDistortTex
If BitAND(GUICtrlRead($nMsg[0]), $GUI_CHECKED) = $GUI_CHECKED Then
$iHasTex = 2
Else
$iHasTex = 1
EndIf
_GuiUpdateState()
Case $idGfxHasTxt
If BitAND(GUICtrlRead($nMsg[0]), $GUI_CHECKED) = $GUI_CHECKED Then
$iHasTxt = 1
GUICtrlSetState($idGfxDistortTxt, $GUI_UNCHECKED)
Else
$iHasTxt = 0
EndIf
_GuiUpdateState()
Case $idGfxDistortTxt
If BitAND(GUICtrlRead($nMsg[0]), $GUI_CHECKED) = $GUI_CHECKED Then
$iHasTxt = 2
Else
$iHasTxt = 1
EndIf
_GuiUpdateState()
Case $idAudHasAud
If BitAND(GUICtrlRead($nMsg[0]), $GUI_CHECKED) = $GUI_CHECKED Then
$iHasAud = 1
GUICtrlSetState($idAudHasBGM, $GUI_DISABLE)
GUICtrlSetState($idAudDistortBGM, $GUI_DISABLE)
GUICtrlSetState($idAudHasSFX, $GUI_DISABLE)
GUICtrlSetState($idAudDistortSFX, $GUI_DISABLE)
GUICtrlSetState($idAudInput, $GUI_DISABLE)
GUICtrlSetState($idAudSync, $GUI_DISABLE)
Else
$iHasAud = 0
EndIf
_GuiUpdateState()
Case $idAudHasBGM
If BitAND(GUICtrlRead($nMsg[0]), $GUI_CHECKED) = $GUI_CHECKED Then
$iHasBgm = 1
GUICtrlSetState($idAudDistortBGM, $GUI_UNCHECKED)
Else
$iHasBgm = 0
EndIf
_GuiUpdateState()
Case $idAudDistortBGM
If BitAND(GUICtrlRead($nMsg[0]), $GUI_CHECKED) = $GUI_CHECKED Then
$iHasBgm = 2
GUICtrlSetState($idGfxDistortTex, $GUI_UNCHECKED)
Else
$iHasBgm = 1
EndIf
_GuiUpdateState()
Case $idAudHasSFX
If BitAND(GUICtrlRead($nMsg[0]), $GUI_CHECKED) = $GUI_CHECKED Then
$iHasSfx = 1
GUICtrlSetState($idAudDistortSFX, $GUI_UNCHECKED)
Else
$iHasSfx = 0
EndIf
_GuiUpdateState()
Case $idAudDistortSFX
If BitAND(GUICtrlRead($nMsg[0]), $GUI_CHECKED) = $GUI_CHECKED Then
$iHasSfx = 2
GUICtrlSetState($idGfxDistortTex, $GUI_UNCHECKED)
Else
$iHasSfx = 1
EndIf
_GuiUpdateState()
EndSwitch
EndIf
EndFunc
Func _GuiSetDefaults()
GUICtrlSetState($idMainReporter, $GUI_DISABLE)
GUICtrlSetState($idMainXbeClose, $GUI_DISABLE)
GUICtrlSetState($idMainSave, $GUI_DISABLE)
GUICtrlSetState($idMainSubmit, $GUI_DISABLE)
GUICtrlSetState($idCxbxBuild, $GUI_DISABLE)
GUICtrlSetState($idCxbxRun, $GUI_DISABLE)
GUICtrlSetState($idCxbxUpdate, $GUI_DISABLE)
GUICtrlSetState($idXbeTitleName, $GUI_DISABLE)
GUICtrlSetState($idStateCrash, $GUI_DISABLE)
GUICtrlSetState($idStateNothing, $GUI_DISABLE)
GUICtrlSetState($idStateLoop, $GUI_DISABLE)
GUICtrlSetState($idStateIntro, $GUI_DISABLE)
GUICtrlSetState($idStateMenu, $GUI_DISABLE)
GUICtrlSetState($idStateGame, $GUI_DISABLE)
GUICtrlSetState($idStatePlay, $GUI_DISABLE)
GUICtrlSetState($idCrashHasCrash, $GUI_DISABLE)
GUICtrlSetState($idCrashFatal, $GUI_DISABLE)
GUICtrlSetState($idCrashIgnore, $GUI_DISABLE)
GUICtrlSetState($idGfxHasGFX, $GUI_DISABLE)
GUICtrlSetState($idGfxHasPoly, $GUI_DISABLE)
GUICtrlSetState($idGfxDistortPoly, $GUI_DISABLE)
GUICtrlSetState($idGfxHasTex, $GUI_DISABLE)
GUICtrlSetState($idGfxDistortTex, $GUI_DISABLE)
GUICtrlSetState($idGfxHasTxt, $GUI_DISABLE)
GUICtrlSetState($idGfxDistortTxt, $GUI_DISABLE)
GUICtrlSetState($idGfxInput, $GUI_DISABLE)
GUICtrlSetState($idGfxSync, $GUI_DISABLE)
GUICtrlSetState($idAudHasAud, $GUI_DISABLE)
GUICtrlSetState($idAudHasBGM, $GUI_DISABLE)
GUICtrlSetState($idAudDistortBGM, $GUI_DISABLE)
GUICtrlSetState($idAudHasSFX, $GUI_DISABLE)
GUICtrlSetState($idAudDistortSFX, $GUI_DISABLE)
GUICtrlSetState($idAudInput, $GUI_DISABLE)
GUICtrlSetState($idAudSync, $GUI_DISABLE)
GUICtrlSetState($idNotes, $GUI_DISABLE)
EndFunc
Func _EnDisableState($i)
If $i Then
$iCtrlState = $GUI_ENABLE
Else
$iCtrlState = $GUI_DISABLE
$iReportState = 0
GUICtrlSetState($idStateCrash, $GUI_UNCHECKED)
GUICtrlSetState($idStateNothing, $GUI_UNCHECKED)
GUICtrlSetState($idStateLoop, $GUI_UNCHECKED)
GUICtrlSetState($idStateIntro, $GUI_UNCHECKED)
GUICtrlSetState($idStateMenu, $GUI_UNCHECKED)
GUICtrlSetState($idStateGame, $GUI_UNCHECKED)
GUICtrlSetState($idStatePlay, $GUI_UNCHECKED)
EndIf
GUICtrlSetState($idStateCrash, $iCtrlState)
GUICtrlSetState($idStateNothing, $iCtrlState)
GUICtrlSetState($idStateLoop, $iCtrlState)
GUICtrlSetState($idStateIntro, $iCtrlState)
GUICtrlSetState($idStateMenu, $iCtrlState)
GUICtrlSetState($idStateGame, $iCtrlState)
GUICtrlSetState($idStatePlay, $iCtrlState)
EndFunc
Func _EnDisableReport($i)
_EnDisableState($i)
If $i Then
$iCtrlState = $GUI_ENABLE
Else
$iCtrlState = $GUI_DISABLE
$iHasGfx = 0
$iReportCrash = 0
$iHasAud = 0
GUICtrlSetState($idCrashFatal, $GUI_DISABLE)
GUICtrlSetState($idCrashIgnore, $GUI_DISABLE)
GUICtrlSetState($idGfxHasPoly, $GUI_DISABLE)
GUICtrlSetState($idGfxDistortPoly, $GUI_DISABLE)
GUICtrlSetState($idGfxHasTex, $GUI_DISABLE)
GUICtrlSetState($idGfxDistortTex, $GUI_DISABLE)
GUICtrlSetState($idGfxHasTxt, $GUI_DISABLE)
GUICtrlSetState($idGfxDistortTxt, $GUI_DISABLE)
GUICtrlSetState($idGfxInput, $GUI_DISABLE)
GUICtrlSetState($idGfxSync, $GUI_DISABLE)
GUICtrlSetState($idAudHasBGM, $GUI_DISABLE)
GUICtrlSetState($idAudDistortBGM, $GUI_DISABLE)
GUICtrlSetState($idAudHasSFX, $GUI_DISABLE)
GUICtrlSetState($idAudDistortSFX, $GUI_DISABLE)
GUICtrlSetState($idAudInput, $GUI_DISABLE)
GUICtrlSetState($idAudSync, $GUI_DISABLE)
GUICtrlSetState($idCrashFatal, $GUI_UNCHECKED)
GUICtrlSetState($idCrashIgnore, $GUI_UNCHECKED)
GUICtrlSetState($idGfxHasPoly, $GUI_UNCHECKED)
GUICtrlSetState($idGfxDistortPoly, $GUI_UNCHECKED)
GUICtrlSetState($idGfxHasTex, $GUI_UNCHECKED)
GUICtrlSetState($idGfxDistortTex, $GUI_UNCHECKED)
GUICtrlSetState($idGfxHasTxt, $GUI_UNCHECKED)
GUICtrlSetState($idGfxDistortTxt, $GUI_UNCHECKED)
GUICtrlSetState($idGfxInput, $GUI_UNCHECKED)
GUICtrlSetState($idGfxSync, $GUI_UNCHECKED)
GUICtrlSetState($idAudHasBGM, $GUI_UNCHECKED)
GUICtrlSetState($idAudDistortBGM, $GUI_UNCHECKED)
GUICtrlSetState($idAudHasSFX, $GUI_UNCHECKED)
GUICtrlSetState($idAudDistortSFX, $GUI_UNCHECKED)
GUICtrlSetState($idAudInput, $GUI_UNCHECKED)
GUICtrlSetState($idAudSync, $GUI_UNCHECKED)
GUICtrlSetState($idCrashHasCrash, $GUI_UNCHECKED)
GUICtrlSetState($idGfxHasGFX, $GUI_UNCHECKED)
GUICtrlSetState($idAudHasAud, $GUI_UNCHECKED)
GUICtrlSetState($idNotes, $GUI_UNCHECKED)
EndIf
GUICtrlSetState($idCrashHasCrash, $iCtrlState)
GUICtrlSetState($idGfxHasGFX, $iCtrlState)
GUICtrlSetState($idAudHasAud, $iCtrlState)
GUICtrlSetState($idNotes, $iCtrlState)
EndFunc
Func _GuiUpdateState()
If $iXbeOpen Then
_EnDisableReport(1)
GUICtrlSetState($idMainXbeOpen, $GUI_DISABLE)
If $sXbeTitleName="" Or $sXbeTitleName="NaN" Or _RestrictNames() Then GUICtrlSetState($idXbeTitleName, $GUI_ENABLE)
If Not $iCxbxRun Then
GUICtrlSetState($idMainReporter, $GUI_ENABLE)
GUICtrlSetState($idMainXbeClose, $GUI_ENABLE)
If $iReportState<>0 Then
GUICtrlSetState($idMainSave, $GUI_ENABLE)
GUICtrlSetState($idMainSubmit, $GUI_ENABLE)
EndIf
If Not $iCxbxNoBuilds Then
GUICtrlSetState($idCxbxBuild, $GUI_ENABLE)
GUICtrlSetState($idCxbxRun, $GUI_ENABLE)
EndIf
GUICtrlSetState($idCxbxUpdate, $GUI_ENABLE)
EndIf
Switch $iReportState
Case 0
GUICtrlSetState($idStateCrash, $GUI_UNCHECKED)
GUICtrlSetState($idStateNothing, $GUI_UNCHECKED)
GUICtrlSetState($idStateLoop, $GUI_UNCHECKED)
GUICtrlSetState($idStateIntro, $GUI_UNCHECKED)
GUICtrlSetState($idStateMenu, $GUI_UNCHECKED)
GUICtrlSetState($idStateGame, $GUI_UNCHECKED)
GUICtrlSetState($idStatePlay, $GUI_UNCHECKED)
Case 1
GUICtrlSetState($idStateCrash, $GUI_CHECKED)
Case 2
GUICtrlSetState($idStateNothing, $GUI_CHECKED)
Case 3
GUICtrlSetState($idStateLoop, $GUI_CHECKED)
Case 4
GUICtrlSetState($idStateIntro, $GUI_CHECKED)
Case 5
GUICtrlSetState($idStateMenu, $GUI_CHECKED)
Case 6
GUICtrlSetState($idStateGame, $GUI_CHECKED)
Case 7
GUICtrlSetState($idStatePlay, $GUI_CHECKED)
EndSwitch
If $iReportCrash > 0 Then
GUICtrlSetState($idCrashHasCrash, $GUI_CHECKED)
GUICtrlSetState($idCrashFatal, $GUI_ENABLE)
GUICtrlSetState($idCrashIgnore, $GUI_ENABLE)
If $iReportCrash = 2 Then
GUICtrlSetState($idCrashFatal, $GUI_CHECKED)
ElseIf $iReportCrash = 3 Then
GUICtrlSetState($idCrashIgnore, $GUI_CHECKED)
EndIf
Else
GUICtrlSetState($idCrashHasCrash, $GUI_UNCHECKED)
GUICtrlSetState($idCrashFatal, $GUI_UNCHECKED)
GUICtrlSetState($idCrashIgnore, $GUI_UNCHECKED)
GUICtrlSetState($idCrashFatal, $GUI_DISABLE)
GUICtrlSetState($idCrashIgnore, $GUI_DISABLE)
EndIf
If $iHasGfx Then
GUICtrlSetState($idGfxHasGFX, $GUI_CHECKED)
GUICtrlSetState($idGfxHasPoly, $GUI_ENABLE)
GUICtrlSetState($idGfxHasTex, $GUI_ENABLE)
GUICtrlSetState($idGfxHasTxt, $GUI_ENABLE)
GUICtrlSetState($idGfxInput, $GUI_ENABLE)
GUICtrlSetState($idGfxSync, $GUI_ENABLE)
If $iInput = 3 Or $iInput = 1 Then GUICtrlSetState($idGfxInput, $GUI_CHECKED)
If $iSync = 3 Or $iSync = 1 Then GUICtrlSetState($idGfxSync, $GUI_CHECKED)
If $iHasPoly > 0 Then
GUICtrlSetState($idGfxHasPoly, $GUI_CHECKED)
GUICtrlSetState($idGfxDistortPoly, $GUI_ENABLE)
If $iHasPoly = 2 Then GUICtrlSetState($idGfxDistortPoly, $GUI_CHECKED)
Else
GUICtrlSetState($idGfxDistortPoly, $GUI_UNCHECKED)
GUICtrlSetState($idGfxDistortPoly, $GUI_DISABLE)
EndIf
If $iHasTex > 0 Then
GUICtrlSetState($idGfxHasTex, $GUI_CHECKED)
GUICtrlSetState($idGfxDistortTex, $GUI_ENABLE)
If $iHasTex = 2 Then GUICtrlSetState($idGfxDistortTex, $GUI_CHECKED)
Else
GUICtrlSetState($idGfxDistortTex, $GUI_UNCHECKED)
GUICtrlSetState($idGfxDistortTex, $GUI_DISABLE)
EndIf
If $iHasTxt > 0 Then
GUICtrlSetState($idGfxHasTxt, $GUI_CHECKED)
GUICtrlSetState($idGfxDistortTxt, $GUI_ENABLE)
If $iHasTxt = 2 Then GUICtrlSetState($idGfxDistortTxt, $GUI_CHECKED)
Else
GUICtrlSetState($idGfxDistortTxt, $GUI_UNCHECKED)
GUICtrlSetState($idGfxDistortTxt, $GUI_DISABLE)
EndIf
Else
$iHasPoly = 0
$iHasTex = 0
$iHasTxt = 0
If $iSync = 3 Or $iSync = 1 Then $iSync -= 1
If $iInput = 3 Or $iInput = 1 Then $iInput -= 1
GUICtrlSetState($idGfxHasGFX, $GUI_UNCHECKED)
GUICtrlSetState($idGfxHasPoly, $GUI_DISABLE)
GUICtrlSetState($idGfxDistortPoly, $GUI_DISABLE)
GUICtrlSetState($idGfxHasTex, $GUI_DISABLE)
GUICtrlSetState($idGfxDistortTex, $GUI_DISABLE)
GUICtrlSetState($idGfxHasTxt, $GUI_DISABLE)
GUICtrlSetState($idGfxDistortTxt, $GUI_DISABLE)
GUICtrlSetState($idGfxInput, $GUI_DISABLE)
GUICtrlSetState($idGfxSync, $GUI_DISABLE)
GUICtrlSetState($idGfxHasPoly, $GUI_UNCHECKED)
GUICtrlSetState($idGfxDistortPoly, $GUI_UNCHECKED)
GUICtrlSetState($idGfxHasTex, $GUI_UNCHECKED)
GUICtrlSetState($idGfxDistortTex, $GUI_UNCHECKED)
GUICtrlSetState($idGfxHasTxt, $GUI_UNCHECKED)
GUICtrlSetState($idGfxDistortTxt, $GUI_UNCHECKED)
GUICtrlSetState($idGfxInput, $GUI_UNCHECKED)
GUICtrlSetState($idGfxSync, $GUI_UNCHECKED)
EndIf
If $iHasAud Then
GUICtrlSetState($idAudHasAud, $GUI_CHECKED)
GUICtrlSetState($idAudHasBGM, $GUI_ENABLE)
GUICtrlSetState($idAudDistortBGM, $GUI_ENABLE)
GUICtrlSetState($idAudHasSFX, $GUI_ENABLE)
GUICtrlSetState($idAudDistortSFX, $GUI_ENABLE)
GUICtrlSetState($idAudInput, $GUI_ENABLE)
GUICtrlSetState($idAudSync, $GUI_ENABLE)
If $iInput = 3 Or $iInput = 2 Then GUICtrlSetState($idAudInput, $GUI_CHECKED)
If $iSync = 3 Or $iSync = 2 Then GUICtrlSetState($idAudSync, $GUI_CHECKED)
If $iHasBgm > 0 Then
GUICtrlSetState($idAudHasBGM, $GUI_CHECKED)
GUICtrlSetState($idAudDistortBgm, $GUI_ENABLE)
If $iHasBgm = 2 Then GUICtrlSetState($idAudDistortBgm, $GUI_CHECKED)
Else
GUICtrlSetState($idAudDistortBgm, $GUI_UNCHECKED)
GUICtrlSetState($idAudDistortBgm, $GUI_DISABLE)
EndIf
If $iHasSfx > 0 Then
GUICtrlSetState($idAudHasSFX, $GUI_CHECKED)
GUICtrlSetState($idAudDistortSfx, $GUI_ENABLE)
If $iHasSfx = 2 Then GUICtrlSetState($idAudDistortSfx, $GUI_CHECKED)
Else
GUICtrlSetState($idAudDistortSfx, $GUI_UNCHECKED)
GUICtrlSetState($idAudDistortSfx, $GUI_DISABLE)
EndIf
Else
$iHasBgm = 0
$iHasSfx = 0
If $iSync = 3 Or $iSync = 2 Then $iSync -= 2
If $iInput = 3 Or $iInput = 2 Then $iInput -= 2
GUICtrlSetState($idAudHasBGM, $GUI_DISABLE)
GUICtrlSetState($idAudDistortBGM, $GUI_DISABLE)
GUICtrlSetState($idAudHasSFX, $GUI_DISABLE)
GUICtrlSetState($idAudDistortSFX, $GUI_DISABLE)
GUICtrlSetState($idAudInput, $GUI_DISABLE)
GUICtrlSetState($idAudSync, $GUI_DISABLE)
GUICtrlSetState($idAudHasAud, $GUI_UNCHECKED)
GUICtrlSetState($idAudHasBGM, $GUI_UNCHECKED)
GUICtrlSetState($idAudDistortBGM, $GUI_UNCHECKED)
GUICtrlSetState($idAudHasSFX, $GUI_UNCHECKED)
GUICtrlSetState($idAudDistortSFX, $GUI_UNCHECKED)
GUICtrlSetState($idAudInput, $GUI_UNCHECKED)
GUICtrlSetState($idAudSync, $GUI_UNCHECKED)
EndIf
Else
$iHasBgm = 0
$iHasSfx = 0
$iHasGfx = 0
$iHasPoly = 0
$iHasTex = 0
$iHasTxt = 0
$iHasBgm = 0
$iHasSfx = 0
$iReportState = 0
$iReportCrash = 0
$iSync = 0
$iInput = 0
_EnDisableReport(0)
GUICtrlSetState($idMainXbeOpen, $GUI_ENABLE)
GUICtrlSetState($idMainReporter, $GUI_DISABLE)
GUICtrlSetState($idMainXbeClose, $GUI_DISABLE)
GUICtrlSetState($idMainSave, $GUI_DISABLE)
GUICtrlSetState($idMainSubmit, $GUI_DISABLE)
GUICtrlSetState($idCxbxBuild, $GUI_DISABLE)
GUICtrlSetState($idCxbxRun, $GUI_DISABLE)
GUICtrlSetState($idCxbxUpdate, $GUI_DISABLE)
GUICtrlSetState($idXbeTitleName, $GUI_DISABLE)
EndIf
EndFunc
