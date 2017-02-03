
Func _B64Decode($sSource)
	Local Static $Opcode, $tMem, $tRevIndex, $fStartup = True

	If $fStartup Then
		If @AutoItX64 Then
			$Opcode = '0xC800000053574D89C74C89C74889D64889CB4C89C89948C7C10400000048F7F148C7C10300000048F7E14989C242807C0EFF3D750E49FFCA42807C0EFE3D750349FFCA4C89C89948C7C10800000048F7F14889C148FFC1488B064989CD48C7C108000000D7C0C0024188C349C1E30648C1E808E2EF49C1E308490FCB4C891F4883C7064883C6084C89E9E2CB4C89D05F5BC9C3'
		Else
			$Opcode = '0xC8080000FF75108B7D108B5D088B750C8B4D148B06D7C0C00288C2C1E808C1E206D7C0C00288C2C1E808C1E206D7C0C00288C2C1E808C1E206D7C0C00288C2C1E808C1E2060FCA891783C70383C604E2C2807EFF3D75084F807EFE3D75014FC6070089F85B29D8C9C21000'
		EndIf

		Local $aMemBuff = DllCall("kernel32.dll", "ptr", "VirtualAlloc", "ptr", 0, "ulong_ptr", BinaryLen($Opcode), "dword", 4096, "dword", 64)
		$tMem = DllStructCreate('byte[' & BinaryLen($Opcode) & ']', $aMemBuff[0])
		DllStructSetData($tMem, 1, $Opcode)

		Local $aRevIndex[128]
		Local $aTable = StringToASCIIArray('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/')
		For $i = 0 To UBound($aTable) - 1
			$aRevIndex[$aTable[$i]] = $i
		Next
		$tRevIndex = DllStructCreate('byte[' & 128 & ']')
		DllStructSetData($tRevIndex, 1, StringToBinary(StringFromASCIIArray($aRevIndex)))

		$fStartup = False
	EndIf

	Local $iLen = StringLen($sSource)
	Local $tOutput = DllStructCreate('byte[' & $iLen + 8 & ']')
	DllCall("kernel32.dll", "bool", "VirtualProtect", "struct*", $tOutput, "dword_ptr", DllStructGetSize($tOutput), "dword", 0x00000004, "dword*", 0)

	Local $tSource = DllStructCreate('char[' & $iLen + 8 & ']')
	DllStructSetData($tSource, 1, $sSource)

	Local $aRet = DllCallAddress('uint', DllStructGetPtr($tMem), 'struct*', $tRevIndex, 'struct*', $tSource, 'struct*', $tOutput, 'uint', (@AutoItX64 ? $iLen : $iLen / 4))

	Return BinaryMid(DllStructGetData($tOutput, 1), 1, $aRet[0])
EndFunc   ;==>_B64Decode

Func _B64Encode($sSource)
	Local Static $Opcode, $tMem, $fStartup = True

	If $fStartup Then
		If @AutoItX64 Then
			$Opcode = '0xC810000053574889CE4889D74C89C34C89C89948C7C10600000048F7F14889C14883FA00740348FFC1488B06480FC848C1E80EC0E802D788470748C1E806C0E802D788470648C1E806C0E802D788470548C1E806C0E802D788470448C1E806C0E802D788470348C1E806C0E802D788470248C1E806C0E802D788470148C1E806C0E802D788074883C6064883C708E2994883FA00743B49C7C5060000004929D54883FA03770349FFC54C29EF4883FA03741F4883FA01740E4883FA047408C6073D48FFC7EB0BC6073DC647013D4883C702C607005F5BC9C3'
		Else
			$Opcode = '0xC80800008B451499B903000000F7F189C1528B5D108B75088B7D0C83FA007401418B160FCAC1EA0888D0243FD7884703C1EA0688D0243FD7884702C1EA0688D0243FD7884701C1EA0688D0243FD7880783C60383C704E2C95A83FA00740DC647FF3D83FA027404C647FE3DC60700C9C21000'
		EndIf

		Local $aMemBuff = DllCall("kernel32.dll", "ptr", "VirtualAlloc", "ptr", 0, "ulong_ptr", BinaryLen($Opcode), "dword", 4096, "dword", 64)
		$tMem = DllStructCreate('byte[' & BinaryLen($Opcode) & ']', $aMemBuff[0])
		DllStructSetData($tMem, 1, $Opcode)

		$fStartup = False
	EndIf

	$sSource = Binary($sSource)
	Local $iLen = BinaryLen($sSource)

	$tSource = DllStructCreate('byte[' & $iLen & ']')
	DllStructSetData($tSource, 1, $sSource)

	Local $tOutput = DllStructCreate('char[' & Ceiling($iLen * (4 / 3) + 3) & ']')
	DllCall("kernel32.dll", "bool", "VirtualProtect", "struct*", $tOutput, "dword_ptr", DllStructGetSize($tOutput), "dword", 0x00000004, "dword*", 0)

	Local $sTable = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

	DllCallAddress('none', DllStructGetPtr($tMem), 'struct*', $tSource, 'struct*', $tOutput, 'str', $sTable, 'uint', $iLen)

	Return DllStructGetData($tOutput, 1)
EndFunc   ;==>_B64Encode
