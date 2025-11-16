/****************************************************************
*
*   Name:     questdefs.h
*
*   Author:   Brendan Murray
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

#ifndef   _QUESTDEFS_H
#define   _QUESTDEFS_H

#ifdef DEBUG
#define DEBUGMSG(x,y) fprintf(stderr, x, y)
#else
#define DEBUGMSG(x,y)
#endif /* Debug */

/* Helpful definitiions */
#define   OK         (0)
#define   ERROR      (~OK)
#define   RECORDLEN  (101)

#ifndef TRUE
#define   TRUE      (0)
#define   FALSE      (~TRUE)
#endif   /* TRUE */

/* Data values in records */
#define   RECLEN    (102L)        /* Size = 100 + CR/LF */
#define   DIGIT(x)  ((char) *(x)-'0')        /* Single ASCII digit */
#define   NUM(x)    (10*DIGIT(x)+DIGIT(x+1)) /* 2-digit ASCII number */
#define   RECNUM(x) (1000*DIGIT(x)+100*DIGIT(x+1)+10*DIGIT(x+2)+DIGIT(x+3))

/* Data types   */
typedef struct {
    char DataRecord[RECORDLEN];   /* BASIC: String * 100, +1 for NUL */
} GameRecord;

typedef  unsigned short  RELREC;
typedef  unsigned char   BYTE;

/*      Record types
 *
 *      RT_FREE         0          Record not in use 
 *      RT_CONTROL      1          Control record: record #0 
 *      RT_TEXT         2          Text for display on screen 
 *      RT_PLACE        3          Describes places & movements 
 *      RT_ARTEFACT     4          Describes objects and actions 
 *      RT_GREMLIN      5          Creatures & things they do! 
 *      RT_CONDITION    6          Actions (logic) 
 *      RT_KEYS         7          Special actions 
 *      RT_STATE        8          Initialise states 
 */
typedef enum  _recordType {
         RT_FREE, RT_CONTROL, RT_TEXT, RT_PLACE, RT_ARTEFACT, RT_GREMLIN,
         RT_CONDITION, RT_KEYS, RT_STATE 
         } RECORDTYPE;

/*      Record types */
typedef  struct   _action       {
         short    act_flag;     /* Action flags */
         char     act_data[4];  /* Action data */
         }        ACTION;

typedef  struct   _move         {
         char     mov_type;     /* Move action: C=move, 0-9=action */
         short    mov_target;   /* Target */
         ACTION   mov_action;   /* What to do */
         }        MOVE;

/* 0. Free record */
typedef  struct   _rec_free     {
         RELREC   f_next;        /* Next free */
         }        REC_FREE;

/* 1. Control record */
typedef  struct   _rec_control  {
         RELREC   c_free;       /* Free record chain */
         RELREC   c_unused;     /*   Never-used records chain */
         short    c_nartefacts; /* Number of artefacts */
         RELREC   c_artefact1;  /* First artefact record */
         short    c_ngremlins;  /* Number of gremlins */
         RELREC   c_gremlin1;   /* First gremlin */
         RELREC   c_start;      /* Start place */
         RELREC   c_banished;   /* Where banished items go */
         RELREC   c_home;       /* Where treasure has to go to score */
         RELREC   c_keys;       /* Default keys record */
         RELREC   c_count;      /* Number of records */
         }        REC_CONTROL;

/* 2. Text record */
/*  Text record flag values
 *
 *     T_FIRST  1              Block 1 is last
 *     T_SECOND 2              Block 2 is last
 *     T_NEXT   3              Continue on next record
 */
typedef enum _textType {
         T_FIRST = 1, T_SECOND, T_NEXT
         } TEXTTYPE;

typedef  struct   _rec_textt    {
         TEXTTYPE txt_type;        /* Text type - see above */
         char     txt_block[2][50];/* 2 text blocks */
         }        REC_TEXT;

/* 3. Place record */
typedef  struct   _rec_place    {
         RELREC   p_longdesc;      /* Text for long description */
         RELREC   p_shortdesc;     /* Text for short description */
         short    p_state;         /* Current state = 1 or 2 */
         RELREC   p_text[2];       /* Text for states */
         RELREC   p_change[2];     /* Text for state changes */
         char     p_command[2][5]; /* Place-specific commands */
         MOVE     p_move[8];       /* 8 moves */
         }        REC_PLACE;

/*   4. Artefact record */
typedef  struct   _rec_artefact {
         RELREC   a_next;          /* Next artefact */
         RELREC   a_shortdesc;     /* Short description */
         char     a_state;         /* Current state */
         RELREC   a_text[2];       /* State description */
         RELREC   a_change[2];     /* State arrival description */
         char     a_name[2][5];    /* Artefact names */
         MOVE     a_move[8];       /* 8 moves */
         char     a_action[3][5];  /* Artefact-specific action words */
         short    a_fuel;          /* Fuel count */
         char     a_switch[2][2];  /* State switches */
         RELREC   a_carry;         /* Carry condition record */
         short    a_number;        /* Artefact number */
         RELREC   a_start;         /* Start location */
         short    a_lockdown;      /* Lock down marker */
         }        REC_ARTEFACT;

/* 5.   Gremlin record */
typedef  struct   _rec_gremlin  {
         RELREC   g_next;          /*   Next gremlin */
         RELREC   g_shortdesc;     /* Short description */
         char     g_state;         /* Current state */
         RELREC   g_text[2];       /* State description */
         RELREC   g_arrival[2];    /* State arrival description */
         char     g_name[2][5];    /* Gremlin names */
         MOVE     g_move[8];       /* 8 moves */
         short    g_food[4];       /* Acceptable foods */
         short    g_weapon[3];     /* Acceptable weapons */
         short    g_foodLevel;     /* Food level */
         short    g_follow;        /* Probability gremlin follows you */
         short    g_attack;        /* Probability gremlin attacks you */
         short    g_feed;          /* Feed size */
         RELREC   g_threat;        /* Threat condition */
         short    g_number;        /* Gremlin number */
         RELREC   g_start;         /* Start location */
         short    g_lockdown;      /* Lock-down marker */
         }        REC_GREMLIN;

/* 6. Condition record */
typedef  struct   _rec_condition {
         ACTION   i_success;       /* Success result */
         ACTION   i_failure;       /* Failure result */
         RELREC   i_successtxt;    /* Success message */
         RELREC   i_failuretxt;    /* Failure message */
         char     i_flag;          /* Condition flag */
         short    i_mandatory[6];  /* Mandatory artefact list */
         short    i_forbidden[6];  /* Forbidden artefact list */
         char     i_state[5];      /* Record in specific state */
         short    i_probability;   /* Probability of failure */
         }        REC_CONDITION;


/* 7. Keys record */
typedef  struct   _key          {
         char     key_word[2][5];  /* Words */
         ACTION   key_action;      /* Action */
         }        KEY;

typedef  struct   _rec_keys     {
         KEY      k_key[7];        /* Up to seven keys */
         RELREC   k_next;          /* Next keys record */
         }        REC_KEYS;

/* 8. State initialisation record */
typedef  struct   _stateset     {
         RELREC   set_recnum;        /* Record to be set */
         short    set_state;         /* Set of this state */
         }        STATESET;

typedef  struct   _rec_state    {
         STATESET s_set[18];         /* Initialise states */
         ACTION   s_action;          /* What to do next */
         }        REC_STATE;

/* Prototypes */
extern int loadDatabase();  /* Load the DB */
extern void cleanupDB();    /* Clean up memory */
extern void loadControlRecord(REC_CONTROL *);
extern unsigned char *getText(int);

#endif   /* _QUESTDEFS_H */
