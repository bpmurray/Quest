/****************************************************************
 *
 *   Name:     fileaccess.c
 *
 *   Author:   Brendan Murray
 *
 *   Desc:     This file contains the code to access the database
 *             reading it into memory and extracting the various
 *             records, returning the data in the provided memory
 *             block. In all get functions, if the provided block
 *             address is NULL, a new block is allocated.
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
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include "questdefs.h"


static unsigned char *pDB = NULL;  /* Database buffer */
static size_t        recCount = 0; /* Number of records in the DB */


int loadDatabase() {
   char controlBuff[RECLEN+1]; /* To hold record 0, the control record */
   RECORDTYPE recType;         /* To verify it is the control rec */
   unsigned short recordCount; /* Total number of records in the DB */
   int   errCode;              /* To hold errno */

   /* Open the file */
   FILE *db = fopen("ADATA", "r");
   if (!db) {
      errCode = errno;
      DEBUGMSG("Open error %d\n", errno);
      return errCode;
   }

   /* Read the control record */
   if (!fgets(controlBuff, RECLEN, db)) {
      errCode = errno;
      DEBUGMSG("Open error %d\n", errno);
      fclose(db);
      return errCode;
   }

   recType = DIGIT(controlBuff+99);
   if (recType != RT_CONTROL) {
      DEBUGMSG("Wrong control type %d\n", recType);
      fclose(db);
      return ERROR;
   }

   recordCount = RECNUM(controlBuff+95) + 1;
   if (recordCount <= 1) {
      DEBUGMSG("Wrong number of records %d\n", recordCount);
      return ERROR;
   }

   rewind(db); /* Read entire file, so go back to start */

   pDB = calloc(recordCount, RECLEN);
   if (!pDB) {
      DEBUGMSG("Failed to allocate %d records\n", recordCount);
      fclose(db);
      return ERROR;
   }

   recCount = fread(pDB, RECLEN, recordCount, db);
   DEBUGMSG("Expected %d records\n", recordCount);
   DEBUGMSG("Read %ld records\n", recCount);
   DEBUGMSG("Read %ld bytes\n", recCount*RECLEN);
   fclose(db);
   return OK;
}



/* Clean up any allocated memory, etc. */
void cleanupDB() {
   if (pDB) {
      free(pDB);
      pDB = NULL;
   }
}

/* Load the control record */
void loadControlRecord(REC_CONTROL *pRec) {
   unsigned char *pBuff = pDB;
   if (!pRec || !pDB)
      return;
   pRec->c_free        = RECNUM(pBuff+0);
   pRec->c_unused      = RECNUM(pBuff+4);
   pRec->c_nartefacts  = NUM(pBuff+8);
   pRec->c_artefact1   = RECNUM(pBuff+10);
   pRec->c_ngremlins   = NUM(pBuff+14);
   pRec->c_gremlin1    = RECNUM(pBuff+16);
   pRec->c_start       = RECNUM(pBuff+20);
   pRec->c_banished    = RECNUM(pBuff+24);
   pRec->c_home        = RECNUM(pBuff+28);
   pRec->c_keys        = RECNUM(pBuff+32);
   pRec->c_count       = RECNUM(pBuff+95);
#ifdef DEBUG
   printf("Control Record\n");
   printf("  free       = %04d\n", pRec->c_free);
   printf("  unused     = %04d\n", pRec->c_unused);
   printf("  nartefacts = %02d\n", pRec->c_nartefacts);
   printf("  artefact1  = %04d\n", pRec->c_artefact1);
   printf("  ngremlins  = %02d\n", pRec->c_ngremlins);
   printf("  gremlin1   = %04d\n", pRec->c_gremlin1);
   printf("  start      = %04d\n", pRec->c_start);
   printf("  banished   = %04d\n", pRec->c_banished);
   printf("  home       = %04d\n", pRec->c_home);
   printf("  keys       = %04d\n", pRec->c_keys);
   printf("  count      = %04d\n", pRec->c_count);
#endif
}

unsigned char *getText(int startRec) {
   static unsigned char txtBuff[408]; /* buffer for text block */
   unsigned char *pBuff = pDB+RECLEN*startRec;
   unsigned char *pText = txtBuff; /* Where to copy the text */
   RECORDTYPE recType;
   TEXTTYPE   txtType;

   memset(txtBuff, 0, sizeof(txtBuff));

   if (startRec < 1 || startRec > recCount) {
      DEBUGMSG("Invalid start %d\n", startRec);
      return NULL;
   }

   do {
      recType = DIGIT(pBuff+99);
      txtType = DIGIT(pBuff+0);
      if (recType != RT_TEXT) {
         DEBUGMSG("Not a text record %d\n", startRec);
         DEBUGMSG("Got type %d\n", recType);
         return NULL;
      }

      if (txtType < T_FIRST || txtType > T_NEXT) {
         DEBUGMSG("Unknown text type %d\n", txtType);
         return NULL;
      }
      /* copy the first text block and trim it */
      strncpy(pText, pBuff+1, 49);
      for (int ix=48; ix>0 && *(pText+ix) <= ' '; ix--) {
         *(pText+ix) = 0;
      }
      pText[strlen(pText)] = '\n';
      pText += strlen(pText);

      /* And the second block */
      if (recType > T_FIRST) {
         strncpy(pText, pBuff+50, 49);
         for (int ix=48; ix>0 && *(pText+ix) <= ' '; ix--) {
            *(pText+ix) = 0;
         }
         pText[strlen(pText)] = '\n';
         pText += strlen(pText);
      }
      pBuff += RECLEN;
   } while (txtType == T_NEXT);

   return(txtBuff);
}


/*   Copy text from b1 into b2, converting %0 and %1 */
void LoadText(char *b1, char *b2, int max)
{
   char   *in = b1, *out = b2;

   strncpy(b2,b1,max);
   for (out = b2 + max - 1; *out <= ' '; out--);
   *(out+1) = (char) NULL;
   if (*(out-1) == '%' && *out =='0')
   {
      *(out-1) = ' ';
      *out     = (char) NULL;
   }
   for (in = b2; *in; in++)
   {
      if (*in == '%' && *(in+1) == '1')
      {
         *in++ = '\n';
         for (out=in+1; *out; *(out-1) = *out++);
         *(out-1) = (char) NULL;
      }
   }
}

/* Load an action into an ACTION structure */
void LoadAction(char *in, ACTION *a)
{
   a->act_flag   = NUM(in);
   strncpy(a->act_data,in+1,4);
}

/* Load a move into a MOVE structure */
void LoadMove(char *in,MOVE *m)
{
   m->mov_type   = *in;
   m->mov_target = NUMBER(in+1);
   LoadAction(in+3,&m->mov_action);
}

/*   Load a key into a KEY structure */
void LoadKey(char *in, KEY *k)
{
   LoadText(in,k->k_word[0],4);
   LoadText(in+4,k->k_word[1],4);
   LoadAction(in+8,&k->k_action);
}

/* Format data for place record */
int SetPlaceRecord(void *p, char *inbuff)
{
   REC_PLACE *r = (REC_PLACE *) p;
   int   i;

   r->p_ld  = RECNUM(inbuff);
   r->p_sd  = RECNUM(inbuff+4);
   r->p_cs  = NUM(inbuff+8);
   r->p_s1d = RECNUM(inbuff+9);
   r->p_s2d = RECNUM(inbuff+13);
   r->p_s1a = RECNUM(inbuff+17);
   r->p_s2a = RECNUM(inbuff+21);
   LoadText(inbuff+25,r->p_k1,4);
   LoadText(inbuff+29,r->p_k2,4);
   for (i=0; i<8; i++)
      LoadMove(inbuff+33+i*8,&r->p_mvs[i]);
   return(RT_PLACE);
}

/* Format data for artefact record */
int SetArtefactRecord(void *p, char *inbuff)
{
   REC_ARTEFACT   *r   = (REC_ARTEFACT *) p;
   int   i;

   r->a_nex = RECNUM(inbuff);
   r->a_sd  = RECNUM(inbuff+4);
   r->a_cs  = *(inbuff+8);
   r->a_s1d = RECNUM(inbuff+9);
   r->a_s2d = RECNUM(inbuff+13);
   r->a_s1a = RECNUM(inbuff+17);
   r->a_s2a = RECNUM(inbuff+21);
   LoadText(inbuff+25,r->a_k1,4);
   LoadText(inbuff+29,r->a_k2,4);
   for (i=0; i<4; i++)
      LoadMove(inbuff+33+i*8,&r->a_mvs[i]);
   LoadText(inbuff+66,r->a_ak1,4);
   LoadText(inbuff+70,r->a_ak2,4);
   LoadText(inbuff+74,r->a_ak3,4);
   r->a_fu  = Str2Num(inbuff+78,3);
   r->a_s1s[0] = *(inbuff+81);
   r->a_s1s[1] = *(inbuff+82);
   r->a_s2s[0] = *(inbuff+83);
   r->a_s2s[1] = *(inbuff+84);
   r->a_cc  =   RECNUM(inbuff+85);
   r->a_num =   NUM2(inbuff+90);
   r->a_loc =   RECNUM(inbuff+92);
   r->a_ldm =   NUM(inbuff+98);
   return(RT_ARTEFACT);
}

/* Format data for gremlin record */
int SetGremlinRecord(void *p, char *inbuff)
{
   REC_GREMLIN   *r   = (REC_GREMLIN *) p;
   int   i;

   r->g_nex = RECNUM(inbuff);
   r->g_sd  = RECNUM(inbuff+4);
   r->g_cs  = *(inbuff+8);
   r->g_s1d = RECNUM(inbuff+9);
   r->g_s2d = RECNUM(inbuff+13);
   r->g_s1a = RECNUM(inbuff+17);
   r->g_s2a = RECNUM(inbuff+21);
   LoadText(inbuff+25,r->g_k1,4);
   LoadText(inbuff+29,r->g_k2,4);
   for (i=0; i<4; i++)
      LoadMove(inbuff+33+i*8,&r->g_mvs[i]);
   for (i=0; i<7; i++)   /* NOTE: the last three are acw's */
      r->g_acf[i] = NUM2(inbuff+66+i*2);
   r->g_foo =   *(inbuff+80);
   r->g_s1s =   NUM2(inbuff+81);
   r->g_s2s =   NUM2(inbuff+83);
   r->g_th  =   RECNUM(inbuff+85);
   r->g_num =   NUM2(inbuff+90);
   r->g_loc =   RECNUM(inbuff+92);
   r->g_ldm =   NUM(inbuff+98);
   return(RT_GREMLIN);
}

/* Format data for contition record */
int SetConditionRecord(void *p, char *inbuff)
{
   REC_CONDITION   *r   = (REC_CONDITION *) p;
   int   i;

   LoadAction(inbuff,&r->i_sr);
   LoadAction(inbuff+5,&r->i_fr);
   r->i_sm  = RECNUM(inbuff+10);
   r->i_fm  = RECNUM(inbuff+14);
   r->i_cf  = *(inbuff+18);
   for (i=0; i<6; i++)
   {
      r->i_ma[i]   = NUM2(inbuff+19+2*i);
      r->i_fa[i]   = NUM2(inbuff+31+2*i);
   }
   strncpy(r->i_rs,inbuff+32,5);
   r->i_pro =   NUM(inbuff+37);
   return(RT_CONDITION);
}

/* Format data for keys record */
int SetKeysRecord(void *p, char *inbuff)
{
   REC_KEYS *r   = (REC_KEYS *) p;
   int   i;

   for (i=0; i<7; i++)
      LoadKey(inbuff+7*i,&r->k_key[i]);
   return(RT_KEYS);
}


/* Format data for state record */
int SetStateRecord(void *p, char *inbuff)
{
   REC_STATE   *r   = (REC_STATE *) p;
   int   i;

   for (i=0; i<18; i++)
   {
      r->s_ini[i].s_rec = RECNUM(inbuff+i*5);
      r->s_ini[i].s_st  = NUM(inbuff+4+i*5);
   }
   LoadAction(inbuff+90,&r->s_act);
   return(RT_STATE);
}

