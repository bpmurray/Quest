' ================================================================
' QUEST ADVENTURE GAME - Reorganized and Documented
' ================================================================
' A text-based adventure game with rooms, artifacts, and creatures
' Original spaghetti code converted to structured, readable format
' ================================================================

' ----------------------------------------------------------------
' TYPE DEFINITIONS AND GLOBAL VARIABLES  
' ----------------------------------------------------------------
Type GameRecord
    DataRecord As String * 100
End Type

' File handling variables
Dim GameRec As GameRecord
Dim RecordNumber As Integer

' Game state variables
Dim CurrentRoom As Integer          ' SI% - Current player location
Dim HomeRoom As Integer             ' HO% - Starting/home room  
Dim WarehouseRoom As Integer        ' WR% - Warehouse room
Dim DarkRoom As Integer             ' DK% - Dark room
Dim MoveCount As Integer            ' MV% - Number of moves made
Dim CarryCount As Integer           ' CC% - Items currently carried
Dim PlayerState As Integer          ' PS% - Player's current state
Dim Score As Double                 ' SC - Current game score
Dim PenaltyPoints As Integer        ' PN% - Penalty points
Dim RandomSeed As Integer           ' RN% - Random number seed

' Game arrays
Dim ArtifactLocation(60) As Integer     ' AL% - Where each artifact is located
Dim ArtifactRecord(60) As Integer       ' AR% - Record number for each artifact
Dim GremlinLocation(40) As Integer      ' GL% - Where each gremlin is located  
Dim GremlinRecord(40) As Integer        ' GR% - Record number for each gremlin
Dim GremlinFactor(40) As Integer        ' GF% - Gremlin behavior factor
Dim LocationList(5) As Integer          ' LL% - Location history list
Dim RecentPlaces(5) As Integer          ' RP% - Recently visited places

' Game control variables
Dim NumArtifacts As Integer         ' NA% - Total number of artifacts
Dim NumGremlins As Integer          ' NG% - Total number of gremlins
Dim CurrentRecord As Integer        ' R% - Current record being processed
Dim FlagRecord As Integer           ' FG% - Flag record number
Dim ActionResult As String          ' AR$ - Action result flag
Dim SecondaryAction As String       ' A2$ - Secondary action to execute
Dim RecordContent As String         ' RC$ - Content of current record
Dim PlaceRecord As String           ' PL$ - Current place record
Dim DataBuffer As String            ' ZZ$ - Data buffer for file operations

' Text processing variables
Dim Word1 As String                 ' W1$ - First word of command
Dim Word2 As String                 ' W2$ - Second word of command
Dim Command As String               ' CO$ - Processed command
Dim Action As String                ' AC$ - Current action being processed
Dim OutputBuffer As String          ' OB$ - Text output buffer
Dim TextOutput As String            ' TX$ - Text to output

' ----------------------------------------------------------------
' MAIN PROGRAM INITIALIZATION
' ----------------------------------------------------------------
Main:
    ' Initialize random seed from real-time clock
    Randomize (Peek(64))
    
    Call InitializeGame
    Call LoadGameData
    Call StartGameLoop

End

' ----------------------------------------------------------------
' GAME INITIALIZATION ROUTINES
' ----------------------------------------------------------------
Sub InitializeGame
    ' Open game data file
    Open "QDATA.dat" For Random As #1 Len = Len(GameRec)
    
    ' Initialize game state
    RandomSeed = 1
    CarryCount = 0
    SecondaryAction = "0"
    MoveCount = 100
    PenaltyPoints = 0
    ActionResult = "N"
End Sub

Sub LoadGameData
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

Sub LoadArtifacts
    ' Load artifact locations and records
    CurrentRecord = FlagRecord
    
    Do
        Call GetRecord
        Dim Index As Integer
        Index = Val(Mid$(RecordContent, 91, 2))
        ArtifactLocation(Index) = Val(Mid$(RecordContent, 93, 4))
        ArtifactRecord(Index) = CurrentRecord
        CurrentRecord = Val(Left$(RecordContent, 4))
    Loop While CurrentRecord > 0
End Sub

Sub LoadGremlins  
    ' Load gremlin locations and records
    CurrentRecord = FlagRecord
    
    Do
        Call GetRecord
        Dim Index As Integer
        Index = Val(Mid$(RecordContent, 91, 2))
        GremlinLocation(Index) = Val(Mid$(RecordContent, 93, 4))
        GremlinRecord(Index) = CurrentRecord
        GremlinFactor(Index) = Val(Mid$(RecordContent, 81, 1))
        CurrentRecord = Val(Left$(RecordContent, 4))
    Loop While CurrentRecord > 0
End Sub

' ----------------------------------------------------------------
' MAIN GAME LOOP
' ----------------------------------------------------------------
Sub StartGameLoop
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
        
    Loop
End Sub

' ----------------------------------------------------------------
' MOVEMENT AND LOCATION PROCESSING
' ----------------------------------------------------------------
Sub ProcessMovement
    ActionResult = "Y"
    Dim TempString As String
    Dim FollowString As String
    
    TempString = "The"
    FollowString = "X"
    
    ' Check which gremlins follow the player
    For GremlinIndex = 1 To NumGremlins
        If GremlinLocation(GremlinIndex) <> CurrentRoom Then
            GoTo NextGremlin
        End If
        
        CurrentRecord = GremlinRecord(GremlinIndex)
        Call GetRecord
        
        Dim StateValue As Integer
        StateValue = Val(Mid$(RecordContent, 9, 1))
        
        If Val(Mid$(RecordContent, 80 + 2 * StateValue, 1)) <= Rnd(RandomSeed) * 9 Then
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

Sub ArriveAtLocation
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

' ----------------------------------------------------------------
' COMMAND PROCESSING
' ----------------------------------------------------------------
Sub GetPlayerInput
    Call FlushOutput
    Call CalculateScore
    
    Print Score; "  :";
    Line Input UserInput$
    
    RandomSeed = Len(UserInput$)
    MoveCount = MoveCount + 1
    
    Call ParseCommand(UserInput$)
End Sub

Sub ParseCommand(InputString As String)
    ' Extract first word
    Call ExtractWord(InputString)
    Word1 = ProcessedWord$
    
    If Len(Word1) = 0 Then
        Word1 = "*   "
    Else
        Word1 = Left$(Word1 + "   ", 4)
    End If
    
    ' Extract second word  
    Call ExtractWord(InputString)
    Word2 = ProcessedWord$
    
    If Len(Word2) = 0 Then
        Word2 = "*   "
    Else
        Word2 = Left$(Word2 + "   ", 4)
    End If
    
    ' Convert to uppercase
    Call ConvertToUppercase(Word1)
    Call ConvertToUppercase(Word2)
    
    ' Handle special commands
    If Word1 = "SAVE" And Word2 = "*   " Then Call SaveGame: Exit Sub
    If Word1 = "LOAD" And Word2 = "*   " Then Call LoadGame: Exit Sub
    If Word1 = "ZPQR" Then Call HandleDebugCommand: Exit Sub
End Sub

Sub ProcessCommand
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
Sub CheckMovementCommands
    Dim DirectionString As String
    DirectionString = "NORTSOUTEASTWESTUP  DOWN" + Mid$(PlaceRecord, 26, 8)
    
    For Index = 1 To 29 Step 4
        If Word1 = Mid$(DirectionString, Index, 4) Then
            Command = "C" + Right$(Str$((Index + 3) / 400), 2)
            Exit For
        End If
    Next Index
End Sub

Sub HandleMovement
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
Sub GetRecord
    ' Read record from data file
    RecordNumber = CurrentRecord + 1
    Get #1, RecordNumber, GameRec
    RecordContent = GameRec.DataRecord
End Sub

Sub DisplayMessage
    If CurrentRecord = 0 Then Exit Sub
    
    Call GetRecord
    TextOutput = ParsedText1$
    Call ProcessTextOutput
    
    If TextContinue$ = "1" Then Exit Sub
    
    TextOutput = ParsedText2$  
    Call ProcessTextOutput
    
    If TextContinue$ = "3" Then
        CurrentRecord = CurrentRecord + 1
        Call DisplayMessage
    End If
End Sub

Sub CalculateScore
    Score = 0
    
    For GremlinIndex = 1 To NumArtifacts
        If ArtifactLocation(GremlinIndex) <> HomeRoom Then GoTo NextArtifact
        
        CurrentRecord = ArtifactRecord(GremlinIndex)
        Call GetRecord
        
        Dim StateValue As Integer
        StateValue = Val(Mid$(RecordContent, 9, 1))
        
        If Mid$(RecordContent, 80 + StateValue + StateValue, 1) = "2" Then
            Score = Score + Val(Mid$(RecordContent, 79, 3))
        End If
        
        NextArtifact:
    Next GremlinIndex
    
    Score = Int(1000 * (10 * Score - PenaltyPoints) / MoveCount) / 100
End Sub

' ----------------------------------------------------------------
' SAVE/LOAD FUNCTIONALITY
' ----------------------------------------------------------------
Sub SaveGame
    Print "FILE NAME PLEASE  :";
    Input UserFileName$
    
    Open UserFileName$ For Output As #3
    Print #3, CurrentRoom, Score, MoveCount, PenaltyPoints, CarryCount, RandomSeed
    
    For Index = 1 To 60
        Print #3, ArtifactLocation(Index), ArtifactRecord(Index)
    Next Index
    
    For Index = 1 To 40
        Print #3, GremlinLocation(Index), GremlinRecord(Index), GremlinFactor(Index)
    Next Index
    
    For Index = 1 To 5
        Print #3, LocationList(Index), RecentPlaces(Index)
    Next Index
    
    Close #3
    GoTo GameLoop
End Sub

Sub LoadGame
    Print "FILE NAME PLEASE  :";
    Input UserFileName$
    
    Open UserFileName$ For Input As #3
    Input #3, CurrentRoom, Score, MoveCount, PenaltyPoints, CarryCount, RandomSeed
    
    For Index = 1 To 60
        Input #3, ArtifactLocation(Index), ArtifactRecord(Index)
    Next Index
    
    For Index = 1 To 40
        Input #3, GremlinLocation(Index), GremlinRecord(Index), GremlinFactor(Index)
    Next Index
    
    For Index = 1 To 5
        Input #3, LocationList(Index), RecentPlaces(Index)
    Next Index
    
    Close #3
    GoTo GameLoop
End Sub

' ----------------------------------------------------------------
' TEXT PROCESSING UTILITIES
' ----------------------------------------------------------------
Sub ExtractWord(ByRef InputString As String)
    ' Remove leading spaces
    Do While Left$(InputString, 1) = " "
        InputString = Right$(InputString, Len(InputString) - 1)
    Loop
    
    ' Find next space
    Dim SpacePosition As Integer
    SpacePosition = InStr(InputString, " ")
    If SpacePosition = 0 Then SpacePosition = Len(InputString) + 1
    
    ' Extract word
    ProcessedWord$ = Left$(InputString, SpacePosition - 1)
    InputString = Right$(InputString, Len(InputString) - SpacePosition + 1)
End Sub

Sub ConvertToUppercase(ByRef WordString As String)
    For Index = 1 To 4
        If Mid$(WordString, Index, 1) > "@" Then
            Mid$(WordString, Index, 1) = Chr$(Asc(Mid$(WordString, Index, 1)) And &H5F)
        End If
    Next Index
End Sub

Sub ProcessTextOutput
    ' Handle text formatting and output
    If Right$(TextOutput, 1) <> " " Then GoTo ProcessSpecialChars
    If Right$(TextOutput, 2) = ". " Then GoTo AddToBuffer
    
    TextOutput = Left$(TextOutput, Len(TextOutput) - 1)
    If Len(TextOutput) = 0 Then Exit Sub
    GoTo ProcessTextOutput
    
    ProcessSpecialChars:
    If Right$(TextOutput, 1) = "." Then TextOutput = TextOutput + " "
    
    AddToBuffer:
    Dim PercentPos As Integer
    PercentPos = InStr(TextOutput, "%")
    If PercentPos = 0 Then PercentPos = Len(TextOutput) + 1
    
    OutputBuffer = OutputBuffer + Left$(TextOutput, PercentPos - 1) + " "
    
    If Len(OutputBuffer) > 70 Then Call WrapText
    If PercentPos > Len(TextOutput) Then Exit Sub
    
    ' Process special formatting codes
    Select Case Val(Mid$(TextOutput, PercentPos + 1, 1))
        Case 1: Call FlushOutput
        Case 2: OutputBuffer = OutputBuffer + "%"
        Case 3: OutputBuffer = Left$(OutputBuffer, Len(OutputBuffer) - 1)
        Case 4: If Len(OutputBuffer) >= 4 Then OutputBuffer = Left$(OutputBuffer, Len(OutputBuffer) - 4) + " "
    End Select
    
    TextOutput = Right$(TextOutput, Len(TextOutput) - PercentPos - 1)
    If Len(TextOutput) > 0 Then GoTo AddToBuffer
End Sub

Sub WrapText
    Dim WrapPos As Integer
    WrapPos = InStr(60, OutputBuffer, " ")
    If WrapPos = 0 Then WrapPos = Len(OutputBuffer)
    
    Print Left$(OutputBuffer, WrapPos)
    OutputBuffer = Right$(OutputBuffer, Len(OutputBuffer) - WrapPos)
    
    ' Remove leading space
    Do While Left$(OutputBuffer, 1) = " "
        OutputBuffer = Right$(OutputBuffer, Len(OutputBuffer) - 1)
    Loop
End Sub

Sub FlushOutput
    If Len(OutputBuffer) > 0 Then Call WrapText
    If Len(OutputBuffer) > 0 Then Print OutputBuffer: OutputBuffer = ""
End Sub

' ----------------------------------------------------------------
' DEBUG AND UTILITY COMMANDS
' ----------------------------------------------------------------
Sub HandleDebugCommand
    If Word2 = "ARTI" Then
        ' Give all artifacts to player
        For GremlinIndex = 1 To NumArtifacts
            ArtifactLocation(GremlinIndex) = 0
        Next GremlinIndex
        CarryCount = NumArtifacts
    ElseIf Word2 = "GREM" Then
        ' Remove all gremlins
        For GremlinIndex = 1 To NumGremlins
            GremlinLocation(GremlinIndex) = 9999
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
Sub ProcessGremlins
    ' Handle gremlin movement and behavior when player isn't moving
    Dim TargetGremlin As Integer
    TargetGremlin = 0
    
    ' Check each gremlin for potential actions
    For GremlinIndex = 1 To NumGremlins
        If GremlinLocation(GremlinIndex) <> CurrentRoom Then GoTo NextGremlin
        
        ' Increment gremlin's action factor
        GremlinFactor(GremlinIndex) = GremlinFactor(GremlinIndex) + 1
        
        ' Check if gremlin should act (random chance based on factor)
        If Rnd(RandomSeed) * 10 <= GremlinFactor(GremlinIndex) Then
            TargetGremlin = GremlinIndex
            GremlinFactor(GremlinIndex) = 9  ' Reset to high value
        End If
        
        NextGremlin:
    Next GremlinIndex
    
    If TargetGremlin = 0 Then Exit Sub
    
    ' Process the acting gremlin
    Call ProcessGremlinAction(TargetGremlin)
End Sub

Sub ProcessGremlinAction(GremlinIndex As Integer)
    CurrentRecord = GremlinRecord(GremlinIndex)
    Call GetRecord
    
    ' Reset gremlin's action factor from record
    GremlinFactor(GremlinIndex) = Val(Mid$(RecordContent, 86, 1))
    
    Dim StateValue As Integer
    StateValue = Val(Mid$(RecordContent, 9, 1))
    
    ' Get gremlin's next action record
    CurrentRecord = Val(Mid$(RecordContent, 87, 4))
    If CurrentRecord = 0 Then Exit Sub
    
    ' Check if gremlin's action succeeds (probability check)
    Dim SuccessChance As Integer
    SuccessChance = Val(Mid$(RecordContent, 81 + 2 * StateValue, 1))
    
    Call GetRecord
    ActionResult = "Y"
    
    If Rnd(RandomSeed) * 9 < SuccessChance Then
        Call ProcessSuccessfulCondition
    Else
        Call ProcessFailedCondition
    End If
End Sub

Sub CheckGremlinAttacks
    ' Check if any gremlins at current location should attack
    Dim OptimalMove As Integer
    OptimalMove = 9999
    
    ' Process gremlins at current location
    For GremlinIndex = 1 To NumGremlins
        If GremlinLocation(GremlinIndex) = CurrentRoom Then
            CurrentRecord = GremlinRecord(GremlinIndex)
            Call ProcessObjectInteraction
        End If
        
        ' Handle gremlins that were following (negative location)
        If GremlinLocation(GremlinIndex) = -CurrentRoom Then
            GremlinLocation(GremlinIndex) = CurrentRoom
        End If
    Next GremlinIndex
End Sub

' ----------------------------------------------------------------
' OBJECT AND LOCATION PROCESSING
' ----------------------------------------------------------------
Sub ProcessArtifactsAtLocation
    ' Handle all artifacts present at current location
    Dim OptimalMove As Integer
    OptimalMove = 9999
    
    For ArtifactIndex = 1 To NumArtifacts
        If ArtifactLocation(ArtifactIndex) = CurrentRoom Or ArtifactLocation(ArtifactIndex) = 0 Then
            CurrentRecord = ArtifactRecord(ArtifactIndex)
            Call ProcessObjectInteraction
        End If
    Next ArtifactIndex
End Sub

Sub ProcessGremlinsAtLocation
    ' Handle all gremlins present at current location
    For GremlinIndex = 1 To NumGremlins
        If GremlinLocation(GremlinIndex) = CurrentRoom Then
            CurrentRecord = GremlinRecord(GremlinIndex)
            Call ProcessObjectInteraction
        End If
    Next GremlinIndex
End Sub

Sub ProcessObjectInteraction
    Call GetRecord
    Dim NameRecord As Integer
    NameRecord = Val(Mid$(RecordContent, 6 + 4 * Val(Mid$(RecordContent, 9, 1)), 4))
    
    ' Get description record
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

' ----------------------------------------------------------------
' COMMAND PROCESSING IMPLEMENTATIONS
' ----------------------------------------------------------------
Sub CheckKeywordInteractions
    ' Check if command matches location keywords
    If Mid$(PlaceRecord, 26, 4) <> "* KR" Then GoTo CheckGremlins
    
    CurrentRecord = Val(Mid$(PlaceRecord, 30, 4))
    Call FindActionInRecord
    If Action <> "?" Then Exit Sub
    
    CheckGremlins:
    ' Check gremlin keywords
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

Sub CheckStandardCommands
    ' Check for standard game commands
    Dim CommandIndex As Integer
    CommandIndex = 0
    
    ' Check against standard command list
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

Sub CheckArtifactCommands
    ' Check if command applies to any artifacts
    For ArtifactIndex = 1 To NumArtifacts
        If ArtifactLocation(ArtifactIndex) <> CurrentRoom And ArtifactLocation(ArtifactIndex) <> 0 Then
            GoTo NextArtifact
        End If
        
        CurrentRecord = ArtifactRecord(ArtifactIndex)
        Call GetRecord
        
        ' Check for keyword match
        If Mid$(RecordContent, 26, 4) = "* KR" Then
            CurrentRecord = Val(Mid$(RecordContent, 30, 4))
            Call FindActionInRecord
            If Action <> "?" Then Call HandleArtifactAction(ArtifactIndex): Exit Sub
        End If
        
        ' Check for direct name match
        If Mid$(RecordContent, 26, 4) = Word2 Or Mid$(RecordContent, 30, 4) = Word2 Then
            Call HandleSpecificArtifact(ArtifactIndex)
            Exit Sub
        End If
        
        NextArtifact:
    Next ArtifactIndex
    
    ' If no artifact found, try default action
    CurrentRecord = DarkRoom
    Call FindActionInRecord
End Sub

' ----------------------------------------------------------------
' SPECIFIC COMMAND HANDLERS
' ----------------------------------------------------------------
Sub HandleLookCommand
    CurrentRecord = Val(Left$(PlaceRecord, 4))
    Call DisplayMessage
    ' Return to location processing
End Sub

Sub HandleInventoryCommand
    CurrentRecord = 342
    Call DisplayMessage
    
    Dim ItemList As String
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

Sub HandleFeedCommand
    Word1 = "F"
    Call HandleCreatureInteraction
End Sub

Sub HandleAttackCommand
    Word1 = "A"
    Call HandleCreatureInteraction  
End Sub

Sub HandleKillCommand
    Word1 = "K"
    Call HandleCreatureInteraction
End Sub

Sub HandleCreatureInteraction
    Dim TargetGremlin As Integer
    TargetGremlin = 1
    
    ' Find matching gremlin
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
    
    ' Process interaction with found gremlin
    Command = Left$(Word1, 1) + Mid$(Str$(TargetGremlin * 4 / 100) + "0", 3, 2)
    Dim GremlinData As String
    GremlinData = RecordContent
    
    Call ExecuteAction
End Sub

Sub HandleScoreCommand
    Call FlushOutput
    Print "SCORE:"; Score
End Sub

Sub HandleEndCommand
    Call FlushOutput
    Print "SCORE:"; Score
    End
End Sub

' ----------------------------------------------------------------
' ACTION EXECUTION ENGINE
' ----------------------------------------------------------------
Sub ExecuteAction
    Dim ActionType As Integer
    Dim ActionData As String
    
    ActionType = Val(Left$(Action, 1)) + 1
    
    Select Case ActionType
        Case 1: Exit Sub  ' No action
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
    
    ' Execute any secondary action
    If SecondaryAction <> "0" Then
        Action = SecondaryAction
        SecondaryAction = "0"
        Call ExecuteAction
    End If
End Sub

Sub ExecuteMessageAction
    Dim MessageNumber As String
    MessageNumber = Right$(Action, 4)
    
    If Left$(MessageNumber, 2) = "??" Then
        Call ProcessDynamicMessage
    Else
        CurrentRecord = Val(MessageNumber)
        Call DisplayMessage
    End If
End Sub

Sub ExecuteMoveAction
    NewPlace = Val(Right$(Action, 4))
    CurrentRecord = NewPlace
    Call GetRecord
    
    ' Check movement conditions
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

' ----------------------------------------------------------------
' CONDITION AND STATE MANAGEMENT
' ----------------------------------------------------------------
Sub ProcessConditionalMovement
    Dim ConditionType As Integer
    ConditionType = Val(Mid$(RecordContent, 19, 1))
    
    Select Case ConditionType
        Case 1, 2: Call CheckPlayerState
        Case 3: Call ProcessSuccessfulCondition
        Case 4: Call ProcessFailedCondition  
        Case 5: Call ProcessBothConditions
    End Select
End Sub

Sub CheckPlayerState
    Dim RequiredState As Integer
    RequiredState = Val(Mid$(RecordContent, 19, 1))
    
    If RequiredState <> PlayerState Then
        Call ProcessFailedCondition
    Else
        Call ProcessMandatoryItems
    End If
End Sub

Sub ProcessMandatoryItems
    ' Check mandatory and forbidden item lists
    Dim ListOffset As Integer
    ListOffset = 0
    
    Do
        ' Check mandatory items
        Dim ItemNumber As String
        ItemNumber = Mid$(RecordContent, ListOffset + 20, 2)
        Call ParseItemNumber(ItemNumber)
        
        If ParsedNumber < 0 Then
            ' Check for gremlin presence
            If GremlinLocation(-ParsedNumber) <> CurrentRoom Then
                Call ProcessFailedCondition
                Exit Sub
            End If
        ElseIf ParsedNumber > 0 Then
            ' Check for artifact possession
            If ArtifactLocation(ParsedNumber) <> 0 Then
                Call ProcessFailedCondition  
                Exit Sub
            End If
        End If
        
        ' Check forbidden items
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

Sub CheckAdditionalConditions
    ' Check for additional state conditions
    Dim SavedRecord As String
    SavedRecord = RecordContent
    
    CurrentRecord = Val(Mid$(RecordContent, 44, 4))
    If CurrentRecord = 0 Then
        Call ProcessSuccessfulCondition
        Exit Sub
    End If
    
    Call GetRecord
    Dim RequiredState As String
    RequiredState = Mid$(RecordContent, 9, 1)
    RecordContent = SavedRecord
    
    If Mid$(RecordContent, 48, 1) <> RequiredState Then
        Call ProcessFailedCondition
        Exit Sub
    End If
    
    ' Random chance check
    If Val(Mid$(RecordContent, 49, 1)) > Rnd(RandomSeed) * 10 Then
        Call ProcessFailedCondition
    Else
        Call ProcessSuccessfulCondition
    End If
End Sub

Sub ProcessSuccessfulCondition
    CurrentRecord = Val(Mid$(RecordContent, 11, 4))
    Action = Left$(RecordContent, 5)
    Call DisplayMessage
    Call ExecuteAction
End Sub

Sub ProcessFailedCondition  
    CurrentRecord = Val(Mid$(RecordContent, 15, 4))
    Action = Mid$(RecordContent, 6, 5)
    Call DisplayMessage
    Call ExecuteAction
End Sub

Sub ProcessBothConditions
    SecondaryAction = Mid$(RecordContent, 6, 5)
    Call ProcessSuccessfulCondition
End Sub

' ----------------------------------------------------------------
' UTILITY FUNCTIONS FOR ACTION PROCESSING
' ----------------------------------------------------------------
Sub ParseItemNumber(ItemString As String)
    ParsedNumber = Val(ItemString)
    
    If Right$(ItemString, 1) <> "P" Then Exit Sub
    
    ' Handle negative number encoding
    ParsedNumber = 0 - 10 * ParsedNumber - (Asc(Right$(ItemString, 1)) And &HF)
End Sub

Sub FindActionInRecord
    Call GetRecord
    Dim SearchIndex As Integer
    SearchIndex = 34
    
    ' Search action table for matching command
    Do
        If Mid$(RecordContent, SearchIndex, 1) = "E" Then Exit Sub
        
        If Mid$(RecordContent, SearchIndex, 3) = Command Then
            Action = Mid$(RecordContent, SearchIndex + 3, 5)
            Exit Sub
        End If
        
        ' Check for wildcard match
        If Mid$(RecordContent, SearchIndex + 1, 2) = "??" And Mid$(RecordContent, SearchIndex, 1) = Left$(Command, 1) Then
            CommandArgs$ = Right$(Command, 2)
            Action = Mid$(RecordContent, SearchIndex + 3, 5)
            Exit Sub
        End If
        
        SearchIndex = SearchIndex + 8
    Loop While SearchIndex < 90
End Sub

Sub ProcessDescription
    Dim StateValue As Integer
    StateValue = Val(Mid$(RecordContent, 9, 1))
    CurrentRecord = Val(Mid$(RecordContent, 6 + 4 * StateValue, 4))
    Call DisplayMessage
End Sub

Sub ProcessDynamicMessage
    If Mid$(Right$(Action, 4), 4, 1) = "0" Then
        CurrentRecord = GremlinRecord(Val(CommandArgs$))
    Else
        CurrentRecord = ArtifactRecord(Val(CommandArgs$))
    End If
    
    Call GetRecord
    Call ProcessArtifactDescription
    TextOutput = "The "
    Call ProcessTextOutput
End Sub

Sub ProcessArtifactDescription
    CurrentRecord = Val(Mid$(RecordContent, 6 + 4 * Val(Mid$(RecordContent, 9, 1)), 4))
End Sub

' ----------------------------------------------------------------
' ARTIFACT MANIPULATION COMMANDS
' ----------------------------------------------------------------
Sub HandleArtifactAction(ArtifactIndex As Integer)
    If Word1 = "CARR" Then
        Call HandleCarryArtifact(ArtifactIndex)
    ElseIf Word1 = "DROP" Then
        Call HandleDropArtifact(ArtifactIndex)
    ElseIf Word1 = "THRO" Then
        Call HandleThrowArtifact(ArtifactIndex)
    Else
        Call HandleUseArtifact(ArtifactIndex)
    End If
End Sub

Sub HandleSpecificArtifact(ArtifactIndex As Integer)
    If Word1 = "CARR" Then
        Call HandleCarryArtifact(ArtifactIndex)
        Exit Sub
    End If
    
    If Word1 = "DROP" Or Word1 = "THRO" Then
        If ArtifactLocation(ArtifactIndex) <> 0 Then
            CurrentRecord = 339
            Call DisplayMessage
            Exit Sub
        End If
        
        CarryCount = CarryCount - 1
        Call PlaceArtifact(ArtifactIndex)
        
        If Word1 = "DROP" Then
            Exit Sub
        Else
            Command = "4"
            Call HandleUseArtifact(ArtifactIndex)
        End If
        
        Exit Sub
    End If
    
    Call HandleUseArtifact(ArtifactIndex)
End Sub

Sub HandleCarryArtifact(ArtifactIndex As Integer)
    CurrentRecord = ArtifactRecord(ArtifactIndex)
    Call GetRecord
    
    Dim StateValue As Integer
    StateValue = Val(Mid$(RecordContent, 9, 1))
    NewPlace = Val(Mid$(RecordContent, 86, 4))
    
    If NewPlace <> 0 Then
        ' Artifact cannot be picked up (special handling)
        CurrentRecord = NewPlace
        Call GetRecord
        Call ExecuteAction
        Exit Sub
    End If
    
    If CarryCount > 6 Then
        CurrentRecord = 340
        Call DisplayMessage
        Exit Sub
    End If
    
    CarryCount = CarryCount + 1
    ArtifactLocation(ArtifactIndex) = 0  ' 0 means carried by player
    Call ExecuteCarryAction
End Sub

Sub HandleDropArtifact(ArtifactIndex As Integer)
    If ArtifactLocation(ArtifactIndex) <> 0 Then
        CurrentRecord = 339
        Call DisplayMessage
        Exit Sub
    End If
    
    CarryCount = CarryCount - 1
    Call PlaceArtifact(ArtifactIndex)
End Sub

Sub HandleThrowArtifact(ArtifactIndex As Integer)
    Call HandleDropArtifact(ArtifactIndex)
    Command = "4"
    Call HandleUseArtifact(ArtifactIndex)
End Sub

Sub HandleUseArtifact(ArtifactIndex As Integer)
    CurrentRecord = ArtifactRecord(ArtifactIndex)
    Call GetRecord
    
    ' Check for action match in artifact's action table
    For ActionIndex = 67 To 75 Step 4
        If Word1 = Mid$(RecordContent, ActionIndex, 4) Then
            Command = Right$(Str$((ActionIndex - 63) / 4), 1)
            Exit For
        End If
    Next ActionIndex
    
    If Command = "X" Then
        ' No matching action found
        CurrentRecord = 338
        Call DisplayMessage
        Exit Sub
    End If
    
    Command = Command + Mid$(Str$(ArtifactIndex / 100) + "0", 3, 2)
    Call ExecuteAction
End Sub

' ----------------------------------------------------------------
' ACTION EXECUTION IMPLEMENTATIONS
' ----------------------------------------------------------------
Sub ExecuteCarryAction
    SecondaryAction = SecondaryAction
    SecondaryAction = "0"
    Call ExecuteAction
End Sub

Sub ExecuteComplexAction
    Dim OperationType As String
    Dim FlagType As Integer
    OperationType = Mid$(Action, 3, 1)
    FlagType = Val(Mid$(Action, 2, 1))
    
    ' Handle wildcard parameters
    If Right$(Action, 2) = "??" Then
        Mid$(Action, 4, 2) = CommandArgs$
    End If
    
    If OperationType = "0" Then
        CurrentRecord = CurrentRoom
        Call ProcessTargetAction
        Exit Sub
    End If
    
    Dim TargetIndex As Integer
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

Sub ProcessSpecificTarget(TargetIndex As Integer, OperationType As String)
    If OperationType = "1" Then
        CurrentRecord = ArtifactRecord(TargetIndex)
    Else
        CurrentRecord = GremlinRecord(TargetIndex)
    End If
    
    Call ProcessTargetAction
End Sub

Sub ProcessAllTargets(OperationType As String, FlagType As Integer)
    Dim FoundTarget As Integer
    FoundTarget = 0
    
    If OperationType = "1" Then
        ' Process artifacts
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
        ' Process gremlins
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
    
    ' No valid target found
    CurrentRecord = 344
    Call DisplayMessage
End Sub

Sub ProcessRandomTarget(OperationType As String)
    Dim RandomIndex As Integer
    
    If OperationType = "1" Then
        ' Random artifact
        Do
            RandomIndex = Int(Rnd(RandomSeed) * NumArtifacts) + 1
            If ArtifactLocation(RandomIndex) = 0 Or ArtifactLocation(RandomIndex) = CurrentRoom Then
                Exit Do
            End If
        Loop
        
        CurrentRecord = ArtifactRecord(RandomIndex)
        Call GetRecord
        
        If Mid$(RecordContent, 99, 1) = "1" Then
            ' This artifact cannot be randomly selected
            CurrentRecord = 344
            Call DisplayMessage
            Exit Sub
        End If
    Else
        ' Random gremlin
        Do
            RandomIndex = Int(Rnd(RandomSeed) * NumGremlins) + 1
            If GremlinLocation(RandomIndex) = CurrentRoom Then
                Exit Do
            End If
        Loop
        
        CurrentRecord = GremlinRecord(RandomIndex)
    End If
    
    Call ProcessTargetAction
End Sub

Sub CheckTargetEligibility(Index As Integer)
    If FoundTarget = 0 Then
        If Rnd(RandomSeed) * 10 > 2 Then Exit Sub
    End If
    FoundTarget = Index
End Sub

Sub ProcessTargetAction
    Call GetRecord
    
    ' Decode the action type
    Dim ActionFlag As Integer
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

Sub ProcessStateChange
    ' Toggle object state
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

Sub ProcessLocationChange
    NewPlace = Val(Mid$(RecordContent, 93, 4))
    
    If NewPlace <> CurrentRoom Then
        NewPlace = WarehouseRoom
        If NewPlace = CurrentRoom Then NewPlace = 9999
    End If
    
    If Mid$(Action, 3, 1) = "1" Then
        ' Moving an artifact
        If ArtifactLocation(FoundTarget) = 0 Then CarryCount = CarryCount - 1
        ArtifactLocation(FoundTarget) = NewPlace
        CurrentRecord = 346
        Call ProcessObjectMessage
    Else
        ' Moving a gremlin
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

Sub ProcessDestroy
    If Left$(Action, 1) = "9" Then
        ' Silent destruction
        Call DestroyObject
        Exit Sub
    End If
    
    ' Destruction with message
    TextOutput = "A "
    Call ProcessTextOutput
    Call ProcessArtifactDescription
    Call ProcessDescription
    CurrentRecord = 348
    Call DisplayMessage
    Call DestroyObject
End Sub

Sub DestroyObject
    If Mid$(Action, 3, 1) = "1" Then
        ' Destroy artifact
        If ArtifactLocation(FoundTarget) = 0 Then CarryCount = CarryCount - 1
        Call PlaceArtifact(FoundTarget)
    Else
        ' Destroy gremlin
        GremlinLocation(FoundTarget) = CurrentRoom
    End If
End Sub

' ----------------------------------------------------------------
' PLAYER DEATH AND REVIVAL
' ----------------------------------------------------------------
Sub ExecutePlayerAction
    If Left$(Action, 1) = "4" Then
        Call HandlePlayerDeath
    ElseIf Left$(Action, 1) = "5" Then
        Call HandlePlayerStateChange
    ElseIf Left$(Action, 1) = "6" Then
        Call HandlePlayerMovement
    ElseIf Left$(Action, 1) = "7" Then
        Call HandlePlayerCommand
    ElseIf Left$(Action, 1) = "8" Then
        Call HandlePlayerStateToggle
    End If
End Sub

Sub HandlePlayerDeath
    Dim DeathMessage As String
    DeathMessage = Right$(Action, 4)
    CurrentRecord = Val(DeathMessage)
    Call DisplayMessage
    
    CurrentRecord = 345
    Call DisplayMessage
    Call FlushOutput
    
    Print ":";
    Line Input UserResponse$
    
    UserResponse$ = Chr$(Asc(Left$(UserResponse$, 1)) And &H5F)
    If UserResponse$ = "N" Then
        Call HandleEndCommand
        Exit Sub
    End If
    
    ' Revive player
    MoveCount = MoveCount + 10
    
    ' Drop all carried items
    For ArtifactIndex = 1 To NumArtifacts
        If ArtifactLocation(ArtifactIndex) = 0 Then
            Call PlaceArtifact(ArtifactIndex)
        End If
    Next ArtifactIndex
    
    CarryCount = 0
    CurrentRoom = HomeRoom
    ActionResult = "Y"
End Sub

Sub HandlePlayerStateChange
    PlayerState = 1
    Mid$(PlaceRecord, 9, 1) = "1"
    RecordContent = PlaceRecord
    CurrentRecord = CurrentRoom
    Call SaveRecord
    Call ExecuteMoveAction
End Sub

Sub HandlePlayerMovement
    Dim ScoreChange As String
    ScoreChange = Right$(Action, 4)
    Call ParseItemNumber(ScoreChange)
    PenaltyPoints = PenaltyPoints + ParsedNumber
    
    ' Continue with secondary action
    Action = SecondaryAction
    SecondaryAction = "0"
    Call ExecuteAction
End Sub

Sub HandlePlayerCommand
    Command = Mid$(Action, 2, 3)
    Call ProcessCommand
End Sub

Sub HandlePlayerStateToggle
    CurrentRecord = Val(Right$(Action, 4))
    Call GetRecord
    
    Dim CurrentState As Integer
    CurrentState = Val(Mid$(RecordContent, 9, 1))
    
    ' Toggle state
    If CurrentState = 1 Then
        Mid$(RecordContent, 9, 1) = "2"
    Else
        Mid$(RecordContent, 9, 1) = "1"
    End If
    
    Call SaveRecord
    
    ' Continue with secondary action
    Action = SecondaryAction
    SecondaryAction = "0"
    Call ExecuteAction
End Sub

' ----------------------------------------------------------------
' COMPLEX MOVEMENT AND MULTI-ACTION PROCESSING
' ----------------------------------------------------------------
Sub ProcessComplexMovement
    ' Handle complex movement with multiple state changes
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
' FEED AND KILL COMMAND PROCESSING
' ----------------------------------------------------------------
Sub ProcessFeedKillCommand
    Dim RequiredItems As String
    Dim MessageNumber As Integer
    
    If Left$(Word1, 1) = "F" Then
        RequiredItems = Mid$(GremlinData, 67, 8)
        MessageNumber = 354
    Else
        RequiredItems = "00" + Mid$(GremlinData, 75, 6)
        MessageNumber = 351
    End If
    
    ' Check if player has required items
    Dim ItemIndex As Integer
    ItemIndex = 1
    
    Do While ItemIndex < 7
        Dim RequiredItem As Integer
        RequiredItem = Val(Mid$(RequiredItems, ItemIndex, 2))
        
        If RequiredItem = 0 Then Exit Do
        
        If ArtifactLocation(RequiredItem) = 0 Then
            ' Player has required item
            Call ProcessSuccessfulFeedKill(RequiredItem, MessageNumber)
            Exit Sub
        End If
        
        ItemIndex = ItemIndex + 2
    Loop
    
    ' Player doesn't have required items
    Call ProcessDescription
    TextOutput = Word2
    Call ProcessTextOutput
    
    If Left$(Word1, 1) = "F" Then
        CurrentRecord = 341
        Call DisplayMessage
    End If
End Sub

Sub ProcessSuccessfulFeedKill(ItemIndex As Integer, MessageNumber As Integer)
    TextOutput = "The " + Word2
    Call ProcessTextOutput
    
    CurrentRecord = MessageNumber + 1
    Call DisplayMessage
    
    CurrentRecord = ArtifactRecord(ItemIndex)
    Call GetRecord
    Call ProcessDescription
    
    If Left$(Word1, 1) = "F" Then
        ' Feed - remove item and reset gremlin
        ArtifactLocation(ItemIndex) = -1
        GremlinFactor(TargetGremlin) = Val(Mid$(GremlinData, 86, 1))
    Else
        ' Kill - remove gremlin
        GremlinLocation(TargetGremlin) = -1
    End If
End Sub

' ----------------------------------------------------------------
' FILE OPERATIONS AND RECORD MANAGEMENT
' ----------------------------------------------------------------
Sub SaveRecord
    ' Write current record back to file
    Dim TempRecord As GameRecord
    TempRecord.DataRecord = RecordContent
    Put #1, CurrentRecord + 1, TempRecord
End Sub

Sub PlaceArtifact(ArtifactIndex As Integer)
    ' Place artifact at appropriate location
    If Mid$(PlaceRecord, 90, 3) = "***" Then
        ArtifactLocation(ArtifactIndex) = Val(Mid$(PlaceRecord, 94, 4))
    Else
        ArtifactLocation(ArtifactIndex) = CurrentRoom
    End If
End Sub

' ----------------------------------------------------------------
' MESSAGE AND TEXT PROCESSING
' ----------------------------------------------------------------
Sub ProcessObjectMessage
    If Left$(Action, 1) = "9" Then Exit Sub
    
    Dim SavedRecord As Integer
    SavedRecord = CurrentRecord
    
    TextOutput = "The "
    Call ProcessTextOutput
    Call ProcessArtifactDescription
    Call ProcessDescription
    
    CurrentRecord = SavedRecord
    Call DisplayMessage
End Sub

Sub ProcessLocationDescription
    ' Display current location description
    Call DisplayMessage
End Sub

' ----------------------------------------------------------------
' TEXT PARSING HELPERS
' ----------------------------------------------------------------
Sub ParseTextTokens
    ' Parse text tokens from record
    Dim TokenStart As Integer
    Dim TokenEnd As Integer
    
    TokenStart = 1
    TokenEnd = InStr(RecordContent, Chr$(0))
    If TokenEnd = 0 Then TokenEnd = Len(RecordContent)
    
    ParsedText1$ = Mid$(RecordContent, TokenStart, TokenEnd - TokenStart)
    
    If TokenEnd < Len(RecordContent) Then
        TokenStart = TokenEnd + 1
        TokenEnd = InStr(TokenStart, RecordContent, Chr$(0))
        If TokenEnd = 0 Then TokenEnd = Len(RecordContent) + 1
        ParsedText2$ = Mid$(RecordContent, TokenStart, TokenEnd - TokenStart)
    Else
        ParsedText2$ = ""
    End If
    
    ' Check for continuation marker
    If Right$(ParsedText2$, 1) = "3" Then
        TextContinue$ = "3"
    Else
        TextContinue$ = "1"
    End If
End Sub

' ----------------------------------------------------------------
' GAME STATE VALIDATION AND DEBUGGING
' ----------------------------------------------------------------
Sub ValidateGameState
    ' Ensure game state is consistent
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

Sub DisplayGameStatus
    ' Debug function to show current game state
    Print "=== GAME STATUS ==="
    Print "Current Room: "; CurrentRoom
    Print "Score: "; Score
    Print "Moves: "; MoveCount  
    Print "Carrying: "; CarryCount; " items"
    Print "Player State: "; PlayerState
    Print
    
    Print "Artifacts:"
    For ArtifactIndex = 1 To NumArtifacts
        If ArtifactLocation(ArtifactIndex) = 0 Then
            Print "  Artifact "; ArtifactIndex; " - CARRIED"
        ElseIf ArtifactLocation(ArtifactIndex) = CurrentRoom Then
            Print "  Artifact "; ArtifactIndex; " - HERE"
        End If
    Next ArtifactIndex
    
    Print "Gremlins:"
    For GremlinIndex = 1 To NumGremlins
        If GremlinLocation(GremlinIndex) = CurrentRoom Then
            Print "  Gremlin "; GremlinIndex; " - HERE (Factor: "; GremlinFactor(GremlinIndex); ")"
        End If
    Next GremlinIndex
    
    Print "=================="
End Sub

' ----------------------------------------------------------------
' ERROR HANDLING AND RECOVERY
' ----------------------------------------------------------------
Sub HandleError(ErrorMessage As String)
    Print "ERROR: "; ErrorMessage
    Print "Game state may be corrupted. Try LOAD to restore."
    Print "Current room: "; CurrentRoom
    Print "Record: "; CurrentRecord
    
    ' Attempt basic recovery
    If CurrentRoom <= 0 Or CurrentRoom > 9999 Then
        CurrentRoom = HomeRoom
        Print "Reset to home room: "; HomeRoom
    End If
    
    ActionResult = "N"
End Sub

' ----------------------------------------------------------------
' MAIN PROGRAM FLOW CONTROL
' ----------------------------------------------------------------
GameLoop:
    ' Return point for save/load operations and game restart
    Call ValidateGameState
    ActionResult = "Y"
    GoTo ArriveAtLocation

' ----------------------------------------------------------------
' PROGRAM TERMINATION
' ----------------------------------------------------------------
Sub CleanupAndExit
    Close #1  ' Close data file
    Print
    Print "Thanks for playing!"
    Print "Final Score: "; Score
    End
End Sub

' Additional utility functions that may be referenced
Dim ParsedText1$ As String
Dim ParsedText2$ As String  
Dim TextContinue$ As String
Dim ProcessedWord$ As String
Dim ParsedNumber As Integer
Dim CommandArgs$ As String
Dim UserFileName$ As String
Dim UserResponse$ As String
Dim GremlinData As String
Dim NewPlace As Integer
Dim TargetGremlin As Integer
Dim FoundTarget As Integer
