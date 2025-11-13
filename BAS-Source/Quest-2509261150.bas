' ================================================================
' QUEST ADVENTURE GAME - Cleaned Version with Debug Toggle & Status
' ================================================================
' A text-based adventure game with rooms, artifacts, and creatures
' Cleaned and updated for QB64/FreeBASIC compatibility
' ================================================================

' ----------------------------------------------------------------
' TYPE DEFINITIONS AND GLOBAL VARIABLES  
' ----------------------------------------------------------------
Type GameRecord
    DataRecord As String * 100
End Type

' File handling variables
Dim Shared GameRec As GameRecord
Dim Shared RecordNumber As Integer

' Game state variables
Dim Shared CurrentRoom As Integer
Dim Shared HomeRoom As Integer
Dim Shared WarehouseRoom As Integer
Dim Shared DarkRoom As Integer
Dim Shared MoveCount As Integer
Dim Shared CarryCount As Integer
Dim Shared PlayerState As Integer
Dim Shared Score As Double
Dim Shared PenaltyPoints As Integer
Dim Shared RandomSeed As Integer
Dim Shared NewPlace As Integer
Dim Shared ParsedNumber As Integer
Dim Shared ProcessedWord As String
Dim Shared CommandArgs As String
Dim Shared ParsedText1 As String
Dim Shared ParsedText2 As String
Dim Shared TextContinue As String
Dim Shared UserInput As String
Dim Shared UserFileName As String
Dim Shared UserResponse As String
Dim Shared GremlinData As String
Dim Shared TargetGremlin As Integer
Dim Shared FoundTarget As Integer

' Game arrays
Dim Shared ArtifactLocation(60) As Integer
Dim Shared ArtifactRecord(60) As Integer
Dim Shared GremlinLocation(40) As Integer
Dim Shared GremlinRecord(40) As Integer
Dim Shared GremlinFactor(40) As Integer
Dim Shared LocationList(5) As Integer
Dim Shared RecentPlaces(5) As Integer

' Game control variables
Dim Shared NumArtifacts As Integer
Dim Shared NumGremlins As Integer
Dim Shared CurrentRecord As Integer
Dim Shared FlagRecord As Integer
Dim Shared ActionResult As String
Dim Shared SecondaryAction As String
Dim Shared RecordContent As String
Dim Shared PlaceRecord As String
Dim Shared DataBuffer As String

' Text processing variables
Dim Shared Word1 As String
Dim Shared Word2 As String
Dim Shared Command As String
Dim Shared Action As String
Dim Shared OutputBuffer As String
Dim Shared TextOutput As String

' Logging
Dim Shared LogFile As Integer
Dim Shared DebugLogging As Integer

' ----------------------------------------------------------------
' ERROR HANDLING
' ----------------------------------------------------------------
On Error GoTo ErrorHandler

' ----------------------------------------------------------------
' MAIN PROGRAM INITIALIZATION
' ----------------------------------------------------------------
Main:
    Randomize Timer
    DebugLogging = 0 ' Default: off
    Call OpenLogFile
    Call InitializeGame
    Call LoadGameData
    Call StartGameLoop
End

' ----------------------------------------------------------------
' LOGGING UTILITIES
' ----------------------------------------------------------------
Sub OpenLogFile
    LogFile = FreeFile
    Open "game_error.log" For Append As #LogFile
    Print #LogFile, "=== Game Session Started at " + Date$ + " " + Time$ + " ==="
End Sub

Sub WriteLog(Message As String)
    If LogFile > 0 Then
        Print #LogFile, Date$; " "; Time$; " - "; Message
    End If
End Sub

Sub DebugLog(Message As String)
    If DebugLogging = 1 Then Call WriteLog("DEBUG: " + Message)
End Sub

Sub CloseLogFile
    If LogFile > 0 Then
        Print #LogFile, "=== Game Session Ended at " + Date$ + " " + Time$ + " ==="
        Close #LogFile
    End If
End Sub

' ----------------------------------------------------------------
' GAME INITIALIZATION ROUTINES
' ----------------------------------------------------------------
Sub InitializeGame
    Open "QDATA.dat" For Random As #1 Len = Len(GameRec)
    RandomSeed = 1
    CarryCount = 0
    SecondaryAction = "0"
    MoveCount = 100
    PenaltyPoints = 0
    ActionResult = "N"
    Call DebugLog("Game initialized")
End Sub

Sub LoadGameData
    CurrentRecord = 0
    Call GetRecord
    CurrentRoom = Val(Mid$(RecordContent, 21, 4))
    HomeRoom = Val(Mid$(RecordContent, 25, 4))
    WarehouseRoom = Val(Mid$(RecordContent, 29, 4))
    DarkRoom = Val(Mid$(RecordContent, 33, 4))
    CurrentRecord = Val(Mid$(RecordContent, 11, 4))
    FlagRecord = Val(Mid$(RecordContent, 17, 4))
    NumArtifacts = Val(Mid$(RecordContent, 9, 2))
    NumGremlins = Val(Mid$(RecordContent, 15, 2))
    Call LoadArtifacts
    Call LoadGremlins
    Call DebugLog("Game data loaded")
End Sub

' ----------------------------------------------------------------
' RUNTIME DEBUG TOGGLE COMMAND
' ----------------------------------------------------------------
Sub HandleDebugToggle
    If Word2 = "ON  " Then
        DebugLogging = 1
        Print "Debug logging ENABLED"
        Call WriteLog("Debug logging enabled at runtime")
    ElseIf Word2 = "OFF " Then
        DebugLogging = 0
        Print "Debug logging DISABLED"
        Call WriteLog("Debug logging disabled at runtime")
    ElseIf Word2 = "STAT" Then
        If DebugLogging = 1 Then
            Print "Debug logging is currently ON"
        Else
            Print "Debug logging is currently OFF"
        End If
    Else
        Print "DEBUG command requires ON, OFF, or STATUS"
    End If
End Sub

' ----------------------------------------------------------------
' INTEGRATE DEBUG TOGGLE INTO COMMANDS
' ----------------------------------------------------------------
Sub ParseCommand(InputString As String)
    Call ExtractWord(InputString)
    Word1 = ProcessedWord
    If Len(Word1) = 0 Then
        Word1 = "*   "
    Else
        Word1 = Left$(Word1 + "   ", 4)
    End If
    Call ExtractWord(InputString)
    Word2 = ProcessedWord
    If Len(Word2) = 0 Then
        Word2 = "*   "
    Else
        Word2 = Left$(Word2 + "   ", 4)
    End If
    Call ConvertToUppercase(Word1)
    Call ConvertToUppercase(Word2)

    If Word1 = "SAVE" And Word2 = "*   " Then Call SaveGame: Exit Sub
    If Word1 = "LOAD" And Word2 = "*   " Then Call LoadGame: Exit Sub
    If Word1 = "ZPQR" Then Call HandleDebugCommand: Exit Sub
    If Word1 = "DEBU" Then Call HandleDebugToggle: Exit Sub
End Sub

' ----------------------------------------------------------------
' ERROR HANDLER
' ----------------------------------------------------------------
ErrorHandler:
    Dim ErrMsg As String
    ErrMsg = "Error code: " + Str$(Err) + " at line: " + Str$(Erl)
    Print "*** ERROR OCCURRED ***"
    Print ErrMsg
    Print "Game state may be corrupted."
    Call WriteLog("RUNTIME ERROR - " + ErrMsg)
    If CurrentRoom <= 0 Or CurrentRoom > 9999 Then
        CurrentRoom = HomeRoom
        Print "Resetting player to home room: "; HomeRoom
        Call WriteLog("Player reset to home room")
    End If
    Resume Next
