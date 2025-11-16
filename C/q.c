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

/* Function prototypes */
chat * getRecord(int recNum);   // Read a record

int main(void)
{
    /* Randomize Timer */
    srand((unsigned int)time(NULL));
    RandomSeed = rand(); /* not strictly necessary but mirrors intent */

    LoadGameData();

    return 0;
}

/*
    ' Load initial game configuration
    CurrentRecord = 0
    Call GetRecord

    ' Parse game configuration from first record
    NumArtifacts = Val(Mid$(RecordContent, 9, 2))
    CurrentRecord = Val(Mid$(RecordContent, 11, 4))
    NumGremlins = Val(Mid$(RecordContent, 15, 2))
    FlagRecord = Val(Mid$(RecordContent, 17, 4))
    CurrentRoom = Val(Mid$(RecordContent, 21, 4))
    HomeRoom = Val(Mid$(RecordContent, 25, 4))
    WarehouseRoom = Val(Mid$(RecordContent, 29, 4))
    DarkRoom = Val(Mid$(RecordContent, 33, 4))

    Call LoadArtifacts
    Call LoadGremlins
End Sub
*/
REC_CONTROL *LoadGameData(void)
{
   static REC_CONTROL ctrlRec;
   char *pRecord = getRecord(0);


         ctrlRec.c_free = RECNUM(pRecord);      /* Free record chain */
         ctrlRec.c_unused = RECNUM(pRecord);    /*   Never-used records chain */
         ctrlRec.c_nartefacts = NUM(pRecord+9);   /* Number of artefacts */
         ctrlRec.c_artefact1 = RECNUM(pRecord); /* First artefact record */
         ctrlRec.c_ngremlins = NUM(pRecord+15);    /* Number of gremlins */
         ctrlRec.c_gremlin1 = RECNUM(pRecord);  /* First gremlin */
         ctrlRec.c_start = RECNUM(pRecord);     /* Start place */
         ctrlRec.c_banished = RECNUM(pRecord);  /* Where banished items go */
         ctrlRec.c_home = RECNUM(pRecord+25);      /* Where treasure has to go to score */
         ctrlRec.c_keys = RECNUM(pRecord);      /* Default keys record */
         ctrlRec.c_count = RECNUM(pRecord);     /* Number of records */


    /* Parse fields from RecordContent using Mid$ + Val */
    CurrentRoom = val_int(tmp); 21
    WarehouseRoom = val_int(tmp); 29
    DarkRoom = val_int(tmp); 33
    CurrentRecord = val_int(tmp); 11
    FlagRecord = val_int(tmp); 17

    LoadArtifacts();
    LoadGremlins();
}

char *getRecord(int RecordNumber)
{
    FILE *f;
    long offset;
    char buffer[RECORDLEN+1];

    f = fopen("QDATA.dat", "rb");
    if (!f) {
        fprintf(stderr, "Error: cannot open QDATA.dat\n");
        exit(EXIT_FAILURE);
    }

    /* Use the record number to get the appropriate line */
    if (recNum >= 0) // If negative, don't seek
    {
       offset = (long)(RecordNumber) * (long) RECORDLEN;
       if (fseek(f, offset, SEEK_SET) != 0) {
           fprintf(stderr, "Error: seek failed in QDATA.dat\n");
           fclose(f);
           exit(EXIT_FAILURE);
       }
    }

    if (fread(Buffer, 1, RECORDLEN, f) != RECORDLEN) {
        fprintf(stderr, "Error: read failed in QDATA.dat (record %d)\n", RecordNumber);
        fclose(f);
        exit(EXIT_FAILURE);
    }
    fclose(f);

    Buffer[RECORDLEN-1] = '\0';  /* ensure NUL */
    if (Buffer[RECORDLEN-2] == '2')
    {
    }
}

