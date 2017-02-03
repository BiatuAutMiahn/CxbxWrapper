#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.2
 Author:         BiatuAutMiahn[@outlook.com]

 Script Function:
	Update Script

#ce ----------------------------------------------------------------------------
#include-once
#include-once
#include <WinAPIProc.au3>
#include <Array.au3>
#include <WinAPIFiles.au3>
#include <FontConstants.au3>
#include <WindowsConstants.au3>
#include <WinHttp.au3>
#include <B64.au3>
#include <SHA1.au3>
#include <LZMA.au3>
#include <Date.au3>
Global Const $_sInfinityProgram_File=StringTrimRight(@AutoItExe,4)&".Update.exe"
Global Const $_sInfinityProgram_Version="20170203173232"
Global Const $_sInfinityProgram_Magik="ap96zsxTMmjR4EqQ"
Global $_idIUM_Progress, $_idIUM_Status, $_iIUM_Test=True, $_sIUM_Title="Infinity Updater"
Global $_iIUM_DataLen, $_iIUM_DataRead, $_iIUM_Start, $_iIUM_Curr, $_iIUM_LZMA=True
If @Compiled Or $_iIUM_Test Then
    _InfinityUpdate_Init()
EndIf
Func _InfinityUpdate_Init()
    Local $iUpdate=True, $iHeight=75, $iWidth=400
    $hWnd=GUICreate($_sIUM_Title,256+64+32,64-4,-1,-1,0x16C00000)
    GUISetIcon(@AutoItExe,-6)
    GUISetFont(8.3,400,0,"Consolas",$hWnd,$CLEARTYPE_QUALITY)
    $_idIUM_Status=GUICtrlCreateLabel("Status: ",8,10,256+64+32,20)
    $_idIUM_Progress=GUICtrlCreateProgress(8,32,256+32+16+32,20)
    GUISetState()
    ;Do the update
    If @Compiled And StringInStr(@ScriptName,".Update.exe") Then
        $sSrc=@ScriptName
        $sDest=StringReplace(@ScriptName,".Update.exe",".exe")
        $sFail="Failed to get parent process information."
        $iParentPID=_WinAPI_GetParentProcess()
        If @error Then _IUM_UpdateFail($sDest,$sFail)
        $sParentName=_WinAPI_GetProcessName($iParentPID)
        If @error Then _IUM_UpdateFail($sDest,$sFail)
        If $sParentName=$sDest Then
            $sFail="Failed to close parent process."
            ProcessClose($iParentPID)
            If @error Then _IUM_UpdateFail($sDest,$sFail)
            ProcessWaitClose($iParentPID)
            If @error Then _IUM_UpdateFail($sDest,$sFail&" "&@Error&"|"&@extended)
            While Sleep(125)
                $aProcesses=ProcessList($sDest)
                If $aProcesses[0][0]<>0 Then
                    For $i=1 To $aProcesses[0][0]
                        $sProcPath=_WinAPI_GetProcessFileName($aProcesses[$i][1])
                        If @error Then ContinueLoop
                        If $sProcPath=@ScriptDir&"\"&$sDest Then
                            MsgBox(48,$_sIUM_Title,"Cannot update while program is running, please close all instances to continue.",0,$hWnd)
                            ExitLoop
                        EndIf
                    Next
                Else
                    ExitLoop
                EndIf
            WEnd
            While Sleep(125)
                If _WinAPI_FileInUse($sDest) Then
                    MsgBox(48,$_sIUM_Title,"Cannot update while file is in use!"&@CRLF&"    -Please close any program(s) that may be using the file."&@CRLF&"    -Please make sure that the application being updated has no other running instances.",0,$hWnd)
                Else
                    ExitLoop
                EndIf
            WEnd
            FileDelete($sDest)
            If @error Then _IUM_UpdateFail($sDest,"Failed to delete outdated data.")
            FileCopy($sSrc,$sDest,1)
            If @error Then _IUM_UpdateFail($sDest,"Failed to copy new data.")
            Local $sCmdLines
            ;_ArrayDisplay($CmdLine,$CmdLineRaw)
            For $i=1 To $CmdLine[0]
                $sParam=$CmdLine[$i]
                If StringRegExp($sParam,'~!CmdLine=(.*)') Then
                    $sCmdLines=StringRegExpReplace($sParam,'~!CmdLine=(.*)',"$1")
                    ExitLoop
                EndIf
            Next
            ;MsgBox(64,"Info",$sCmdLines)
            Run($sDest&' ~!Update.Success ~!CmdLine='&$sCmdLines&'',@ScriptDir)
        Else
            MsgBox(16,"Error","This is an Updater!",0,$hWnd)
        EndIf
        Exit
    EndIf
    If @Compiled Then
        If FileExists($_sInfinityProgram_File) Then FileDelete($_sInfinityProgram_File)
        If StringInStr($CmdLineRaw,"~!Update.Success") Then
            GUICtrlSetData($_idIUM_Status,"Status: Updating Icons...")
            If @OSArch="X64" Then
                _WinAPI_Wow64EnableWow64FsRedirection(False)
            EndIf
            RunWait("ie4uinit.exe -ClearIconCache",@SystemDir,@SW_HIDE)
            RunWait("ie4uinit.exe -Show",@SystemDir,@SW_HIDE)
            If @OSArch="X64" Then
                _WinAPI_Wow64EnableWow64FsRedirection(True)
            EndIf
            Sleep(250)
            GUICtrlSetData($_idIUM_Status,"Status: Updating Icons...Done")
            Sleep(250)
            GUICtrlSetData($_idIUM_Status,"Status: Update Success")
            GUICtrlSetData($_idIUM_Progress,100)
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
            GUICtrlSetData($_idIUM_Status,"Status: Update Failed")
            $sRet=MsgBox(32+4,$_sIUM_Title,"The Update Attempt has failed."&@CRLF&"Error: "&StringReplace($CmdLineRaw,"~!Update.Failed","")&@CRLF&@CRLF&", would you like to try again?",0,$hWnd)
            Switch $sRet
                Case 7
                    $iUpdate=False
                Case Else
                    $iUpdate=True
            EndSwitch
        EndIf
    EndIf
    If $iUpdate Or $_iIUM_Test Then
        GUICtrlSetData($_idIUM_Progress,0)
        GUICtrlSetData($_idIUM_Status,"Status: Checking for Update...")
        Sleep(500)
        $sRet=_IUM_CheckUpdate($_sInfinityProgram_Magik)
        If @error Then
            GUICtrlSetData($_idIUM_Status,"Status: Checking for Update...No Update Available!")
            Sleep(500)
        Else
            If StringLeft($sRet,2)="~!" Then
                Local $_sIUM_ErrMsg
                Switch $sRet
                    Case "~!Error@1","~!Error@6";Invalid Request
                        $_sIUM_ErrMsg="Invalid Server Request"
                    Case "~!Error@2";No Magik Specified
                        $_sIUM_ErrMsg="Magik Error"
                    Case "~!Error@3","~!Error@5";Invalid Magik
                        $_sIUM_ErrMsg="Server Update Data Error 3"
                    Case "~!Error@4"
                        $_sIUM_ErrMsg="Server Update Data Error 4"
                EndSwitch
                If $_sIUM_ErrMsg<>"" Then
                    GUICtrlSetData($_idIUM_Status,"Status: Checking for Update...Failed!")
                    MsgBox(16,$_sIUM_Title,$_sIUM_ErrMsg,0,$hWnd)
                    Return
                EndIf
            EndIf
            If Number($_sInfinityProgram_Version)>=Number($sRet) Then
                GUICtrlSetData($_idIUM_Status,"Status: Checking for Update...No Update Available!")
                Sleep(500)
            Else
                GUICtrlSetData($_idIUM_Status,"Status: Checking for Update...Update Available!")
                Sleep(500)
                $iRet=MsgBox(64+4,"Update Available","There is a new update available, would you like to upgrade?"&@CRLF& _
                                                     "NOTE: Updates may be unstable or buggy as this software is a beta."&@CRLF& _
                                                     "    Please contact the developer for help."&@CRLF&@CRLF& _
                                                     "Current Version: "&_IUM_FormatVer($_sInfinityProgram_Version)&@CRLF& _
                                                     "Latest Version: "&_IUM_FormatVer($sRet)&@CRLF,0,$hWnd)
                If $iRet=6 Then
                    GUICtrlSetData($_idIUM_Status,"Status: Awaiting Response...")
                    $sUpdate=_IUM_Update($_sInfinityProgram_Magik)
                    If StringLeft($sUpdate,2)="~!" Then
                        Local $_sIUM_ErrMsg
                        Switch $sUpdate
                            Case "~!Error@1","~!Error@6";Invalid Request
                                $_sIUM_ErrMsg="Invalid Server Request"
                            Case "~!Error@2";No Magik Specified
                                $_sIUM_ErrMsg="Magik Error"
                            Case "~!Error@3","~!Error@5";Invalid Magik
                                $_sIUM_ErrMsg="Server Update Data Error 3"
                            Case "~!Error@4"
                                $_sIUM_ErrMsg="Server Update Data Error 4"
                        EndSwitch
                        If $_sIUM_ErrMsg<>"" Then
                            GUICtrlSetData($_idIUM_Status,"Status: Downloading Update...Failed!")
                            MsgBox(16,$_sIUM_Title,$_sIUM_ErrMsg,0,$hWnd)
                            Return
                        EndIf
                    EndIf
                    GUICtrlSetData($_idIUM_Status,"Status: Downloading Update...Done")
                    GUICtrlSetData($_idIUM_Status,"Status: Updating...")
                    $hFile=FileOpen($_sInfinityProgram_File,2+16)
                    FileWrite($hFile,$sUpdate)
                    FileClose($hFile)
                    Local $sCmdLines
                    For $i=1 To $CmdLine[0]
                        $sCmdLines&=$CmdLine[$i]
                        If $i<>$CmdLine[0] Then $sCmdLines&="|"
                    Next
                    $sCmdLines=Binary($sCmdLines)
                    ;MsgBox(64,"Info",$sCmdLines)
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

Func _IUM_UpdateFail($sRun,$sError="NaN")
    Run($sRun&" ~!Update.Failed,"&$sError,@ScriptDir)
    Exit 1
EndFunc

Func _IUM_Stat()
EndFunc

Func _IUM_Update($sMagik)
    Local $_sIUM_GetType="Get"
    Local $hOpen = _WinHttpOpen()
    If @error Then Return SetError(1,0,0)
    Local $hConnect = _WinHttpConnect($hOpen, "InfinityCommunicationsGateway.net")
    If @error Then Return SetError(3,0,0)
    If $_iIUM_LZMA Then $_sIUM_GetType&="Lzma"
    Local $hRequest = _WinHttpSimpleSendSSLRequest($hConnect, "GET","priv/Infinity.UpdateManager/?Action="&$_sIUM_GetType&"&Magik="&$sMagik)
    If @error Then Return SetError(4,0,0)
    GUICtrlSetData($_idIUM_Status,"Status: Downloading Update...")
    Local $sStatusCode = _WinHttpQueryHeaders($hRequest, $WINHTTP_QUERY_STATUS_CODE, $WINHTTP_HEADER_NAME_BY_INDEX, $WINHTTP_NO_HEADER_INDEX)
    If @error Then Return SetError(5,0,0)
    If $sStatusCode<>"200" Then Return SetError(6,$sStatusCode,0)
    $sContentLength = _WinHttpQueryHeaders($hRequest, $WINHTTP_QUERY_CONTENT_LENGTH, $WINHTTP_HEADER_NAME_BY_INDEX, $WINHTTP_NO_HEADER_INDEX)
    If @error Then Return SetError(7,0,0)
    $_iIUM_DataLen=Int($sContentLength)
    Local $vData
    $_iIUM_DataRead=0
    If _WinHttpQueryDataAvailable($hRequest) Then
        $_iIUM_Start=_Date_Time_GetTickCount()/1000
        While Sleep(1)
            $vDataTmp=_WinHttpReadData($hRequest, 2)
            If @error Then ExitLoop
            $_iIUM_DataRead+=@extended
            $vData &=BinaryToString($vDataTmp)
            GUICtrlSetData($_idIUM_Progress,100*($_iIUM_DataRead/$_iIUM_DataLen))
            $_iIUM_Curr=_Date_Time_GetTickCount()/1000
            GUICtrlSetData($_idIUM_Status,"Status: Downloading Update... ("&_WinAPI_StrFormatByteSize($_iIUM_DataRead)&"/"&_WinAPI_StrFormatByteSize($_iIUM_DataLen)&"@"&_WinAPI_StrFormatByteSize(($_iIUM_DataRead/($_iIUM_Curr-$_iIUM_Start)))&"/s)")
        WEnd
    Else
        If @error Then Return SetError(8,0,0)
    EndIf
    _WinHttpCloseHandle($hRequest)
    _WinHttpCloseHandle($hConnect)
    _WinHttpCloseHandle($hOpen)
    $sHash=_IUM_GetHash($sMagik)
    If @error Then Return SetError(9,@Error,0)
    If $_iIUM_LZMA Then $vData=_LZMA_Decompress(_B64Decode($vData))
    If $sHash<>_SHA1($vData) Then
        MsgBox(48,$_sIUM_Title,"Integrity Check Failed!")
        Return SetError(10,0,0)
    EndIf
    Sleep(1000)
    Return SetError(0,0,$vData)
EndFunc

Func _IUM_CheckUpdate($sMagik)
    Local $hOpen = _WinHttpOpen()
    If @error Then Return SetError(1,0,0)
    Local $hConnect = _WinHttpConnect($hOpen, "InfinityCommunicationsGateway.net")
    If @error Then Return SetError(3,0,0)
    Local $hRequest = _WinHttpSimpleSendSSLRequest($hConnect, "GET","priv/Infinity.UpdateManager?Action=Check&Magik="&$sMagik)
    If @error Then Return SetError(4,0,0)
    Local $sStatusCode = _WinHttpQueryHeaders($hRequest, $WINHTTP_QUERY_STATUS_CODE, $WINHTTP_HEADER_NAME_BY_INDEX, $WINHTTP_NO_HEADER_INDEX)
    If @error Then Return SetError(5,0,0)
    If $sStatusCode<>"200" Then Return SetError(6,$sStatusCode,0)
    Local $sContentRange = _WinHttpQueryHeaders($hRequest, $WINHTTP_QUERY_CONTENT_LENGTH, $WINHTTP_HEADER_NAME_BY_INDEX, $WINHTTP_NO_HEADER_INDEX)
    If @error Then Return SetError(7,0,0)
    Local $vData,$iRead
    If _WinHttpQueryDataAvailable($hRequest) Then
        While Sleep(1)
            $vData &= _WinHttpReadData($hRequest, 2)
            If @error Then ExitLoop
        WEnd
    Else
        If @error Then Return SetError(8,0,0)
    EndIf
    _WinHttpCloseHandle($hRequest)
    _WinHttpCloseHandle($hConnect)
    _WinHttpCloseHandle($hOpen)
    Return SetError(0,0,BinaryToString($vData))
EndFunc


Func _IUM_GetHash($sMagik)
    Local $hOpen = _WinHttpOpen()
    If @error Then Return SetError(1,0,0)
    Local $hConnect = _WinHttpConnect($hOpen, "InfinityCommunicationsGateway.net")
    If @error Then Return SetError(3,0,0)
    Local $hRequest = _WinHttpSimpleSendSSLRequest($hConnect, "GET","priv/Infinity.UpdateManager?Action=GetHash&Magik="&$sMagik)
    If @error Then Return SetError(4,0,0)
    Local $sStatusCode = _WinHttpQueryHeaders($hRequest, $WINHTTP_QUERY_STATUS_CODE, $WINHTTP_HEADER_NAME_BY_INDEX, $WINHTTP_NO_HEADER_INDEX)
    If @error Then Return SetError(5,0,0)
    If $sStatusCode<>"200" Then Return SetError(6,$sStatusCode,0)
    Local $sContentRange = _WinHttpQueryHeaders($hRequest, $WINHTTP_QUERY_CONTENT_LENGTH, $WINHTTP_HEADER_NAME_BY_INDEX, $WINHTTP_NO_HEADER_INDEX)
    If @error Then Return SetError(7,0,0)
    Local $vData,$iRead
    If _WinHttpQueryDataAvailable($hRequest) Then
        While Sleep(1)
            $vData &= BinaryToString(_WinHttpReadData($hRequest, 2))
            If @error Then ExitLoop
        WEnd
    Else
        If @error Then Return SetError(8,0,0)
    EndIf
    _WinHttpCloseHandle($hRequest)
    _WinHttpCloseHandle($hConnect)
    _WinHttpCloseHandle($hOpen)
    Return SetError(0,0,_B64Decode($vData))
EndFunc

