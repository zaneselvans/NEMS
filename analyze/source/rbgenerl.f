C              ::: RBGENERL.FOR  4-25-94 :::
C
C DATES:  (removed earlier history)
C    7-05-93...Added char keys, ROWST and COLST
C   BEGIN 12.3
C   12-17-93...Recognize VECTOR(-1:0) in RUGETV and _NAME(-1:0) in RUGETC
C    4-15-94...Added integer keys NAMELN and NTAB(i) (RUINIT sets default)
C              (RUGETN and RUTRAN recognize)
C              RULATX does not omit double blanks
C
C This contains the following subroutines for the RULEBASE module of ANALYZE
C
C   RUINIT.....initializes elements
C              (MUST BE CALLED BEFORE OTHER RULEBASE SUBROUTINES)
C   RUTRAN.....translates a line (substituting key references)
C   RUGETN.....gets value of integer key
C   RUGETC.....gets value of character key
C   RUGETV.....gets value of value key (returns value string)
C   RUGETS.....gets value of switch key
C   RUGETI.....gets index spec (for VECTOR or _NAME)
C   RUPUTP.....sets user parameter key = value
C   RUGETP.....gets user parameter value from key
C   RULATX.....adds text
C
      SUBROUTINE RUINIT
C     =================
      IMPLICIT INTEGER (A-U), DOUBLE PRECISION (Z)
C
      INCLUDE 'DCANAL.'
      INCLUDE 'DCRULE.'
CITSO      INCLUDE (DCANAL)
CITSO      INCLUDE (DCRULE)
CI$$INSERT DCANAL
CI$$INSERT DCRULE
C
C This initializes RULEBASE module
C
C LOCAL
      CHARACTER*64  FILNAM
      CHARACTER*128 CLIST
      CHARACTER*1   CHAR
      LOGICAL       EXIST
C :::::::::::::::::::::::: BEGIN :::::::::::::::::::::::::::::
      VERRUL = '4.25'
      SWRDBG = SWDBG
      RPAUSE = 0
      RPAUS0 = 1
      NRULES = 0
      NTABS  = 10
      DO 10 I=1,NTABS
10    NTAB(I) = 10*I
      IF( PMXRUL.LE.0 )RETURN
      RCODE = 0
      FILNAM = 'RULBASE'
      CALL FSETNM('RULEBASE',FILNAM,BEGEXT,RCODE)
      IF(RCODE.NE.0)RETURN
C
      CALL FINQUR(FILNAM,IOSTAT,EXIST,*1390)
      IF( .NOT.EXIST .OR. IOSTAT.NE.0 )RETURN
C
C RULBASE FILE (7 CHAR NAME FOR TSO) TELLS US IF INTERPRT COMMAND
C IS ENABLED
      CALL FLOPEN(DATFIL,FILNAM,'FORMATTED','OLD',*1300)
C
C READ RULE NAMES
100   CALL FLRDLN(CLIST,DATFIL,RCODE)
         IF(RCODE)190,110,1390
110      CONTINUE
         IF(CLIST.EQ.'ENDATA')GOTO 190
         IF(NRULES.EQ.PMXRUL)THEN
            PRINT *,' ** RULEBASE ERROR...TOO MANY RULE FILES...',
     1              'LIMIT=',PMXRUL
            PRINT *,' ...SEE MODEL MANAGER (PRESS ANY KEY)'
            CALL FGTCHR('.','.',CHAR)
            GOTO  190
         ENDIF
         NRULES = NRULES + 1
         FIRST = 1
         LAST = 80
         CALL FTOKEN(CLIST,FIRST,LAST,RULNAM(NRULES),8,CHAR)
      GOTO 100
C
190   CLOSE(DATFIL)
      IF(NRULES.EQ.0)RETURN
C
C  INITIALIZE RULEBASE DATA
      MAXRUP =  PMXRUP
      MAXRST =  PMXRST
      NVECTR = 0
C SET INTEGER RULE KEYS (KEEP WITHIN 7 CHARS)
      RULINT( 1) = 'NROWS'
      RULINT( 2) = 'NCOLS'
      RULINT( 3) = 'NONZERO'
      RULINT( 4) = 'NRBLKS'
      RULINT( 5) = 'NCBLKS'
      RULINT( 6) = 'NSTACK'
      RULINT( 7) = 'NSTACK1'
      RULINT( 8) = 'NSTACK2'
      RULINT( 9) = 'NZROW'
      RULINT(10) = 'NZCOL'
      RULINT(11) = 'NZRSUB'
      RULINT(12) = 'NZCSUB'
      RULINT(13) = 'NONES'
      RULINT(14) = 'NVALUES'
      RULINT(15) = 'NRSYN'
      RULINT(16) = 'NCSYN'
      RULINT(17) = 'NESYN'
      RULINT(18) = 'NVECTOR'
      RULINT(19) = 'NAMELN'
      RULINT(20) = 'NTAB'
      NRUINT = 20
C SET CHARACTER RULE KEYS (KEEP WITHIN 7 CHARS AND DO NOT START WITH N OR V)
      RULCHR(1) = 'PROBLEM'
      RULCHR(2) = 'RHS'
      RULCHR(3) = 'BOUND'
      RULCHR(4) = 'RANGE'
      RULCHR(5) = 'OBJ'
      RULCHR(6) = 'OPT'
      RULCHR(7) = 'ROW'
      RULCHR(8) = 'COLUMN'
      RULCHR(9) = 'STATUS'
      RULCHR(10)= 'ROWST'
      RULCHR(11)= 'COLST'
      RULCHR(12)= '_NAME'
C                  :...MUST BE LAST CHR KEY
      NRUCHR = 12
C SET VALUE RULE KEYS (KEEP WITHIN 7 CHARS)
      RULVAL(1) = 'VROWLO'
      RULVAL(2) = 'VROWUP'
      RULVAL(3) = 'VROWC'
      RULVAL(4) = 'VROWY'
      RULVAL(5) = 'VROWP'
      RULVAL(6) = 'VCOLLO'
      RULVAL(7) = 'VCOLUP'
      RULVAL(8) = 'VCOLC'
      RULVAL(9) = 'VCOLX'
      RULVAL(10)= 'VCOLD'
      RULVAL(11)= 'VLOOK'
      RULVAL(12)= 'VDENSTY'
      RULVAL(13)= 'VECTOR'
      NRUVAL = 13
C SET SWITCH RULE KEYS
      RULSWK(1) = 'SWMSG '
      RULSWK(2) = 'SWOTFIL'
      RULSWK(3) = 'SWINFIL'
      RULSWK(4) = 'SWRATE'
      RULSWK(5) = 'SWSYN '
      NRUSWK = 5
C            HERE ARE THE COMMANDS (ALPHABETICAL)
C ANALYZE command spec
C CALC parameter [=] expression
C DEBUG [comment]
C ENDLOOP
C ENTITY member [set]
C EXIT
C GOTO label | TOP
C IF string relation string THEN command
C LOOKUP key name(s)
C LOOP
C NEXT [ROW] [COL]
C POP   {1 2} parameter
C PUSH  {1 2} string
C QUEUE {1 2} string
C SET parameter [=][string]
C SKIP number (of lines) | LOOP | ENDLOOP
C STACK [{1 2}]
C TEXT [number [MARGIN=margin [indent] ] | TAB = value [,...] ]
C VECTOR {PUT name value | CLEAR | SORT | FTRAN {ROW | COL}}
C
C A colon (:) in column 1 indicates a label (for GOTO).
C An astrisk (*) in column 1 is a comment, not part of text, which is
C ignored (even in line count for SKIP).
C
C NORMAL RETURN
      RETURN
C
C ERROR RETURNS
1300  CLOSE(DATFIL)
1390  CONTINUE
      IF(SWDBG)THEN
         PRINT *,' ...AT 1390 WITH NRULES=',NRULES
         CALL SYSDBG
      ENDIF
      NRULES = 0
      RETURN
C
C ** RUINIT ENDS HERE
      END
      SUBROUTINE RUTRAN(CLIST,FIRST,LAST,RCODE)
C     =================
      IMPLICIT INTEGER (A-U), DOUBLE PRECISION (Z)
C
      INCLUDE 'DCANAL.'
      INCLUDE 'DCRULE.'
CITSO      INCLUDE (DCANAL)
CITSO      INCLUDE (DCRULE)
CI$$INSERT DCANAL
CI$$INSERT DCRULE
C
C This translates CLIST(FIRST:LAST), substituting key references, and
C puts result into CLIST with FIRST=1 and LAST updated.
C
      CHARACTER*128 CLIST
C LOCAL
      CHARACTER*16  RNAME,CNAME
      CHARACTER*1   CHAR
      CHARACTER*128 CTEMP
      CHARACTER*32  STRVAL
C :::::::::::::::::::: BEGIN ::::::::::::::::::::::::
      I1 = FIRST
5     IF( I1.GE.LAST-1 )GOTO 10
C SQUEEZE OUT BLANK AFTER (
      CALL FLOOKF(CLIST,I1,LAST,'(',I)
      IF( I.GT.0 )THEN
         IF( CLIST(I+1:I+1).EQ.' ' )THEN
            CTEMP = CLIST(I1:I)//CLIST(I+2:LAST)
            CLIST(I1:) = CTEMP
            LAST = LAST-1
         ELSE
            I1 = I+1
         ENDIF
         GOTO 5
      ENDIF
10    CTEMP = ' '
      LTEMP = 0
100   CONTINUE
      IF( FIRST.GT.LAST )GOTO 900
      IF( LTEMP.GE.128 )THEN
         PRINT *,' ** RULEBASE ERROR...STRING LENGTH EXCEEDS 128:'
         GOTO 1300
      ENDIF
      LTEMP = LTEMP + 1
      IF(CLIST(FIRST:FIRST).NE.'%')THEN
         CTEMP(LTEMP:) = CLIST(FIRST:FIRST)
         FIRST = FIRST + 1
         GOTO 100
      ENDIF
C RULE KEY SPECIFIED (BY %)...LOOKUP
      FIRST = FIRST + 1
      N = 0
150   CONTINUE
      N = N + 1
      CHAR = CLIST(FIRST+N:FIRST+N)
      IF( CHAR.NE.' ' .AND. CHAR.NE.',' .AND. CHAR.NE.'=' .AND.
     1    CHAR.NE.'(' .AND. CHAR.NE.')' .AND. CHAR.NE.'{' .AND.
     1    CHAR.NE.'}' .AND. CHAR.NE.'.' .AND. CHAR.NE.'*' .AND.
     2    CHAR.NE.'%' ) GOTO 150
      RNAME = CLIST(FIRST:FIRST+N-1)
C NOW RNAME CONTAINS KEY...ADVANCE FIRST FOR SUBSEQUENT PARSING
      FIRST = FIRST + N
C  (FIRST NOW POINTS TO CHAR IN CLIST)
C
      IF( CHAR.EQ.'(' )THEN
C ( DELIMITS STRING RANGE OR INDEX SPEC
         CALL FLOOKF(CLIST,FIRST,LAST,')',I)
         IF( I.EQ.0 )THEN
            PRINT *,' ** MISSING ) IN %',RNAME
            GOTO 1300
         ENDIF
         CALL FLOOKF(CLIST,FIRST,I,':',RANGE)
      ELSE
         RANGE = 0
      ENDIF
C RANGE > 0 IFF STRING RANGE SPEC IN ...(...:...)
C                                       :   :...RANGE > 0
C                                       :...FIRST
      STRVAL = ' '
C          :...WILL BE NULL UNLESS THIS IS INTRINSIC CHAR OR USER PARAM
      IF( RNAME(1:1).EQ.'N' )THEN
C INTEGER INTRINSIC KEY
         IF( RNAME.EQ.'NTAB ' )THEN
C ...GET INDEX SPEC (NOTE: RUGETI CALLS RUGETN, SO WE MUST GET INDEX HERE)
            IF( CHAR.NE.'(' )THEN
               PRINT *,' ** MISSING ( FOR NTAB'
               GOTO 1300
            ENDIF
            IF( CLIST(FIRST:FIRST).EQ.'(' )FIRST = FIRST+1
            CALL FTOKEN(CLIST,FIRST,LAST,STRVAL,8,CHAR)
            IF( STRVAL.EQ.' ' )THEN
               PRINT *,' ** MISSING NTAB INDEX'
               GOTO 1300
            ENDIF
            IF( CHAR.NE.')' )THEN
               IF( CLIST(FIRST:FIRST).EQ.')' )THEN
                  FIRST = FIRST + 1
               ELSE
                  PRINT *,' ** MISSING OR MISPLACED ) FOR NTAB'
                  GOTO 1300
               ENDIF
            ENDIF
            L = 2
            CALL FC2I(STRVAL,L,ITAB,RCODE)
            IF( RCODE.NE.0 )GOTO 1300
C ...ITAB = INDEX OF NTAB
            CALL RUGETN(RNAME,N,ITAB)
            IF( ITAB.NE.0 )GOTO 1300
            CALL FI2C(STRVAL,N,ITAB)
CC INSERT %TN% AS CONTROL IN TEXT (RULATX WILL RECOGNIZE)
            CTEMP(LTEMP:) = '%T'//STRVAL(ITAB:8)//'%'
            STRVAL = ' '
         ELSE
            CALL RUGETN(RNAME,N,RCODE)
            IF( RCODE.NE.0 )GOTO 1300
            CALL FI2C(RNAME,N,I)
            CTEMP(LTEMP:) = RNAME(I:)
         ENDIF
      ELSE IF( RNAME(1:1).EQ.'%' )THEN
C USER PARAMETER (SET PREVIOUSLY)
         CNAME = RNAME(2:)
         CALL RUGETP(CNAME,STRVAL,RCODE)
C ...NOTE STRVAL COULD BE NULL
      ELSE IF( RNAME(1:1).EQ.'V' )THEN
C VALUE INTRINSIC KEY
         IF( CHAR.EQ.'(' )THEN
            IF( RANGE.GT.0 )THEN
               PRINT *,' ** : SHOULD NOT BE IN %',RNAME
               GOTO 1300
            ENDIF
C ...GET INDEX SPEC OF VECTOR
            CALL RUGETI(CLIST,FIRST,LAST,RCODE,RC)
            IF( RC.NE.0 )GOTO 1300
C ...RCODE = INDEX OF VECTOR
         ENDIF
         CALL RUGETV(RNAME,CTEMP(LTEMP:),RCODE)
      ELSE IF( RNAME(1:2).EQ.'SW' )THEN
C SWITCH INTRINSIC KEY
         CALL RUGETS(RNAME,CTEMP(LTEMP:),RCODE)
      ELSE
C CHARACTER INTRINSIC KEY (DOES NOT BEGIN WITH N, V, OR SW)
         IF( CHAR.EQ.'(' .AND. RANGE.EQ.0 )THEN
C ...GET INDEX SPEC OF _NAME
            CALL RUGETI(CLIST,FIRST,LAST,RCODE,RC)
            IF( RC.NE.0 )GOTO 1300
C ...RCODE = INDEX OF VECTOR
         ENDIF
         CALL RUGETC(RNAME,STRVAL,RCODE)
      ENDIF
      IF( RCODE.NE.0 )GOTO 1300
C
      IF( STRVAL.NE.' ' )THEN
C CHECK FOR STRING RANGE (APPLIES TO NONNULL CHAR KEY OR USER PARAM)
         IF( RANGE.GT.0 )THEN
C STRING RANGE
            FIRST = FIRST + 1
            CALL FTOKEN(CLIST,FIRST,LAST,RNAME,16,CHAR)
            IF( CHAR.NE.')' )THEN
               PRINT *,' ** MISSING ) AFTER %',RNAME
               GOTO 1300
            ENDIF
C NOW RNAME = i:j   ...FIND COLON (IN RNAME)
            CALL FLOOK(RNAME,1,15,':',COLON)
            IF( COLON.EQ.0 )THEN
               PRINT *,' ** SYSERR RUTRAN...NO COLON IN ',RNAME
               GOTO 1300
            ENDIF
C GET FIRST DIGIT (LEFT OF COLON)
            IF( COLON.EQ.1 )THEN
               I1 = 1
            ELSE
               L = COLON-1
               CNAME = RNAME(1:L)
               CALL FC2I(CNAME,L,I1,RCODE)
               IF( RCODE.NE.0 )GOTO 1300
            ENDIF
C GET 2ND DIGIT (RIGHT OF COLON)
            IF( COLON.GE.FIRST )THEN
               I2 = 16
            ELSE
               L = 16-COLON
               CNAME = RNAME(COLON+1:)
               CALL FC2I(CNAME,L,I2,RCODE)
               IF( RCODE.NE.0 )GOTO 1300
            ENDIF
C
            IF( I1.LT.1 .OR. I2.GT.16 .OR. I1.GT.I2 )THEN
               PRINT *,' ** STRING RANGE SYNTAX ERROR IN '//RNAME
               GOTO 1300
            ENDIF
C SET TEXT EQUAL TO SUBSTRING OF CHARACTER VARIABLE
            CTEMP(LTEMP:) = STRVAL(I1:I2)
         ELSE
C SET TEXT EQUAL TO FULL CHARACTER VARIABLE
            CTEMP(LTEMP:) = STRVAL
         ENDIF
      ENDIF
C
C ADVANCE LTEMP TO LAST CHAR OF CTEMP AND GOTO TOP OF LOOP (100)
      CALL FSLEN(CTEMP,128,LTEMP)
      GOTO 100
C
900   CONTINUE
C COMPRESS MULTIPLE BLANKS
      CLIST = ' '
      LAST = 0
      FIRST = 1
      IF( LTEMP.EQ.0 )RETURN
      L = 1
      CHAR = CTEMP(1:1)
C ...CHAR IS LAST CHARACTER...PUT INTO CLIST
950   LAST = LAST + 1
960   CLIST(LAST:LAST) = CHAR
970   IF( L.EQ.LTEMP )GOTO 990
      L = L+1
      IF(CHAR.NE.' ')THEN
         CHAR = CTEMP(L:L)
         GOTO 950
      ENDIF
C ...LAST CHAR WAS BLANK
      IF(CTEMP(L:L).EQ.' ')GOTO 970
C ...NEW CHAR IS NOT BLANK
      CHAR = CTEMP(L:L)
      GOTO 950
C
990   CONTINUE
      IF( SWLOOP )CALL FSSUBS(CLIST,LAST,RCODE)
C                      :...SUBSTITUTE STRINGS (MAY HAVE CHANGED)
      RETURN
C
C ALL ERROR RETURNS COME HERE
1300  CONTINUE
      PRINT *,' LAST LINE:'
      PRINT *,' ',CLIST(:LAST)
      IF( LTEMP.GT.0 )THEN
         PRINT *,' PARTIAL PARSE:'
         PRINT *,' ',CTEMP(:LTEMP)
      ENDIF
      RCODE = 1
      RETURN
C
C ** RUTRAN ENDS HERE
      END
      SUBROUTINE RUGETN(RNAME,N,RCODE)
C     =================
      IMPLICIT INTEGER (A-U), DOUBLE PRECISION (Z)
C
      INCLUDE 'DCANAL.'
      INCLUDE 'DCRULE.'
CITSO      INCLUDE (DCANAL)
CITSO      INCLUDE (DCRULE)
CI$$INSERT DCANAL
CI$$INSERT DCRULE
C
C This gets value of integer keyword (RNAME) and puts into N
C
      CHARACTER*16   RNAME
C LOCAL
      LOGICAL*1      SW
C :::::::::::::::::::: BEGIN ::::::::::::::::::::::::
C LOOK UP INTEGER KEY
      DO 100 K=1,NRUINT
         IF(RNAME.EQ.RULINT(K))GOTO 190
100   CONTINUE
      PRINT *,' ** RULEBASE ERROR...UNABLE TO FIND %',RNAME
      RCODE = 1
      RETURN
C
190   CONTINUE
      IND = RCODE
      RCODE = 0
C         BRANCH ON KEY TO SET N
      GOTO(1010,1020,1030,1040,1050,1060,1070,1080,1090,
     1     1100,1110,1120,1130,1140,1150,1160, 1170,1180,1190,
     2     2000),K
C
C NROWS
1010  N = NRCSUB(1)
      RETURN
C NCOLS
1020  N = NRCSUB(2)
      RETURN
C NONZERO
1030  IF(.NOT.SWSBNZ)
     1   CALL GMAPNZ(NRCSUB(1),RCSUB1(1),NRCSUB(2),RCSUB1(2),NZSUB)
      N = NZSUB
      RETURN
C NRBLKS
1040  N = NRBLKS
      RETURN
C NCBLKS
1050  N = NCBLKS
      RETURN
C NSTACK
1060  N = RSTCK1 + PMXRST-RSTCK2+1
      RETURN
C NSTACK1
1070  N = RSTCK1
      RETURN
C NSTACK2
1080  N = PMXRST-RSTCK2+1
      RETURN
C NZROW
1090  CALL GETRIM('ROW ',RULROW,VL,VU,VC,N)
      RETURN
C NZCOL
1100  CALL GETRIM('COL ',RULROW,VL,VU,VC,N)
      RETURN
C NZRSUB
1110  N = 0
      DO 1115 COLUMN=1,NCOLS
         CALL GETMAP('COL ',COLUMN,SW)
         IF(.NOT.SW)GOTO 1115
         CALL GETCOL(COLUMN,NZ,MAXLST,ROWLST,VALLST)
         IF(NZ.EQ.0)GOTO 1115
         DO 1113 I=1,NZ
            IF(ROWLST(I).EQ.RULROW)THEN
               N = N+1
               GOTO 1115
            ENDIF
1113     CONTINUE
1115  CONTINUE
      RETURN
C NZCSUB
1120  N = 0
      CALL GETCOL(RULCOL,NZ,MAXLST,ROWLST,VALLST)
      IF(NZ.EQ.0)RETURN
      DO 1125 I=1,NZ
         ROW = ROWLST(I)
         CALL GETMAP('ROW ',ROW,SW)
         IF(SW)N=N+1
1125  CONTINUE
      RETURN
1130  N = NONES
      RETURN
1140  N = NVALS
      RETURN
1150  N = NRSYN
      RETURN
1160  N = NCSYN
      RETURN
1170  N = NENTY
      RETURN
1180  N = NVECTR
      RETURN
1190  N = NAMELN
      RETURN
2000  CONTINUE
C NTAB HAS INDEX SPEC = IND (SET BY CALLER)
      IF( IND.GE.1 .AND. IND.LE.NTABS )THEN
         N = NTAB(IND)
      ELSE
C CALLER CHECKED INDEX VALUE
         PRINT *,' ** SYSERR...RUGETN NTAB, IND =',IND
         RCODE = 1
      ENDIF
      RETURN
C
C ** RUGETN ENDS HERE
      END
      SUBROUTINE RUGETC(RNAME,STRING,RCODE)
C     =================
      IMPLICIT INTEGER (A-U), DOUBLE PRECISION (Z)
C
      INCLUDE 'DCANAL.'
      INCLUDE 'DCRULE.'
CITSO      INCLUDE (DCANAL)
CITSO      INCLUDE (DCRULE)
CI$$INSERT DCANAL
CI$$INSERT DCRULE
C
C This gets value of character keyword (RNAME) and puts into STRING
C
      CHARACTER*(*) STRING
      CHARACTER*16  RNAME
C LOCAL
      CHARACTER*1   CHAR
C :::::::::::::::::::::: BEGIN ::::::::::::::::::::::
C LOOKUP KEY
      DO 100 K=1,NRUCHR
         IF( RNAME.EQ.RULCHR(K) )GOTO 190
100   CONTINUE
      PRINT *,' ** RULEBASE ERROR...UNABLE TO FIND %',RNAME
      RCODE = 1
      RETURN
C
190   CONTINUE
      IF( K.EQ.NRUCHR )GOTO 1200
      RCODE = 0
C         BRANCH ON KEY TO SET CNAME
      GOTO(1010,1020,1030,1040,1050,1060,1070,1080,1090,1100,1110),K
1010  STRING = PRBNAM
      RETURN
1020  STRING = RHSNAM
      RETURN
1030  STRING = BNDNAM
      RETURN
1040  STRING = RNGNAM
      RETURN
1050  STRING = OBJNAM
      RETURN
1060  STRING = OPTNAM
      RETURN
1070  IF(RULROW.LE.0.OR.RULROW.GT.NROWS)THEN
         STRING = ' '
      ELSE
         CALL GETNAM('ROW ',RULROW,STRING)
      ENDIF
      RETURN
1080  IF(RULCOL.LE.0.OR.RULCOL.GT.NCOLS)THEN
         STRING = ' '
      ELSE
         CALL GETNAM('COL ',RULCOL,STRING)
      ENDIF
      RETURN
1090  STRING = SOLST
      RETURN
1100  IF( RULROW.LE.0.OR.RULROW.GT.NROWS )THEN
         STRING = ' '
      ELSE
         CALL GETST('ROW ',RULROW,CHAR,STNUM)
         STRING = CHAR
      ENDIF
      RETURN
1110  IF( RULCOL.LE.0.OR.RULCOL.GT.NCOLS )THEN
         STRING = ' '
      ELSE
         CALL GETST('COL ',RULCOL,CHAR,STNUM)
         STRING = CHAR
      ENDIF
      RETURN
C
1200  CONTINUE
C _NAME PARAM HAS INDEX SPEC = RCODE
      IF( RCODE.GE.-1 .AND. RCODE.LE.NVECTR )THEN
CC                 :...4-15-94
         STRING = VECNAM(RCODE)
         RCODE = 0
      ELSE
C CALLER CHECKED INDEX VALUE (IN RUGETI)
         PRINT *,' ** SYSERR...RCODE =',RCODE
         RCODE = 1
      ENDIF
      RETURN
C
C ** RUGETC ENDS HERE
      END
      SUBROUTINE RUGETV(RNAME,STRING,RCODE)
C     =================
      IMPLICIT INTEGER (A-U), DOUBLE PRECISION (Z)
C
      INCLUDE 'DCANAL.'
      INCLUDE 'DCRULE.'
CITSO      INCLUDE (DCANAL)
CITSO      INCLUDE (DCRULE)
CI$$INSERT DCANAL
CI$$INSERT DCRULE
C
C This gets value of value keyword (RNAME) and puts into STRING (>= 12)
C If RNAME = VECTOR, RCODE = I (Reference was to %VECTOR(I)).
C
      CHARACTER*(*) STRING
      CHARACTER*16  RNAME
C LOCAL
      CHARACTER*1   CHAR
      INTEGER STNUM
C ::::::::::::::::::::::: BEGIN ::::::::::::::::::::::::
C LOOKUP KEY
      DO 100 K=1,NRUVAL
         IF(RNAME.EQ.RULVAL(K))GOTO 190
100   CONTINUE
      PRINT *,' RULEBASE ERROR...UNABLE TO FIND %V ',RNAME
      RCODE = 1
      RETURN
C
190   CONTINUE
      IF( K.EQ.NRUVAL )GOTO 1200
      RCODE = 0
C         BRANCH ON KEY TO SET STRING
      GOTO(1010,1020,1030,1040,1050,1060,1070,1080,1090,1100,1110,
     1     1120),K
1010  CALL GETBND('ROW ',RULROW,V,VU)
      GOTO 2000
1020  CALL GETBND('ROW ',RULROW,VL,V)
      GOTO 2000
1030  CALL GETRIM('ROW ',RULROW,VL,VU,V,NZ)
      GOTO 2000
1040  CALL GETSOL('ROW ',RULROW,V,VP,CHAR,STNUM)
      GOTO 2000
1050  CALL GETSOL('ROW ',RULROW,VX,V,CHAR,STNUM)
      GOTO 2000
1060  CALL GETBND('COL ',RULCOL,V,VU)
      GOTO 2000
1070  CALL GETBND('COL ',RULCOL,VL,V)
      GOTO 2000
1080  CALL GETRIM('COL ',RULCOL,VL,VU,V,NZ)
      GOTO 2000
1090  CALL GETSOL('COL ',RULCOL,V,VP,CHAR,STNUM)
      GOTO 2000
1100  CALL GETSOL('COL ',RULCOL,VX,V,CHAR,STNUM)
      GOTO 2000
1110  V = VLOOK
      GOTO 2000
1120  V = NROWS*NCOLS
      V = 100.0*NONZER/V
      GOTO 2000
C VECTOR HAS INDEX SPEC = RCODE
1200  CONTINUE
      IF( RCODE.GE.-1 .AND. RCODE.LE.NVECTR )THEN
CC                 :...4-14-94
         V = VECTOR(RCODE)
         RCODE = 0
      ELSE
C CALLER CHECKED INDEX VALUE (IN RUGETI)
         PRINT *,' ** SYSERR...RCODE =',RCODE
         RCODE = 1
         RETURN
      ENDIF
C
2000  CONTINUE
C CONVERT VALUE (V) TO STRING
      STRING = ' '
      CALL FR2CLJ(STRING,V,LAST)
      RETURN
C
C ** RUGETV ENDS HERE
      END
      SUBROUTINE RUGETS(RNAME,STRING,RCODE)
C     =================
      IMPLICIT INTEGER (A-U), DOUBLE PRECISION (Z)
C
      INCLUDE 'DCFLIP.'
      INCLUDE 'DCANAL.'
      INCLUDE 'DCRULE.'
CITSO      INCLUDE (DCFLIP)
CITSO      INCLUDE (DCANAL)
CITSO      INCLUDE (DCRULE)
CI$$INSERT DCFLIP
CI$$INSERT DCANAL
CI$$INSERT DCRULE
C                DCFLIP NEEDED FOR FILE UNITS
C
C This gets value of switch keyword (RNAME) and puts into STRING
C
      CHARACTER*(*) STRING
      CHARACTER*16  RNAME
C LOCAL
      LOGICAL*1     SW
C :::::::::::::::::::::::::::: BEGIN :::::::::::::::::::::::::::::::::
C LOOKUP KEY
      DO 100 K=1,NRUSWK
         IF( RNAME.EQ.RULSWK(K) )GOTO 190
100   CONTINUE
      PRINT *,' RULEBASE ERROR...UNABLE TO FIND %SW ',RNAME
      RCODE = 1
      RETURN
C
190   CONTINUE
      RCODE = 0
C         BRANCH ON KEY TO SET STRING
C         ===========================
      GOTO(1010,1020,1030,1040,1050),K
C SWMSG = MESSAGE SWITCH (DCANAL)
1010  SW = SWMSG
      GOTO 2000
C SWOTFIL = OUTPUT GOING TO FILE (UNITS OUTPUT AND TTYOUT FROM DCFLIP)
1020  SW = (OUTPUT.NE.TTYOUT)
      GOTO 2000
C SWINFIL = INPUT COMING FROM FILE (UNITS INPUT AND TTYIN FROM DCFLIP)
1030  SW = (INPUT.NE.TTYIN)
      GOTO 2000
C SWRATE = RATE/BASIS SWITCH (DCANAL)
1040  SW = SWRATE
      GOTO 2000
C SWSYN = SYNTAX
1050  SW = SWEXPL
C FALL THRU TO 2000 TO PUT SWITCH VALUE (SW) INTO STRING
C
2000  CONTINUE
C CONVERT VALUE (SW) TO STRING (STRING)
      STRING = ' '
      IF( SW )THEN
         STRING = 'T'
      ELSE
         STRING = 'F'
      ENDIF
      RETURN
C
C ** RUGETS ENDS HERE
      END
      SUBROUTINE RUGETI(CLIST,FIRST,LAST,I,RCODE)
C     =================
      IMPLICIT INTEGER (A-U), DOUBLE PRECISION (Z)
C
      INCLUDE 'DCANAL.'
      INCLUDE 'DCRULE.'
CITSO      INCLUDE (DCANAL)
CITSO      INCLUDE (DCRULE)
CI$$INSERT DCANAL
CI$$INSERT DCRULE
C
C This gets index spec (I) from CLIST(FIRST:LAST)
C
      CHARACTER*128 CLIST
C LOCAL
      CHARACTER*16  CNAME,STRVAL
      CHARACTER*1   CHAR
C :::::::::::::::::::::::::: BEGIN :::::::::::::::::::::::::::::::
      IF( CLIST(FIRST:FIRST).EQ.'(' )FIRST = FIRST+1
      CALL FTOKEN(CLIST,FIRST,LAST,STRVAL,9,CHAR)
      IF( STRVAL.EQ.' ' )THEN
         PRINT *,' ** MISSING INDEX SPEC'
         GOTO 1399
      ENDIF
      IF( CHAR.NE.')' )THEN
C ADVANCE FIRST PAST ) FOR CALLER
         CALL FLOOKF(CLIST,FIRST,LAST,')',I)
         IF( I.EQ.0 )THEN
            PRINT *,' ** MISSING ) IN INDEX SPEC'
            GOTO 1399
         ENDIF
         FIRST = I+1
      ENDIF
C STRVAL = INDEX SPEC
      IF( STRVAL(9:9).NE.' ' )GOTO 1300
      IF( STRVAL(1:1).EQ.'%' )THEN
C SPEC = PARAM
         IF( STRVAL(2:2).EQ.'%' )THEN
C ...USER PARAM
            CNAME = STRVAL(3:)
            CALL RUGETP(CNAME,STRVAL,RCODE)
         ELSE IF( STRVAL(2:2).EQ.'N' )THEN
C ...INTRINSIC INTEGER PARAM
            CNAME = STRVAL(2:)
            CALL RUGETN(CNAME,I,RCODE)
            IF( RCODE.EQ.0 )GOTO 500
         ELSE
            GOTO 1300
         ENDIF
         IF( RCODE.NE.0 )RETURN
      ENDIF
C STRVAL = STRING OF INTEGER VALUE
      IF( STRVAL.EQ.'-1 ')THEN
         I = -1
      ELSE
         CALL FC2I(STRVAL,8,I,RCODE)
         IF( RCODE.NE.0 )RETURN
      ENDIF
C I = INDEX VALUE
500   CONTINUE
      IF( I.LT.-1 .OR. I.GT.NVECTR )THEN
CC             :...4-15-94
         PRINT *,' ** INDEX OUT OF RANGE...',I
         IF( NVECTR.EQ.0 )THEN
            PRINT *,' %NVECTOR = 0, SO VECTOR IS NULL'
         ELSE
            PRINT *,' ...SHOULD BE -1 TO %NVECTOR =',NVECTR
CC                                 :
         ENDIF
         GOTO 1399
      ENDIF
C
      RETURN
C
1300  PRINT *,' ** ',STRVAL(:9),' NOT RECOGNIZED'
1399  RCODE = 1
      RETURN
C
C ** RUGETI ENDS HERE
      END
      SUBROUTINE RUPUTP(CLIST,FIRST,LAST,RCODE)
C     =================
      IMPLICIT INTEGER (A-U), DOUBLE PRECISION (Z)
C
      INCLUDE 'DCANAL.'
      INCLUDE 'DCRULE.'
CITSO      INCLUDE (DCANAL)
CITSO      INCLUDE (DCRULE)
CI$$INSERT DCANAL
CI$$INSERT DCRULE
C
C This sets parameter key = value, parsed from CLIST(FIRST:LAST)
C
      CHARACTER*128 CLIST
C LOCAL
      CHARACTER*16  RNAME
      CHARACTER*1   CHAR,STR1
C :::::::::::::::::::::::::: BEGIN :::::::::::::::::::::::::::::::
C PARSE PARAMETER KEY
      CALL FTOKEN(CLIST,FIRST,LAST,RNAME,7,STR1)
      IF(RNAME.EQ.' ')THEN
         PRINT *,' ** RULEBASE ERROR...SET NEEDS PARAMETER NAME'
         GOTO 13
      ENDIF
      IF(RNAME(7:7).NE.' ')THEN
        PRINT *,' ** RULEBASE ERROR...PARAMETER NAME TOO LONG: ',RNAME
        GOTO 13
      ENDIF
C CHECK NAME (MUST HAVE NO SPECIAL CHARS)
      CALL FSLEN(RNAME,6,L)
      DO 10 K=1,L
         CHAR = RNAME(K:K)
         IF(CHAR.EQ.'%'.OR.CHAR.EQ.'%'.OR.CHAR.EQ.'*')THEN
            PRINT *,' ** RULEBASE ERROR...PARAMETER NAME CANNOT',
     1              ' HAVE ',CHAR
            GOTO 13
         ENDIF
10    CONTINUE
C OK
      IF(NRUPRM.EQ.0)GOTO 90
C
C LOOKUP PARAMETER KEY
C
      DO 50 K=1,NRUPRM
50    IF(RUPNAM(K).EQ.RNAME)GOTO 100
C
C MUST ADD NEW PARAMETER
C ...FIRST CHECK WE HAVE ROOM
      IF(NRUPRM.EQ.MAXRUP)THEN
         PRINT *,' ** RULEBASE ERROR...PARAMETER LIMIT REACHED...',
     1            MAXRUP
         GOTO 13
      ENDIF
C OK, ADD NEW PARAMETER
90    NRUPRM = NRUPRM + 1
      K = NRUPRM
      RUPNAM(K) = RNAME
C
C SET VALUE OF PARAMETER K
100   CONTINUE
C SKIP LEADING BLANKS
      IF( CLIST(FIRST:FIRST).EQ.' ' )THEN
         IF( FIRST.GT.LAST )THEN
C ...VALUE IS NULL
            IF( STR1.EQ.' ' )THEN
C ...DELETE PARAMETER
               RUPNAM(K) = RUPNAM(NRUPRM)
               RUPVAL(K) = RUPVAL(NRUPRM)
               NRUPRM = NRUPRM-1
            ELSE
C SET PARAMETER VALUE = NULL
               RUPVAL(K) = ' '
            ENDIF
            RETURN
         ENDIF
         FIRST = FIRST+1
         GOTO 100
      ENDIF
C NOW VALUE = CLIST(FIRST:LAST), WHERE 1ST CHAR IS NOT BLANK
      IF( LAST-FIRST.LT.16 )THEN
         RUPVAL(K) = CLIST(FIRST:LAST)
         RETURN
      ENDIF
C
      PRINT *,' ** RULEBASE ERROR...PARAMETER '//RUPNAM(K)//
     1        ' VALUE TOO LONG'
      PRINT *,' ...'//CLIST(FIRST:LAST)//' EXCEEDS 16 CHARS'
C
C ERROR RETURN
13    RCODE = 1
      RETURN
C
C ** RUPUTP ENDS HERE
      END
      SUBROUTINE RUGETP(RNAME,STRVAL,RCODE)
C     =================
      IMPLICIT INTEGER (A-U), DOUBLE PRECISION (Z)
C
      INCLUDE 'DCANAL.'
      INCLUDE 'DCRULE.'
CITSO      INCLUDE (DCANAL)
CITSO      INCLUDE (DCRULE)
CI$$INSERT DCANAL
CI$$INSERT DCRULE
C
C This gets parameter value from key (RNAME) and puts into STRVAL
C
      CHARACTER*(*) STRVAL
      CHARACTER*16  RNAME
C :::::::::::::::::::::::::: BEGIN :::::::::::::::::::::::::::::::
      IF(NRUPRM.EQ.0)GOTO 1300
C LOOK UP PARAMETER
      DO 100 K=1,NRUPRM
         IF(RNAME.EQ.RUPNAM(K))THEN
            STRVAL = RUPVAL(K)
            RETURN
         ENDIF
100   CONTINUE
C
1300  PRINT *,' ** RULEBASE ERROR...UNABLE TO FIND PARAMETER %%',RNAME
      RCODE = 1
      RETURN
C
C ** RUGETP ENDS HERE
      END
      SUBROUTINE RULATX(CLIST,LINE,*)
C     =================
      IMPLICIT INTEGER (A-U), DOUBLE PRECISION (Z)
C
      INCLUDE 'DCANAL.'
      INCLUDE 'DCRULE.'
CITSO      INCLUDE (DCANAL)
CITSO      INCLUDE (DCRULE)
CI$$INSERT DCANAL
CI$$INSERT DCRULE
C
C This adds text CLIST to RULTXT
C ...and shifts punctuation following blank
C
      CHARACTER*(*) CLIST
C LOCAL
      CHARACTER*128 CTEMP
      CHARACTER*8   STR8
      CHARACTER*1   CHAR,CHAR0
C :::::::::::::::::::::: BEGIN :::::::::::::::::::::::::::::
C REDUCE RULE TEXT, IF FULL
      IF(ENDTXT.GE.120)
     1   CALL FTEXT(RULTXT,ENDTXT,MARGIN,INDENT,LINE,'KEEP',*9000)
      CTEMP = CLIST
      CALL FSLEN(CTEMP,128,LAST)
      IF( LAST.EQ.0 )RETURN
      RCODE = 0
C COPY CLIST TO CTEMP, OMITTING LEADING AND DOUBLE BLANKS
CC AND RECOGNIZING TABS (%T#%)
      CTEMP = ' '
      CHAR0 = ' '
      K = 0
      I = 1
1     CONTINUE
        CHAR = CLIST(I:I)
        IF( CHAR.EQ.' '.AND.CHAR0.EQ.' ' )GOTO 4
        IF( CLIST(I:I+1).EQ.'%T' )THEN
CC TAB
           I1 = I+2
           CALL FLOOKF(CLIST,I1,I1+3,'%',I)
           IF( I.EQ.0 )THEN
              PRINT *,' ** SYSERR RULATX TAB ',CLIST(I1:I1+3)
              GOTO 9000
           ELSE
              CLIST(I:I) = ' '
           ENDIF
           CALL FTOKEN(CLIST,I1,LAST,STR8,8,CHAR)
           CALL FC2I(STR8,8,K,RCODE)
           IF( RCODE.NE.0 )THEN
              PRINT *,' ** SYSERR RULATX TAB ',STR8,' ',RCODE
              GOTO 9000
           ENDIF
CC DECREASE K TO SUPERIMPOSE ON RULTXT (OR MUST GO TO NEW LINE)
           IF( K.GT.ENDTXT )K = K - ENDTXT
        ELSE
           K = K+1
           CTEMP(K:) = CHAR
           CHAR0 = CHAR
        ENDIF
4     CONTINUE
      IF( I.LT.LAST )THEN
         I = I+1
         GOTO 1
      ENDIF
C
      IF( K.EQ.0 )RETURN
      LAST = K
C LOOP TO SHIFT PUNCTUATION
      CLIST = CTEMP
      CHAR0 = CLIST(1:1)
      FIRST = 2
      IF( CHAR0.EQ.'.' .OR. CHAR0.EQ.','.OR.CHAR0.EQ.')'.OR.
     C    CHAR0.EQ.';' )THEN
         IF(CLIST(1:3).NE.'...')THEN
C PUT PUNCTUATION AT END OF CURRENT RULE TEXT
C (NOTE:  WE DO NOT SHIFT ELLIPSIS ...)
            ENDTXT = ENDTXT+1
            RULTXT(ENDTXT:) = CHAR0
            CHAR0 = CLIST(2:2)
            FIRST = 3
         ENDIF
      ENDIF
      K = 1
      CTEMP = CHAR0
C NOW CHAR0//CLIST(FIRST:LAST) CONTAINS THE NEW TEXT.
      DO 5 I=FIRST,LAST
         CHAR = CLIST(I:I)
         IF( CHAR0.EQ.' ' .AND. (CHAR.EQ.'.' .OR.
     C                           CHAR.EQ.',' .OR.
     C                           CHAR.EQ.':' .OR.
     C                           CHAR.EQ.')' .OR.
     C                           CHAR.EQ.';' ) ) THEN
C OVERWRITE PREVIOUS BLANK WITH PUNCTUATION
            CTEMP(K:K) = CHAR
         ELSE
C ADD NEW CHAR
            K = K+1
            CTEMP(K:K) = CHAR
         ENDIF
         CHAR0 = CHAR
5     CONTINUE
C
      CALL FSLEN(RULTXT,128,ENDTXT)
      IF(ENDTXT.EQ.0)THEN
         RULTXT = CTEMP
         GOTO 900
      ENDIF
      CHAR = RULTXT(ENDTXT:ENDTXT)
      IF(CHAR.EQ.'.')THEN
C ADD BLANK AFTER PERIOD
         ENDTXT = ENDTXT+1
         RULTXT(ENDTXT:) = ' '
      ENDIF
C WE NOW HAVE TEXT = RULTXT(:ENDTXT) + CTEMP
C                                      :...= NEW TEXT WITH LEADING
C                                            AND DOUBLE BLANKS REMOVED
      IF(CHAR.NE.' '.AND.CTEMP(1:1).NE.' ')THEN
C INSERT BLANK BETWEEN RULTXT AND CTEMP
         ENDTXT = ENDTXT+1
         RULTXT(ENDTXT:) = ' '
      ELSE IF(CHAR.EQ.' '.AND.CTEMP(1:1).EQ.' ')THEN
C  OMIT DOUBLE BLANK
C         ENDTXT = ENDTXT-1
      ENDIF
      CALL FSLEN(CTEMP,128,LAST)
      IF(ENDTXT+LAST.LE.128)THEN
         RULTXT(ENDTXT+1:) = CTEMP
         GOTO 900
      ENDIF
C XFER AS MUCH AS POSSIBLE FROM CTEMP TO RULTXT
      DO 250 I=128-ENDTXT,1,-1
         CHAR = CTEMP(I:I)
         IF(CHAR.EQ.' '.OR.CHAR.EQ.','.OR.CHAR.EQ.';'.OR.
     1      CHAR.EQ.')')GOTO 300
250   CONTINUE
300   RULTXT(ENDTXT+1:) = CTEMP(1:I)
      ENDTXT = ENDTXT + I
      CALL FTEXT(RULTXT,ENDTXT,MARGIN,INDENT,LINE,'KEEP',*9000)
      IF(ENDTXT.GT.0)THEN
         IF(RULTXT(ENDTXT:ENDTXT).NE.' ')ENDTXT = ENDTXT+1
      ENDIF
      RULTXT(ENDTXT+1:) = CTEMP(I+1:)
C
900   CONTINUE
      CALL FSLEN(RULTXT,128,ENDTXT)
      IF( ENDTXT.EQ.0 )RETURN
      IF(RULTXT(ENDTXT:ENDTXT).EQ.'.' .AND. ENDTXT.GT.1)THEN
         IF(RULTXT(ENDTXT-1:ENDTXT-1).EQ.' ')THEN
            ENDTXT = ENDTXT-1
            RULTXT(ENDTXT:) = '.'
         ENDIF
      ENDIF
      RETURN
C
9000  RETURN 1
C
C ** RULATX ENDS HERE
      END
