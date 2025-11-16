' ================================================================
' QUEST ADVENTURE GAME - Visual Basic Version
' ================================================================
' A text-based adventure game with rooms, artifacts, and creatures
' Converted from QuickBasic to Visual Basic
' ================================================================

Option Explicit

' ----------------------------------------------------------------
' TYPE DEFINITIONS AND MODULE-LEVEL VARIABLES
' ----------------------------------------------------------------
Private Type GameRecord
    DataRecord As String * 100
End Type

' File handling variables
Private GameRec As GameRecord
Private RecordNumber As Integer
Private FileNum As Integer

' Game state variables
Private CurrentRoom As Integer          ' Current player location
Private HomeRoom As Integer             ' Starting/home room
Private WarehouseRoom As Integer        ' Warehouse room
Private DarkRoom As Integer             ' Dark room
Private MoveCount As Integer            ' Number of moves made
Private CarryCount As Integer           ' Items currently carried
Private PlayerState As Integer          ' Player's current state
Private Score As Double                 ' Current game score
Private PenaltyPoints As Integer        ' Penalty points
Private RandomSeed As Integer           ' Random number seed

' Game arrays
Private ArtifactLocation(1 To 60) As Integer     ' Where each artifact is located
Private ArtifactRecord(1 To 60) As Integer       ' Record number for each artifact
Private GremlinLocation(1 To 40) As Integer      ' Where each gremlin is located
Private GremlinRecord(1 To 40) As Integer        ' Record number for each gremlin
Private GremlinFactor(1 To 40) As Integer        ' Gremlin behavior factor
Private LocationList(1 To 5) As Integer          ' Location history list
Private RecentPlaces(0 To 5) As Integer          ' Recently visited places

' Game control variables
Private NumArtifacts As Integer         ' Total number of artifacts
Private NumGremlins As Integer          ' Total number of gremlins
Private CurrentRecord As Integer        ' Current record being processed
Private FlagRecord As Integer           ' Flag record number
Private ActionResult As String          ' Action result flag
Private SecondaryAction As String       ' Secondary action to execute
Private RecordContent As String         ' Content of current record
Private PlaceRecord As String           ' Current place record
Private DataBuffer As String            ' Data buffer for file operations

' Text processing variables
Private Word1 As String                 ' First word of command
Private Word2 As String                 ' Second word of command
Private Command As String               ' Processed command
Private Action As String                ' Current action being processed
Private OutputBuffer As String          ' Text output buffer
Private TextOutput As String            ' Text to output
Private ProcessedWord As String         ' Processed word from input
Private CommandArgs As String           ' Command arguments
Private ParsedText1 As String           ' First parsed text
Private ParsedText2 As String           ' Second parsed text
Private TextContinue As String          ' Text continuation flag
Private UserInput As String             ' User input string
Private UserFileName As String          ' Save/load filename
Private UserResponse As String          ' User response
Private GremlinData As String           ' Gremlin data string
Private NewPlace As Integer             ' New location for movement
Private ParsedNumber As Integer         ' Parsed numeric value

' Loop control variables
Private GremlinIndex As Integer
Private ArtifactIndex As Integer
Private Index As Integer
Private CheckIndex As Integer
Private ActionIndex As Integer
Private ProcessIndex As Integer
Private ItemIndex As Integer
Private SearchIndex As Integer
Private ListOffset As Integer
Private OptimalMove As Integer
Private TargetGremlin As Integer
Private FoundTarget As Integer

' ----------------------------------------------------------------
' MAIN PROGRAM ENTRY POINT
' ----------------------------------------------------------------
Public Sub Main()
    ' Initialize random seed from system timer
    Randomize Timer
    
    Call InitializeGame
    Call LoadGameData
    Call GameLoop
End Sub

' ----------------------------------------------------------------
' GAME INITIALIZATION ROUTINES
' ----------------------------------------------------------------
Private Sub InitializeGame()
    ' Open game data file
    FileNum = FreeFile
    Open App.Path & "\QDATA.dat" For Random As #FileNum Len = Len(GameRec)
    
    ' Initialize game state
    RandomSeed = 1
    CarryCount = 0
    SecondaryAction = "0"
    MoveCount = 100
    PenaltyPoints = 0
    ActionResult = "N"
    OutputBuffer = ""
End Sub

Private Sub LoadGameData()
    ' Load initial game configuration
    CurrentRecord = 0
    Call GetRecord
    
    ' Parse game configuration from first record
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
End Sub

Private Sub LoadArtifacts()
    Dim i As Integer
    CurrentRecord = FlagRecord
    
    Do
        Call GetRecord
        i = Val(Mid$(RecordContent, 91, 2))
        ArtifactLocation(i) = Val(Mid$(RecordContent, 93, 4))
        ArtifactRecord(i) = CurrentRecord
        CurrentRecord = Val(Left$(RecordContent, 4))
    Loop While CurrentRecord > 0
End Sub

Private Sub LoadGremlins()
    Dim i As Integer
    CurrentRecord = FlagRecord
    
    Do
        Call GetRecord
        i = Val(Mid$(RecordContent, 91, 2))
        GremlinLocation(i) = Val(Mid$(RecordContent, 93, 4))
        GremlinRecord(i) = CurrentRecord
        GremlinFactor(i) = Val(Mid$(RecordContent, 81, 1))
        CurrentRecord = Val(Left$(RecordContent, 4))
    Loop While CurrentRecord > 0
End Sub

' ----------------------------------------------------------------
' MAIN GAME LOOP
' ----------------------------------------------------------------
Private Sub GameLoop()
    Call ValidateGameState
    ActionResult = "Y"
    Call ArriveAtLocation
    Call StartGameLoop
End Sub

Private Sub StartGameLoop()
    ActionResult = "N"
    
    Do
        If ActionResult = "Y" Then
            Call ProcessMovement
        Else
            Call ProcessGremlins
        End If
        
        Call ArriveAtLocation
        
        If ActionResult <> "Y" Then
            Call CheckGremlinAttacks
        End If
        
        Call DisplayLocation
        Call GetPlayerInput
        Call ProcessCommand
        
        DoEvents  ' Allow Windows to process messages
    Loop
End Sub

' ----------------------------------------------------------------
' MOVEMENT AND LOCATION PROCESSING
' ----------------------------------------------------------------
Private Sub ProcessMovement()
    Dim TempString As String
    Dim FollowString As String
    Dim StateValue As Integer
    
    ActionResult = "Y"
    TempString = "The"
    FollowString = "X"
    
    ' Check which gremlins follow the player
    For GremlinIndex = 1 To NumGremlins
        If GremlinLocation(GremlinIndex) <> CurrentRoom Then
            GoTo NextGremlin
        End If
        
        CurrentRecord = GremlinRecord(GremlinIndex)
        Call GetRecord
        
        StateValue = Val(Mid$(RecordContent, 9, 1))
        
        If Val(Mid$(RecordContent, 80 + 2 * StateValue, 1)) <= Rnd * 9 Then
            GoTo NextGremlin
        End If
        
        TextOutput = TempString
        Call ProcessTextOutput
        
        If TempString = "The" Then
            FollowString = "%4has"
        Else
            FollowString = "%4have"
        End If
        
        TempString = "%4and"
        Call ProcessDescription
        GremlinLocation(GremlinIndex) = -NewPlace
        
NextGremlin:
    Next GremlinIndex
    
    CurrentRoom = NewPlace
    
    If FollowString <> "X" Then
        TextOutput = FollowString + " following you. "
        Call ProcessTextOutput
        ActionResult = "N"
    End If
End Sub

Private Sub ArriveAtLocation()
    CurrentRecord = CurrentRoom
    Call GetRecord
    PlaceRecord = RecordContent
    CurrentRecord = Val(Left$(PlaceRecord, 4))
    
    ' Update location history
    For Index = 1 To 5
        If CurrentRoom = RecentPlaces(Index) Then
            CurrentRecord = Val(Mid$(PlaceRecord, 5, 4))
        End If
        RecentPlaces(Index - 1) = RecentPlaces(Index)
    Next Index
    
    RecentPlaces(5) = CurrentRoom
    Call ProcessLocationDescription
    
    PlayerState = Val(Mid$(PlaceRecord, 9, 1))
    CurrentRecord = Val(Mid$(PlaceRecord, 6 + 4 * PlayerState, 4))
    Call ProcessLocationDescription
    
    ' Process artifacts and gremlins at current location
    Call ProcessArtifactsAtLocation
    Call ProcessGremlinsAtLocation
End Sub

Private Sub DisplayLocation()
    ' Location is displayed through ArriveAtLocation
End Sub

' ----------------------------------------------------------------
' COMMAND PROCESSING
' ----------------------------------------------------------------
Private Sub GetPlayerInput()
    Call FlushOutput
    Call CalculateScore
    
    Debug.Print Score & "  :";
    UserInput = InputBox("Enter command:", "Quest Adventure", "")
    
    If UserInput = "" Then UserInput = "*"
    
    RandomSeed = Len(UserInput)
    MoveCount = MoveCount + 1
    
    Call ParseCommand(UserInput)
End Sub

Private Sub ParseCommand(InputString As String)
    ' Extract first word
    Call ExtractWord(InputString)
    Word1 = ProcessedWord
    
    If Len(Word1) = 0 Then
        Word1 = "*   "
    Else
        Word1 = Left$(Word1 & "   ", 4)
    End If
    
    ' Extract second word
    Call ExtractWord(InputString)
    Word2 = ProcessedWord
    
    If Len(Word2) = 0 Then
        Word2 = "*   "
    Else
        Word2 = Left$(Word2 & "   ", 4)
    End If
    
    ' Convert to uppercase
    Call ConvertToUppercase(Word1)
    Call ConvertToUppercase(Word2)
    
    ' Handle special commands
    If Word1 = "SAVE" And Word2 = "*   " Then Call SaveGame: Exit Sub
    If Word1 = "LOAD" And Word2 = "*   " Then Call LoadGame: Exit Sub
    If Word1 = "ZPQR" Then Call HandleDebugCommand: Exit Sub
End Sub

Private Sub ProcessCommand()
    Command = "?"
    Action = "?"
    
    ' Check for movement commands
    Call CheckMovementCommands
    If Command <> "?" Then Call HandleMovement: Exit Sub
    
    ' Check for keyword interactions
    Call CheckKeywordInteractions
    If Action <> "?" Then Call ExecuteAction: Exit Sub
    
    ' Check for standard game commands
    Call CheckStandardCommands
    If Action <> "?" Then Call ExecuteAction: Exit Sub
    
    ' Command not recognized
    CurrentRecord = 344
    Call DisplayMessage
End Sub

' ----------------------------------------------------------------
' MOVEMENT HANDLING
' ----------------------------------------------------------------
Private Sub CheckMovementCommands()
    Dim DirectionString As String
    
    DirectionString = "NORTSOUTEASTWESTUP  DOWN" & Mid$(PlaceRecord, 26, 8)
    
    For Index = 1 To 29 Step 4
        If Word1 = Mid$(DirectionString, Index, 4) Then
            Command = "C" & Right$(CStr((Index + 3) / 400), 2)
            Exit For
        End If
    Next Index
End Sub

Private Sub HandleMovement()
    Action = "?"
    RecordContent = PlaceRecord
    Call FindActionInRecord
    
    If Action <> "?" Then
        Call ExecuteAction
    Else
        CurrentRecord = 343
        Call DisplayMessage
    End If
End Sub

' ----------------------------------------------------------------
' GAME UTILITIES
' ----------------------------------------------------------------
Private Sub GetRecord()
    ' Read record from data file
    RecordNumber = CurrentRecord + 1
    Get #FileNum, RecordNumber, GameRec
    RecordContent = GameRec.DataRecord
End Sub

Private Sub SaveRecord()
    ' Write current record back to file
    Dim TempRecord As GameRecord
    TempRecord.DataRecord = RecordContent
    Put #FileNum, CurrentRecord + 1, TempRecord
End Sub

Private Sub DisplayMessage()
    If CurrentRecord = 0 Then Exit Sub
    
    Call GetRecord
    Call ParseTextTokens
    
    TextOutput = ParsedText1
    Call ProcessTextOutput
    
    If TextContinue = "1" Then Exit Sub
    
    TextOutput = ParsedText2
    Call ProcessTextOutput
    
    If TextContinue = "3" Then
        CurrentRecord = CurrentRecord + 1
        Call DisplayMessage
    End If
End Sub

Private Sub CalculateScore()
    Dim StateValue As Integer
    
    Score = 0
    
    For ArtifactIndex = 1 To NumArtifacts
        If ArtifactLocation(ArtifactIndex) <> HomeRoom Then GoTo NextArtifact
        
        CurrentRecord = ArtifactRecord(ArtifactIndex)
        Call GetRecord
        
        StateValue = Val(Mid$(RecordContent, 9, 1))
        
        If Mid$(RecordContent, 80 + StateValue + StateValue, 1) = "2" Then
            Score = Score + Val(Mid$(RecordContent, 79, 3))
        End If
        
NextArtifact:
    Next ArtifactIndex
    
    Score = Int(1000 * (10 * Score - PenaltyPoints) / MoveCount) / 100
End Sub

' ----------------------------------------------------------------
' SAVE/LOAD FUNCTIONALITY
' ----------------------------------------------------------------
Private Sub SaveGame()
    Dim SaveFileNum As Integer
    
    UserFileName = InputBox("Enter filename to save:", "Save Game", "SAVEGAME.SAV")
    If UserFileName = "" Then
        Call ArriveAtLocation
        Exit Sub
    End If
    
    SaveFileNum = FreeFile
    Open App.Path & "\" & UserFileName For Output As #SaveFileNum
    Print #SaveFileNum, CurrentRoom; Score; MoveCount; PenaltyPoints; CarryCount; RandomSeed
    
    For Index = 1 To 60
        Print #SaveFileNum, ArtifactLocation(Index); ArtifactRecord(Index)
    Next Index
    
    For Index = 1 To 40
        Print #SaveFileNum, GremlinLocation(Index); GremlinRecord(Index); GremlinFactor(Index)
    Next Index
    
    For Index = 1 To 5
        Print #SaveFileNum, LocationList(Index); RecentPlaces(Index)
    Next Index
    
    Close #SaveFileNum
    MsgBox "Game saved successfully!", vbInformation
    Call ArriveAtLocation
End Sub

Private Sub LoadGame()
    Dim LoadFileNum As Integer
    
    UserFileName = InputBox("Enter filename to load:", "Load Game", "SAVEGAME.SAV")
    If UserFileName = "" Then
        Call ArriveAtLocation
        Exit Sub
    End If
    
    On Error GoTo LoadError
    
    LoadFileNum = FreeFile
    Open App.Path & "\" & UserFileName For Input As #LoadFileNum
    Input #LoadFileNum, CurrentRoom, Score, MoveCount, PenaltyPoints, CarryCount, RandomSeed
    
    For Index = 1 To 60
        Input #LoadFileNum, ArtifactLocation(Index), ArtifactRecord(Index)
    Next Index
    
    For Index = 1 To 40
        Input #LoadFileNum, GremlinLocation(Index), GremlinRecord(Index), GremlinFactor(Index)
    Next Index
    
    For Index = 1 To 5
        Input #LoadFileNum, LocationList(Index), RecentPlaces(Index)
    Next Index
    
    Close #LoadFileNum
    MsgBox "Game loaded successfully!", vbInformation
    Call ArriveAtLocation
    Exit Sub
    
LoadError:
    MsgBox "Error loading game: " & Err.Description, vbExclamation
    Call ArriveAtLocation
End Sub

' ----------------------------------------------------------------
' TEXT PROCESSING UTILITIES
' ----------------------------------------------------------------
Private Sub ExtractWord(ByRef InputString As String)
    Dim SpacePosition As Integer
    
    ' Remove leading spaces
    Do While Left$(InputString, 1) = " "
        InputString = Right$(InputString, Len(InputString) - 1)
    Loop
    
    ' Find next space
    SpacePosition = InStr(InputString, " ")
    If SpacePosition = 0 Then SpacePosition = Len(InputString) + 1
    
    ' Extract word
    ProcessedWord = Left$(InputString, SpacePosition - 1)
    InputString = Right$(InputString, Len(InputString) - SpacePosition + 1)
End Sub

Private Sub ConvertToUppercase(ByRef WordString As String)
    WordString = UCase$(WordString)
End Sub

Private Sub ProcessTextOutput()
    Dim PercentPos As Integer
    Dim FormatCode As Integer
    
    ' Handle text formatting and output
    If Right$(TextOutput, 1) <> " " Then GoTo ProcessSpecialChars
    If Right$(TextOutput, 2) = ". " Then GoTo AddToBuffer
    
    TextOutput = Left$(TextOutput, Len(TextOutput) - 1)
    If Len(TextOutput) = 0 Then Exit Sub
    GoTo ProcessTextOutput
    
ProcessSpecialChars:
    If Right$(TextOutput, 1) = "." Then TextOutput = TextOutput & " "
    
AddToBuffer:
    PercentPos = InStr(TextOutput, "%")
    If PercentPos = 0 Then PercentPos = Len(TextOutput) + 1
    
    OutputBuffer = OutputBuffer & Left$(TextOutput, PercentPos - 1) & " "
    
    If Len(OutputBuffer) > 70 Then Call WrapText
    If PercentPos > Len(TextOutput) Then Exit Sub
    
    ' Process special formatting codes
    FormatCode = Val(Mid$(TextOutput, PercentPos + 1, 1))
    Select Case FormatCode
        Case 1: Call FlushOutput
        Case 2: OutputBuffer = OutputBuffer & "%"
        Case 3: OutputBuffer = Left$(OutputBuffer, Len(OutputBuffer) - 1)
        Case 4: If Len(OutputBuffer) >= 4 Then OutputBuffer = Left$(OutputBuffer, Len(OutputBuffer) - 4) & " "
    End Select
    
    TextOutput = Right$(TextOutput, Len(TextOutput) - PercentPos - 1)
    If Len(TextOutput) > 0 Then GoTo AddToBuffer
End Sub

Private Sub WrapText()
    Dim WrapPos As Integer
    
    WrapPos = InStr(60, OutputBuffer, " ")
    If WrapPos = 0 Then WrapPos = Len(OutputBuffer)
    
    Debug.Print Left$(OutputBuffer, WrapPos)
    OutputBuffer = Right$(OutputBuffer, Len(OutputBuffer) - WrapPos)
    
    ' Remove leading space
    Do While Left$(OutputBuffer, 1) = " "
        OutputBuffer = Right$(OutputBuffer, Len(OutputBuffer) - 1)
    Loop
End Sub

Private Sub FlushOutput()
    If Len(OutputBuffer) > 0 Then Call WrapText
    If Len(OutputBuffer) > 0 Then
        Debug.Print OutputBuffer
        OutputBuffer = ""
    End If
End Sub

Private Sub ParseTextTokens()
    ' Parse text tokens from record
    ParsedText1 = Mid$(RecordContent, 1, 40)
    ParsedText2 = Mid$(RecordContent, 41, 40)
    
    If Right$(RecordContent, 1) = "3" Then
        TextContinue = "3"
    Else
        TextContinue = "1"
    End If
End Sub

' ----------------------------------------------------------------
' DEBUG AND UTILITY COMMANDS
' ----------------------------------------------------------------
Private Sub HandleDebugCommand()
    If Word2 = "ARTI" Then
        ' Give all artifacts to player
        For ArtifactIndex = 1 To NumArtifacts
            ArtifactLocation(ArtifactIndex) = 0
        Next ArtifactIndex
        CarryCount = NumArtifacts
    ElseIf Word2 = "GREM" Then
        ' Remove all gremlins
        For GremlinIndex = 1 To NumGremlins
            GremlinLocation(GremlinIndex) = -1
        Next GremlinIndex
    Else
        ' Teleport to specified room
        CurrentRoom = Val(Word2)
        ActionResult = "Y"
    End If
End Sub

' ----------------------------------------------------------------
' GREMLIN AI AND BEHAVIOR
' ----------------------------------------------------------------
Private Sub ProcessGremlins()
    TargetGremlin = 0
    
    For GremlinIndex = 1 To NumGremlins
        If GremlinLocation(GremlinIndex) <> CurrentRoom Then GoTo NextGremlin
        
        GremlinFactor(GremlinIndex) = GremlinFactor(GremlinIndex) + 1
        
        If Rnd * 10 <= GremlinFactor(GremlinIndex) Then
            TargetGremlin = GremlinIndex
            GremlinFactor(GremlinIndex) = 9
        End If
        
NextGremlin:
    Next GremlinIndex
    
    If TargetGremlin = 0 Then Exit Sub
    Call ProcessGremlinAction(TargetGremlin)
End Sub

Private Sub ProcessGremlinAction(GremIndex As Integer)
    Dim StateValue As Integer
    Dim SuccessChance As Integer
    
    CurrentRecord = GremlinRecord(GremIndex)
    Call GetRecord
    
    GremlinFactor(GremIndex) = Val(Mid$(RecordContent, 86, 1))
    StateValue = Val(Mid$(RecordContent, 9, 1))
    CurrentRecord = Val(Mid$(RecordContent, 87, 4))
    
    If CurrentRecord = 0 Then Exit Sub
    
    SuccessChance = Val(Mid$(RecordContent, 81 + 2 * StateValue, 1))
    Call GetRecord
    ActionResult = "Y"
    
    If Rnd * 9 < SuccessChance Then
        Call ProcessSuccessfulCondition
    Else
        Call ProcessFailedCondition
    End If
End Sub

Private Sub CheckGremlinAttacks()
    OptimalMove = 9999
    
    For GremlinIndex = 1 To NumGremlins
        If GremlinLocation(GremlinIndex) = CurrentRoom Then
            CurrentRecord = GremlinRecord(GremlinIndex)
            Call ProcessObjectInteraction
        End If
        
        If GremlinLocation(GremlinIndex) = -CurrentRoom Then
            GremlinLocation(GremlinIndex) = CurrentRoom
        End If
    Next GremlinIndex
End Sub

' ----------------------------------------------------------------
' OBJECT AND LOCATION PROCESSING
' ----------------------------------------------------------------
Private Sub ProcessArtifactsAtLocation()
    OptimalMove = 9999
    
    For ArtifactIndex = 1 To NumArtifacts
        If ArtifactLocation(ArtifactIndex) = CurrentRoom Or ArtifactLocation(ArtifactIndex) = 0 Then
            CurrentRecord = ArtifactRecord(ArtifactIndex)
            Call ProcessObjectInteraction
        End If
    Next ArtifactIndex
End Sub

Private Sub ProcessGremlinsAtLocation()
    For GremlinIndex = 1 To NumGremlins
        If GremlinLocation(GremlinIndex) = CurrentRoom Then
            CurrentRecord = GremlinRecord(GremlinIndex)
            Call ProcessObjectInteraction
        End If
    Next GremlinIndex
End Sub

Private Sub ProcessObjectInteraction()
    Dim NameRecord As Integer
    Dim StateVal As Integer
    
    Call GetRecord
    StateVal = Val(Mid$(RecordContent, 9, 1))
    NameRecord = Val(Mid$(RecordContent, 6 + 4 * StateVal, 4))
    
    CurrentRecord = Val(Mid$(RecordContent, 5, 4))
    If CurrentRecord = 0 Then GoTo DisplayName
    
    If CurrentRecord = OptimalMove Then
        TextOutput = "%4and a"
        Call ProcessTextOutput
    Else
        Call DisplayMessage
    End If
    
DisplayName:
    OptimalMove = CurrentRecord
    CurrentRecord = NameRecord
    Call DisplayMessage
End Sub

Private Sub ProcessLocationDescription()
    Call DisplayMessage
End Sub

' ----------------------------------------------------------------
' COMMAND PROCESSING IMPLEMENTATIONS
' ----------------------------------------------------------------
Private Sub CheckKeywordInteractions()
    If Mid$(PlaceRecord, 26, 4) <> "* KR" Then GoTo CheckGremlins
    
    CurrentRecord = Val(Mid$(PlaceRecord, 30, 4))
    Call FindActionInRecord
    If Action <> "?" Then Exit Sub
    
CheckGremlins:
    For GremlinIndex = NumGremlins To 1 Step -1
        If GremlinLocation(GremlinIndex) <> CurrentRoom Then GoTo NextGremlin
        
        CurrentRecord = GremlinRecord(GremlinIndex)
        Call GetRecord
        
        If Mid$(RecordContent, 26, 4) <> "* KR" Then GoTo NextGremlin
        
        CurrentRecord = Val(Mid$(RecordContent, 30, 4))
        Call FindActionInRecord
        If Action <> "?" Then Exit Sub
        
NextGremlin:
    Next GremlinIndex
End Sub

Private Sub CheckStandardCommands()
    Dim CommandIndex As Integer
    CommandIndex = 0
    
    For CheckIndex = 1 To 25 Step 4
        If Mid$("LOOKINVEFEEDSCOREND ATTAKILL", CheckIndex, 4) = Word1 Then
            CommandIndex = (CheckIndex + 3) / 4
            Exit For
        End If
    Next CheckIndex
    
    Select Case CommandIndex
        Case 1: Call HandleLookCommand
        Case 2: Call HandleInventoryCommand
        Case 3: Call HandleFeedCommand
        Case 4: Call HandleScoreCommand
        Case 5: Call HandleEndCommand
        Case 6: Call HandleAttackCommand
        Case 7: Call HandleKillCommand
        Case Else: Call CheckArtifactCommands
    End Select
End Sub

Private Sub CheckArtifactCommands()
    For ArtifactIndex = 1 To NumArtifacts
        If ArtifactLocation(ArtifactIndex) <> CurrentRoom And ArtifactLocation(ArtifactIndex) <> 0 Then
            GoTo NextArtifact
        End If
        
        CurrentRecord = ArtifactRecord(ArtifactIndex)
        Call GetRecord
        
        If Mid$(RecordContent, 26, 4) = "* KR" Then
            CurrentRecord = Val(Mid$(RecordContent, 30, 4))
            Call FindActionInRecord
            If Action <> "?" Then Call HandleArtifactAction(ArtifactIndex): Exit Sub
        End If
        
        If Mid$(RecordContent, 26, 4) = Word2 Or Mid$(RecordContent, 30, 4) = Word2 Then
            Call HandleSpecificArtifact(ArtifactIndex)
            Exit Sub
        End If
        
NextArtifact:
    Next ArtifactIndex
    
    CurrentRecord = DarkRoom
    Call FindActionInRecord
End Sub

' ----------------------------------------------------------------
' SPECIFIC COMMAND HANDLERS
' ----------------------------------------------------------------
Private Sub HandleLookCommand()
    CurrentRecord = Val(Left$(PlaceRecord, 4))
    Call DisplayMessage
End Sub

Private Sub HandleInventoryCommand()
    Dim ItemList As String
    
    CurrentRecord = 342
    Call DisplayMessage
    
    ItemList = "%1NOTHING%1"
    
    For ArtifactIndex = 1 To NumArtifacts
        If ArtifactLocation(ArtifactIndex) <> 0 Then GoTo NextInventoryItem
        
        TextOutput = "%1A "
        Call ProcessTextOutput
        CurrentRecord = ArtifactRecord(ArtifactIndex)
        Call GetRecord
        Call ProcessDescription
        ItemList = " %1"
        
NextInventoryItem:
    Next ArtifactIndex
    
    TextOutput = ItemList
    Call ProcessTextOutput
End Sub

Private Sub HandleFeedCommand()
    Word1 = "F"
    Call HandleCreatureInteraction
End Sub

Private Sub HandleAttackCommand()
    Word1 = "A"
    Call HandleCreatureInteraction
End Sub

Private Sub HandleKillCommand()
    Word1 = "K"
    Call HandleCreatureInteraction
End Sub

Private Sub HandleCreatureInteraction()
    TargetGremlin = 1
    
    Do
        If GremlinLocation(TargetGremlin) <> CurrentRoom Then GoTo NextTarget
        
        CurrentRecord = GremlinRecord(TargetGremlin)
        Call GetRecord
        
        If Word2 = Mid$(RecordContent, 26, 4) Or Word2 = Mid$(RecordContent, 30, 4) Then
            Exit Do
        End If
        
NextTarget:
        TargetGremlin = TargetGremlin + 1
        If TargetGremlin > NumGremlins Then
            CurrentRecord = 339
            Call DisplayMessage
            Exit Sub
        End If
    Loop
    
    Command = Left$(Word1, 1) & Mid$(CStr(TargetGremlin * 4 / 100) & "0", 3, 2)
    GremlinData = RecordContent
    Call ExecuteAction
End Sub

Private Sub HandleScoreCommand()
    Call FlushOutput
    MsgBox "SCORE: " & Score, vbInformation, "Quest Adventure"
End Sub

Private Sub HandleEndCommand()
    Call FlushOutput
    MsgBox "SCORE: " & Score, vbInformation, "Game Over"
    Close #FileNum
    End
End Sub

' ----------------------------------------------------------------
' ACTION EXECUTION ENGINE
' ----------------------------------------------------------------
Private Sub ExecuteAction()
    Dim ActionType As Integer
    
    ActionType = Val(Left$(Action, 1)) + 1
    
    Select Case ActionType
        Case 1: Exit Sub
        Case 2: Call ExecuteMessageAction
        Case 3: Call ExecuteMoveAction
        Case 4: Call ExecuteComplexAction
        Case 5: Call ExecuteCarryAction
        Case 6: Call ExecuteDropAction
        Case 7: Call ExecutePlayerAction
        Case 8: Call ExecuteStateAction
        Case 9: Call ExecuteDestroyAction
        Case 10: Call ExecuteComplexAction
    End Select
    
    If SecondaryAction <> "0" Then
        Action = SecondaryAction
        SecondaryAction = "0"
        Call ExecuteAction
    End If
End Sub

Private Sub ExecuteMessageAction()
    Dim MessageNumber As String
    MessageNumber = Right$(Action, 4)
    
    If Left$(MessageNumber, 2) = "??" Then
        Call ProcessDynamicMessage
    Else
        CurrentRecord = Val(MessageNumber)
        Call DisplayMessage
    End If
End Sub

Private Sub ExecuteMoveAction()
    NewPlace = Val(Right$(Action, 4))
    CurrentRecord = NewPlace
    Call GetRecord
    
    If Right$(RecordContent, 1) < "6" Then
        Call ProcessMovement
        Exit Sub
    End If
    
    If Right$(RecordContent, 1) > "6" Then
        Call ProcessComplexMovement
        Exit Sub
    End If
    
    Call ProcessConditionalMovement
End Sub

Private Sub ExecuteCarryAction()
    SecondaryAction = SecondaryAction
    SecondaryAction = "0"
    Call ExecuteAction
End Sub

Private Sub ExecuteDropAction()
    If Mid$(Action, 3, 1) = "1" Then
        If ArtifactLocation(FoundTarget) = 0 Then
            CarryCount = CarryCount - 1
        End If
        Call PlaceArtifact(FoundTarget)
        CurrentRecord = 346
        Call DisplayMessage
    End If
    
    Action = SecondaryAction
    SecondaryAction = "0"
    If Action <> "0" Then Call ExecuteAction
End Sub

Private Sub ExecutePlayerAction()
    Select Case Val(Left$(Action, 1))
        Case 4: Call HandlePlayerDeath
        Case 5: Call HandlePlayerStateChange
        Case 6: Call HandlePlayerMovement
        Case 7: Call HandlePlayerCommand
        Case 8: Call HandlePlayerStateToggle
    End Select
End Sub

Private Sub ExecuteStateAction()
    Dim CurrentState As Integer
    
    CurrentRecord = Val(Right$(Action, 4))
    Call GetRecord
    
    CurrentState = Val(Mid$(RecordContent, 9, 1))
    
    If CurrentState = 1 Then
        Mid$(RecordContent, 9, 1) = "2"
    Else
        Mid$(RecordContent, 9, 1) = "1"
    End If
    
    Call SaveRecord
    
    CurrentRecord = Val(Mid$(RecordContent, 14 + 4 * Val(Mid$(RecordContent, 9, 1)), 4))
    Call DisplayMessage
    
    Action = SecondaryAction
    SecondaryAction = "0"
    If Action <> "0" Then Call ExecuteAction
End Sub

Private Sub ExecuteDestroyAction()
    If Left$(Action, 1) = "9" Then
        Call DestroyObject
    Else
        TextOutput = "A "
        Call ProcessTextOutput
        Call ProcessArtifactDescription
        Call ProcessDescription
        CurrentRecord = 348
        Call DisplayMessage
        Call DestroyObject
    End If
    
    Action = SecondaryAction
    SecondaryAction = "0"
    If Action <> "0" Then Call ExecuteAction
End Sub

Private Sub ExecuteComplexAction()
    Dim OperationType As String
    Dim FlagType As Integer
    Dim TargetIndex As Integer
    
    FlagType = Val(Mid$(Action, 2, 1))
    OperationType = Mid$(Action, 3, 1)
    
    If Right$(Action, 2) = "??" Then
        Mid$(Action, 4, 2) = CommandArgs
    End If
    
    If OperationType = "0" Then
        CurrentRecord = CurrentRoom
        Call ProcessTargetAction
        Exit Sub
    End If
    
    TargetIndex = Val(Right$(Action, 2))
    
    If TargetIndex > 0 Then
        Call ProcessSpecificTarget(TargetIndex, OperationType)
        Exit Sub
    End If
    
    If FlagType = 3 Then
        Call ProcessRandomTarget(OperationType)
        Exit Sub
    End If
    
    Call ProcessAllTargets(OperationType, FlagType)
End Sub

' ----------------------------------------------------------------
' CONDITION AND STATE MANAGEMENT
' ----------------------------------------------------------------
Private Sub ProcessConditionalMovement()
    Dim ConditionType As Integer
    ConditionType = Val(Mid$(RecordContent, 19, 1))
    
    Select Case ConditionType
        Case 1, 2: Call CheckPlayerState
        Case 3: Call ProcessSuccessfulCondition
        Case 4: Call ProcessFailedCondition
        Case 5: Call ProcessBothConditions
    End Select
End Sub

Private Sub CheckPlayerState()
    Dim RequiredState As Integer
    RequiredState = Val(Mid$(RecordContent, 19, 1))
    
    If RequiredState <> PlayerState Then
        Call ProcessFailedCondition
    Else
        Call ProcessMandatoryItems
    End If
End Sub

Private Sub ProcessMandatoryItems()
    Dim ItemNumber As String
    
    ListOffset = 0
    
    Do
        ItemNumber = Mid$(RecordContent, ListOffset + 20, 2)
        Call ParseItemNumber(ItemNumber)
        
        If ParsedNumber < 0 Then
            If GremlinLocation(-ParsedNumber) <> CurrentRoom Then
                Call ProcessFailedCondition
                Exit Sub
            End If
        ElseIf ParsedNumber > 0 Then
            If ArtifactLocation(ParsedNumber) <> 0 Then
                Call ProcessFailedCondition
                Exit Sub
            End If
        End If
        
        ItemNumber = Mid$(RecordContent, ListOffset + 32, 2)
        Call ParseItemNumber(ItemNumber)
        
        If ParsedNumber < 0 Then
            If GremlinLocation(ParsedNumber) = CurrentRoom Then
                Call ProcessFailedCondition
                Exit Sub
            End If
        ElseIf ParsedNumber > 0 Then
            If ArtifactLocation(ParsedNumber) = 0 Then
                Call ProcessFailedCondition
                Exit Sub
            End If
        End If
        
        ListOffset = ListOffset + 2
    Loop While ListOffset < 10
    
    Call CheckAdditionalConditions
End Sub

Private Sub CheckAdditionalConditions()
    Dim SavedRecord As String
    Dim RequiredState As String
    
    SavedRecord = RecordContent
    
    CurrentRecord = Val(Mid$(RecordContent, 44, 4))
    If CurrentRecord = 0 Then
        Call ProcessSuccessfulCondition
        Exit Sub
    End If
    
    Call GetRecord
    RequiredState = Mid$(RecordContent, 9, 1)
    RecordContent = SavedRecord
    
    If Mid$(RecordContent, 48, 1) <> RequiredState Then
        Call ProcessFailedCondition
        Exit Sub
    End If
    
    If Val(Mid$(RecordContent, 49, 1)) > Rnd * 10 Then
        Call ProcessFailedCondition
    Else
        Call ProcessSuccessfulCondition
    End If
End Sub

Private Sub ProcessSuccessfulCondition()
    CurrentRecord = Val(Mid$(RecordContent, 11, 4))
    Action = Left$(RecordContent, 5)
    Call DisplayMessage
    Call ExecuteAction
End Sub

Private Sub ProcessFailedCondition()
    CurrentRecord = Val(Mid$(RecordContent, 15, 4))
    Action = Mid$(RecordContent, 6, 5)
    Call DisplayMessage
    Call ExecuteAction
End Sub

Private Sub ProcessBothConditions()
    SecondaryAction = Mid$(RecordContent, 6, 5)
    Call ProcessSuccessfulCondition
End Sub

' ----------------------------------------------------------------
' UTILITY FUNCTIONS FOR ACTION PROCESSING
' ----------------------------------------------------------------
Private Sub ParseItemNumber(ItemString As String)
    ParsedNumber = Val(ItemString)
    
    If Right$(ItemString, 1) <> "P" Then Exit Sub
    
    ParsedNumber = 0 - 10 * ParsedNumber - (Asc(Right$(ItemString, 1)) And &HF)
End Sub

Private Sub FindActionInRecord()
    Call GetRecord
    
    SearchIndex = 34
    
    Do
        If Mid$(RecordContent, SearchIndex, 1) = "E" Then Exit Sub
        
        If Mid$(RecordContent, SearchIndex, 3) = Command Then
            Action = Mid$(RecordContent, SearchIndex + 3, 5)
            Exit Sub
        End If
        
        If Mid$(RecordContent, SearchIndex + 1, 2) = "??" And Mid$(RecordContent, SearchIndex, 1) = Left$(Command, 1) Then
            CommandArgs = Right$(Command, 2)
            Action = Mid$(RecordContent, SearchIndex + 3, 5)
            Exit Sub
        End If
        
        SearchIndex = SearchIndex + 8
    Loop While SearchIndex < 90
End Sub

Private Sub ProcessDescription()
    Dim StateValue As Integer
    StateValue = Val(Mid$(RecordContent, 9, 1))
    CurrentRecord = Val(Mid$(RecordContent, 6 + 4 * StateValue, 4))
    Call DisplayMessage
End Sub

Private Sub ProcessDynamicMessage()
    If Mid$(Right$(Action, 4), 4, 1) = "0" Then
        CurrentRecord = GremlinRecord(Val(CommandArgs))
    Else
        CurrentRecord = ArtifactRecord(Val(CommandArgs))
    End If
    
    Call GetRecord
    Call ProcessArtifactDescription
    TextOutput = "The "
    Call ProcessTextOutput
End Sub

Private Sub ProcessArtifactDescription()
    CurrentRecord = Val(Mid$(RecordContent, 6 + 4 * Val(Mid$(RecordContent, 9, 1)), 4))
End Sub

' ----------------------------------------------------------------
' ARTIFACT MANIPULATION COMMANDS
' ----------------------------------------------------------------
Private Sub HandleArtifactAction(ArtIndex As Integer)
    If Word1 = "CARR" Then
        Call HandleCarryArtifact(ArtIndex)
    ElseIf Word1 = "DROP" Then
        Call HandleDropArtifact(ArtIndex)
    ElseIf Word1 = "THRO" Then
        Call HandleThrowArtifact(ArtIndex)
    Else
        Call HandleUseArtifact(ArtIndex)
    End If
End Sub

Private Sub HandleSpecificArtifact(ArtIndex As Integer)
    If Word1 = "CARR" Then
        Call HandleCarryArtifact(ArtIndex)
        Exit Sub
    End If
    
    If Word1 = "DROP" Or Word1 = "THRO" Then
        If ArtifactLocation(ArtIndex) <> 0 Then
            CurrentRecord = 339
            Call DisplayMessage
            Exit Sub
        End If
        
        CarryCount = CarryCount - 1
        Call PlaceArtifact(ArtIndex)
        
        If Word1 = "DROP" Then
            Exit Sub
        Else
            Command = "4"
            Call HandleUseArtifact(ArtIndex)
        End If
        
        Exit Sub
    End If
    
    Call HandleUseArtifact(ArtIndex)
End Sub

Private Sub HandleCarryArtifact(ArtIndex As Integer)
    Dim StateValue As Integer
    
    CurrentRecord = ArtifactRecord(ArtIndex)
    Call GetRecord
    
    StateValue = Val(Mid$(RecordContent, 9, 1))
    NewPlace = Val(Mid$(RecordContent, 86, 4))
    
    If NewPlace <> 0 Then
        CurrentRecord = NewPlace
        Call GetRecord
        Call ExecuteAction
        Exit Sub
    End If
    
    If CarryCount >= 6 Then
        CurrentRecord = 340
        Call DisplayMessage
        Exit Sub
    End If
    
    CarryCount = CarryCount + 1
    ArtifactLocation(ArtIndex) = 0
    Call ExecuteCarryAction
End Sub

Private Sub HandleDropArtifact(ArtIndex As Integer)
    If ArtifactLocation(ArtIndex) <> 0 Then
        CurrentRecord = 339
        Call DisplayMessage
        Exit Sub
    End If
    
    CarryCount = CarryCount - 1
    Call PlaceArtifact(ArtIndex)
End Sub

Private Sub HandleThrowArtifact(ArtIndex As Integer)
    Call HandleDropArtifact(ArtIndex)
    Command = "4"
    Call HandleUseArtifact(ArtIndex)
End Sub

Private Sub HandleUseArtifact(ArtIndex As Integer)
    CurrentRecord = ArtifactRecord(ArtIndex)
    Call GetRecord
    
    For ActionIndex = 67 To 75 Step 4
        If Word1 = Mid$(RecordContent, ActionIndex, 4) Then
            Command = Right$(CStr((ActionIndex - 63) / 4), 1)
            Exit For
        End If
    Next ActionIndex
    
    If Command = "X" Then
        CurrentRecord = 338
        Call DisplayMessage
        Exit Sub
    End If
    
    Command = Command & Mid$(CStr(ArtIndex / 100) & "0", 3, 2)
    Call ExecuteAction
End Sub

' ----------------------------------------------------------------
' COMPLEX ACTION PROCESSING
' ----------------------------------------------------------------
Private Sub ProcessSpecificTarget(TargetIndex As Integer, OperationType As String)
    If OperationType = "1" Then
        CurrentRecord = ArtifactRecord(TargetIndex)
    Else
        CurrentRecord = GremlinRecord(TargetIndex)
    End If
    
    Call ProcessTargetAction
End Sub

Private Sub ProcessAllTargets(OperationType As String, FlagType As Integer)
    FoundTarget = 0
    
    If OperationType = "1" Then
        For ArtifactIndex = 1 To NumArtifacts
            If ArtifactLocation(ArtifactIndex) = 0 Or ArtifactLocation(ArtifactIndex) = CurrentRoom Then
                Call CheckTargetEligibility(ArtifactIndex)
                If FoundTarget > 0 Then
                    CurrentRecord = ArtifactRecord(FoundTarget)
                    Call ProcessTargetAction
                    Exit Sub
                End If
            End If
        Next ArtifactIndex
    Else
        For GremlinIndex = 1 To NumGremlins
            If GremlinLocation(GremlinIndex) = CurrentRoom Then
                Call CheckTargetEligibility(GremlinIndex)
                If FoundTarget > 0 Then
                    CurrentRecord = GremlinRecord(FoundTarget)
                    Call ProcessTargetAction
                    Exit Sub
                End If
            End If
        Next GremlinIndex
    End If
    
    CurrentRecord = 344
    Call DisplayMessage
End Sub

Private Sub ProcessRandomTarget(OperationType As String)
    Dim RandomIndex As Integer
    
    If OperationType = "1" Then
        Do
            RandomIndex = Int(Rnd * NumArtifacts) + 1
            If ArtifactLocation(RandomIndex) = 0 Or ArtifactLocation(RandomIndex) = CurrentRoom Then
                Exit Do
            End If
        Loop
        
        CurrentRecord = ArtifactRecord(RandomIndex)
        Call GetRecord
        
        If Mid$(RecordContent, 99, 1) = "1" Then
            CurrentRecord = 344
            Call DisplayMessage
            Exit Sub
        End If
    Else
        Do
            RandomIndex = Int(Rnd * NumGremlins) + 1
            If GremlinLocation(RandomIndex) = CurrentRoom Then
                Exit Do
            End If
        Loop
        
        CurrentRecord = GremlinRecord(RandomIndex)
    End If
    
    Call ProcessTargetAction
End Sub

Private Sub CheckTargetEligibility(Index As Integer)
    If FoundTarget = 0 Then
        If Rnd * 10 > 2 Then Exit Sub
    End If
    FoundTarget = Index
End Sub

Private Sub ProcessTargetAction()
    Dim ActionFlag As Integer
    
    Call GetRecord
    
    ActionFlag = Val(Left$(Action, 1)) - 3
    
    Select Case ActionFlag
        Case 0: Call ProcessStateChange
        Case 1: Call ProcessLocationChange
        Case 2: Call ProcessLocationChange
        Case 3: Call ProcessDestroy
        Case 4: Call ExecuteCarryAction
        Case 5: Call ExecuteDropAction
    End Select
End Sub

Private Sub ProcessStateChange()
    Dim CurrentState As Integer
    
    CurrentState = Val(Mid$(RecordContent, 9, 1))
    
    If CurrentState = 1 Then
        Mid$(RecordContent, 9, 1) = "2"
    Else
        Mid$(RecordContent, 9, 1) = "1"
    End If
    
    Call SaveRecord
    
    If Mid$(Action, 3, 1) = "0" Then
        PlayerState = Val(Mid$(RecordContent, 9, 1))
        PlaceRecord = RecordContent
    End If
    
    CurrentRecord = Val(Mid$(RecordContent, 14 + 4 * Val(Mid$(RecordContent, 9, 1)), 4))
    Call DisplayMessage
End Sub

Private Sub ProcessLocationChange()
    NewPlace = Val(Mid$(RecordContent, 93, 4))
    
    If NewPlace <> CurrentRoom Then
        NewPlace = WarehouseRoom
        If NewPlace = CurrentRoom Then NewPlace = 9999
    End If
    
    If Mid$(Action, 3, 1) = "1" Then
        If ArtifactLocation(FoundTarget) = 0 Then CarryCount = CarryCount - 1
        ArtifactLocation(FoundTarget) = NewPlace
        CurrentRecord = 346
        Call ProcessObjectMessage
    Else
        GremlinLocation(FoundTarget) = NewPlace
        If Val(Left$(Action, 1)) = 1 Then
            CurrentRecord = 346
            Call ProcessObjectMessage
        Else
            CurrentRecord = 347
            Call ProcessObjectMessage
        End If
    End If
End Sub

Private Sub ProcessDestroy()
    If Left$(Action, 1) = "9" Then
        Call DestroyObject
        Exit Sub
    End If
    
    TextOutput = "A "
    Call ProcessTextOutput
    Call ProcessArtifactDescription
    Call ProcessDescription
    CurrentRecord = 348
    Call DisplayMessage
    Call DestroyObject
End Sub

Private Sub DestroyObject()
    If Mid$(Action, 3, 1) = "1" Then
        If ArtifactLocation(FoundTarget) = 0 Then CarryCount = CarryCount - 1
        Call PlaceArtifact(FoundTarget)
    Else
        GremlinLocation(FoundTarget) = CurrentRoom
    End If
End Sub

' ----------------------------------------------------------------
' PLAYER DEATH AND REVIVAL
' ----------------------------------------------------------------
Private Sub HandlePlayerDeath()
    Dim DeathMessage As String
    
    DeathMessage = Right$(Action, 4)
    CurrentRecord = Val(DeathMessage)
    Call DisplayMessage
    
    CurrentRecord = 345
    Call DisplayMessage
    Call FlushOutput
    
    UserResponse = InputBox("Continue? (Y/N)", "Quest Adventure", "Y")
    UserResponse = UCase$(Left$(UserResponse, 1))
    
    If UserResponse = "N" Then
        Call HandleEndCommand
        Exit Sub
    End If
    
    MoveCount = MoveCount + 10
    
    For ArtifactIndex = 1 To NumArtifacts
        If ArtifactLocation(ArtifactIndex) = 0 Then
            Call PlaceArtifact(ArtifactIndex)
        End If
    Next ArtifactIndex
    
    CarryCount = 0
    CurrentRoom = HomeRoom
    ActionResult = "Y"
End Sub

Private Sub HandlePlayerStateChange()
    PlayerState = 1
    Mid$(PlaceRecord, 9, 1) = "1"
    RecordContent = PlaceRecord
    CurrentRecord = CurrentRoom
    Call SaveRecord
    Call ExecuteMoveAction
End Sub

Private Sub HandlePlayerMovement()
    Dim ScoreChange As String
    
    ScoreChange = Right$(Action, 4)
    Call ParseItemNumber(ScoreChange)
    PenaltyPoints = PenaltyPoints + ParsedNumber
    
    Action = SecondaryAction
    SecondaryAction = "0"
    Call ExecuteAction
End Sub

Private Sub HandlePlayerCommand()
    Command = Mid$(Action, 2, 3)
    Call ProcessCommand
End Sub

Private Sub HandlePlayerStateToggle()
    Dim CurrentState As Integer
    
    CurrentRecord = Val(Right$(Action, 4))
    Call GetRecord
    
    CurrentState = Val(Mid$(RecordContent, 9, 1))
    
    If CurrentState = 1 Then
        Mid$(RecordContent, 9, 1) = "2"
    Else
        Mid$(RecordContent, 9, 1) = "1"
    End If
    
    Call SaveRecord
    
    Action = SecondaryAction
    SecondaryAction = "0"
    Call ExecuteAction
End Sub

' ----------------------------------------------------------------
' COMPLEX MOVEMENT AND MULTI-ACTION PROCESSING
' ----------------------------------------------------------------
Private Sub ProcessComplexMovement()
    Dim SavedRecord As String
    
    SavedRecord = RecordContent
    
    For ProcessIndex = 1 To 86 Step 5
        CurrentRecord = Val(Mid$(SavedRecord, ProcessIndex, 4))
        If CurrentRecord = 0 Then Exit For
        
        Call GetRecord
        Mid$(RecordContent, 9, 1) = Mid$(SavedRecord, ProcessIndex + 4, 1)
        Call SaveRecord
    Next ProcessIndex
    
    Action = Mid$(SavedRecord, 91, 5)
    Call ExecuteAction
End Sub

' ----------------------------------------------------------------
' FILE OPERATIONS AND RECORD MANAGEMENT
' ----------------------------------------------------------------
Private Sub PlaceArtifact(ArtIndex As Integer)
    If Mid$(PlaceRecord, 90, 3) = "***" Then
        ArtifactLocation(ArtIndex) = Val(Mid$(PlaceRecord, 94, 4))
    Else
        ArtifactLocation(ArtIndex) = CurrentRoom
    End If
End Sub

' ----------------------------------------------------------------
' MESSAGE AND TEXT PROCESSING
' ----------------------------------------------------------------
Private Sub ProcessObjectMessage()
    Dim SavedRecord As Integer
    
    If Left$(Action, 1) = "9" Then Exit Sub
    
    SavedRecord = CurrentRecord
    
    TextOutput = "The "
    Call ProcessTextOutput
    Call ProcessArtifactDescription
    Call ProcessDescription
    
    CurrentRecord = SavedRecord
    Call DisplayMessage
End Sub

' ----------------------------------------------------------------
' GAME STATE VALIDATION
' ----------------------------------------------------------------
Private Sub ValidateGameState()
    For ArtifactIndex = 1 To NumArtifacts
        If ArtifactLocation(ArtifactIndex) < -1 Then
            ArtifactLocation(ArtifactIndex) = CurrentRoom
        End If
    Next ArtifactIndex
    
    For GremlinIndex = 1 To NumGremlins
        If GremlinLocation(GremlinIndex) < -9999 Then
            GremlinLocation(GremlinIndex) = 9999
        End If
    Next GremlinIndex
    
    If CarryCount < 0 Then CarryCount = 0
    If CarryCount > NumArtifacts Then CarryCount = NumArtifacts
End Sub