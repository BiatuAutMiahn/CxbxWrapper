#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Resources\Cxbx.ico
#AutoIt3Wrapper_Outfile=..\CxbxWrapper.exe
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_UseUpx=y
#AutoIt3Wrapper_Res_Description=Cxbx-Reloaded Logger and Report Generator
#AutoIt3Wrapper_Res_Fileversion=1.0.0.0
#AutoIt3Wrapper_Res_LegalCopyright=InfinityResearchAndDevelopment 2017
#AutoIt3Wrapper_Run_Before=T:\Services\wwwRoot\priv\Infinity.UpdateManager\InfinityUpdate2.exe "%scriptdir%" "%out%"
#AutoIt3Wrapper_Run_Au3Stripper=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <ButtonConstants.au3>
#include <ComboConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <WinApiDiag.au3>
#include <File.au3>
#include <ProcessConstants.au3>
#include <String.au3>
#include <GuiComboBox.au3>
#include <Date.au3>
#Include "Includes\SHA1.au3"
#include "Includes\WinHttp.au3"
#include "Includes\Updater.au3"
Global $sTitle="Cxbx Wrapper v1.0 (Build: "&$_sInfinityProgram_Version&")"
_WinAPI_Wow64EnableWow64FsRedirection(0)
#Region ### START Koda GUI section ### Form=C:\Users\Biatu\Documents\Form1.kxf
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
#EndRegion ### END Koda GUI section ###
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
        $iRet=RunWait(@ComSpec&' /c msbuild "'&$sRepoDir&'\build\win32\Cxbx.sln" /m >"%temp%\Build.'&$aCommits[$i][1]&'.log"',$sRepoDir,@SW_HIDE);,0x10);,0x10)
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
            ;If $iOutput Then Cout($sTmp1)
            ;Cout($sTmp1)
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
EndFunc   ;==>_CxbxRun

Func __FileCountLines($sFilePath)
	Local $N = FileGetSize($sFilePath) - 1
	If @error Or $N = -1 Then Return 0
	Return StringLen(StringAddCR(FileRead($sFilePath, $N))) - $N + 1
EndFunc   ;==>__FileCountLines

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
				If FileGetSize($sLogTmpPath) >= (16 * 1048576) Then
					FileDelete($sLogPath&"\*.tmp")
					FileDelete($sLogFile&".7z")
					FileDelete($sLogFile)
                    WinSetTitle($hCxbxUpdate,"","Compressing Log...")
                    GUICtrlSetData($idCxbxUpdateMsg,"Please Wait...")
                    GUISetState(@SW_SHOW,$hCxbxUpdate)
					$iPid = Run(@ComSpec&' /c call "'&@ScriptDir&'\Data\Bin\7z.exe" a -bso0 -bse0 -bsp1 -t7z -m1=lzma2 -mx=9 -mfb=64 -md=32m -ms=on -mmt=on -mtm=on -mtc=on -myx=9 -r "' & $sLogFile & '.7z" "' & $sLogTmpPath & '"', @ScriptDir,@SW_HIDE,0x8)
                    ;$iPid = RunWait('"'&@ScriptDir&'\Data\Bin\7z.exe" a -t7z -m1=lzma2 -mx=9 -mfb=64 -md=32m -ms=on -mmt=on -mtm=on -mtc=on -myx=9 -r "' & $sLogPath & '.7z" "' & $sLogTmpPath & '"', @ScriptDir, @SW_SHOW)
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
						;Sleep(1)
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
;~             FileClose($hLog)

;~             FileWrite($hLogOut,$sLog)
;~             FileClose($hLogOut)
			ExitLoop
		EndIf
;~         If BinaryLen($sLog)>=128*1048576 Then
;~             FileWrite($hLogOut,$sLog)
;~             $sLog=""
;~         EndIf
;~         $iEnd=__FileCountLines($sLogTmpPath)
;~         If $iStart=$iEnd Then ContinueLoop
		;ConsoleWrite($iEnd&@CRLF)
;~         $hTimer=TimerInit()
;~         For $i=$iStart To $iEnd
;~             ;ConsoleWrite($i&@CRLF)
;~             ;ToolTip($i)
;~             $sLine=FileReadLine($hLog,$i)
;~             $sLine=StringStripCR(StringReplace(StringStripWS($sLine,7),@LF,""))
;~             If $sLine="" Then ContinueLoop
;~             If StringInStr($sLine,"(") Or StringInStr($sLine,"{") Or StringInStr($sLine,"}") Or StringInStr($sLine,")") Then
;~                 $iLeftBrace=0
;~                 $iRightBrace=0
;~                 StringReplace($sLine,"{","")
;~                 $iLeftBrace+=@extended
;~                 StringReplace($sLine,"(","")
;~                 $iLeftBrace+=@extended
;~                 StringReplace($sLine,"}","")
;~                 $iRightBrace+=@extended
;~                 StringReplace($sLine,")","")
;~                 $iRightBrace+=@extended
;~                 If $iLeftBrace>=1 Then
;~                     $iLogNest+=$iLeftBrace
;~                 EndIf
;~                 If $iRightBrace>0 Then
;~                     $iLogNest-=$iRightBrace
;~                 EndIf
;~                 If $iLogNest>0 Then $iLogWasNest=1
;~             EndIf
;~             If $iLogWasNest Then
;~                 If $iLogNest>0 Then
;~                     If $sLine="(" Or StringLeft($sLine,3)="[0x" Then
;~                         $sLogNest&=_StringRepeat("    ",$iLogNest-1)&$sLine&@CRLF
;~                     Else
;~                         $sLogNest&=_StringRepeat("    ",$iLogNest)&$sLine&@CRLF
;~                     EndIf
;~                 Else
;~                     If $sLine="(" Or StringLeft($sLine,3)="[0x" Then
;~                         $sLogNest&=_StringRepeat("    ",$iLogNest-1)&$sLine&@CRLF
;~                     Else
;~                         $sLogNest&=_StringRepeat("    ",$iLogNest)&$sLine&@CRLF
;~                     EndIf
;~                     ;FileWriteLine($hLogOut,$sLogNest)
;~                     $sLog&=$sLogNest&@CRLF
;~                     $sLogNest=""
;~                     $iLogWasNest=0
;~                 EndIf
;~             Else
;~                 ;FileWriteLine($hLogOut,$sLine)
;~                 $sLog&=$sLine&@CRLF
;~             EndIf
;~             ;$iStart=$iEnd
;~         Next
		;FileClose(FileOpen($sLogTmpPath,2))
		;$hLog=FileOpen($sLogTmpPath)
		;FileDelete($sLogTmpPath)
;~         ConsoleWrite($iEnd&"|"&TimerDiff($hTimer)&@CRLF)
	WEnd
	$iError = _WinAPI_GetExitCodeProcess($hChild)
	_CxbxRun(0)
EndFunc   ;==>_RunCxbx

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
EndFunc   ;==>_GetCxbxBuilds

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
;~ 	ConsoleWrite("Magic:                    " & $bMagic & @CRLF)
;~ 	ConsoleWrite("Base Address:             " & $bBaseAddr & @CRLF)
;~ 	ConsoleWrite("Entry Point  Address:     " & $bEntryAddr & @CRLF)
;~ 	ConsoleWrite("Certificate Address:      " & $bCertAddr & @CRLF) ;
;~ 	ConsoleWrite("Library Versions Address: " & $bLibsAddr & @CRLF) ;
;~ 	ConsoleWrite("Certificate Size:         " & $bCertSize & @CRLF) ;
;~ 	ConsoleWrite("API Version Name:         " & $bLibName & @CRLF) ;
;~ 	ConsoleWrite("Title Name:               " & $bTitleName & @CRLF) ;
;~ 	ConsoleWrite("Title ID:                 " & $bTitleID & @CRLF) ;
;~ 	ConsoleWrite("API Version:              " & $bLibVer & @CRLF) ;
;~ 	ConsoleWrite("Debug:                    " & ($bDebug = 0) & @CRLF)
	If $bTitleID <> "" Then
        $sXbeTitleID=$bTitleID
		GUICtrlSetData($idXbeTitleID, "Title ID:    " & $bTitleID)
	EndIf
    $iXbeDebug=$bDebug
    GUICtrlSetData($idXbeDebug, "Debug:       " & ($bDebug = 0))
    If $bLibVer Then
        $iXbeAPI=$bLibVer
        GUICtrlSetData($idXbeVerAPI, "API Version: " & $bLibVer)
    EndIf
    If $bTitleName<>"" Then
		$sXbeTitleName = $bTitleName
		GUICtrlSetState($idXbeTitleName, $GUI_DISABLE)
		GUICtrlSetData($idXbeTitleName, $bTitleName)
	EndIf
EndFunc   ;==>_XbeGetInfo

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
        ;$iPid=RunWait(@ComSpec&" /k echo "&$sCmd,@ScriptDir,@SW_SHOW)
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
EndFunc   ;==>_SaveReport

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
                ;GUICtrlSetState($idXbeTitleName,$GUI_DISABLE)
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
        ;_ArrayDisplay($aSections)
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
EndFunc   ;==>_LoadReport

Func _LoadConfig()
    If FileExists($sDataFile) Then
        $sReporterName=IniRead($sDataFile,"Config","Reporter","")
        If $sReporterName<>"" Then GUICtrlSetData($idMainReporter,$sReporterName)
    EndIf
EndFunc

#Region GuiStuff
Func GuiEvents()
	;MsgBox(64,"","Here")
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
;~                 If $sReporterName="" Then
;~                     MsgBox(48,$sTitle,"Please Enter a Reporter Name")
;~                     Return
;~                 EndIf

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
                ;ConsoleWrite($sCxbxBuild&"|"&$sCxbxBuildPath&@CRLF)
            Case $idCxbxUpdate
                _UpdateCxbx()
            Case $idMainXbeOpen
                $sXbePath = FileOpenDialog($sTitle, -1, "Xbox Executable (*.xbe)", 3)
                If $sXbePath = "" Then Return
                $sXbeDir = StringRegExpReplace($sXbePath, "(.*)\\.*\.xbe", "$1")
                _XbeGetInfo($sXbePath)
                ;ContinueLoop
                $iXbeOpen = 1
                _LoadReport()
                _GuiUpdateState()
            Case $idGfxInput
                If BitAND(GUICtrlRead($nMsg[0]), $GUI_CHECKED) = $GUI_CHECKED Then
                    $iInput += 1
                    ;GUICtrlSetState($nMsg,$GUI_UNCHECKED)
                Else
                    $iInput -= 1
                EndIf
                _GuiUpdateState()
            Case $idGfxSync
                If BitAND(GUICtrlRead($nMsg[0]), $GUI_CHECKED) = $GUI_CHECKED Then
                    $iSync += 1
                    ;GUICtrlSetState($nMsg,$GUI_UNCHECKED)
                Else
                    $iSync -= 1
                EndIf
                _GuiUpdateState()
            Case $idAudInput
                If BitAND(GUICtrlRead($nMsg[0]), $GUI_CHECKED) = $GUI_CHECKED Then
                    $iInput += 2
                    ;GUICtrlSetState($nMsg,$GUI_UNCHECKED)
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
EndFunc   ;==>GuiEvents
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
EndFunc   ;==>_GuiSetDefaults

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
EndFunc   ;==>_EnDisableState

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
EndFunc   ;==>_EnDisableReport

Func _GuiUpdateState()
	If $iXbeOpen Then
		;ConsoleWrite($iInput&@CRLF)
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

EndFunc   ;==>_GuiUpdateState
#EndRegion GuiStuff
