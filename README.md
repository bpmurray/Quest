# Quest
ICL System 25 text adventure game


The program is driven by the database, ADATA. This is a text file with
fixed-length records, each 100 bytes long (plus 2 extra for CR and LF).

Note: 
   all positions below are zero-based.
   record numbers are 4 digits, making a maximum of 9999 records allowed

Each record has a single byte at position 99, and this determines the content
of the record:  
    0 : The record is unused, except for a pointer to the next free record  
    1 : Control record - this is the very first record in the file.  
    2 : Text to show on the screen  
    3 : Place, describes places and movements  
    4 : Artefact, describes objects and actions  
    5 : Creatures, describes creatures and the things they do  
    6 : Actions, conditionals and the logic for the game  
    7 : Keys, special actions  
    8 : State, initialisation  

The control record (Type 1) has the following contents:  
    00(4)  Points to the start of the free record chain (0)  
    04(4)  Points to the never-used records chain (3926)  
    08(2)  Total number of artefacts  
    10(4)  Points to the first artefact record  
    14(2)  Total number of gremlins  
    16(4)  Points to the first gremlin record  
    20(4)  Initial place record, i.e. starting location  
    24(4)  Place record of where banished items go  
    28(4)  Place record of where treasure has to go to score  
    32(4)  Default keys record  
    95(4)  Total number of records (3925)  

The text record (Type 2) has the following contents:  
    00(1)  Flag: 1 = Only 1 block of text, 2 = 2 blocks, 3 = continue on next record  
    01(49) First block of text  
    50(49) Second block of text  

The place record (Type 3) has the following contents:  
    00(4)  Text record for long description  
    04(4)  Text record for short description  
    08(1)  Current state - 1 or 2  
    09(4)  Text record for state 1  
    13(4)  Text record for state 2  
    17(4)  Text record for state changing to 1  
    21(4)  Text record for state changing to 2  
    25(10) Two place-specific commands  


The artefact record (Type 4) has the following contents:  
    TBD.  
    
The creature record (Type 5) has the following contents:  
    TBD.  
    
The action record (Type 6) has the following contents:  
    TBD.  
    
The keys record (Type 7) has the following contents:  
    TBD.  
    
The state record (Type 8) has the following contents:  
    TBD.  
    

