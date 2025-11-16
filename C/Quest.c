/* ================================================================
   QUEST ADVENTURE GAME  (C Port Skeleton)
   ------------------------------------------------
   Ported from quest_normalised.bas
   - Structured, no GOTOs
   - Core data structures and main loop translated
   - A subset of Subs fully implemented as examples
   - Many Subs left as TODO stubs (fill in from BASIC source)
   ===============================================================*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <time.h>
#include "questdefs.h"

/* ----------------------------------------------------------------
   GLOBAL VARIABLES (Dim Shared ...)
   ---------------------------------------------------------------- */

/* File handling */
GameRecord GameRec;
int RecordNumber;

/* Game arrays (BASIC arrays are usually 1-based; we give an extra slot) */
int ArtifactLocation[61];   /* AL% - Where each artifact is located */
int ArtifactRecord[61];     /* AR% - Record number for each artifact */
int GremlinLocation[41];    /* GL% - Where each gremlin is located */
int GremlinRecord[41];      /* GR% - Record number for each gremlin */
int GremlinFactor[41];      /* GF% - Gremlin behavior factor */
int LocationList[6];        /* LL% - Location history list */
int RecentPlaces[6];        /* RP% - Recently visited places */

/* Game control variables */
int NumArtifacts;           /* NA% */
int NumGremlins;            /* NG% */
int CurrentRecord;          /* R%  */
int FlagRecord;             /* FG% */
char ActionResult[2];       /* "Y"/"N" etc */
char SecondaryAction[8];    /* A2$ */
char RecordContent[256];    /* RC$ */
char PlaceRecord[256];      /* PL$ */
char DataBuffer[256];       /* ZZ$ */

/* Text / command processing */
char Word1[32];             /* W1$ */
char Word2[32];             /* W2$ */
char CommandStr[32];        /* Command */
char ActionStr[32];         /* AC$ */
char OutputBuffer[512];     /* OB$ */
char TextOutput[512];       /* TX$ */
char ParsedText1[512];
char ParsedText2[512];
char TextContinue[2];       /* "0" / "1" etc */
char UserInput[256];
char UserFileName[256];
char UserResponse[8];
char GremlinData[256];
char ProcessedWord[64];
char CommandArgs[128];

/* Game state */
int NewPlace;
int ParsedNumber;
int TargetGremlin;
int FoundTarget;
int GremlinIndex;
int ArtifactIndex;
int IndexVar;               /* "Index" in BASIC */

/* Locations */
int CurrentRoom;            /* SI% */
int HomeRoom;               /* HO% */
int WarehouseRoom;          /* WR% */
int DarkRoom;               /* DK% */

/* Scoring / randomness */
double Score;               /* SC */
int RandomSeed;             /* RN% */
int CarryCount;             /* CC% */
int MoveCount;              /* MV% */
int PenaltyPoints;          /* PN% */

/* ----------------------------------------------------------------
   BASIC-LIKE UTILITY FUNCTIONS (Mid$, Val, etc.)
   ---------------------------------------------------------------- */

/* Equivalent of BASIC Mid$(s, start, length)
   - 1-based index for start, like BASIC
   - result is NUL-terminated in dest
*/
void mid_substr(const char *src, int start, int length, char *dest, size_t dest_size)
{
    if (dest_size == 0) return;

    int src_len = (int)strlen(src);
    if (start < 1 || start > src_len) {
        dest[0] = '\0';
        return;
    }

    int max_len = src_len - (start - 1);
    if (length > max_len) length = max_len;

    if (length >= (int)dest_size) length = (int)dest_size - 1;

    strncpy(dest, src + (start - 1), length);
    dest[length] = '\0';
}

/* Equivalent of BASIC Val() for simple integers */
int val_int(const char *s)
{
    /* Skip leading spaces */
    while (*s && isspace((unsigned char)*s)) s++;

    int sign = 1;
    if (*s == '+') {
        s++;
    } else if (*s == '-') {
        sign = -1;
        s++;
    }

    long result = 0;
    while (*s && isdigit((unsigned char)*s)) {
        result = result * 10 + (*s - '0');
        s++;
    }

    return (int)(sign * result);
}

/* ----------------------------------------------------------------
   FORWARD DECLARATIONS FOR GAME SUBS (from BASIC)
   ---------------------------------------------------------------- */

/* Initialization & main loop */
void InitializeGame(void);
void LoadGameData(void);
void LoadArtifacts(void);
void LoadGremlins(void);
void StartGameLoop(void);
void ArriveAtLocation(void);
void ProcessMovement(void);
void ProcessGremlins(void);
void CheckGremlinAttacks(void);
void ProcessLocationDescription(void);
void GetPlayerInput(void);
void ProcessCommand(void);
void ValidateGameState(void);
void CleanupAndExit(void);

/* File / record handling */
void getRecord(void);
void DisplayMessage(void);

/* Text parsing */
void ParseTextTokens(void);
void ProcessTextOutput(void);

/* Saving & loading */
void SaveGame(void);
void LoadGame(void);

/* (…there are ~90 subs; add prototypes here as you port them…) */

/* ----------------------------------------------------------------
   MAIN (translates the BASIC "Main:" section)
   ---------------------------------------------------------------- */
/*
 BASIC:
   Main:
   Randomize Timer

   Call InitializeGame
   Call LoadGameData

   GameLoop:
   ' Main game loop - entry point for save/load operations
   Call ValidateGameState
   ActionResult = "Y"
   Call ArriveAtLocation
   Call StartGameLoop

   End
*/
int main(void)
{
    /* Randomize Timer */
    srand((unsigned int)time(NULL));
    RandomSeed = rand(); /* not strictly necessary but mirrors intent */

    InitializeGame();
    LoadGameData();

    /* Main game loop entry */
    ValidateGameState();
    strcpy(ActionResult, "Y");
    ArriveAtLocation();
    StartGameLoop();   /* this Do/Loop runs until game ends */

    /* In BASIC it does "End"; here we can just exit. */
    return 0;
}

/* ----------------------------------------------------------------
   GAME INITIALIZATION ROUTINES
   ---------------------------------------------------------------- */

/*
 BASIC Sub InitializeGame:

    ' Open game data file
    Open "QDATA.dat" For Random As #1 Len = Len(GameRec)

    ' Initialize game state
    RandomSeed = 1
    CarryCount = 0
    SecondaryAction = "0"
    MoveCount = 1         ' FIX: was RECORDLEN, set to 1 to avoid divide-by-zero in score
    PenaltyPoints = 0
    ActionResult = "N"
    OutputBuffer = ""
End Sub
*/
void InitializeGame(void)
{
    /* Open QDATA.dat as a random-access binary file.
       BASIC uses record-length = Len(GameRec) = RECORDLEN bytes.
       We use standard C I/O and translate "Get #1, n" manually in GetRecord(). */

    /* In BASIC, #1 is a global file number; here we’ll just use a FILE*.
       You could keep a global FILE* GameFile; for brevity, GetRecord will fopen/fclose. */

    RandomSeed = 1;
    CarryCount = 0;
    strcpy(SecondaryAction, "0");
    MoveCount = 1;      /* set to 1 to avoid divide-by-zero as in FIX comment */
    PenaltyPoints = 0;
    strcpy(ActionResult, "N");
    OutputBuffer[0] = '\0';
}

/*
 BASIC Sub LoadGameData:

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
*/
void LoadGameData(void)
{
    char tmp[16];

    CurrentRecord = 0;
    char * GetRecord(0);

    /* Parse fields from RecordContent using Mid$ + Val */
    mid_substr(RecordContent, 21, 4, tmp, sizeof(tmp));
    CurrentRoom = val_int(tmp);

    mid_substr(RecordContent, 25, 4, tmp, sizeof(tmp));
    HomeRoom = val_int(tmp);

    mid_substr(RecordContent, 29, 4, tmp, sizeof(tmp));
    WarehouseRoom = val_int(tmp);

    mid_substr(RecordContent, 33, 4, tmp, sizeof(tmp));
    DarkRoom = val_int(tmp);

    mid_substr(RecordContent, 11, 4, tmp, sizeof(tmp));
    CurrentRecord = val_int(tmp);

    mid_substr(RecordContent, 17, 4, tmp, sizeof(tmp));
    FlagRecord = val_int(tmp);

    mid_substr(RecordContent, 9, 2, tmp, sizeof(tmp));
    NumArtifacts = val_int(tmp);

    mid_substr(RecordContent, 15, 2, tmp, sizeof(tmp));
    NumGremlins = val_int(tmp);

    LoadArtifacts();
    LoadGremlins();
}

/* ----------------------------------------------------------------
   MAIN GAME LOOP
   ---------------------------------------------------------------- */
/*
 BASIC Sub StartGameLoop:

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

        ' Call DisplayLocation
        Call ProcessLocationDescription
        Call GetPlayerInput
        Call ProcessCommand

    Loop
End Sub
*/
void StartGameLoop(void)
{
    strcpy(ActionResult, "N");

    while (1) {
        if (strcmp(ActionResult, "Y") == 0) {
            ProcessMovement();
        } else {
            ProcessGremlins();
        }

        ArriveAtLocation();

        if (strcmp(ActionResult, "Y") != 0) {
            CheckGremlinAttacks();
        }

        /* Location description */
        ProcessLocationDescription();

        /* Input + command processing */
        GetPlayerInput();
        ProcessCommand();

        /* In BASIC, this Do/Loop may be terminated from inside
           subs using "End" or by calling CleanupAndExit.
           Here you could add a global "GameRunning" flag if you like. */
    }
}

/* ----------------------------------------------------------------
   FILE / RECORD HANDLING
   ---------------------------------------------------------------- */
/*
 BASIC GetRecord:

    If CurrentRecord = 0 Then
        RecordNumber = 1
    Else
        RecordNumber = CurrentRecord
    End If

    Get #1, RecordNumber, GameRec
    RecordContent = GameRec.DataRecord
End Sub
*/
void getRecord(unsigned int RecordNumber)
{
    FILE *f;
    long offset;

    f = fopen("QDATA.dat", "rb");
    if (!f) {
        fprintf(stderr, "Error: cannot open QDATA.dat\n");
        exit(EXIT_FAILURE);
    }

    /* BASIC random-access "Get #1, n, GameRec" uses record-length RECORDLEN.
       We emulate that with a seek to (n-1) * RECORDLEN. */
    offset = (long)(RecordNumber) * (long) RECORDLEN;
    if (fseek(f, offset, SEEK_SET) != 0) {
        fprintf(stderr, "Error: seek failed in QDATA.dat\n");
        fclose(f);
        exit(EXIT_FAILURE);
    }

    if (fread(GameRec.DataRecord, 1, RECORDLEN, f) != RECORDLEN) {
        fprintf(stderr, "Error: read failed in QDATA.dat (record %d)\n", RecordNumber);
        fclose(f);
        exit(EXIT_FAILURE);
    }
    fclose(f);

    GameRec.DataRecord[RECORDLEN-1] = '\0';  /* ensure NUL */
    strncpy(RecordContent, GameRec.DataRecord, sizeof(RecordContent) - 1);
    RecordContent[sizeof(RecordContent) - 1] = '\0';
}

/*
 BASIC DisplayMessage:

    If CurrentRecord = 0 Then Exit Sub

    Call GetRecord
    Call ParseTextTokens  ' Parse the text tokens from record

    TextOutput = ParsedText1
    Call ProcessTextOutput

    If TextContinue = "1" Then Exit Sub

    TextOutput = ParsedText2
    Call ProcessTextOutput
End Sub
*/
void DisplayMessage(int recNum)
{
    if (recNum == 0) return;

    getRecord(recNum);
    ParseTextTokens();

    strncpy(TextOutput, ParsedText1, sizeof(TextOutput) - 1);
    TextOutput[sizeof(TextOutput) - 1] = '\0';
    ProcessTextOutput();

    if (strcmp(TextContinue, "1") == 0) return;

    strncpy(TextOutput, ParsedText2, sizeof(TextOutput) - 1);
    TextOutput[sizeof(TextOutput) - 1] = '\0';
    ProcessTextOutput();
}

/* ----------------------------------------------------------------
   VALIDATION / DEBUG (skeleton)
   ---------------------------------------------------------------- */
/*
 BASIC ValidateGameState loops through artifacts/gremlins
 and clamps invalid locations. Translate directly as you like.
*/
void ValidateGameState(void)
{
    int i;

    for (i = 1; i <= NumArtifacts && i < (int)(sizeof(ArtifactLocation)/sizeof(ArtifactLocation[0])); i++) {
        if (ArtifactLocation[i] < -1) {
            ArtifactLocation[i] = CurrentRoom;
        }
    }

    for (i = 1; i <= NumGremlins && i < (int)(sizeof(GremlinLocation)/sizeof(GremlinLocation[0])); i++) {
        if (GremlinLocation[i] < -1) {
            GremlinLocation[i] = -1;
        }
    }

    /* TODO: copy any extra checks from BASIC ValidateGameState */
}

/* ----------------------------------------------------------------
   PROGRAM TERMINATION
   ---------------------------------------------------------------- */
/*
 BASIC CleanupAndExit:

    Close #1  ' Close data file
    Print
    Print "Thanks for playing!"
    Print "Final Score: "; Score
    End
End Sub
*/
void CleanupAndExit(void)
{
    printf("\nThanks for playing!\n");
    printf("Final Score: %.0f\n", Score);
    /* In C, we just exit. */
    exit(0);
}

/* ----------------------------------------------------------------
   STUBS FOR REMAINING SUBS
   ----------------------------------------------------------------
   Each of these should be translated from the BASIC code in the
   same style as above. For now they are just placeholders so the
   file compiles.
   ---------------------------------------------------------------- */

void LoadArtifacts(void)
{
    /* TODO: translate from BASIC LoadArtifacts */
}

void LoadGremlins(void)
{
    /* TODO: translate from BASIC LoadGremlins */
}

void ArriveAtLocation(void)
{
    /* TODO: translate from BASIC ArriveAtLocation */
}

void ProcessMovement(void)
{
    /* TODO: translate from BASIC ProcessMovement */
}

void ProcessGremlins(void)
{
    /* TODO: translate from BASIC ProcessGremlins */
}

void CheckGremlinAttacks(void)
{
    /* TODO: translate from BASIC CheckGremlinAttacks */
}

void ProcessLocationDescription(void)
{
    /* TODO: translate from BASIC ProcessLocationDescription */
}

void GetPlayerInput(void)
{
    /* Basic translation of INPUT:
       LINE INPUT UserInput$  ->  fgets(UserInput, ...) */

    printf("\n> ");
    if (fgets(UserInput, sizeof(UserInput), stdin) == NULL) {
        strcpy(UserInput, "");
    } else {
        /* Strip trailing newline */
        size_t len = strlen(UserInput);
        if (len > 0 && UserInput[len-1] == '\n')
            UserInput[len-1] = '\0';
    }
}

void ProcessCommand(void)
{
    /* TODO: translate from BASIC ProcessCommand (parsing Word1, Word2, etc.) */
}

void ParseTextTokens(void)
{
    /* TODO: translate from BASIC ParseTextTokens; fills ParsedText1, ParsedText2 and TextContinue */
}

void ProcessTextOutput(void)
{
    /* For now just print TextOutput.
       BASIC version handles word-wrapping, token substitution, etc. */
    printf("%s", TextOutput);
}

void SaveGame(void)
{
    /* TODO: translate from BASIC SaveGame */
}

void LoadGame(void)
{
    /* TODO: translate from BASIC LoadGame */
}

/* (Add more stubbed Subs here as needed) */


