' quest_smoketest.bas — minimal tests that do NOT require QDATA.dat

DECLARE SUB ConvertToUppercase (WordString$)
DECLARE SUB ExtractWord (InputString$)
DECLARE SUB ProcessTextOutput ()
DECLARE SUB WrapText ()
DECLARE SUB FlushOutput ()

DIM SHARED OutputBuffer$, TextOutput$, ProcessedWord$

CLS
PRINT "Running smoke tests..."

' ---- Test ConvertToUppercase ----
DIM s$
s$ = "ab z"
CALL ConvertToUppercase(s$)
IF s$ = "AB Z" THEN
  PRINT "ConvertToUppercase: PASS"
ELSE
  PRINT "ConvertToUppercase: FAIL -> "; s$
END IF

' ---- Test ExtractWord ----
DIM line$
line$ = "  take   lamp  now"
CALL ExtractWord(line$)
IF ProcessedWord$ = "take" THEN
  PRINT "ExtractWord #1: PASS"
ELSE
  PRINT "ExtractWord #1: FAIL -> "; ProcessedWord$
END IF
CALL ExtractWord(line$)
IF ProcessedWord$ = "lamp" THEN
  PRINT "ExtractWord #2: PASS"
ELSE
  PRINT "ExtractWord #2: FAIL -> "; ProcessedWord$
END IF
CALL ExtractWord(line$)
IF ProcessedWord$ = "now" THEN
  PRINT "ExtractWord #3: PASS"
ELSE
  PRINT "ExtractWord #3: FAIL -> "; ProcessedWord$
END IF

' ---- Test ProcessTextOutput / Wrap / Flush ----
OutputBuffer$ = ""
TextOutput$ = "This is a sentence."
CALL ProcessTextOutput
CALL FlushOutput  ' should print wrapped line(s), not crash
PRINT "ProcessTextOutput: PASS (manual visual check above)"

PRINT : PRINT "All smoke tests done."

END

' ---------------- Utility copies ----------------

SUB ConvertToUppercase (WordString$)
  DIM i%
  FOR i% = 1 TO LEN(WordString$)
    IF MID$(WordString$, i%, 1) > "@" THEN
      MID$(WordString$, i%, 1) = CHR$(ASC(MID$(WordString$, i%, 1)) AND &H5F)
    END IF
  NEXT i%
END SUB

SUB ExtractWord (InputString$)
  DO WHILE LEN(InputString$) > 0 AND LEFT$(InputString$, 1) = " "
    InputString$ = MID$(InputString$, 2)
  LOOP
  DIM p%
  p% = INSTR(InputString$, " ")
  IF p% = 0 THEN p% = LEN(InputString$) + 1
  ProcessedWord$ = LEFT$(InputString$, p% - 1)
  IF p% <= LEN(InputString$) THEN
    InputString$ = MID$(InputString$, p% + 1)
  ELSE
    InputString$ = ""
  END IF
END SUB

SUB ProcessTextOutput
  IF LEN(TextOutput$) = 0 THEN EXIT SUB
  IF RIGHT$(TextOutput$, 1) = "." AND RIGHT$(TextOutput$, 2) <> ". " THEN
    TextOutput$ = TextOutput$ + " "
  END IF
  DIM rem$
  rem$ = TextOutput$
  DO WHILE LEN(rem$) > 0
    DIM pos%
    pos% = INSTR(rem$, "%")
    IF pos% = 0 THEN pos% = LEN(rem$) + 1
    OutputBuffer$ = OutputBuffer$ + LEFT$(rem$, pos% - 1) + " "
    IF LEN(OutputBuffer$) > 70 THEN CALL WrapText
    IF pos% > LEN(rem$) THEN
      rem$ = ""
    ELSE
      rem$ = MID$(rem$, pos% + 2) ' ignore codes in this smoke test
    END IF
  LOOP
END SUB

SUB WrapText
  DIM WrapPos%
  WrapPos% = INSTR(60, OutputBuffer$, " ")
  IF WrapPos% = 0 THEN WrapPos% = LEN(OutputBuffer$)
  PRINT LEFT$(OutputBuffer$, WrapPos%)
  OutputBuffer$ = MID$(OutputBuffer$, WrapPos% + 1)
  DO WHILE LEN(OutputBuffer$) > 0 AND LEFT$(OutputBuffer$, 1) = " "
    OutputBuffer$ = MID$(OutputBuffer$, 2)
  LOOP
END SUB

SUB FlushOutput
  IF LEN(OutputBuffer$) > 0 THEN CALL WrapText
  IF LEN(OutputBuffer$) > 0 THEN PRINT OutputBuffer$
  OutputBuffer$ = ""
END SUB

