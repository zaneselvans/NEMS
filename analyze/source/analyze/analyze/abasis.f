C                  ::: ABASIS.FOR  8-22-95 :::
C
C Earlier dates deleted
C       1-08-95...Added MAXTIM to BASIS CHECK
C       7-29-95...Added NOCHANGE option to BASIS REFRESH
C       8-04-95...Added CALL AKEYS0 to set defaults in ABASIS.
C       8-15-95...NOCHANGE <--- REPLACE;  PIVOT needs to REFRESH
C
C This contains the following ANALYZE subroutines.
C
C    ABASIS...Executes BASIS command (link with outside).
C    ABARNG...Tests BFS for redundant rows.
C
      SUBROUTINE ABASIS(CLIST,FIRST,LAST,RCODE)
C     =================
      IMPLICIT INTEGER (A-U), DOUBLE PRECISION (Z)
C
      INCLUDE 'DCANAL.'
      INCLUDE 'DCFLIP.'
CITSO      INCLUDE (DCANAL)
CITSO      INCLUDE (DCFLIP)
CI$$INSERT DCANAL
CI$$INSERT DCFLIP
C ...NEED DCFLIP FOR WHETHER OUTPUT=TTYOUT
C
C This executes BASIS command (see BASIS.DOC).
C   Syntax: BASIS [{ STATS [FREQ=freq]
C                  | REDUNDAN
C                  | CHECK [tolerance] [//[FIX][FREQ=freq][TIME=sec]]
C                  |{ADD | DELETE} {SPIKE | NONSPIKE | segment}
C                  | REFRESH [PRIMAL|DUAL][//[REPLACE][FREQ=freq][TIME=sec]]
C                  | PIVOT {ROW | COL} name FOR {ROW | COL} name
C                  | CLEAR }]
C
      CHARACTER*128 CLIST
C                   ===== ALSO USED FOR OUTPUT
C LOCAL
      CHARACTER*16  RNAME,CNAME
      CHARACTER*8   OPTION(8)
      CHARACTER*4   ROWCOL
      CHARACTER*1   CHAR,FTNOTE
      LOGICAL*1     SW
C ...FOR GBREFR
      LOGICAL*1     SWREPL,SWPRML,SWDUAL
      INTEGER       RNUMP, CNUMP, RNUMD, CNUMD, CNUMB
      REAL          RAVGP, CAVGP, RAVGD, CAVGD, CAVGB
      REAL          RMAXP, CMAXP, RMAXD, CMAXD, CMAXB
      CHARACTER*16  RNAMEP,CNAMEP,RNAMED,CNAMED,CNAMEB,NEWST
C ...WILL ALSO USE ROWCOL,RNAME, AND CHAR
C ...ZVALUE AND MAXLST ARE IN DCANAL
C ::::::::::::::::::::::::::: BEGIN :::::::::::::::::::::::::::::::::
C PARSE OPTION
      OPTION(1) = 'STATS   '
      OPTION(2) = 'REDUNDAN'
      OPTION(3) = 'CHECK   '
      OPTION(4) = 'ADD     '
      OPTION(5) = 'DELETE  '
      OPTION(6) = 'REFRESH '
      OPTION(7) = 'PIVOT   '
      OPTION(8) = 'CLEAR   '
      NUMBER = 8
      CALL FOPTN(CLIST,FIRST,LAST,OPTION,NUMBER,RCODE)
      IF( RCODE.NE.0 )RETURN
      IF( NUMBER.EQ.8 )THEN
         CALL BASCLR
         SWRATE = .FALSE.
         RETURN
      ENDIF
C INITIALIZE (FOR MOST OPTIONS)
      LINE = 0
      CALL FLOOK(CLIST,FIRST,LAST,'//',ISPEC)
      IF( ISPEC.GT.0 )THEN
         F = ISPEC+2
         L = LAST
         LAST = ISPEC-1
      ENDIF
      CALL AKEYS0
      CALL FCLOCK(TIME0)
C
      IF( NUMBER.LE.1 )THEN
C STATS (DEFAULT IF NUMBER=0)
         IF( NUMBER.EQ.1.AND.FIRST.LE.LAST )THEN
C ...GET MESSAGE FREQUENCY
            OPTION(1) = 'FREQ '
            CALL FOPTN(CLIST,FIRST,LAST,OPTION,NUMBER,RCODE)
            IF( RCODE.NE.0 )RETURN
            IF( NUMBER.EQ.1 )THEN
               CALL FCL2IN(CLIST,FIRST,LAST,FREQ0,RCODE)
               IF( RCODE.NE.0 )RETURN
               IF( FREQ0.EQ.0 )FREQ0 = 99 999
            ENDIF
         ENDIF
         NUMBER = 1
      ENDIF
C
      IF( .NOT.SWRATE )THEN
C BASIS MUST BE SETUP
         IF( SWMSG .AND. (NRCSUB(1).GT.0 .OR. NRCSUB(2).GT.0) )
     1      PRINT *,' Submatrix will be cleared...',
     2              'please reset after basis is setup.'
         NZ = NROWS
         CALL BAGNDA(ZVALUE,NZ,SWMSG,FREQ0,RCODE)
         IF( RCODE.NE.0 )THEN
            IF( RCODE.EQ.2 )PRINT *,' Solution is not basic...'
            PRINT *,' ** CANNOT SETUP BASIS'
            RETURN
         ENDIF
         SWRATE = .TRUE.
      ENDIF
C =============================================
C BRANCH ON OPTION
      GOTO (100,200,300,400,400,600,700),NUMBER
C STATS
100   CALL BASTAT(NFTRI,NBTRI,NLGL,NKRNL,NSPIK,NZ,NFILL,RCODE)
      IF( RCODE.GT.0 .OR. .NOT.SWMSG )RETURN
      IF( RCODE.LT.0 )THEN
         CLIST = 'Warning: Pivots corrupt basis statistics.'
         CALL FSLEN(CLIST,70,LAST)
         CALL FTEXT(CLIST,LAST,1,0,LINE,'CLEAR ',*9000)
         RCODE = 0
      ENDIF
C WRITE SUMMARY TO OUTPUT (USING FTEXT)
      IF( NKRNL.EQ.0 )THEN
         CALL FI2C(RNAME,NZ,F)
         CALL FI2C(CNAME,NFILL,FC)
         CLIST = 'The basis triangularizes...Structural nonzeroes = '
     1          //RNAME(F:8)//'.'
         CALL FSLEN(CLIST,70,LAST)
         CALL FTEXT(CLIST,LAST,1,0,LINE,'CLEAR ',*9000)
         RETURN
      ENDIF
C GIVE PICTURE OF BASIS STRUCTURE
      CLIST = 'The basis is structured thusly:'
      CALL FSLEN(CLIST,70,LAST)
      CALL FTEXT(CLIST,LAST,5,0,LINE,'CLEAR ',*9000)
      CLIST = '�.           '
      LAST = 15
      CALL FTEXT(CLIST,LAST,10,0,LINE,'CLEAR ',*9000)
      CLIST = '� .          '
      LAST = 15
      CALL FTEXT(CLIST,LAST,10,0,LINE,'CLEAR ',*9000)
      CLIST = '�F .         '
      LAST = 15
      CALL FTEXT(CLIST,LAST,10,0,LINE,'CLEAR ',*9000)
      CLIST = '�������Ŀ    '
      LAST = 15
      CALL FTEXT(CLIST,LAST,10,0,LINE,'CLEAR ',*9000)
      CLIST = '�   � K �    '
      LAST = 15
      CALL FTEXT(CLIST,LAST,10,0,LINE,'CLEAR ',*9000)
      CLIST = '�   ���Ĵ    '
      LAST = 15
      CALL FTEXT(CLIST,LAST,10,0,LINE,'CLEAR ',*9000)
      CLIST = '�       �.   '
      LAST = 15
      CALL FTEXT(CLIST,LAST,10,0,LINE,'CLEAR ',*9000)
      CLIST = '�       � .  '
      LAST = 15
      CALL FTEXT(CLIST,LAST,10,0,LINE,'CLEAR ',*9000)
      CLIST = '�       �R . '
      LAST = 15
      CALL FTEXT(CLIST,LAST,10,0,LINE,'CLEAR ',*9000)
      CLIST = '������������'
      LAST = 15
      CALL FTEXT(CLIST,LAST,10,0,LINE,'CLEAR ',*9000)
C GIVE BASIS STATS
      CALL FI2C(RNAME,NFTRI,F)
      CLIST = 'F = front triangle has '//RNAME(F:8)//' structurals'
      CALL FSLEN(CLIST,70,LAST)
      CALL FTEXT(CLIST,LAST,5,0,LINE,'CLEAR ',*9000)
      CALL FI2C(RNAME,NBTRI,F)
      CALL FI2C(CNAME,NLGL,FC)
      CLIST = 'R = rear  triangle has '//RNAME(F:8)//
     1        ' structurals and '//CNAME(FC:8)//' logicals'
      CALL FSLEN(CLIST,70,LAST)
      CALL FTEXT(CLIST,LAST,5,0,LINE,'CLEAR ',*9000)
      CALL FI2C(RNAME,NKRNL,F)
      CALL FI2C(CNAME,NSPIK,FC)
      CLIST = 'K = kernel has '//RNAME(F:8)//' structurals, with '
     1       //CNAME(FC:8)//' spikes'
      CALL FSLEN(CLIST,80,LAST)
      CALL FTEXT(CLIST,LAST,5,0,LINE,'CLEAR ',*9000)
C
      NZ = NZ + NFILL
      CALL FI2C(RNAME,NZ,F)
      CALL FI2C(CNAME,NFILL,FC)
      CLIST = '...Structural nonzeroes = '//RNAME(F:8)//', with '
     1        //CNAME(FC:8)//' fill-in.'
      CALL FSLEN(CLIST,90,LAST)
      CALL FTEXT(CLIST,LAST,5,0,LINE,'CLEAR ',*9000)
      RETURN
C
C REDUND
200   CALL ABARNG(RCODE)
      RETURN
C
300   CONTINUE
C CHECK [tolerance] [//[FIX][FREQ=freq][TIME=number]]
C ...THIS FTRANS EACH BASIC COLUMN IN SUBMATRIX TO SEE
C    HOW MUCH ERROR THERE IS
      REMAIN = NRCSUB(2)
      IF( REMAIN.EQ.0 )THEN
         PRINT *,' NO COLUMNS IN SUBMATRIX'
         RETURN
      ENDIF
C SET DEFAULT OPTION...NO FIX
      FIX = 0
C SEE IF OPTIONS SPECIFIED
      IF( ISPEC.GT.0 )THEN
C YES...IN CLIST(F:L)
         OPTION(1) = 'FIX '
         OPTION(2) = 'FREQ '
         OPTION(3) = 'TIME '
310      NUMBER = 3
           CALL FOPTN(CLIST,F,L,OPTION,NUMBER,RCODE)
           IF( RCODE.NE.0 )RETURN
           IF( NUMBER.EQ.0 )GOTO 319
           IF( NUMBER.EQ.1 )THEN
              FIX = ISPEC
           ELSE
              CALL AKEYIN(OPTION(NUMBER),CLIST,F,L,RCODE,*9000)
              IF( RCODE.NE.0 )RETURN
           ENDIF
         GOTO 310
319      CONTINUE
      ENDIF
C ===== END OPTION SPECS =====
C SEE IF THERE IS A TOLERANCE SPECIFIED
      CALL FTOKEN(CLIST,FIRST,LAST,RNAME,12,CHAR)
      IF( RNAME.NE.' ' )THEN
         CALL FC2R(RNAME,VCHTOL,RCODE)
         IF( RCODE.NE.0 )RETURN
         IF( VCHTOL.LT.0. )THEN
            PRINT *,' ** TOLERANCE CANNOT BE NEGATIVE'
            RCODE = 1
            RETURN
         ENDIF
      ELSE
C SET CHECK TOLERANCE TO ABSOLUTE QUANTITY DIFFERENCE
         VCHTOL = VAXDIF
         CALL FR2CLJ(RNAME,VCHTOL,L)
      ENDIF
C
      CLIST = 'Checking basic columns with tolerance='//RNAME
      FTNOTE = ' '
      IF( FIX.GT.0 )THEN
         CALL FSLEN(CLIST,80,LAST)
         CLIST(LAST+1:) = '...WILL FIX'
      ENDIF
      CALL FSLEN(CLIST,100,LAST)
      CALL FTEXT(CLIST,LAST,1,0,LINE,'CLEAR ',*9000)
      NCERR  = 0
      NCBAS  = 0
      NOTFIX = 0
      NFIXED = 0
      VWORST = 0.
      JWORST = 0
      FREQ   = FREQ0
C
C  ::: LOOP OVER COLUMNS (FOR OUTPUT TO BE ALPHABETICAL) :::
      DO 350 J=RCSUB1(2),NCOLS
         CALL GETMAP('COL ',J,SW)
         IF( .NOT.SW )GOTO 350
         REMAIN = REMAIN - 1
         CALL GETST('COL ',J,CHAR,STNUM)
         IF( CHAR.NE.'B'.AND.CHAR.NE.'I' )GOTO 350
         NCBAS = NCBAS + 1
C COLUMN J IS BASIC...FTRAN IT
         CALL GALPHA('COL ',J,ZVALUE,NROWS)
C ...NOW ZVALUE= -A(J)   (NOTE THE -)
         CALL GFTRAN(ZVALUE,NROWS)
C NOW ZVALUE = SHOULD = -UNIT VECTOR
C ...GET ITS PIVOT ROW
         CALL GETPIV(ROW,'COL ',J)
C ...MAKE ITS ALPHA VALUE THEORETICALLY = 0
         ZVALUE(ROW) = ZVALUE(ROW) + 1.
         VMAX = 0.
         IMAX = 0
         NUMBER = 0
C
C  ::: LOOP OVER ROWS...ALPHA'S SHOULD = 0 :::
         DO 325 I=1,NROWS
C SET ZVALUE = ALPHA (= -ZVALUE) IN CASE WE FIX
            ZVALUE(I) = -ZVALUE(I)
            VDIF = ZVALUE(I)
            IF( ABS(VDIF).LE.VCHTOL )GOTO 325
            NUMBER = NUMBER+1
            IF( ABS(VDIF).GT.ABS(VMAX) )THEN
               VMAX = VDIF
               IMAX = I
            ENDIF
325      CONTINUE
         IF( IMAX.EQ.0 )GOTO 340
C FTRAN ERROR FOR COL J
         NCERR = NCERR+1
         IF( ABS(VMAX).GT.ABS(VWORST) )THEN
            VWORST = VMAX
            JWORST = J
            IWORST = IMAX
            NWORST = NUMBER
         ENDIF
         IF( FIX.GT.0 )THEN
            ZVALUE(ROW) = ZVALUE(ROW) + 1.
            CALL GBALPH(ZVALUE,NROWS,ROW,RCODE)
            SW = (RCODE.EQ.0)
            IF( SW )THEN
               NFIXED = NFIXED+1
            ELSE
               NOTFIX = NOTFIX+1
               RCODE  = 0
            ENDIF
         ENDIF
         IF( FREQ.GT.1 )THEN
            FREQ = FREQ-1
         ELSE IF( FREQ.EQ.1 )THEN
            FREQ = FREQ0
C PREPARE TO WRITE DISCREPANCY TO OUTPUT
            CALL GETNAM('COL ',J,CNAME)
            CALL GETNAM('ROW ',IMAX,RNAME)
            CALL GETBVP(IMAX,ROWCOL,PIVCOL)
            CLIST = ' '
            CALL GETNAM(ROWCOL,PIVCOL,CLIST)
            IF( .NOT.SW )THEN
               FTNOTE     = '*'
               CLIST(17:) = FTNOTE
            ENDIF
C OK, WE HAVE OUTPUT LINE...FIRST, HAVE WE WRITTEN HEADER?
            IF( NCERR.EQ.1 )WRITE(OUTPUT,301,ERR=1310)
C ...HEADER FORMAT:
301         FORMAT(1X,'Column',T18,'Discrepancy',T38,'Row',T57,'Pivot'/
     1             1X,77('=') )
C WRITE DISCREPANCY
            WRITE(OUTPUT,302,ERR=1310)
     1              CNAME,  VMAX,     RNAME,    ROWCOL,CLIST
302         FORMAT(1X,A16,1X,G18.10, T38,A16,1X, A4,  A17)
         ENDIF
C    ======== END ERROR PROCESSING =========
340      CONTINUE
         IF( REMAIN.EQ.0 )GOTO 380
         CALL FCLOCK(TIME)
         ELAPSE = TIME-TIME0
         IF( ELAPSE.GT.MAXTIM )THEN
            PRINT *,NCBAS,' BASIC COLUMNS CHECKED',
     1                 REMAIN,' COLUMNS REMAIN IN SUBMATRIX'
            IF( NCERR.EQ.0 )THEN
               PRINT *,' ...NO ERRORS'
            ELSE
               CALL GETNAM('COL ',JWORST,CNAME)
               PRINT *,NCERR,' WITH ERROR',VWORST,
     1                 ' = WORST, FOR COL ',CNAME(:NAMELN)
            ENDIF
            CALL FLTIME(ELAPSE,MAXTIM,*9000)
            TIME0 = TIME
         ENDIF
350   CONTINUE
C  ::: END OF LOOP OVER COLUMNS :::
C
380   CONTINUE
      IF( NCERR.EQ.0 )THEN
         WRITE(OUTPUT,389,ERR=1310)NCBAS
389      FORMAT(I6,' Basic columns checked...No errors found.')
         IF( OUTPUT.NE.TTYOUT .AND. SWMSG )WRITE(*,389,ERR=1310)NCBAS
         RETURN
      ENDIF
      IF( FREQ0.GT.0 )THEN
         WRITE(OUTPUT,396,ERR=1310)
396      FORMAT(1X,77('='))
         IF( FTNOTE.NE.' ' )WRITE(OUTPUT,397,ERR=1310)FTNOTE
397      FORMAT(1X,A1,'NOT FIXED'/)
      ENDIF
C FINAL SUMMARY
      CALL GETNAM('COL ',JWORST,CNAME)
      CALL GETNAM('ROW ',IWORST,RNAME)
      WRITE(OUTPUT,398,ERR=1310)
     1  NCBAS,NCERR,CNAME,
     2  NWORST,VWORST,RNAME,
     3  NFIXED,NOTFIX
398   FORMAT(/
     1  I6,' Basic columns checked;',I5,' have error...worst is ',A16/
     2  I6,' Discrepancies with ',G18.10,' in row ',A16/
     3  I6,' Columns were fixed',I5,' failed to be fixed.')
      IF( OUTPUT.NE.TTYOUT )WRITE(*,398)NCBAS,NCERR,CNAME,
     2                      NWORST,VWORST,RNAME, NFIXED,NOTFIX
C RECOMPUTE JWORST AND SHOW ITS DESCREPANCIES
      WRITE(OUTPUT,3001,ERR=1310)CNAME
3001  FORMAT(T20,A16/1X,'Row',T20,'FTRAN Discrepancy'/1X,39('='))
      CALL GALPHA('COL ',JWORST,ZVALUE,NROWS)
      CALL GFTRAN(ZVALUE,NROWS)
      CALL GETPIV(ROW,'COL ',JWORST)
      ZVALUE(ROW) = ZVALUE(ROW) + 1.
      DO 3025 I=1,NROWS
         VDIF = ZVALUE(I)
         IF( ABS(VDIF).LE.VCHTOL )GOTO 3025
         CALL GETNAM('ROW ',I,RNAME)
         WRITE(OUTPUT,3026,ERR=1310)RNAME,VDIF
3026     FORMAT(1X,A16,T20,G20.10)
3025  CONTINUE
C
      RETURN
C
400   CONTINUE
C ADD|DELETE  {SPIKE | NONSPIKE | FTRI | KERNEL | BTRI}
      SW = OPTION(NUMBER).EQ.'ADD '
      OPTION(1) = 'SPIKE '
      OPTION(2) = 'NONSPIKE'
      OPTION(3) = 'FTRI '
      OPTION(4) = 'KERNEL'
      OPTION(5) = 'BTRI '
      N = 5
      RCODE = -1
      CALL FOPTN(CLIST,FIRST,LAST,OPTION,N,RCODE)
      IF( RCODE.NE.0 )RETURN
      CALL GSPIKE(OPTION(N),SW,NUMBER)
      IF( SWMSG )THEN
          RNAME = OPTION(N)
          CALL FSLEN(RNAME,8,L)
          L = L+2
          IF( NUMBER.NE.1 )THEN
             RNAME(L:) = 'columns'
             L = L+7
          ELSE
             RNAME(L:) = 'column'
             L = L+6
          ENDIF
          IF( SW )THEN
             CNAME = 'added to'
             LC = 9
          ELSE
             CNAME = 'deleted from'
             LC = 13
          ENDIF
          PRINT *,NUMBER,' '//RNAME(:L)//CNAME(:LC)//'submatrix.'
      ENDIF
      IF( NUMBER.GT.0 )CALL ASETSB('COL ')
      RETURN
C
600   CONTINUE
C REFRESH [PRIMAL|DUAL] [//[REPLACE][FREQ=freq][TIME=number]]
      SWREPL = .FALSE.
C SEE IF USER SPECIFIES OPTION
      IF( ISPEC.GT.0 )THEN
C YES...IN CLIST(F:L)
         OPTION(1) = 'REPLACE'
         OPTION(2) = 'FREQ '
         OPTION(3) = 'TIME '
610      NUMBER = 3
           CALL FOPTN(CLIST,F,L,OPTION,NUMBER,RCODE)
           IF( RCODE.NE.0 )RETURN
           IF( NUMBER.EQ.0 )GOTO 650
           IF( NUMBER.EQ.1 )THEN
              SWREPL = .TRUE.
           ELSE
              CALL AKEYIN(OPTION(NUMBER),CLIST,F,L,RCODE,*9000)
              IF( RCODE.NE.0 )RETURN
           ENDIF
         GOTO 610
      ENDIF
C ===== END OPTION SPECS =====
650   CONTINUE
      SWPRML = .TRUE.
      SWDUAL = .TRUE.
C GET USER'S {PRIMAL|DUAL} SPEC IN CLIST(FIRST:LAST)
      OPTION(1) = 'PRIMAL'
      OPTION(2) = 'DUAL '
      NUMBER = 2
      CALL FOPTN(CLIST,FIRST,LAST,OPTION,NUMBER,RCODE)
      IF( RCODE.NE.0 )RETURN
      SWPRML = (NUMBER.EQ.0) .OR. (NUMBER.EQ.1)
      SWDUAL = (NUMBER.EQ.0) .OR. (NUMBER.EQ.2)
      IF( .NOT.SWREPL )CALL GMPCLR
      CALL GBREFR(SWREPL,SWPRML,SWDUAL,ZVALUE,NROWS,CLIST,
     1    SWMSG,FREQ0,MAXTIM,
     2    VAXDIF,VRXDIF,VAPDIF,VRPDIF,VAXINF,VRXINF,VAPINF,VTOL0C,
     3    RNUMP,RAVGP,RMAXP,RNAMEP, CNUMP,CAVGP,CMAXP,CNAMEP,
     4    RNUMD,RAVGD,RMAXD,RNAMED, CNUMD,CAVGD,CMAXD,CNAMED,
     5    CNUMB,CAVGB,CMAXB,CNAMEB,
     6    NEWST,ROWCOL,RNAME,CHAR,VRC,VRCDIF, *1300)
      IF( .NOT.SWREPL )THEN
C SET SUBMATRIX
         CALL ASETSB('ROW ')
         CALL ASETSB('COL ')
      ENDIF
C REPORT RESULTS (ALSO CHANGES SOLST IF REPLACED)
      CLIST = 'BASIS REFRESH Results'
      CALL ABRVER(CLIST,SWREPL,SWPRML,SWDUAL,
     1    RNUMP,RAVGP,RMAXP,RNAMEP, CNUMP,CAVGP,CMAXP,CNAMEP,
     2    RNUMD,RAVGD,RMAXD,RNAMED, CNUMD,CAVGD,CMAXD,CNAMED,
     3    CNUMB,CAVGB,CMAXB,CNAMEB,
     4    NEWST,ROWCOL,RNAME,CHAR,VRC,VRCDIF)
      RETURN
C
700   CONTINUE
C PIVOT {HISTORY
C       |COLUMN name [FOR {ROW|COL} name]
C       |UNDO [#]}
      OPTION(1) = 'HISTORY'
      OPTION(2) = 'COLUMN '
      OPTION(3) = 'UNDO   '
      NUMBER = 3
      CALL FOPTN(CLIST,FIRST,LAST,OPTION,NUMBER,RCODE)
      IF( RCODE.NE.0 )RETURN
      IF( NUMBER.EQ.2 )GOTO 820
      IF( NUMBER.EQ.3 )GOTO 830
C HISTORY (NUMBER=0 OR 1)
      NUMBER = 100
      CALL GBPHST(CLIST(1:60),CLIST(62:127),RNAME,NUMBER)
      IF( NUMBER.EQ.0 )THEN
         CLIST = 'NO PIVOTS'
         LAST = 10
         CALL FTEXT(CLIST,LAST,1,0,LINE,'CLEAR',*9000)
         RETURN
      ENDIF
C HEADER
      CLIST = 'PIVOT'
      CLIST(10:) = 'ENTER'
      TAB = NAMELN+18
      CLIST(TAB:) = 'EXIT'
      TABST = TAB + NAMELN + 8
      CLIST(TABST:) = 'STATUS'
      ENDCL = TABST + 15
      LAST = ENDCL
      CALL FTEXT(CLIST,LAST,1,0,LINE,'CLEAR',*9000)
C LOOP (FROM LAST TO FIRST)
      DO 810 PIVOT=NUMBER,1,-1
         CALL FI2C(CNAME,PIVOT,FIRST)
         IF( PIVOT.GT.9 )THEN
            CLIST = CNAME(FIRST:8)
         ELSE
            CLIST = ' '//CNAME(FIRST:8)
         ENDIF
         CALL GBPHST(CLIST(10:TAB-2),CLIST(TAB:TAB+22),
     1               CLIST(TABST:ENDCL),PIVOT)
         LAST = ENDCL
         CALL FTEXT(CLIST,LAST,1,0,LINE,'CLEAR',*9000)
810   CONTINUE
      RETURN
C
820   CONTINUE
C PERFORM PIVOT
C GET ENTERING COLUMN
      CALL FTOKEN(CLIST,FIRST,LAST,CNAME,16,CHAR)
      CALL GETNUM('COL ',CNAME,NUMIN)
      IF( NUMIN.EQ.0 )THEN
         PRINT *,' ** COLUMN '//CNAME(:NAMELN)//' NOT FOUND'
         GOTO 1300
      ENDIF
C OK, COLUMN NUMIN ENTERS
      CALL FTOKEN(CLIST,FIRST,LAST,RNAME,4,CHAR)
      IF( RNAME.EQ.' ' )THEN
C AUTOMATIC SELECTION
         NUMOUT = 0
         ROWCOL = 'Auto'
      ELSE
         CALL FMATCH(RNAME,'FOR ',' ',SW)
         ROWCOL = ' '
         IF( .NOT.SW )THEN
            PRINT *,' ** ',RNAME(4:),' NOT RECOGNIZED'
            GOTO 1300
         ENDIF
C GET EXITING ROWCOL
         OPTION(1) = 'ROW    '
         OPTION(2) = 'COLUMN '
         NUMBER = 2
         RCODE = -1
         CALL FOPTN(CLIST,FIRST,LAST,OPTION,NUMBER,RCODE)
         IF( RCODE.NE.0 )RETURN
         ROWCOL = OPTION(NUMBER)(:3)
         CALL FTOKEN(CLIST,FIRST,LAST,RNAME,16,CHAR)
         CALL GETNUM(ROWCOL,RNAME,NUMOUT)
         IF( NUMOUT.EQ.0 )THEN
            PRINT *,' ** '//ROWCOL//RNAME(:NAMELN)//' NOT FOUND'
            GOTO 1300
         ENDIF
      ENDIF
C NOW COL NUMIN ENTERS AND <ROWCOL> NUMOUT EXITS BASIS
      SW = NUMOUT.EQ.0
C                :...MEANS CHOOSE BY 1ST BASIC DRIVEN TO BOUND
      CALL GPIVOT('COL ',NUMIN,ROWCOL,NUMOUT,ZVALUE,NROWS,
     1            VTOL0P,VTOL0A,VAXINF,VRXINF, NUMPIV, *1300)
      IF( NUMOUT.EQ.0 )THEN
C COULD NOT FIND BASIC DRIVEN TO BOUND
         L = NAMELN
         CALL FSQUEZ(CNAME,L)
         PRINT *,' NO BASIC VARIABLE IS DRIVEN TO BOUND',
     1           ' (WITHIN RANGE OF ',CNAME(:L),')'
         PRINT *,' ...BASIS NOT CHANGED'
         GOTO 9000
      ENDIF
      IF( SW.AND.SWMSG )THEN
C LET USER KNOW WHICH VAR LEFT BASIS
         CALL GETNAM(ROWCOL,NUMOUT,RNAME)
         PRINT *,' ',ROWCOL,RNAME(:NAMELN),' LEFT BASIS'
      ENDIF
      SWPRML = .FALSE.
      GOTO 890
C
830   CONTINUE
C UNDO [#]
      IF( FIRST.GT.LAST )THEN
         NUMBER = 1
      ELSE
         CALL FCL2IN(CLIST,FIRST,LAST,NUMBER,RCODE)
         IF( RCODE.NE.0 )RETURN
      ENDIF
      CALL GBUNDO(NUMBER)
      SWPRML = .TRUE.
C
890   CONTINUE
C WE GET HERE AFTER BASIS PIVOT [UNDO]
C REFRESH TO UPDATE DUAL PRICES AND GET NEW SOLUTION STATUS
C NOTE:  FROM PIVOT, WE DO NOT REFRESH PRIMAL VALUES (DONE BY GPIVOT)
C        FROM UNDO,  WE MUST REFRESH PRIMAL VALUES
      SWREPL = .TRUE.
      SWDUAL = .TRUE.
      SW     = .FALSE.
      FREQ0  = 0
      MAXTIM = 99999
      CALL GBREFR(SWREPL,SWPRML,SWDUAL,ZVALUE,NROWS,CLIST,
     1    SW   ,FREQ0,MAXTIM,
     2    VAXDIF,VRXDIF,VAPDIF,VRPDIF,VAXINF,VRXINF,VAPINF,VTOL0C,
     3    RNUMP,RAVGP,RMAXP,RNAMEP, CNUMP,CAVGP,CMAXP,CNAMEP,
     4    RNUMD,RAVGD,RMAXD,RNAMED, CNUMD,CAVGD,CMAXD,CNAMED,
     5    CNUMB,CAVGB,CMAXB,CNAMEB,
     6    NEWST,ROWCOL,RNAME,CHAR,VRC,VRCDIF, *1300)
      IF( NEWST.EQ.SOLST )RETURN
C LET USER KNOW STATUS HAS CHANGED
      CALL FSLEN(SOLST,16,L)
      CLIST = 'Solution status changed from '//SOLST(:L)//
     1        ' to '//NEWST
      SOLST = NEWST
      CALL FSLEN(CLIST,128,LAST)
      IF( SWMSG .AND. OUTPUT.NE.TTYOUT )PRINT *,' ',CLIST(:LAST)
      CALL FTEXT(CLIST,LAST,1,0,LINE,'CLEAR',*9000)
C
C NORMAL RETURN OR USER ABORT (FROM FTEXT)
9000  RETURN
C
1300  CONTINUE
      RCODE = 13
      RETURN
1310  PRINT *,' ** IO ERROR WRITING TO OUTPUT FILE',OUTPUT
      RCODE = 1
      RETURN
C
C ** ABASIS ENDS HERE
      END
      SUBROUTINE ABARNG(RCODE)
C     =================
      IMPLICIT INTEGER (A-U), DOUBLE PRECISION (Z)
C
      INCLUDE 'DCANAL.'
CITSO      INCLUDE (DCANAL)
CI$$INSERT DCANAL
C
C This tests resident basic solution for strong redundancy.
C ...See REDUND.DOC for algorithm description.
C
C LOCAL
      CHARACTER*128 CLIST
      CHARACTER*16  RNAME
      CHARACTER*4   ROWCOL
      LOGICAL*1     SW,SWRC,SWMIN,SWMAX
C ::::::::::::::::::::::::::: BEGIN :::::::::::::::::::::::::::::::::
C PRE-PROCESS RANGES
      CALL GBARNG(RCODE)
      IF(RCODE.NE.0)RETURN
C
C FORM BLOCKS
      RNAME = 'RED.LO'
      CALL BLKNEW('ROW ',RNAME,BRLO,RCODE)
         IF(RCODE.NE.0)RETURN
      RNAME = 'RED.UP'
      CALL BLKNEW('ROW ',RNAME,BRUP,RCODE)
         IF(RCODE.NE.0)RETURN
      RNAME = 'RED.FR'
      CALL BLKNEW('ROW ',RNAME,BRFR,RCODE)
         IF(RCODE.NE.0)RETURN
      RNAME = 'RED.LO'
      CALL BLKNEW('COL ',RNAME,BCLO,RCODE)
         IF(RCODE.NE.0)RETURN
      RNAME = 'RED.UP'
      CALL BLKNEW('COL ',RNAME,BCUP,RCODE)
         IF(RCODE.NE.0)RETURN
      RNAME = 'RED.FR'
      CALL BLKNEW('COL ',RNAME,BCFR,RCODE)
         IF(RCODE.NE.0)RETURN
C
C    EXECUTE THE REDUNDANCY TEST
C
C DECREASE INFINITY TO AVOID FALSE INFERENCE
      VINFX = VINF/8.
      IF(SWMSG)THEN
         CLIST = 'REDUNDANCY TEST'
         CALL FCENTR(CLIST,FIRST,LAST)
         CALL FTEXT(CLIST,LAST,1,0,LINE,'CLEAR ',*9000)
      ENDIF
C
C LOOP OVER BASIC VARIABLES TO TEST THEIR BOUNDS
      DO 500 I=1,NROWS
         CALL GBRNGV(I,ROWCOL,NUMBER,VMIN,VMAX)
         CALL GETMAP(ROWCOL,NUMBER,SW)
         IF(.NOT.SW)GOTO 500
         CALL GETBND(ROWCOL,NUMBER,VL,VU)
C FORGET FREE VARIABLE
         IF(VL.LE.-VINF .AND. VU.GE.VINF)GOTO 500
C PURIFY VMIN
         IF(VMIN.LE.-VINFX)THEN
            VMIN = -VINF
         ELSE
            INTV = VMIN
            FRAC = 10000*(VMIN - FLOAT(INTV))
            VMIN = FLOAT(INTV) + FLOAT(FRAC)/10000.
         ENDIF
C PURIFY VMAX
         IF(VMAX.GE. VINFX)THEN
            VMAX = VINF
         ELSE
            INTV = VMAX
            FRAC = 10000*(VMAX - FLOAT(INTV))
            VMAX = FLOAT(INTV) + FLOAT(FRAC)/10000.
         ENDIF
C SET REDUNDANCY SWITCHES
         SWMIN = VMIN.GE.VL
         SWMAX = VMAX.LE.VU
         IF(SWMIN.AND.SWMAX)THEN
C BASIC VARIABLE IS TOTALLY REDUNDANT
            IF(ROWCOL.EQ.'ROW ')THEN
               BLOC = BRFR
            ELSE
               BLOC = BCFR
            ENDIF
         ELSE IF(SWMIN .AND. VL.GT.-VINF)THEN
C BASIC VARIABLE'S LOWER BOUND IS REDUNDANT
            IF(ROWCOL.EQ.'ROW ')THEN
               BLOC = BRLO
            ELSE
               BLOC = BCLO
            ENDIF
         ELSE IF(SWMAX .AND. VU.LT. VINF)THEN
C BASIC VARIABLE'S UPPER BOUND IS REDUNDANT
            IF(ROWCOL.EQ.'ROW ')THEN
               BLOC = BRUP
            ELSE
               BLOC = BCUP
            ENDIF
         ELSE
            GOTO 500
         ENDIF
C ...ADD TO BLOCK
         CALL BLKADD(ROWCOL,NUMBER,BLOC)
500   CONTINUE
C
900   CONTINUE
      SWRC = .TRUE.
C ERASE EMPTY BLOCKS, BUT THIS MUST BE DONE IN ORDER OF LAST TO
C       FIRST IN ORDER FOR BERASE TO WORK PROPERLY.
C ROW ORDER OF ERASURE:  FR,LO,UP
      IF(BNUMBR(BRFR).EQ.0)THEN
         SW = SWMSG
         SWMSG = .FALSE.
         CALL BERASE('ROW ',BRFR)
         SWMSG = SW
      ELSE
         SWRC = .FALSE.
         IF(SWMSG)PRINT *,BNUMBR(BRFR),' IN ROW BLOCK RED.FR'
      ENDIF
      IF(BNUMBR(BRUP).EQ.0)THEN
         SW = SWMSG
         SWMSG = .FALSE.
         CALL BERASE('ROW ',BRUP)
         SWMSG = SW
      ELSE
         SWRC = .FALSE.
         IF(SWMSG) PRINT *,BNUMBR(BRUP),' IN ROW BLOCK RED.UP'
      ENDIF
      IF(BNUMBR(BRLO).EQ.0)THEN
         SW = SWMSG
         SWMSG = .FALSE.
         CALL BERASE('ROW ',BRLO)
         SWMSG = SW
      ELSE
         SWRC = .FALSE.
         IF(SWMSG)PRINT *,BNUMBR(BRLO),' IN ROW BLOCK RED.LO'
      ENDIF
C COLUMN ORDER OF ERASURE:  FR,UP,LO
      IF(BNUMBR(BCFR).EQ.0)THEN
         SW = SWMSG
         SWMSG = .FALSE.
         CALL BERASE('COL ',BCFR)
         SWMSG = SW
      ELSE
         SWRC = .FALSE.
         IF(SWMSG)PRINT *,BNUMBR(BCFR),' IN COLUMN BLOCK RED.FR'
      ENDIF
      IF(BNUMBR(BCUP).EQ.0)THEN
         SW = SWMSG
         SWMSG = .FALSE.
         CALL BERASE('COL ',BCUP)
         SWMSG = SW
      ELSE
         SWRC = .FALSE.
         IF(SWMSG)PRINT *,BNUMBR(BCUP),' IN COLUMN BLOCK RED.UP'
      ENDIF
      IF(BNUMBR(BCLO).EQ.0)THEN
         SW = SWMSG
         SWMSG = .FALSE.
         CALL BERASE('COL ',BCLO)
         SWMSG = SW
      ELSE
         SWRC = .FALSE.
         IF(SWMSG)PRINT *,BNUMBR(BCLO),' IN COLUMN BLOCK RED.LO'
      ENDIF
C
      IF(SWRC)PRINT *,' ...NO REDUNDANCY FOUND'
C
9000  RETURN
C
C ** ABARNG ENDS HERE
      END
