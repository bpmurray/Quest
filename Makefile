DEBUG    = -DDEBUG
CFLAGS	= -c $(DEBUG)
CC			= gcc
DELETE	= rm

.c.o:
	$(CC) -o $@ $(CFLAGS)  $<

all:	quest.exe

quest.exe:	quest.o fileaccess.o
		$(CC) -o $@ $?

fileaccess.o:	fileaccess.c questdefs.h 

quest.o:			quest.c questdefs.h 

clean:
	$(DELETE) *.o quest.exe


