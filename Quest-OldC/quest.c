/****************************************************************
 *
 *   Name:     quest.c
 *
 *   Author:   Brendan Murray
 *
 *   Desc:     This is the main controlling module, calling all
 *             the other parts.
 *
 *   Date:     January 2023
 *
 *         Copyright (C) Brendan Murray 1992-2023
 *               All rights reserved
 *
 *===============================================================
 *   History:
 *   Brendan Murray      Sept 1992      Initial version
 *   Brendan Murray      Jan  2023      Restarted
 *
 ****************************************************************/

#include <stdio.h>
#include <string.h>
#include "questdefs.h"

REC_CONTROL controlRec;

int main() {
   int errCode = OK;
   char *pText;

   errCode = loadDatabase();
   if (errCode) {
      DEBUGMSG("Error %d\n", errCode);
   }

   loadControlRecord(&controlRec);

   pText = getText(41);
   printf(">>%s<<", pText);

   cleanupDB();

   return OK;
}
