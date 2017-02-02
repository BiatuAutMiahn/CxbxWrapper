#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.2
 Author:         BiatuAutMiahn[@outlook.com]

 Script Function:
	Update Script

#ce ----------------------------------------------------------------------------
#include-once
#include <WinAPIProc.au3>
#include <Array.au3>
#include <WinAPIFiles.au3>
#include <FontConstants.au3>
#include <WindowsConstants.au3>
Global Const $_sInfinityProgram_File=StringTrimRight(@AutoItExe,4)&".Update.exe"
Global Const $_sInfinityProgram_Version="20170202034143"
Global Const $_sInfinityProgram_Magik="ap96zsxTMmjR4EqQ"
Global $_idIUM_Progress, $_idIUM_Status, $iTest=False;, $sTitle=""
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
    ;$idProg=GUICtrlCreateProgress(4,$iHeight-25,$iWidth-8,20)
    $idProg=GUICtrlCreateProgress(4,$iHeight-52,$iWidth-14,20)
    $_idIUM_Progress=$idProg
    GUISetState()
    ;Do the update
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
                $iRet=MsgBox(64+4,"Update Available","There is a new update available, would you like to upgrade?"&@CRLF& _
                                                     "NOTE: Updates may be unstable or buggy as this software is a beta."&@CRLF& _
                                                     "    Please contact the developer for help."&@CRLF&@CRLF& _
                                                     "Current Version: "&_IUM_FormatVer($_sInfinityProgram_Version)&@CRLF& _
                                                     "Latest Version: "&_IUM_FormatVer($sRet)&@CRLF)
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

Func _IUM_UpdateFail($sRun)
    Run($sRun&" ~!Update.Failed",@ScriptDir)
    Exit 1
EndFunc

Func _IUM_Shutdown()
    TCPShutdown()
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
                If $iProg Then;, $_iIUM_SizeLast
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
                    Sleep(1000); Wait for progress bar
                EndIf
                ExitLoop
            EndIf
        EndIf
    Until False
    TCPCloseSocket($hSocket)
    Return SetError(0,$sHeader,$bData)
EndFunc

Func _IUM_DownloadStat();$_iIUM_DataLen
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
        ;Else
            ;ExitLoop
        EndIf
    Next
    Return $iAvg/$iMax
EndFunc
