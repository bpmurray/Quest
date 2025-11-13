$Debug


Type Record
    datarec As String * 100
End Type

Dim rec As Record
Dim recordNum As Integer

1 Randomize (Peek(64)): Rem TAKE RANDOM SEED FROM REAL TIME CLOCK
10 Rem INITIALISATION
15 Dim AL%(60), AR%(60), GL%(40), GR%(40), GF%(40), LL%(5), RP%(5)
20 Open "QDATA.dat" For Random As #1 Len = Len(rec)
25 Rem Dim ZZ$ AS STRING * 100
26 Dim ZZ$
35 RN% = 1: CC% = 0: A2$ = "0": MV% = 100: PN% = 0
100 R% = 0: GoSub 9010
105 SI% = Val(Mid$(RC$, 21, 4)): HO% = Val(Mid$(RC$, 25, 4)): WR% = Val(Mid$(RC$, 29, 4))
110 DK% = Val(Mid$(RC$, 33, 4)): R% = Val(Mid$(RC$, 11, 4)): FG% = Val(Mid$(RC$, 17, 4))
115 NA% = Val(Mid$(RC$, 9, 2)): NG% = Val(Mid$(RC$, 15, 2))
150 GoSub 9010: X% = Val(Mid$(RC$, 91, 2))
155 AL%(X%) = Val(Mid$(RC$, 93, 4)): AR%(X%) = R%
160 R% = Val(Left$(RC$, 4)): If R% > 0 Then 150 Else R% = FG%
170 GoSub 9010: X% = Val(Mid$(RC$, 91, 2))
175 GL%(X%) = Val(Mid$(RC$, 93, 4)): GR%(X%) = R%: GF%(X%) = Val(Mid$(RC$, 81, 1))
180 R% = Val(Left$(RC$, 4)): If R% > 0 Then 170
190 AR$ = "N": GoTo 600
500 AR$ = "Y": S2$ = "The": S1$ = "X": Rem  MOVE
505 For G% = 1 To NG%
    510 If GL%(G%) <> SI% Then 550
    515 R% = GR%(G%): GoSub 9010: ST% = Val(Mid$(RC$, 9, 1))
    520 If Val(Mid$(RC$, 80 + 2 * ST%, 1)) <= Rnd(RN%) * 9 Then 550
    525 TX$ = S2$: GoSub 9230
    530 If S2$ = "The" Then S1$ = "%4has" Else S1$ = "%4have"
    535 S2$ = "%4and": GoSub 8010: GL%(G%) = -NP%
550 Next G%
560 SI% = NP%: If S1$ = "X" Then 600
565 TX$ = S1$ + " following you. ": GoSub 9230: AR$ = "N"
600 R% = SI%: GoSub 9010: PL$ = RC$: R% = Val(Left$(PL$, 4)): Rem ARRIVE
605 For X% = 1 To 5
    610 If SI% = RP%(X%) Then R% = Val(Mid$(PL$, 5, 4))
    615 RP%(X% - 1) = RP%(X%)
620 Next X%
625 RP%(5) = SI%: GoSub 9120
630 PS% = Val(Mid$(PL$, 9, 1)): R% = Val(Mid$(PL$, 6 + 4 * PL%, 4)): GoSub 9120
635 OM% = 9999: For G% = 1 To NG%
    645 If GL%(G%) = SI% Then R% = GR%(G%): GoSub 8100
    647 If GL%(G%) = -SI% Then GL%(G%) = SI%
650 Next G%
660 For G% = 1 To NA%
    665 If AL%(G%) = SI% Then R% = AR%(G%): GoSub 8100
670 Next G%
700 If AR$ = "Y" Then AR$ = "N": GoTo 900 Else TG% = 0
705 For X% = 1 To NG%
    710 If GL%(X%) <> SI% Then 720
    715 GF%(X%) = GF%(X%) + 1: If Rnd(RN%) * 10 <= GF%(X%) Then TG% = X%: GF%(X%) = 9
720 Next X%
730 If TG% = 0 Then 900 Else R% = GR%(TG%): GoSub 9010
735 GF%(TG%) = Val(Mid$(RC$, 86, 1))
740 ST% = Val(Mid$(RC$, 9, 1))
745 R% = Val(Mid$(RC$, 87, 4)): If R% = 0 Then 900
750 Y% = Val(Mid$(RC$, 81 + 2 * ST%, 1)): GoSub 9010: AR$ = "Y"
755 If Rnd(RN%) * 9 < Y% Then 3500 Else GoTo 3600
900 GoSub 9850
910 GoSub 9500: Print SC; "  :";: Line Input CO$: RN% = Len(CO$): MV% = MV% + 1
920 GoSub 8200: L1$ = LW$
930 If Len(L1$) = 0 Then W1$ = "*   " Else W1$ = Left$(L1$ + "   ", 4)
940 GoSub 8200
950 L2$ = LW$: GoSub 8200: If Len(LW$) > 0 Then 950
960 If Len(L2$) = 0 Then W2$ = "*   " Else W2$ = Left$(L2$ + "   ", 4)
970 For X% = 1 To 4
    980 If Mid$(W1$, X%, 1) > "@" Then Mid$(W1$, X%, 1) = Chr$(Asc(Mid$(W1$, X%, 1)) And &H5F)
    990 If Mid$(W2$, X%, 1) > "@" Then Mid$(W2$, X%, 1) = Chr$(Asc(Mid$(W2$, X%, 1)) And &H5F)
995 Next X%
996 If W1$ = "SAVE" And W2$ = "*   " Then 10000
997 If W1$ = "LOAD" And W2$ = "*   " Then 10080
999 If W1$ = "ZPQR" Then 9950
1000 CO$ = "?": AC$ = "?"
1030 DC$ = "NORTSOUTEASTWESTUP  DOWN" + Mid$(PL$, 26, 8): For X% = 1 To 29 Step 4
    1035 If W1$ = Mid$(DC$, X%, 4) Then CO$ = "C" + Right$(Str$((X% + 3) / 400), 2)
1040 Next X%: If CO$ <> "?" Then 2000
1042 If Mid$(PL$, 26, 4) <> "* KR" Then 1050
1044 R% = Val(Mid$(PL$, 30, 4)): GoSub 8300: If AC$ <> "?" Then 3000
1050 G% = NG%
1060 If GL%(G%) <> SI% Then 1100
1070 R% = GR%(G%): GoSub 9010: If Mid$(RC$, 26, 4) <> "* KR" Then 1100
1080 R% = Val(Mid$(RC$, 30, 4)): GoSub 8300
1090 If AC$ <> "?" Then 3000
1100 G% = G% - 1: If G% > 0 Then 1060
1110 Y% = 0: For X% = 1 To 25 Step 4
    1120 If Mid$("LOOKINVEFEEDSCOREND ATTAKILL", X%, 4) = W1$ Then Y% = (X% + 3) / 4
1130 Next X%: G% = 1
1140 On Y% GOTO 1560, 1500, 1410, 1570, 1600, 1400, 1410
1150 If AL%(G%) <> SI% And AL%(G%) <> 0 Then 1190 Else R% = AR%(G%): GoSub 9010
1160 If Mid$(RC$, 26, 4) <> "* KR" Then 1180
1170 R% = Val(Mid$(RC$, 30, 4)): GoSub 8300: If AC$ = "?" Then 1190 Else GoTo 3000
1180 If Mid$(RC$, 26, 4) = W2$ Or Mid$(RC$, 30, 4) = W2$ Then 1210
1190 G% = G% + 1: If G% <= NA% Then 1150
1200 R% = DK%: GoSub 8300: GoTo 3000: Rem ACT ON ACTION
1210 If W1$ = "CARR" Then 1330
1220 If W1$ = "DROP" Then 1300
1230 If W1$ = "THRO" Then 1300
1250 R% = AR%(G%): GoSub 9010: CO$ = "X": For X% = 67 To 75 Step 4
    1260 If W1$ = Mid$(RC$, X%, 4) Then CO$ = Right$(Str$((X% - 63) / 4), 1)
1270 Next X%: If CO$ = "X" Then R% = 338: GoSub 9120: GoTo 700
1280 CO$ = CO$ + Mid$(Str$(G% / 100) + "0", 3, 2): GoTo 2000
1300 If AL%(G%) <> 0 Then R% = 339: GoSub 9120: GoTo 700
1310 CC% = CC% - 1: GoSub 8400: If W1$ = "DROP" Then 700 Else CO$ = "4": GoTo 1280
1330 R% = AR%(G%): GoSub 9010: ST% = Val(Mid$(RC$, 9, 1))
1340 NP% = Val(Mid$(RC$, 86, 4)): If NP% <> 0 Then 3205
1350 If CC% > 6 Then R% = 340: GoSub 9120: GoTo 700
1360 CC% = CC% + 1: AL%(G%) = 0: GoTo 3100
1400 W1$ = "K": Rem   FEED / KILL / ATTACH HANDLER
1410 TG% = 1
1420 If GL%(TG%) <> SI% Then 1450
1430 R% = GR%(TG%): GoSub 9010: If W2$ = Mid$(RC$, 26, 4) Then 1460
1440 If W2$ = Mid$(RC$, 30, 4) Then 1460
1450 TG% = TG% + 1: If TG% > NG% Then R% = 339: GoSub 9120: GoTo 700 Else GoTo 1420
1460 CO$ = Left$(W1$, 1) + Mid$(Str$(TG% * 4 / 100) + "0", 3, 2): KG$ = RC$: GoTo 2000
1500 R% = 342: GoSub 9120: Rem    INVENTORY COMMAND HANDLER
1510 S$ = "%1NOTHING%1": For G% = 1 To NA%
    1520 If AL%(G%) <> 0 Then 1540
    1530 TX$ = "%1A ": GoSub 9200: R% = AR%(G%): GoSub 9010: GoSub 8000: S$ = " %1"
1540 Next G%
1550 TX$ = S$: GoSub 9230: GoTo 700
1560 R% = Val(Left$(PL$, 4)): GoSub 9120: GoTo 630
1570 GoSub 9500: Print "SCORE:"; SC: GoTo 910
1600 GoSub 9500: Print "SCORE:"; SC: End
2000 AC$ = "?": RC$ = PL$: Rem FIND THE CURRENT CO$ COMMAND
2010 GoSub 8505: If AC$ <> "?" Then 3000
2020 If Left$(CO$, 1) = "C" Then R% = 343: GoSub 9120: GoTo 700
2030 G% = 1: Rem SEE IF THE COMMAND IS APPLICABLE TO ANY PRESENT GREMLIN PRINT
2040 If GL%(G%) <> SI% Then 2060
2050 R% = GR%(G%): GoSub 8500: If AC$ <> "?" Then 3000
2060 G% = G% + 1: If G% <= NG% Then 2040
2070 G% = 1: Rem SEE IF THE COMMAND IS APPLICABLE TO ANY PRESENT ARTIFACT
2080 If AL%(G%) <> SI% And AL%(G%) <> 0 Then 2100
2090 R% = AR%(G%): GoSub 8500: If AC$ <> "?" Then 3000
2100 G% = G% + 1: If G% <= NA% Then 2080
2120 If Left$(CO$, 1) = "F" Or Left$(CO$, 1) = "K" Then 2200
2130 R% = 344: GoSub 9120: GoTo 700
2150 Rem FINALLY IF COMMAND IS A FEED OR KILL, ACT ON THAT
2200 If Left$(W1$, 1) = "F" Then S$ = Mid$(KG$, 67, 8): M% = 354: GoTo 2220
2210 S$ = "00" + Mid$(KG$, 75, 6): M% = 351
2220 X% = 1: Rem HAVE WE ANY OF THE REQUIRED ARTIFACTS ?
2230 G% = Val(Mid$(S$, X%, 2)): If G% = 0 Then 2250
2240 If AL%%(G%) = 0 Then 2300
2250 If X% < 6 Then X% = X% + 2: GoTo 2230
2260 GoSub 9110: TX$ = L2$: GoSub 9200
2270 If Left$(W1$, 1) = "F" Then R% = 341: GoSub 9120
2280 GoTo 700
2300 TX$ = "The " + L2$: GoSub 9200: R% = M% + 1: GoSub 9120
2310 R% = AR%(G%): GoSub 9010: GoSub 8000: If Left$(W1$, 1) = "F" Then 2400
2320 GL%(TG%) = -1: GoTo 700
2400 AL%(G%) = -1: GF%(TG%) = Val(Mid$(KG$, 86, 1)): GoTo 700
3000 X% = Val(Left$(AC$, 1)) + 1: Rem   ACT ON ACTION IN AC$
3010 On X% GOTO 700, 3050, 3200, 5000, 3850, 3870, 4000, 4100, 4200, 5000
3020 GoTo 9999
3050 M$ = Right$(AC$, 4): GoSub 9100: Rem ACTION = MESSAGE OUT
3100 AC$ = A2$: A2$ = "0": GoTo 3000: Rem ACT ON ACTION IN A2$
3200 NP% = Val(Right$(AC$, 4)): Rem MOVE
3205 R% = NP%: GoSub 9010
3210 If Right$(RC$, 1) < "6" Then 500
3220 If Right$(RC$, 1) > "6" Then 3800
3250 X% = Val(Mid$(RC$, 19, 1)): On X% GOTO 3270, 3270, 3280, 3600, 3700
3270 If X% <> PS% Then 3600
3280 LV% = 0: Rem PROCESS MANDATORY/FORBIDDEN LISTS
3290 N$ = Mid$(RC$, LV + 20, 2): GoSub 8600: If N% < 0 Then 3320
3300 If N% = 0 Then 3330
3310 If AL%(N%) <> 0 Then 3600 Else GoTo 3330
3320 If GL%(-N%) <> SI% Then 3600
3330 N$ = Mid$(RC$, LV + 32, 2): GoSub 8600: If N% < 0 Then 3360
3340 If N% = 0 Then 3370
3350 If AL%(N%) = 0 Then 3600 Else GoTo 3370
3360 If GL%(N%) = SI% Then 3600
3370 If LV% < 10 Then LV% = LV% + 2: GoTo 3290
3380 CR$ = RC$: R% = Val(Mid$(RC$, 44, 4)): If R% = 0 Then 3410
3390 GoSub 9010: ST$ = Mid$(RC$, 9, 1): RC$ = CR$
3400 If Mid$(RC$, 48, 1) <> ST$ Then 3600
3410 If Val(Mid$(RC$, 49, 1)) > Rnd(RN%) * 10 Then 3600
3500 R% = Val(Mid$(RC$, 11, 4)): Rem CONDITION SUCCEEDS
3510 AC$ = Left$(RC$, 5): GoSub 9120: GoTo 3000
3600 R% = Val(Mid$(RC$, 15, 4)): Rem CONDITION FAILS
3610 AC$ = Mid$(RC$, 6, 5): GoSub 9120: GoTo 3000
3700 A2$ = Mid$(RC$, 6, 5): GoTo 3500: Rem CONDITION SUCCEEDS AND FAILS
3800 CR$ = RC$: For IN% = 1 To 86 Step 5
    3810 R% = Val(Mid$(CR$, IN%, 4)): If R% = 0 Then 3830
    3820 GoSub 9010: Mid$(RC$, 9, 1) = Mid$(CR$, IN% + 4, 1): GoSub 9600
3830 Next IN%: AC$ = Mid$(CR$, 91, 5): GoTo 3000
3850 PS% = 1: Mid$(PL$, 9, 1) = "1": RC$ = PL$: R% = SI%
3860 GoSub 9600: GoTo 3200
3870 N$ = Right$(AC$, 4): GoSub 8600: PN% = PN% + N%: GoTo 3100
4000 M$ = Right$(AC$, 4): GoSub 9100: Rem KILL PLAYER
4010 R% = 345: GoSub 9120: GoSub 9850
4015 Print ":";: Line Input S$
4020 S$ = Chr$(Asc(Left$(S$, 1)) And &H5F): If S$ = "N" Then 1600
4030 MV% = MV% + 10: For G% = 1 To NA%
    4040 If AL%(G%) = 0 Then GoSub 8400
4050 Next G%: CC% = 0: SI% = HO%: AR$ = "Y": GoTo 600
4100 CO$ = Mid$(AC$, 2, 3): GoTo 2000
4200 R% = Val(Right$(AC$, 4)): GoSub 9010: X% = Val(Mid$(RC$, 9, 1))
4220 Mid$(RC$, 9, 1) = Mid$("21", X%, 1): GoSub 9600: GoTo 3100
5000 TY$ = Mid$(AC$, 3, 1): FL% = Val(Mid$(AC$, 2, 1)): Rem FURTHER DECODE
5010 If Right$(AC$, 2) = "??" Then Mid$(AC$, 4, 2) = CA$
5020 If TY$ = "0" Then R% = SI%: GoTo 6000
5030 G% = Val(Right$(AC$, 2)): If G% > 0 Then 5160
5040 If FL% = 3 Then 5200
5050 If TY$ <> "1" Then 5120
5060 For X% = 1 To NA%
    5070 If AL%(X%) = 0 Or AL%(X%) = SI% Then GoSub 8700
5080 Next X%
5090 If G% > 0 Then R% = AR%(G%): GoTo 6000
5100 R% = 344: GoSub 9120: GoTo 3100
5120 For X% = 1 To NG%
    5130 If GL%(X%) = SI% Then GoSub 8700
5140 Next X%
5150 If G% > 0 Then R% = GR%(G%): GoTo 6000 Else GoTo 5100
5160 If TY$ = "1" Then R% = AR%(G%) Else R% = GR%(G%)
5170 GoTo 6000
5200 If TY$ <> "1" Then 5250
5210 G% = Int(Rnd(RN%) * NA%) + 1
5220 If AL%(G%) = 0 Or AL%(G%) = SI% Then 5100
5230 R% = AR%(G%)
5240 GoSub 9010: If Mid$(RC$, 99, 1) = "1" Then 5100 Else GoTo 6100
5250 G% = Int(Rnd(RN%) * NG%) + 1
5260 If GL% = SI% Then 5100 Else R% = GR%(G%): GoTo 5240
6000 GoSub 9010: Rem GOT RECORD NO AFFECTED
6100 Rem DECODE ACTION
6110 On FL% + 1 GOTO 6200, 6300, 6370, 6400, 1360, 1350
6200 X% = Val(Mid$(RC$, 9, 1)): Mid$(RC$, 9, 1) = Mid$("21", X%, 1)
6230 GoSub 9600: If TY$ = "0" Then PS% = Val(Mid$(RC$, 9, 1)): PL$ = RC$
6240 R% = Val(Mid$(RC$, 14 + 4 * Val(Mid$(RC$, 9, 1)), 4)): GoSub 9120
6250 GoTo 3100
6300 NP% = Val(Mid$(RC$, 93, 4)): If NP% <> SI% Then 6330
6310 NP% = WR%: If NP% = SI% Then NP% = 9999
6330 If TY$ <> "1" Then 6380
6340 If AL%(G%) = 0 Then CC% = CC% - 1
6350 AL%(G%) = NP%
6360 R% = 346: GoSub 9900: GoTo 3100
6370 NP% = 9999: GoTo 6330
6380 GL%(G%) = NP%: If FL% = 1 Then 6360
6390 R% = 347: GoSub 9900: GoTo 3100
6400 If Left$(AC$, 1) = "9" Then 6430
6410 TX$ = "A ": GoSub 9220: GoSub 9750: GoSub 9110
6420 R% = 348: GoSub 9120
6430 If TY$ <> "1" Then 6460
6440 If AL%(G%) = 0 Then CC% = CC% - 1
6450 GoSub 8400: GoTo 3100
6460 GL%(G%) = SI%: GoTo 3100
8000 ST% = Val(Mid$(RC$, 9, 1))
8010 R% = Val(Mid$(RC$, 6 + 4 * ST%, 4)): GoTo 9120
8100 GoSub 9010: NM% = Val(Mid$(RC$, 6 + 4 * Val(Mid$(RC$, 9, 1)), 4))
8110 R% = Val(Mid$(RC$, 5, 4)): If R% = 0 Then 8130
8120 If R% = OM% Then TX$ = "%4and a": GoSub 9230 Else GoSub 9120
8130 OM% = R%: R% = NM%: GoTo 9120
8200 If Left$(CO$, 1) = " " Then CO$ = Right$(CO$, Len(CO$) - 1): GoTo 8200
8210 X% = InStr(CO$, " "): If X% = 0 Then X% = Len(CO$) + 1
8220 LW$ = Left$(CO$, X% - 1): CO$ = Right$(CO$, Len(CO$) - X% + 1)
8230 Return
8300 GoSub 9010: For X% = 1 To 91 Step 13
    8305 If Mid$(RC$, X%, 4) <> "?   " And Mid$(RC$, X%, 4) <> W1$ Then 8330
    8310 If Mid$(RC$, X% + 4, 4) <> "?   " And Mid$(RC$, X% + 4, 4) <> W2$ Then 8330
    8320 AC$ = Mid$(RC$, X% + 8, 5): X% = 91
8330 Next X%
8340 R% = Val(Mid$(RC$, 92, 4)): If R% = 0 Or AC$ <> "?" Then Return Else GoTo 8300
8400 If Mid$(PL$, 90, 3) = "***" Then AL%(G%) = Val(Mid$(PL$, 94, 4)) Else AL%(G%) = SI%
8410 Return
8500 GoSub 9010: Rem SLICE OFF ARTIFACT/GREMLIN ACTION LIST
8505 X% = 34: Rem SCAN THE TABLE FOR THE CO$ COMMAND
8510 If Mid$(RC$, X%, 1) = "E" Then Return
8520 If Mid$(RC$, X%, 3) = CO$ Then 8590
8530 If Mid$(RC$, X% + 1, 2) = "??" And Mid$(RC$, X%, 1) = Left$(CO$, 1) Then 8580
8540 If X% < 90 Then X% = X% + 8: GoTo 8510 Else Return
8580 CA$ = Right$(CO$, 2)
8590 AC$ = Mid$(RC$, X% + 3, 5): Return
8600 N% = Val(N$): If Right$(N$, 1) <> "P" Then Return: Rem S25 NUMERIC -> BINARY
8610 N% = 0 - 10 * N% - (Asc(Right$(N$, 1)) And &HF): Return
8700 If G% = 0 Then 8720
8710 If Rnd(RN%) * 10 > 2 Then Return
8720 G% = X%: Return
9000 Rem Let R% = Val(R$): Rem GET RECORD (STRING)
9005 Rem Stop
9010 GoSub 9050: RC$ = ZZ$: Rem GET RECORD (NUMERIC)
9020 Return
9050 Let recordNum = R% + 1
9052 Get #1, recordNum, rec
9053 Let ZZ$ = rec.datarec
9055 Return
9100 If Left$(M$, 2) = "??" Then GoSub 9700 Else M% = Val(M$)
9110 R% = M%: Rem OUTPUT TEXT (NUMERIC)
9120 If R% = 0 Then 9190 Else GoSub 9050: TX$ = T1$: GoSub 9200
9130 If TC$ = "1" Then 9190 Else TX$ = T2$: GoSub 9200
9140 If TC$ = "3" Then R% = R% + 1: GoTo 9120
9190 Return
9200 If Right$(TX$, 1) <> " " Then 9225
9210 If Right$(TX$, 2) = ". " Then 9230 Else TX$ = Left$(TX$, Len(TX$) - 1)
9220 If Len(TX$) = 0 Then 9190 Else GoTo 9200
9225 If Right$(TX$, 1) = "." Then TX$ = TX$ + " "
9230 Let X% = InStr(TX$, "%")
9240 If X% = 0 Then X% = Len(TX$) + 1
9250 OB$ = OB$ + Left$(TX$, X% - 1) + " "
9260 If Len(OB$) > 70 Then GoSub 9300
9270 If X% > Len(TX$) Then 9190
9280 On Val(Mid$(TX$, X% + 1, 1)) GOSUB 9400, 9410, 9420, 9430
9290 TX$ = Right$(TX$, Len(TX$) - X% - 1): If Len(TX$) = 0 Then 9190 Else GoTo 9230
9300 Y% = InStr(60, OB$, " "): If Y% = 0 Then Y% = Len(OB$)
9310 Print Left$(OB$, Y%)
9320 OB$ = Right$(OB$, Len(OB$) - Y%)
9325 If Left$(OB$, 1) = " " Then OB$ = Right$(OB$, Len(OB$) - 1): GoTo 9325
9330 Return
9400 Print OB$: OB$ = "": Return
9410 OB$ = OB$ + "%": Return
9420 OB$ = Left$(OB$, Len(OB$) - 1): Return
9430 If Len(OB$) < 4 Then Return Else OB$ = Left$(OB$, Len(OB$) - 4) + " ": Return
9500 SC = 0: For G% = 1 To NA%
    9510 If AL%(G%) <> HO% Then 9540
    9520 R% = AR%(G%): GoSub 9010: ST% = Val(Mid$(RC$, 9, 1))
    9530 If Mid$(RC$, 80 + ST% + ST%, 1) = "2" Then SC = SC + Val(Mid$(RC$, 79, 3))
9540 Next G%: SC = Int(1000 * (10 * SC - PN%) / MV%) / 100: Return
9600 LSet ZZ$ = RC$: Put #1, R% + 1, ZZ$: Return
9610 Rem LSET Z2%=RC$ : PUT $2,R%-2499 : RETURN
9700 If Mid$(M$, 4, 1) = "0" Then 9720
9710 R% = GR%(Val(CA$)): GoTo 9730
9720 R% = AR%(Val(CA$))
9730 GoSub 9010: GoSub 9750: TX$ = "The ": GoSub 9200: Return
9750 M% = Val(Mid$(RC$, 6 + 4 * Val(Mid$(RC$, 9, 1)), 4)): Return
9850 If Len(OB$) > 0 Then GoSub 9300 Else Return
9860 If Len(OB$) > 0 Then Print OB$: OB$ = ""
9870 Return
9900 If Left$(AC$, 1) = "9" Then Return Else SV% = R%
9905 TX$ = "The ": GoSub 9200: GoSub 9750: GoSub 9110
9910 R% = SV%: GoTo 9120
9950 If W2$ <> "ARTI" Then 9960
9955 For G% = 1 To NA%: AL%(G%) = 0: Next G%
9957 CC% = NA%: GoTo 910
9960 If W2$ <> "GREM" Then 9970
9965 For G% = 1 To NG%: GL%(G%) = 9999: Next G%
9967 GoTo 910
9970 SI% = Val(W2$): AR$ = "Y": GoTo 600
9999 Print "NOT SUPPORTED": Stop
10000 Print "FILE NAME PLEASE  :";: Input USERFILE$
10010 Open USERFILE$ For Output As #3
10020 Print #3, SI%, SC, MV%, PN%, CC%, RN%
10030 For ZZZ = 1 To 60: Print #3, AL%(ZZZ), AR%(ZZZ): Next ZZZ
10040 For ZZZ = 1 To 40: Print #3, GL%(ZZZ), GR%(ZZZ), GF%(ZZZ): Next ZZZ
10050 For ZZZ = 1 To 5: Print #3, LL%(ZZZ), RP%(ZZZ): Next ZZZ
10060 Close #3
10070 GoTo 600
10080 Print "FILE NAME PLEASE  :";: Input USERFILE$
10090 Open USERFILE$ For Input As #3
10100 Input #3, SI%, SC, MV%, PN%, CC%, RN%
10110 For ZZZ = 1 To 60: Input #3, AL%(ZZZ), AR%(ZZZ): Next ZZZ
10120 For ZZZ = 1 To 40: Input #3, GL%(ZZZ), GR%(ZZZ), GF%(ZZZ): Next ZZZ
10130 For ZZZ = 1 To 5: Input #3, LL%(ZZZ), RP%(ZZZ): Next ZZZ
10140 Close #3
10150 GoTo 600



