C                 ::: FLSCREEN.FOR  8-21-95 :::
C
C Earlier dates deleted
C       4-24-94...Added FCLOCK
C       7-28-95...Cosmetic change in FPRMPT and added FLTIME
C       8-07-95...Added CALL FSCASE in FGTCHR
C       8-15-95...Added ERR= in WRITE in FTEXT
C
C This file contains the following FLIP routines.
C
C For screen display/text writing support.
C ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
C    FCENTR...centers string, relative to screen width
C    FTEXT....prints text
C    FPRMPT...scrolling prompt
C    FPAUSE...pause prompt (used for debug)
C    FGTCHR...get character response from terminal
C    FEJECT..._EJECT command
C    FCLRSC...clears screen
C    FCLOCK...returns time, if available
C    FLTIME...time interrupt prompt
C
      SUBROUTINE FCENTR(CLIST,FIRST,LAST)
C     ==================
      IMPLICIT INTEGER (A-U), DOUBLE PRECISION (Z)
C
C CENTER CLIST
C   RETURNS FIRST NONBLANK (TAB)
C         & LAST  NONBLANK
C
      INCLUDE 'DCFLIP.'
CITSO      INCLUDE (DCFLIP)
CI$$INSERT DCFLIP
C
      CHARACTER*128 CLIST
C ::::::::::::::::::::::::::: BEGIN ::::::::::::::::::::::::::::::
      CALL FSLEN(CLIST,128,LAST)
      IF(LAST.GE.SCRWTH)THEN
C TRUNCATE TO SCREEN WIDTH (SCRWTH)
         FIRST = 1
         LAST  = SCRWTH
         RETURN
      ENDIF
C LENGTH < SCRWTH...SHIFT RIGHT TO CENTER
      FIRST = (SCRWTH - LAST + 1)/2
      LAST = FIRST + LAST - 1
C LOOP TO SHIFT CHARACTERS (TAB FOR CENTERING)
      DO 100 I=LAST,FIRST,-1
100   CLIST(I:I)=CLIST(I-FIRST+1:I-FIRST+1)
      DO 110 I=1,FIRST-1
110   CLIST(I:I)=' '
C
      RETURN
C
C ** FCENTR ENDS HERE
      END
      SUBROUTINE FTEXT(CLIST,LAST,MARGIN,INDENT,LINE,BUFFER,*)
C     ================
      IMPLICIT INTEGER (A-U), DOUBLE PRECISION (Z)
C
C THIS PRINTS LINE OF TEXT FROM CLIST TO OUTPUT
C
C   LAST IS DECREMENTED (AND LINES PRINTED) UNTIL IT IS BELOW SCREEN
C      WIDTH (SCRWTH)...LAST=0 IF CLIST(:LAST) IS PRINTED (EG, IF IT
C      FITS ON 1 LINE).
C
C   MARGIN IS LEFT INDENTATION FOR ALL LINES...IT MUST BE AT LEAST 1
C      AND AT MOST SCRWTH-1 (AND IS ADJUSTED ACCORDINGLY).
C
C   INDENT IS (ADDED) LEFT INDENTATION FOR 1ST LINE...IT MAY BE NEGATIVE,
C      BUT IT MUST SATISFY:  0 < MARGIN+INDENT < SCRWTH
C
C   BUFFER IS FOR ADDED INSTRUCTIONS...
C      'CLEAR' MEANS KEEP WRITING UNTIL CLIST IS NULL.
C      'SKIP'  MEANS 'CLEAR' + SKIP LINE
C      'EJECT' MEANS SKIP LINE BEFORE PRINTING
C      'KEEP'  MEANS KEEP WRITING UNTIL CLIST IS BELOW SCREEN WIDTH
C              (BUT KEEP REMAINDER IN CLIST)
C
C ...ALTERNATE RETURN IS FROM FPRMPT (USER ABORT)
C
      INCLUDE 'DCFLIP.'
CITSO      INCLUDE (DCFLIP)
CI$$INSERT DCFLIP
C
      CHARACTER*(*) CLIST
      CHARACTER*(*) BUFFER
C LOCAL
      CHARACTER*192 CTEMP
      CHARACTER*1   CHAR
C ::::::::::::::::::::::::::: BEGIN ::::::::::::::::::::::::::::::
      CHAR = ' '
4     IF(LAST.EQ.0 .OR. BUFFER.EQ.'EJECT ')THEN
C SIMPLY PRINT A BLANK LINE
         CALL FPRMPT(LINE,*99)
         WRITE(OUTPUT,1,ERR=1300)CHAR  ! EDT
         WRITE(456,*)CHAR  ! EDT
1        FORMAT(128A1)
         IF( LAST.EQ.0 )RETURN
      ENDIF
C PREPARE TO PRINT 1ST LINE (INDENT)
      FIRST = MARGIN + INDENT + 2
C NOTE:  THE ADDED BLANK FOR LEFT MARGIN (+2 INSTEAD OF +1) IS BECAUSE PC
C        CHOPS FIRST CHARACTER OF PRINTED LINE.
C
C HERE IS WHERE WE PRINT 1 LINE OF CLIST WITH LEFT MARGIN SET
5     IF(FIRST.LE.1)FIRST=2
      IF(FIRST.GT.SCRWTH)FIRST=SCRWTH
      CTEMP = ' '
      CTEMP(FIRST:) = CLIST
      CALL FSLEN(CTEMP,192,L)
      IF(L.GT.SCRWTH)THEN
C BACKUP
         L = SCRWTH + 1
10       IF(CTEMP(L:L).NE.' ')THEN
            L = L-1
            GOTO 10
         ENDIF
      ENDIF
C NOW CTEMP(:L) FITS ON LINE
      CALL FPRMPT(LINE,*99)
      WRITE(OUTPUT,1,ERR=1300)(CTEMP(I:I),I=1,L) ! EDT
      WRITE(456,*)(CTEMP(I:I),I=1,L)   ! EDT
C TRANSFER REMAINING TEXT (IF ANY) TO UPDATE CLIST
C SKIP TRAILING BLANKS OF WHAT WE JUST PRINTED
      CLIST = CTEMP(L+1:)
      CTEMP = CLIST
C ...AND LOCATION OF LAST NONBLANK CHAR
      CALL FSLEN(CTEMP,192,LAST)
C NOW CLIST(:LAST) = REMAINING TEXT
      IF(LAST.EQ.0)THEN
         IF(BUFFER.EQ.'SKIP')THEN
            CALL FPRMPT(LINE,*99)
            WRITE(OUTPUT,1,ERR=1300)CHAR  ! EDT
            WRITE(456,*)CHAR  ! EDT
         ENDIF
         RETURN
      ENDIF
C ...BUT WE MUST REMOVE LEADING BLANKS THAT WERE TRAILING BLANKS
C    AT THE BREAK (L)
C
      DO 90 L=1,LAST
         IF(CLIST(L:L).NE.' ')GOTO 100
90    CONTINUE
100   CONTINUE
C  WE WANT TO SKIP CLIST(1:L-1)
      CTEMP = CLIST(L:)
      CALL FSLEN(CTEMP,192,LAST)
      CLIST = CTEMP
C
C  OK, WE NOW HAVE CLIST SET WITH CLIST(1:LAST) AS THE REMAINING TEXT AND
C     CLIST(1:1) NOT BLANK
C
      IF(LAST.LT.SCRWTH .AND. BUFFER.EQ.'KEEP')RETURN
      IF(BUFFER.EQ.'SKIP')WRITE(OUTPUT,1,ERR=1300)CHAR
      IF(LAST.EQ.0)RETURN
C
C PREPARE FOR NEW LINE
      FIRST = MARGIN + 2
      GOTO 5
C
1300  PRINT *,' ** IO ERROR WRITING OUTPUT FILE...ABORTING'
C ALTERNATE RETURN BY USER'S REPLY TO FPRMPT
99    RETURN 1
C
C ** FTEXT ENDS HERE
      END
      SUBROUTINE FPRMPT(LINE,*)
C     =================
      IMPLICIT INTEGER (A-U), DOUBLE PRECISION (Z)
      LOGICAL SECOND_ARG_BOOL
      COMMON /SKIP_PROMPT/ SECOND_ARG_BOOL
      

C
C PROMPT IF LINE IS AT BOTTOM OF SCREEN (NO PROMPT IF OUTPUT = FILE)
C ...ALTERNATE RETURN IF USER ABORTS
C
      INCLUDE 'DCFLIP.'
CITSO      INCLUDE (DCFLIP)
CI$$INSERT DCFLIP
C
C LOCAL
      CHARACTER*1 CHAR
C ::::::::::::::::::::::::::: BEGIN ::::::::::::::::::::::::::::::
      LINE = LINE + 1
CIEIA      IF( LINE.LT.SCRLEN-1 )RETURN
      IF( LINE.LT.SCRLEN )RETURN
C NOW LINE HAS REACHED THE SCREEN LENGTH (SCRLEN)
      LINE = 0
CIEIA      LINE = 1
      IF( OUTPUT.NE.TTYOUT )THEN
C OUTPUT = FILE (NOT TERMINAL)...WRITE NEW PAGE
         WRITE(OUTPUT,'(1H1)',ERR=13)
         RETURN
      ENDIF
C OUTPUT = TERMINAL...PROMPT FOR CONTINUATION
5     CONTINUE
        IF (SECOND_ARG_BOOL .EQ. .TRUE.) THEN
            RETURN
        END IF
        PRINT *,' ...Continue (Y/N)?'
        CALL FGTCHR('YN','Y',CHAR)
CIEIA        CALL FCLRSC
        IF( CHAR.EQ.'Y' )RETURN
        IF( CHAR.NE.'N' )PRINT *,' ...ABORTING'
        RETURN 1
C
13    PRINT *,' ** IO ERROR WRITING TO OUTPUT...ABORTING'
      RETURN 1
C
C ** FPRMPT ENDS HERE
      END
      SUBROUTINE FPAUSE(PAUSE)
C     =================
      IMPLICIT INTEGER (A-U), DOUBLE PRECISION (Z)
C
C PROMPT FOR PAUSE VALUE
C
      CHARACTER*12 STRVAL
      LOGICAL*1    SW
C ::::::::::::::::::::::::::: BEGIN ::::::::::::::::::::::::::::::
      STRVAL = ' '
1     PRINT *,' ENTER PAUSE VALUE (',PAUSE,') '
      READ(*,'(A12)')STRVAL
      IF(STRVAL.EQ.' ')RETURN
      IF(STRVAL.EQ.'*')THEN
         PAUSE = 32000
         RETURN
      ENDIF
C PARSE VALUE
      RCODE = 0
      SW = STRVAL(1:1).EQ.'-'
      IF(SW)STRVAL(1:1) = ' '
      CALL FC2I(STRVAL,12,INT,RCODE)
      IF( RCODE.EQ.0 )THEN
         IF(SW)THEN
            PAUSE = -INT
         ELSE
            PAUSE = INT
         ENDIF
         RETURN
      ENDIF
      PRINT *,' ?',STRVAL
      GOTO 1
C
C ** FPAUSE ENDS HERE
      END
      SUBROUTINE FGTCHR(STRING,DEFALT,RESPNS)
C     =================
      IMPLICIT INTEGER (A-U), DOUBLE PRECISION (Z)
c
      INCLUDE 'DCFLIP.'
CITSO      INCLUDE (DCFLIP)
CI$$INSERT DCFLIP
C
C This gets 1-char response from terminal.  Choices are (STRING)
C with default (DEFAULT).
      CHARACTER*(*) STRING
      CHARACTER*1   DEFALT,RESPNS
C
C       STRING null causes a SYSERR message
C       Max length of string = 8 (= number of responses)
C       DEFALT null makes a response mandatory;  else, DEFALT is a
C          char in STRING and RESPNS=DEFALT if user just presses enter
C       Upon return, RESPNS = blank means user refuses to answer
C          (wants to abort)
C
C ADAPTED FROM ROUTINE WRITTEN BY Dave R. Heltne, Optimization Dept.,
C Shell Development Co., May 11, 1992.
C
C LOCAL
      CHARACTER*8 STR8
      CHARACTER*1 ANSWER
      LOGICAL*1   SW
C ::::::::::::::::::::::::::: BEGIN ::::::::::::::::::::::::::::::
      STR8 = STRING
      CALL FSLEN(STR8,8,NUMBER)
      IF(NUMBER.LE.0)THEN
         PRINT *,' ** SYSERR FGTCHR...NULL STRING'
         GOTO 1390
      ENDIF
C CONVERT TO UPPER CASE
      CALL FSCASE(STR8,1,NUMBER)
      SW = .FALSE.
C          :..SAYS USER HAS NOT RESPONDED YET
10    CONTINUE
      ANSWER = ' '
      READ(*,FMT='(A1)') ANSWER
CITSO      READ(*,FMT='(A1)') ANSWER
CICMS      READ(TTYIN,FMT='(A1)',END=100,ERR=1300)ANSWER
100   CONTINUE
CICMS      REWIND TTYIN
      IF(ANSWER.EQ.' ')THEN
C RESPONSE = NULL
         IF(DEFALT.NE.' ')THEN
C ...USE DEFAULT
            RESPNS = DEFALT
            RETURN
         ENDIF
C ...NO DEFAULT...ABORT IF 2ND ATTEMPT
         GOTO 1300
      ENDIF
      CALL FSCASE(ANSWER,1,1)
C
      IF(ANSWER.EQ.'?')THEN
         PRINT *,' ENTER ONE OF:',(' ',STR8(I:I),I=1,NUMBER)
         IF(DEFALT.NE.' ')PRINT *,' ...DEFAULT IS ',DEFALT
         GOTO 10
      ENDIF
C USER GAVE ANSWER...LOOKUP IN STRING
      DO 500 I=1,NUMBER
         IF(ANSWER.EQ.STRING(I:I))THEN
            RESPNS = ANSWER
            RETURN
         ENDIF
500   CONTINUE
C
C ERROR
1300  CONTINUE
      IF(.NOT.SW)THEN
         PRINT *,' MUST ENTER ONE OF:',(' ',STR8(I:I),I=1,NUMBER)
         PRINT *,' ...TRY AGAIN '
         SW = .TRUE.
         GOTO 10
      ENDIF
1390  PRINT *,' ...ABORTING'
      RESPNS = ' '
      RETURN
C
C ** FGTCHR ENDS HERE
      END
      SUBROUTINE FEJECT(CLIST,FIRST,LAST,LINE,RCODE)
C     =================
      IMPLICIT INTEGER (A-U), DOUBLE PRECISION (Z)
C
C EXECUTE _EJECT COMMAND
C    Syntax:  _EJECT [UNLESS number]
C                            :...number of lines <= LINE
      INCLUDE 'DCFLIP.'
CITSO      INCLUDE (DCFLIP)
CI$$INSERT DCFLIP
C
      CHARACTER*(*) CLIST
C LOCAL
      CHARACTER*8   CNDKEY(1)
      CHARACTER*1   CHAR
C ::::::::::::::::::::::::::: BEGIN ::::::::::::::::::::::::::::::
      NUMBER = 1
      CNDKEY(1) = 'UNLESS  '
      CALL FOPTN(CLIST,FIRST,LAST,CNDKEY,NUMBER,RCODE)
      IF(RCODE.NE.0)RETURN
      IF(NUMBER.EQ.0)GOTO 100
C CONDITION SPECIFIED ... GET CONDITION NUMBER (OF LINES)
      CALL FVRNG(CLIST,FIRST,LAST,VL,VU,VINF,CHAR,RCODE)
      IF(RCODE.NE.0)RETURN
      CNDNUM = VL + .1
C
C ...UNLESS number
      IF(LINE.LT.CNDNUM)RETURN
C
100   CONTINUE
C EXECUTE THE EJECTION
      IF(TTYOUT.EQ.OUTPUT)THEN
C OUTPUT = TERMINAL...CLEAR SCREEN
         CALL FCLRSC
      ELSE
C OUTPUT = FILE...WRITE PAGE EJECTION
         WRITE(OUTPUT,101,ERR=1300)
101      FORMAT('1')
      ENDIF
C RETURN WITH LINE INITIALIZED
      LINE = 0
      RETURN
C
1300  PRINT *,' ** ERROR ENCOUNTERED WRITING TO OUTPUT FILE'
      RCODE = 1
      RETURN
C
C ** FEJECT ENDS HERE
      END
      SUBROUTINE FCLRSC
C     =================
      IMPLICIT INTEGER (A-U), DOUBLE PRECISION (Z)
C
C CLEARS SCREEN
C
      INCLUDE 'DCFLIP.'
CITSO      INCLUDE (DCFLIP)
CI$$INSERT DCFLIP
C
      PARAMETER (DUMMY=0, LCLMAX=99)
C ::::::::::::::::::::::::::: BEGIN ::::::::::::::::::::::::::::::
CICMS      IF(DUMMY.EQ.0)THEN
CICMS         CALL FVMCMD('CLRSCRN',RCODE)
CICMS         RETURN
CICMS      ENDIF
CIEIA      IF(DUMMY.EQ.0)THEN
CIEIA         CALL CLEAR
CIEIA         RETURN
CIEIA      ENDIF
      NUMBER = SCRLEN
      IF(NUMBER.GT.LCLMAX)NUMBER = LCLMAX
      DO 10 I=1,NUMBER
10    PRINT *
      RETURN
C
C ** FCLRSC ENDS HERE
      END
      SUBROUTINE FCLOCK(SECOND)
C     =================
C Returns time in seconds, if available.  If not, returns -1.
      INTEGER SECOND
C ::::::::::::::::::::::::::: BEGIN ::::::::::::::::::::::::::::::
      SECOND = -1
C LAHEY TIMER GIVES NUMBER OF TICKS SINCE MIDNIGHT
CLAHEY      CALL TIMER(SECOND)
C ...EACH TICK = 100-TH OF A SECOND
CLAHEY      SECOND = SECOND/100
C RISC CLOCK GIVES CPU CLOCK TIME IN SECONDS
      second=int(secnds(0.0)*100.)
      RETURN
C
C ** FCLOCK ENDS HERE
      END
      SUBROUTINE FLTIME(ELAPSE,MAXTIM,*)
C     =================
C Time interrupt...alternate return means user aborts.
C    ELAPSE = Elapsed time (caller got this).
C    MAXTIM = Setting of time for interrupt...user can change.
C
      INTEGER     ELAPSE,MAXTIM
C LOCAL
      CHARACTER*1  CHAR
      CHARACTER*12 STR12
      INTEGER     TIME
C ::::::::::::::::::::::::::: BEGIN ::::::::::::::::::::::::::::::
      PRINT *,ELAPSE,' = ELAPSED TIME...Continue ',
     1     '(Y/N, or T to change TIME)? '
      CALL FGTCHR('YNT','Y',CHAR)
      IF( CHAR.EQ.'N' )RETURN 1
      IF( CHAR.EQ.'T' )THEN
C USER WANTS TO CHANGE MAXTIM
10       PRINT *,MAXTIM,' = TIME...Enter change (nothing to accept)'
         READ(*,'(A12)')STR12
         IF( STR12.EQ.' ' )RETURN
         RCODE = 0
         CALL FC2I(STR12,12,TIME,RCODE)
         IF( RCODE.NE.0 .OR. TIME.LT.0 )THEN
            PRINT *,' Enter TIME as a positive integer'
         ELSE
            MAXTIM = TIME
         ENDIF
         GOTO 10
      ENDIF
C
      RETURN
C
C ** FLTIME ENDS HERE
      END
