C              ::: ASCHMA.FOR  4-22-95 :::
C
C Dates: Earlier log deleted
C        3-19-94...Enhanced SYNTAX GENERATE (EXGENR)
C        7-23-94...Added pauses in ASCHDO if truncation messages
C
C This contains routines to support the SCHEMA command in ANALYZE
C (does not include SCHEMA.FOR routines).
C
C     ASCHMA.....executes SCHEMA command (link with outside world)
C     ASCHDO.....forms schema from syntax information
C     EXDOMN.....puts domain referenced in syntax map
C     EXDSPD.....displays domain sets
C     ASTRIP.....finds row or column strip number from LP name
C     EXGENR.....executes SYNTAX GENERATE command...ADDED 7-2-93
C     EXPARS.....parses domain set (called only by EXGENR)
C     EXAMEM.....adds set member (called only by EXGENR)
C
      SUBROUTINE ASCHMA(CLIST,FIRST,LAST,RCODE)
C     =================
      IMPLICIT INTEGER (A-U), DOUBLE PRECISION (Z)
C
      INCLUDE 'DCANAL.'
      INCLUDE 'DCSCHEMA.'
CITSO      INCLUDE (DCANAL)
CITSO      INCLUDE (DCSCHEMA)
CI$$INSERT DCANAL
CI$$INSERT DCSCHEMA
C
C This executes SCHEMA command from ANALYZE.
C    Syntax: SCHEMA [DISPLAY [options] | CLEAR | ERASE {ROW|COL} class
C                  |{LOAD SAVE} [filespec] ]
C NO OPTION JUST SETS SCHEMA (SUMMARY INFO GIVEN IF NOT IN RULE FILE)
      CHARACTER*128 CLIST
C LOCAL
      CHARACTER*1  CHAR
      CHARACTER*4  ROWCOL
      CHARACTER*8  OPTION(5),STR8
      LOGICAL      SWHEAD
      LOGICAL*1    PICK(3),SWSUM
C :::::::::::::::::::::::::::: BEGIN ::::::::::::::::::::::::::::::::::
C SEE IF SPECIAL OPTION (FOLLOWING //) IS PRESENT
      CALL FLOOK(CLIST,FIRST,LAST,'//',IOPTN)
      IF(IOPTN.GT.0)THEN
         LOPTN = LAST
         LAST = IOPTN-1
         IOPTN= IOPTN+2
      ENDIF
C GET OPTION
      OPTION(1) = 'DISPLAY'
      OPTION(2) = 'LOAD '
      OPTION(3) = 'SAVE '
      OPTION(4) = 'CLEAR '
      OPTION(5) = 'ERASE '
      NUMBER = 5
      CALL FOPTN(CLIST,FIRST,LAST,OPTION,NUMBER,RCODE)
      IF( RCODE.NE.0 )RETURN
      IF( NUMBER.EQ.0 )THEN
C JUST GIVE SCHEMA DIMENSIONS
         IF( SCHNR.LE.0 .OR. SCHNC.LE.0 )THEN
C ...FIRST SET SCHEMA
            CALL ASCHDO(RCODE)
            IF( RCODE.NE.0 )GOTO 400
         ENDIF
C ...SUPPRESS SCHEMA DIMENSION MESSAGE IF IN RULE FILE
C    (CALLER JUST WANTS TO SET SCHEMA)
         IF( .NOT.SWRULE )CALL SCHSUM
         RETURN
      ENDIF
C
C BRANCH ON PRIMARY OPTION
      GOTO(100,200,300,400,500),NUMBER
C
100   CONTINUE
C DISPLAY [{TABLE, DOMAINS, EQUATION [//{SUM | NOSUM | NOHEAD}]}]
C                                          :...DEFAULT  10-22
C GET PRIMARY OPTIONS
      OPTION(1) = 'TABLE  '
      OPTION(2) = 'EQUATION'
      OPTION(3) = 'DOMAINS'
      NUMBER = 3
      CALL FOPSET(CLIST,FIRST,LAST,OPTION,NUMBER,PICK,RCODE)
      IF(RCODE.NE.0)RETURN
C SET DEFAULT TO INCLUDE 'Sum'
      SWSUM = .TRUE.
      SWHEAD= (SCHNR.LT.20)
CC          :...PRINT HEADER AS DEFAULT IFF NUMBER OF ROWS < 20
CC              (ELSE, SUPPRESS HEADER)...REPLACES WHEN SWRULE=T
      IF(IOPTN.GT.0)THEN
C GET SPECIAL OPTION FOLLOWING //
         OPTION(1) = 'SUM  '
         OPTION(2) = 'NOSUM'
         OPTION(3) = 'NOHEAD'
         RCODE = -1
150      CONTINUE
           N = 3
           CALL FOPTN(CLIST,IOPTN,LOPTN,OPTION,N,RCODE)
           IF(RCODE.NE.0)GOTO 1390
           IF( N.EQ.0 )GOTO 159
           IF( N.LT.3 )THEN
              SWSUM = N.EQ.1
           ELSE
              SWHEAD=.FALSE.
           ENDIF
          GOTO 150
159      CONTINUE
      ENDIF
C
      IF( .NOT.PICK(2) .AND. .NOT.PICK(3) )PICK(1) = .TRUE.
C (DEFAULT DISPLAY IS TABLE ONLY)
      IF(SCHNR.LE.0 .OR. SCHNC.LE.0)THEN
C SET SCHEMA
         CALL ASCHDO(RCODE)
         IF(RCODE.NE.0)RETURN
      ENDIF
      LINE = 1
C
      IF(PICK(1))THEN
C DISPLAY TABLE
         CALL SCHDSP(LINE,SWHEAD,RCODE)
CC 10-22                  :...WAS LGL4
         IF(RCODE.NE.0)RETURN
      ENDIF
C
      IF(PICK(2))THEN
C DISPLAY EQUATION
         IF( SCHCOL(SCHNC).EQ.RHSNAM .OR. SCHCOL(SCHNC).EQ.' ' )THEN
            RHS = 1
         ELSE
            RHS = 0
         ENDIF
         CALL FLOOK(SCHROW(SCHNR),1,14,':UP',BOUND)
         IF(BOUND.GT.0)BOUND = 2
         CALL SCHEQN(LINE,BOUND,RHS,SWSUM,*190)
      ENDIF
      IF( PICK(3) )CALL EXDSPD(LINE)
190   RETURN
C
200   CONTINUE
C LOAD [filespec]
      CALL SCHFIL(CLIST,FIRST,LAST,'UNFORMATTED',
     1            PCKFIL,NAMLEN,PRBNAM, RCODE)
      IF(RCODE.EQ.0)CALL SCHRDP(PCKFIL,RCODE)
      CLOSE(PCKFIL)
      RETURN
C
300   CONTINUE
C SAVE [filespec]
      CALL SCHFIL(CLIST,FIRST,LAST,'UNFORMATTED',
     1            PCKFIL,NAMLEN,PRBNAM, RCODE)
      IF(RCODE.EQ.0)CALL SCHWRP(PCKFIL,RCODE)
      CLOSE(PCKFIL)
      IF(SWMSG.AND.RCODE.EQ.0)PRINT *,' SCHEMA FILE WRITTEN'
      RETURN
C
400   CONTINUE
C CLEAR
      SCHNR = 0
      SCHNC = 0
      RETURN
C
500   CONTINUE
C ERASE {ROW|COL} class
      CALL AGETRC(CLIST,FIRST,LAST,ROWCOL,RCODE)
      IF( RCODE.NE.0 )RETURN
      CALL FTOKEN(CLIST,FIRST,LAST,STR8,8,CHAR)
      IF( STR8.EQ.' ' )THEN
         PRINT *,' ** MISSING ',ROWCOL,' CLASS'
         RCODE = 1
      ELSE
         CALL SCHDEL(ROWCOL,STR8,RCODE)
      ENDIF
      RETURN
C ERROR RETURN
1390  PRINT *,' ...SCHEMA ABORTED'
      RCODE = 1
      RETURN
C
C ** ASCHMA ENDS HERE
      END
      SUBROUTINE ASCHDO(RCODE)
C     =================
      IMPLICIT INTEGER (A-U), DOUBLE PRECISION (Z)
C
      INCLUDE 'DCANAL.'
      INCLUDE 'DCSCHEMA.'
CITSO      INCLUDE (DCANAL)
CITSO      INCLUDE (DCSCHEMA)
CI$$INSERT DCANAL
CI$$INSERT DCSCHEMA
C
C This forms schema from syntax information.
C
C LOCAL
      CHARACTER*128 CLIST
      CHARACTER*16  RNAME,CNAME
      CHARACTER*1   CHAR
      LOGICAL*1     SW,SWP
C
      REAL  DATMIN(PMSROW,PMSCOL),DATMAX(PMSROW,PMSCOL)
C ::::::::::::::::::::::::::: BEGIN :::::::::::::::::::::::::::::::::
      IF( .NOT.SWEXPL )THEN
         PRINT *,' ** SYNTAX NOT IN MEMORY'
         GOTO 1300
      ENDIF
      IF( NRSYN.LT.1 .OR. NRSYN.GT.PMSROW .OR.
     1    NCSYN.LT.1 .OR. NCSYN.GT.PMSCOL )THEN
         PRINT *,' ** NUMBER OF ROW/COLUMN CLASSES OUT OF RANGE'
         PRINT *,'    MAX ROWS =',PMSROW-1,' MAX COLS =',PMSCOL-1
         GOTO 1300
      ENDIF
C
C FORM ROW STRIPS
      SCHNR = NRSYN
      SCHRLN= 0
      SWP   = .FALSE.
C       :...PAUSE SWITCH IF MESSAGES ARE WRITTEN
C
      DO 100 I=1,SCHNR
         CLIST = EXKEY(IRSYN+I)
         CALL FSLEN(CLIST,16,LAST)
C GET ROW CLASS' DOMAIN
         CALL EXDOMN(CLIST,LAST,IRSYN+I,RCODE)
         IF( RCODE.NE.0 )GOTO 1300
         IF( LAST.GT.16 )THEN
            PRINT *,' HAD TO TRUNCATE ROW STRIP ',CLIST(:LAST)
            LAST = 16
            CLIST(17:) = ' '
            SWP = .TRUE.
         ENDIF
C ADD ROW STRIP NAME
         SCHROW(I) = CLIST(:LAST)
C ...UPDATE ROW'S NAME LENGTH (SCHRLN)
         IF(SCHRLN.LT.LAST)SCHRLN=LAST
100   CONTINUE
C
      IF( SWP )THEN
         PRINT *,' OK TO CONTINUE? '
         CALL FGTCHR('YN','Y',CHAR)
         IF( CHAR.NE.'Y' )GOTO 1300
         SWP = .FALSE.
      ENDIF
      IF(SCHROW(SCHNR)(1:1).EQ.EXCHAR)THEN
         ROWILD = SCHNR
         SCHROW(SCHNR) = 'other'
      ELSE
         ROWILD = 0
      ENDIF
C
      IF( SCHNR.LT.PMSROW )THEN
C ADD OBJECTIVE AS ROW STRIP
         SCHNR = SCHNR+1
         SCHROW(SCHNR) = OBJNAM
         CALL FSLEN(OBJNAM,16,LAST)
         IF( SCHRLN.LT.LAST )SCHRLN=LAST
         SW = .TRUE.
      ENDIF
C
C FORM COLUMN STRIPS
      SCHNC = NCSYN
      SCHCLN= 0
C
      DO 200 J=1,SCHNC
         CLIST = EXKEY(ICSYN+J)
         CALL FSLEN(CLIST,8,LAST)
C GET COLUMN CLASS'S DOMAIN
         CALL EXDOMN(CLIST,LAST,ICSYN+J,RCODE)
         IF( RCODE.NE.0 )THEN
            IF( SWDBG )PRINT *,' IN 200, J=',J,' EXKEY=',EXKEY(ICSYN+J)
            GOTO 1300
         ENDIF
         IF( LAST.GT.16 )THEN
            PRINT *,' HAD TO TRUNCATE COLUMN STRIP ',CLIST(:LAST)
            LAST = 16
            CLIST(17:) = ' '
            SWP = .TRUE.
         ENDIF
         SCHCOL(J) = CLIST(:LAST)
         IF( SCHCLN.LT.LAST )SCHCLN=LAST
200   CONTINUE
C
      IF( SWP )THEN
         PRINT *,' OK TO CONTINUE? '
         CALL FGTCHR('YN','Y',CHAR)
         IF( CHAR.NE.'Y' )GOTO 1300
         SWP = .FALSE.
      ENDIF
      IF( SCHCOL(SCHNC)(1:1).EQ.EXCHAR )THEN
         COWILD = SCHNC
         SCHCOL(SCHNC) = 'other'
      ELSE
         COWILD = 0
      ENDIF
C
C FORM DATA (CELL) ENTRIES
C
C INITIALIZE TO BLANK
      DO 300 I=1,SCHNR
      DO 300 J=1,SCHNC
         SCHDAT(I,J) = ' '
C ...AND NONZERO RANGE
         DATMIN(I,J) = VINF
         DATMAX(I,J) = -VINF
300   CONTINUE
C
C   ::: LOOP OVER NONZEROES TO FORM RANGE STATEMENT IN DATA CELLS :::
C
      DO 900 J=1,NCOLS
         CALL GETCOL(J,NZ,PMXROW,ROWLST,VALLST)
         IF( NZ.EQ.0 )GOTO 900
         CALL GETNAM('COL ',J,CNAME)
         CALL ASTRIP('COL ',CNAME,COLSTR)
         IF( COLSTR.EQ.0 )THEN
C NOT IN ANY CLASS...SEE IF WILD CHAR WAS SPECIFIED
            IF( COWILD.EQ.0 )GOTO 900
            COLSTR = COWILD
         ENDIF
C NOW COLSTR = COLUMN STRIP NUMBER
C
C    ::: LOOP OVER COLUMN (J) NONZEROES :::
C
         DO 600 K=1,NZ
            I = ROWLST(K)
            IF( I.EQ.OBJNUM )THEN
               IF( .NOT.SW )GOTO 600
C SW=TRUE MEANS OBJ IS (LAST) ROW STRIP
               ROWSTR = SCHNR
            ELSE
               CALL GETNAM('ROW ',I,RNAME)
               CALL ASTRIP('ROW ',RNAME,ROWSTR)
               IF(ROWSTR.EQ.0)THEN
C   NOT IN ANY CLASS...SEE IF WILD CHAR WAS SPECIFIED
                  IF(ROWILD.EQ.0)GOTO 600
                  ROWSTR = ROWILD
               ENDIF
            ENDIF
C UPDATE DATA (CELL) ENTRY IN (ROWSTR,COLSTR) ACCORDING TO:
C ...MARK CELL TO HAVE NONBLANK
            SCHDAT(ROWSTR,COLSTR) = '*'
C ...UPDATE RANGE
            IF(DATMIN(ROWSTR,COLSTR).GT.VALLST(K))
     1         DATMIN(ROWSTR,COLSTR) = VALLST(K)
            IF(DATMAX(ROWSTR,COLSTR).LT.VALLST(K))
     1         DATMAX(ROWSTR,COLSTR) = VALLST(K)
600      CONTINUE
900   CONTINUE
C     ::: END LOOP OVER NONZEROES :::
C
      IF( SCHNC.GE.PMSCOL )GOTO 1500
C
C ADD RHS AS A COLUMN STRIP
      SCHNC = SCHNC + 1
      IF(RHSNAM.NE.'none')THEN
         SCHCOL(SCHNC) = RHSNAM
         CALL FSLEN(RHSNAM,16,LENGTH)
         IF(SCHCLN.LT.LENGTH)SCHCLN=LENGTH
      ELSE
         SCHCOL(SCHNC) = ' '
      ENDIF
C
C LOOP OVER ROWS TO OBTAIN RELATION AND RANGE
C ...FIRST INITIALIZE
      IF(SW)THEN
         SCHDAT(SCHNR,SCHNC) = '...'//OPTNAM(:3)
         NR = SCHNR-1
      ELSE
         NR = SCHNR
      ENDIF
C
      DO 1200 I=1,NR
         SCHDAT(I,SCHNC) = ' '
         DATMIN(I,SCHNC) =  VINF
         DATMAX(I,SCHNC) = -VINF
1200  CONTINUE
C
C ...NOW LOOP
      DO 1250 I=1,NROWS
         IF(I.EQ.OBJNUM)GOTO 1250
         CALL GETBND('ROW ',I,VL,VU)
         CALL GETNAM('ROW ',I,RNAME)
         CALL ASTRIP('ROW ',RNAME,ROWSTR)
         IF(ROWSTR.EQ.0)GOTO 1250
C GET THIS ROW'S RELATION
         IF(VL.GE.VU)THEN
            CNAME = '=='
         ELSE IF(VL.LE.-VINF .AND. VU.GE. VINF)THEN
            CNAME = '...FREE'
         ELSE IF(VL.GT.-VINF .AND. VU.GE. VINF)THEN
            CNAME = '>='
         ELSE IF(VL.LE.-VINF .AND. VU.LT. VINF)THEN
            CNAME = '<='
         ELSE
C -* < VL < VU < * ...RANGE
            CNAME = 'r='
         ENDIF
C COMPARE WITH THIS STRIP'S SETTING
         IF(SCHDAT(ROWSTR,SCHNC).EQ.' ')THEN
            SCHDAT(ROWSTR,SCHNC) = CNAME
         ELSE IF(SCHDAT(ROWSTR,SCHNC).NE.CNAME)THEN
            SCHDAT(ROWSTR,SCHNC) = '...Mixed'
            GOTO 1250
         ENDIF
C
C UPDATE ITS NUMERIC RANGE
         IF(VL.GT.-VINF)THEN
            IF(VL.LT.DATMIN(ROWSTR,SCHNC))DATMIN(ROWSTR,SCHNC)=VL
            IF(VL.GT.DATMAX(ROWSTR,SCHNC))DATMAX(ROWSTR,SCHNC)=VL
         ENDIF
         IF(VU.LT. VINF)THEN
            IF(VU.LT.DATMIN(ROWSTR,SCHNC))DATMIN(ROWSTR,SCHNC)=VU
            IF(VU.GT.DATMAX(ROWSTR,SCHNC))DATMAX(ROWSTR,SCHNC)=VU
         ENDIF
1250  CONTINUE
C    ::: END LOOP OVER ROWS :::
C
C END RHS COLUMN STRIP
C
      IF(SCHNR+2.GT.PMSROW .OR. BNDNAM.EQ.'none')GOTO 1500
C
C FORM BOUNDS AS 2 MORE ROW STRIPS
C
      SCHNR1= SCHNR+1
      SCHNR = SCHNR+2
      CALL FSLEN(BNDNAM,16,LENGTH)
      IF(LENGTH+3.GT.SCHRLN)THEN
         SCHROW(SCHNR1) = ':LO'
         SCHROW(SCHNR ) = ':UP'
         IF(SCHRLN.LT.3)SCHRLN=3
      ELSE
         SCHROW(SCHNR1) = BNDNAM(:LENGTH)//':LO'
         SCHROW(SCHNR ) = BNDNAM(:LENGTH)//':UP'
      ENDIF
C
C INITIALIZE BOUNDxACTIVITY CELL ENTRIES
      DO 1400 COLSTR=1,SCHNC-1
         SCHDAT(SCHNR1,COLSTR) = '*'
         SCHDAT(SCHNR, COLSTR) = '=:'
         DATMIN(SCHNR1,COLSTR) = VINF
         DATMIN(SCHNR, COLSTR) = VINF
         DATMAX(SCHNR1,COLSTR) = -VINF
         DATMAX(SCHNR, COLSTR) = -VINF
1400  CONTINUE
C
C INITIALIZE BOUNDxRHS CELL ENTRIES (UNMARKED LEAVES BLANK)
      SCHDAT(SCHNR1,SCHNC) = ' '
      SCHDAT(SCHNR ,SCHNC) = ' '
C
C ...NOW LOOP OVER COLUMNS
      DO 1450 J=1,NCOLS
         CALL GETBND('COL ',J,VL,VU)
         CALL GETNAM('COL ',J,CNAME)
         CALL ASTRIP('COL ',CNAME,COLSTR)
         IF(COLSTR.EQ.0)GOTO 1450
C UPDATE RANGE OF LOWER BOUND
         IF(VL.LT.DATMIN(SCHNR1,COLSTR))DATMIN(SCHNR1,COLSTR)=VL
         IF(VL.GT.DATMAX(SCHNR1,COLSTR))DATMAX(SCHNR1,COLSTR)=VL
         IF(VL.LT.VU)SCHDAT(SCHNR,COLSTR) = '*'
C UPDATE RANGE OF UPPER BOUND
         IF(VU.LT.DATMIN(SCHNR ,COLSTR))DATMIN(SCHNR ,COLSTR)=VU
         IF(VU.GT.DATMAX(SCHNR ,COLSTR))DATMAX(SCHNR ,COLSTR)=VU
1450  CONTINUE
C  ::: END LOOP OVER COLUMNS :::
C
C     END BOUND STRIPS
C
1500  CONTINUE
C
C SET DATA CELL ENTRIES ACCORDING TO RANGE
C
      DO 1900 I=1,SCHNR
      DO 1900 J=1,SCHNC
         RNAME = SCHDAT(I,J)
         IF(RNAME.EQ.' '.OR.RNAME(:3).EQ.'...')GOTO 1900
C CELL IS RANGED
         VMIN = DATMIN(I,J)
         VMAX = DATMAX(I,J)
         IF(VMIN.GE.VINF .AND. VMAX.LE.-VINF)GOTO 1900
C ...AND ENTRIES WERE FOUND
         IF(VMIN.GE.VINF)THEN
            SCHDAT(I,J) = '*'
            GOTO 1900
         ENDIF
         IF(VMAX.LE.-VINF)THEN
            SCHDAT(I,J) = '-*'
            GOTO 1900
         ENDIF
C
C SAVE LEAD (FOR RHS STRIP)
         IF(RNAME.EQ.'*')THEN
C * WAS JUST INDICATOR...NO LEAD
            CLIST  = ' '
            LENGTH = 0
         ELSE IF(RNAME.EQ.'=:')THEN
C THIS IS :UP ROW STRIP AND LO=UP FOR ALL COLUMNS
            SCHDAT(I,J) = '='
            GOTO 1900
         ELSE
C THIS IS RHS COLUMN STRIP AND LEAD (RNAME) IS RELATION
            CLIST = RNAME
            CALL FSLEN(CLIST,16,LENGTH)
         ENDIF
C NOW CLIST IS INITIALIZED TO CELL ENTRY
C (BLANK IF COLUMN STRIP IS NOT RHS)
C
C CONVERT LOWER PART OF CELL RANGE (VMIN) INTO STRING (RNAME)
         IF(VMIN.LE.-VINF/2)THEN
            RNAME = '-*'
         ELSE
C CONVERT NUMERIC MIN TO STRING (VMIN===>RNAME)
            CALL FR2C(RNAME,VMIN)
         ENDIF
C SEE IF THERE IS A FRACTIONAL PART
         CALL FLOOK(RNAME,1,16,'.',FRAC)
         IF(FRAC.NE.0)THEN
C ...THERE IS...REMOVE TRAILING 0'S
            CALL FSLEN(RNAME,16,LR)
1850        IF(RNAME(LR:LR).EQ.'0')THEN
               RNAME(LR:) = ' '
               LR = LR-1
               GOTO 1850
            ENDIF
            IF(VMAX.GT.VMIN)THEN
C REDUCE NUMBER OF DIGITS IN FRACTIONAL PART
               IF(FRAC.GT.3)THEN
                  NFRAC = 2
               ELSE IF(FRAC.GT.2)THEN
                  NFRAC = 3
               ELSE
                  NFRAC = 4
               ENDIF
               IF(LR.GT.FRAC+NFRAC)THEN
                  LR = FRAC+NFRAC
                  RNAME(LR:) = ' '
               ENDIF
            ENDIF
         ENDIF
C
C SET (OR AUGMENT) THIS CELL'S STRING (CLIST)
         IF(CLIST.EQ.' ')THEN
            CLIST = RNAME
         ELSE
            CALL FSLEN(CLIST,8,LENGTH)
            CLIST(LENGTH+2:) = RNAME
         ENDIF
         CALL FSLEN(CLIST,18,LENGTH)
C
         IF(VMIN.GE.VMAX)GOTO 1890
C                        :...ALL NONZEROES = DATMIN
         LENGTH = LENGTH+1
         CLIST(LENGTH:)='/'
C GET UPPER VALUE OF NUMERIC RANGE
         IF(VMAX.GE.VINF/2)THEN
            CNAME = '*'
            LC = 1
         ELSE
            CALL FR2C(CNAME,VMAX)
            CALL FSLEN(CNAME,16,LC)
            CALL FSQUEZ(CNAME,LC)
C SEE IF THERE IS A FRACTIONAL PART
            CALL FLOOK(CNAME,1,LC,'.',FRAC)
            IF(FRAC.NE.0)THEN
C ...THERE IS...REMOVE TRAILING 0'S
1860           IF(CNAME(LC:LC).EQ.'0')THEN
                  CNAME(LC:) = ' '
                  LC = LC-1
                  GOTO 1860
               ENDIF
C ...AND REDUCE NUMBER OF DIGITS IN FRACTIONAL PART
               IF(FRAC.GT.3)THEN
                  NFRAC = 2
               ELSE IF(FRAC.GT.2)THEN
                  NFRAC = 3
               ELSE
                  NFRAC = 4
               ENDIF
               IF(LC.GT.FRAC+NFRAC)THEN
                  LC = FRAC+NFRAC
                  CNAME(LC:) = ' '
               ENDIF
            ENDIF
         ENDIF
C
C CHECK LENGTH OF CELL (ACTUALLY WIDTH)
         IF(LENGTH+LC.GT.16)THEN
C ...TOO MUCH, SO INDICATE ... FOR UPPER RANGE VALUE
            LENGTH = LENGTH+1
            CLIST(LENGTH:)='...'
         ELSE
            CLIST(LENGTH+1:) = CNAME
         ENDIF
C
1890     CONTINUE
C SET SCHEMA CELL ENTRY (SCHDAT)
         CALL FSLEN(CLIST,64,LENGTH)
         CALL FSQUEZ(CLIST,LENGTH)
         IF(CLIST(1:2).EQ.'==')THEN
            CLIST(2:2)=' '
         ELSE IF(CLIST(2:2).EQ.'='.OR.CLIST(2:2).EQ.'r')THEN
C INSERT BLANK AFTER RELATION
            CNAME = CLIST(1:2)
            RNAME = CLIST(3:)
            CLIST = CNAME(1:2)//' '//RNAME
            CALL FSLEN(CLIST,20,LENGTH)
         ENDIF
C
         SCHDAT(I,J) = CLIST(:LENGTH)
C FINALLY, UPDATE COLUMN STRIP LENGTH
         IF(SCHCLN.LT.LENGTH)SCHCLN=LENGTH
C NEXT CELL
1900  CONTINUE
C
C SCHEMA NOW SET
      RETURN
C
C FATAL ERROR
1300  CONTINUE
      RCODE = 1
C CALLER WILL TAKE ACTION (SUCH AS CLEAR SCHEMA)
      RETURN
C
C ** ASCHDO ENDS HERE
      END
      SUBROUTINE EXDOMN(CLIST,LAST,KEYLOC,RCODE)
C     =================
      IMPLICIT INTEGER (A-U), DOUBLE PRECISION (Z)
C
      INCLUDE 'DCANAL.'
CITSO      INCLUDE (DCANAL)
CI$$INSERT DCANAL
C
C This puts domain referenced in EXTABL(KEYLOC) into CLIST(LAST+1:)
C and advances LAST.
C
C EXTABL(KEYLOC) is parsed for set maps:  &set:posn (&=EXCHAR).
C DOMAIN(1),...,DOMAIN(16) is 4-char array s.t. DOMAIN(i) = i-th set
C (Logic changed 1-15-94).
C
      CHARACTER*128 CLIST
C LOCAL
      CHARACTER*80  STR80
      CHARACTER*16  STR16
      CHARACTER*8   STR8
      CHARACTER*4   DOMAIN(16)
      CHARACTER*64  DOM64
      EQUIVALENCE  (DOM64,DOMAIN(1))
C ::::::::::::::::::::::::::: BEGIN :::::::::::::::::::::::::::::::::
      IF( NENTY.EQ.0 )RETURN
C              :...MEANS NO ENTITY SETS; HENCE, NO DOMAINS
C XFER SYNTAX TO SCALAR (STR80)
      STR80 = EXTABL(KEYLOC)
      CALL FSLEN(STR80,80,LS)
      IF( LS.EQ.0 )RETURN
C INITIALIZE SETS IN DOMAIN
      NUMBER = 0
      DOM64  = ' '
      BEGIN = 1
C
C ::: LOOP OVER TEXT IN SYNTAX TABLE (STR80) TO FIND SET MAPS :::
100   CONTINUE
        IF( BEGIN.GE.LS )GOTO 190
C LOOK FOR SET REFERENCE IN (REMAINDER OF) TRANSLATION STRING
        CALL FLOOKF(STR80,BEGIN,LS,EXCHAR,IAMIT)
        IF( IAMIT.EQ.0 )GOTO 190
C WE MAY HAVE FOUND A SET REFERENCE
        CALL FLOOKF(STR80,IAMIT+2,IAMIT+5,':',COLON)
        IF( COLON.EQ.0 )THEN
C ...NO COLON...ASSUME NOT A SET REFERENCE
           BEGIN = IAMIT+1
           GOTO 100
        ENDIF
C COPY SET'S NAME
        STR8 = STR80(IAMIT+1:COLON-1)
C LOOKUP SET
        CALL EXLOC8('SET ',STR8,NUMSET)
        IF( NUMSET.EQ.0 )THEN
C ...SET NOT FOUND...ASSUME NOT A SET REFERENCE
           BEGIN = COLON+1
           GOTO 100
         ENDIF
C GET POSITION IN STRIP
C ...EXTRACT DIGITS (1 OR 2)
           STR16 = STR80(COLON+1:COLON+2)
           CALL FC2I(STR16,2,POSN,RCODE)
           IF( RCODE.NE.0 )THEN
C ...ASSUME 1 DIGIT (2ND CHAR MIGHT BE PUNCTUATION)
              STR16(2:) = ' '
              RCODE = 0
              CALL FC2I(STR16,1,POSN,RCODE)
              IF( RCODE.NE.0 )THEN
C INTEGER DOES NOT FOLLOW COLON...ASSUME NOT A SET REFERENCE
                 RCODE = 0
                 BEGIN = COLON+1
                 GOTO 100
              ENDIF
           ENDIF
C NOW WE HAVE SET MAP:  STR8 = SET, POSN = POSITION
           IF( POSN.GT.16 )THEN
              PRINT *,' ** POSITION OUT OF RANGE IN SET MAP:',
     1                STR80(IAMIT:COLON+2)
              RCODE = 1
              RETURN
           ENDIF
           IF( DOMAIN(POSN).NE.' ' )THEN
              PRINT *,' ** POSITION IN SET MAP ',STR80(IAMIT:COLON+2),
     1                ' ALREADY HAS ',DOMAIN(POSN)
              RCODE = 1
              RETURN
           ENDIF
C OK, ADD SET TO DOMAIN IN ITS POSITION
           DOMAIN(POSN) = STR8
           NUMBER = NUMBER+1
           BEGIN = COLON+1
         GOTO 100
C ::: END OF LOOP OVER SYNTAX :::
C
190   CONTINUE
C DOMAIN(1),...,DOMAIN(16) CONTAIN DOMAIN WITH NUMBER OF SETS
      IF( NUMBER.EQ.0 )RETURN
C DOMAIN IS PRESENT...PUT TOGETHER WITH COMMAS
      STR16 = ' '
      BEGIN = 0
      DO 400 I=1,16
         IF( DOMAIN(I).EQ.' ' )GOTO 400
         STR16(BEGIN+1:) = DOMAIN(I)//','
         BEGIN = 16
         CALL FSQUEZ(STR16,BEGIN)
400   CONTINUE
C PUT INTO CLIST
      CLIST(LAST+1:) = '('//STR16(:BEGIN-1)//')'
C                                       :...REMOVES LAST COMMA
      CALL FSLEN(CLIST,128,LAST)
      RETURN
C
C ** EXDOMN ENDS HERE
      END
      SUBROUTINE EXDSPD(LINE)
C     =================
      IMPLICIT INTEGER (A-U), DOUBLE PRECISION (Z)
C
      INCLUDE 'DCANAL.'
CITSO      INCLUDE (DCANAL)
CI$$INSERT DCANAL
C
C This displays domain sets...to OUTPUT (calling FTEXT).
C
C LOCAL
      CHARACTER*128 CLIST
C ::::::::::::::::::::::::::: BEGIN :::::::::::::::::::::::::::::::::
      IF( NENTY.EQ.0 )THEN
         PRINT *,' NO ENTITY SETS (FOR DOMAINS) HAVE BEEN DEFINED'
         RETURN
      ENDIF
C
      CLIST = '    DOMAIN INFORMATION'
      LAST = 23
      CALL FTEXT(CLIST,LAST,1,0,LINE,'CLEAR ',*900)
C
C ::: LOOP OVER ENTITY SETS :::
      DO 100 I=1,NENTY
         LOC = EXINDX(I-1)+1
         CLIST = EXKEY(LOC)//EXTABL(LOC)
         CALL FSLEN(CLIST,128,LAST)
         IF(ATTRIB(I).GT.0)THEN
            ATTR = ATTRIB(I)
            CLIST(LAST+2:) = '(Attributed '//ATRTYP(ATTR)
            CALL FSLEN(CLIST,128,LAST)
            LAST = LAST+1
            CLIST(LAST:) = ')'
         ENDIF
         CALL FTEXT(CLIST,LAST,10,-8,LINE,'CLEAR ',*900)
100   CONTINUE
C
900   RETURN
C
C ** EXDSPD ENDS HERE
      END
      SUBROUTINE ASTRIP(ROWCOL,CNAME,NUMBER)
C     =================
      IMPLICIT INTEGER (A-U), DOUBLE PRECISION (Z)
C
      INCLUDE 'DCANAL.'
      INCLUDE 'DCSCHEMA.'
CITSO      INCLUDE (DCANAL)
CITSO      INCLUDE (DCSCHEMA)
CI$$INSERT DCANAL
CI$$INSERT DCSCHEMA
C
C This finds strip (NUMBER) of (ROWCOL) (CNAME)
C     INPUT:  ROWCOL = ROW | COL
C             CNAME  = LP NAME
C
      CHARACTER*4   ROWCOL
      CHARACTER*16  CNAME
C LOCAL
      CHARACTER*16  RNAME
C
C  ...THIS IS TO CONSOLIDATE CODE FOR ROW VS. COLUMN LOOKUP
      CHARACTER*16 STRIP(PMSROW+PMSCOL)
!      EQUIVALENCE (SCHROW(1),STRIP(1)), (SCHCOL(1),STRIP(PMSROW+1))
C ::::::::::::::::::::::::::: BEGIN :::::::::::::::::::::::::::::::::
      IF(ROWCOL.EQ.'COL ')THEN
         N0 = PMSROW
         N  = SCHNC
      ELSE
         N0 = 0
         N  = SCHNR
      ENDIF
C FIND ROW STRIP
      DO 100 NUMBER=1,N
         RNAME = STRIP(N0 + NUMBER)
C REMOVE DOMAIN FROM STRIP NAME
         CALL FLOOK(RNAME,2,16,'(',IAMIT)
         IF(IAMIT.GT.0)RNAME(IAMIT:)=' '
         CALL FSLEN(RNAME,16,LAST)
C NOW COMPARE
         IF(RNAME(:LAST).EQ.CNAME(:LAST))RETURN
100   CONTINUE
      NUMBER = 0
      RETURN
C
C ** ASTRIP ENDS HERE
      END
      SUBROUTINE EXGENR(CLIST,FIRST,LAST,RCODE)
C     =================
      IMPLICIT INTEGER (A-U), DOUBLE PRECISION (Z)
C
      INCLUDE 'DCANAL.'
CITSO      INCLUDE (DCANAL)
CI$$INSERT DCANAL
C
C This executes SYNTAX GENERATE [filespec] [//USING filespec]
C LOCAL
      CHARACTER*128 CLIST
      CHARACTER*64  FILNAM,STR64
      CHARACTER*16  RNAME,STR16,CNAME
      CHARACTER*8   STR8,SETNAM
      CHARACTER*1   CHAR
      LOGICAL*1     SW
C ::::::::::::::::::::::::::: BEGIN :::::::::::::::::::::::::::::::::
      IF( SWEXPL )THEN
         PRINT *,' ** CANNOT GENERATE BECAUSE SYNTAX IS RESIDENT'
         RCODE = 1
         RETURN
      ENDIF
      CALL FLOOK(CLIST,FIRST,LAST,'//',IUSE)
      IF( IUSE.GT.0 )THEN
C USING SPECIFIED
         F = IUSE+2
         CALL FTOKEN(CLIST,F,LAST,STR8,8,CHAR)
         IF( STR8.EQ.' ' )THEN
            PRINT *,' ** USING EXPECTED'
            GOTO 1390
         ENDIF
         CALL FMATCH(STR8,'USING ',' ',SW)
         IF( .NOT.SW )THEN
            PRINT *,' ** ?',STR8,'...USING EXPECTED'
            GOTO 1390
         ENDIF
C ...PARSE FILESPEC
         CALL FILEIN(CLIST,F,LAST,'SYNTAX ',FILNAM,RCODE)
         IF( RCODE.NE.0 )RETURN
         LAST = IUSE-1
         IF( FILNAM.EQ.'*' )THEN
C ...USER IS FOOLING AROUND, TELLING US TO USE TERMINAL
            IUSE = 0
         ELSE
            CALL FSLEN(FILNAM,64,LF)
            CALL FLOPEN(DATFIL,FILNAM,'FORMATTED','OLD',*1350)
         ENDIF
      ENDIF
C PARSE FILESPEC
      CALL FTOKEN(CLIST,FIRST,LAST,STR64,64,CHAR)
      IF( STR64.EQ.' ' )STR64 = PRBNAM
      CALL FSETNM('SYNTAX  ',STR64,BEGEXT,RCODE)
      IF( RCODE.NE.0 )RETURN
      CALL FILOUT(STR64,RCODE)
      IF( RCODE.NE.0 )RETURN
C FILESPEC IS SET...WE'LL NOW USE CLIST LOCALLY (OPEN AND WRITE LATER)
C INITIALIZE
      NR = 0
      NC = 0
      NS = 0
C WE'LL USE EXTABL TO STORE ROW AND COLUMN SYNTAX MAPS, AND
C EXKEY TO STORE SETS
C
100   CONTINUE
      IF( IUSE.EQ.0 )THEN
C PROMPT FOR ROW SYNTAX
         PRINT *,' ROW (Press enter to end rows; * to abort): '
         READ(*,'(A79)')CLIST
         IF( CLIST.EQ.'*' )GOTO 1390
      ELSE
110      READ(DATFIL,'(A79)',ERR=1320,END=1325)CLIST
         IF( CLIST(1:1).EQ.'*' )GOTO 110
      ENDIF
      IF( CLIST.EQ.' ' )GOTO 900
      FIRST = 1
      CALL FSLEN(CLIST,79,LAST)
      CALL FTOKEN(CLIST,FIRST,LAST,RNAME,16,CHAR)
      IF( RNAME.EQ.OBJNAM .AND. CHAR.NE.'(' )THEN
         PRINT *,' IT IS NOT NECESSARY TO INCLUDE THE OBJECTIVE'
         GOTO 100
      ENDIF
      IF( NR.GT.0 )THEN
C CHECK CLASS CONFLICT
         DO 150 I=1,NR
            IF( RNAME(1:8).EQ.EXKEY(I) )THEN
               PRINT *,' ** ROW CLASS ',RNAME(:8),' ALREADY DEFINED'
               GOTO 100
            ENDIF
150      CONTINUE
      ELSE
C CHECK FOR OVERFLOW
         IF( NR.GE.20 )THEN
            PRINT *,' **',NR,' ARE TOO MANY CLASSES...MAX = 20'
            RCODE = 1
            RETURN
         ENDIF
      ENDIF
      NR = NR+1
      EXTABL(NR) = RNAME
      CALL FSLEN(RNAME,8,LEX)
      POSN = LEX+1
      IF( CHAR.EQ.'(' )CALL EXPARS(CLIST,FIRST,LAST,NR,NS,POSN,*100)
      GOTO 100
C
900   CONTINUE
C END ROWS
      IF( NR.EQ.0 )THEN
         PRINT *,' ** NO ROW CLASS DEFINED'
         RCODE = 1
         RETURN
      ENDIF
C
1000  CONTINUE
C PROMPT FOR COL SYNTAX
      IF( IUSE.EQ.0 )THEN
         PRINT *,' COL (Press enter to end columns; * to abort): '
         READ(*,'(A79)')CLIST
         IF( CLIST.EQ.'*' )GOTO 1390
      ELSE
1010     READ(DATFIL,'(A79)',ERR=1320,END=1325)CLIST
         IF( CLIST(1:1).EQ.'*' )GOTO 1010
      ENDIF
      IF( CLIST.EQ.' ' )GOTO 1900
      FIRST = 1
      CALL FSLEN(CLIST,79,LAST)
      CALL FTOKEN(CLIST,FIRST,LAST,RNAME,16,CHAR)
      IF( NC.GT.0 )THEN
C CHECK CLASS CONFLICT
         DO 1500 I=NR+1,NR+NC
            IF( RNAME(1:8).EQ.EXKEY(I) )THEN
               PRINT *,' ** COL CLASS ',RNAME(:8),' ALREADY DEFINED'
               GOTO 1000
            ENDIF
1500     CONTINUE
      ELSE
C CHECK FOR OVERFLOW
         IF( NC.GE.20 )THEN
            PRINT *,' **',NC,' ARE TOO MANY CLASSES...MAX = 20'
            RCODE = 1
            RETURN
         ENDIF
      ENDIF
      NC = NC+1
      EXTABL(NR+NC) = RNAME
      CALL FSLEN(RNAME,8,LEX)
      POSN = LEX+1
      IF( CHAR.EQ.'(' )CALL EXPARS(CLIST,FIRST,LAST,NR+NC,NS,POSN,*100)
      GOTO 1000
C
1900  CONTINUE
C END COLS
      IF( IUSE.GT.0 )CLOSE(DATFIL)
      IF( NC.EQ.0 )THEN
         PRINT *,' ** NO COL CLASS DEFINED'
         RCODE = 1
         RETURN
      ENDIF
C ================= END DISCOURSE =====================
C NOW EXKEY(1)    ,...,EXKEY(NS)     = SET NAMES
C     EXTABL(1)   ,...,EXTABL(NR)    = ROW CLASSES
C     EXTABL(NR+1),...,EXTABL(NR+NC) = COLUMN CLASSES
C =====================================================
      IF( IUSE.GT.0 .AND. SWMSG )PRINT *,' ',FILNAM(:LF),' READ'
C OPEN SYNTAX FILE
      FILNAM = STR64
      CALL FSLEN(FILNAM,64,LF)
      CALL FLOPEN(DATFIL,FILNAM,'FORMATTED','UNKNOWN',*1350)
      WRITE(DATFIL,1,ERR=1360)
1     FORMAT('* SKELETON SYNTAX FILE GENERATED BY ANALYZE')
      IF( NS.EQ.0 )THEN
         WRITE(DATFIL,'(9H* NO SETS)',ERR=1360)
         GOTO 9000
      ENDIF
C
      WRITE(DATFIL,'(6H* SETS)',ERR=1360)
      DO 6000 SET=1,NS
         SETNAM = EXKEY(SET)
         WRITE(DATFIL,'(A8)',ERR=1360)SETNAM
         CALL FSLEN(SETNAM,8,LS)
C TALLY MEMBERS
         NMEM = 0
         DO 4000 K=1,NR
            CALL FLOOKF(EXTABL(K),1,60,'&'//SETNAM(:LS)//':',ISET)
            IF( ISET.EQ.0 )GOTO 4000
C ROW CLASS HAS SET IN ITS DOMAIN
            ISET = ISET+LS+2
C NOW EXTABL(K)(ISET:ISET+1) = POSN
            CALL FTOKEN(EXTABL(K),ISET,80,STR8,8,CHAR)
            CALL FC2I(STR8,8,POSN,RCODE)
C POSN:POSN+LS-1 DEFINES SUBSTRING OF ROW NAME THAT CONTAINS A MEMBER
            F = 1
            CALL FTOKEN(EXTABL(K),F,ISET,RNAME,16,CHAR)
C RNAME = ROW CLASS (FIRST PART OF ROW NAME)
            CALL FSLEN(RNAME,16,LR)
C
C ::: LOOP OVER ROWS IN THIS CLASS TO GET MEMBERS :::
            DO 3500 ROW=1,NROWS
               IF( ROW.EQ.OBJNUM )GOTO 3500
               CALL GETNAM('ROW ',ROW,STR16)
               IF( RNAME(:LR).NE.STR16(:LR) )GOTO 3500
C ROW IS IN CLASS...GET ITS SET MEMBER
               STR8 = STR16(POSN:POSN+LS-1)
C ADD SET MEMBER (IF NOT ALREADY THERE)
               CALL EXAMEM(NS,NMEM,STR8,*1390)
3500        CONTINUE
4000     CONTINUE
C NOW THE SAME LOGIC FOR COLUMN CLASSES
         DO 4900 K=NR+1,NR+NC
            CALL FLOOKF(EXTABL(K),1,78,'&'//SETNAM(:LS)//':',ISET)
            IF( ISET.EQ.0 )GOTO 4900
C COL CLASS HAS SET IN ITS DOMAIN
            ISET = ISET+LS+2
            CALL FTOKEN(EXTABL(K),ISET,80,STR8,8,CHAR)
            CALL FC2I(STR8,8,POSN,RCODE)
C POSN:POSN+LS-1 DEFINES SUBSTRING OF COL NAME THAT CONTAINS A MEMBER
            F = 1
            CALL FTOKEN(EXTABL(K),F,ISET,RNAME,16,CHAR)
C RNAME = COL CLASS (FIRST PART OF ROW NAME)
            CALL FSLEN(RNAME,16,LR)
C
C ::: LOOP OVER COLS IN THIS CLASS TO GET MEMBERS :::
            DO 4500 COL=1,NCOLS
               CALL GETNAM('COL ',COL,STR16)
               IF( RNAME(:LR).NE.STR16(:LR) )GOTO 4500
C COL IS IN CLASS...GET ITS SET MEMBER
               STR8 = STR16(POSN:POSN+LS-1)
C ADD SET MEMBER (IF NOT ALREADY THERE)
               CALL EXAMEM(NS,NMEM,STR8,*1390)
4500        CONTINUE
4900     CONTINUE
C ==== NOW EXKEY(NS+1),...,EXKEY(NS+NMEM) = MEMBERS OF SET ====
         IF( NMEM.GT.0 )THEN
            WRITE(DATFIL,'(1X,A8)',ERR=1360) (EXKEY(I),I=NS+1,NS+NMEM)
         ELSE
            WRITE(DATFIL,'(12H* NO MEMBERS)',ERR=1360)
         ENDIF
C NEXT SET
6000  CONTINUE
C
C
CC ================= 7-23-94 ========================
C ADD VERB TO ROW SYNTAX WITH THE FOLLOWING RULES:
C       =0 or <= 0 or >= 0  ===> balances
C       =+ or >= + or <= -  ===> demands
C       =- or <= + or >= -  ===> limits
C       else                ===> requires
C ...FREE ROWS IN CLASS ARE SKIPPED
C IF THE ABOVE DOES NOT HOLD THROUGHOUT CLASS, NO VERB IS ENTERED
C
C ::: LOOP OVER ROW CLASSES :::
      DO 7000 I=1,NR
C SCAN MATRIX
         FIRST=1
         LAST =80
         CALL FTOKEN(EXTABL(I),FIRST,LAST,CNAME,16,CHAR)
         IF( CNAME.EQ.' ' )GOTO 7090
C CNAME = NAME OF ROW CLASS
         CALL FSLEN(CNAME,8,LC)
         STR16 = ' '
C
C   ::: LOOP OVER ROWS :::
         DO 6500 ROW=1,NROWS
            CALL GETNAM('ROW ',ROW,RNAME)
            IF( RNAME(:LC).NE.CNAME(:LC) )GOTO 6500
C ROW IS IN THIS CLASS...GET ITS TYPE
            CALL GETYPE(ROW,CHAR)
            IF( CHAR.EQ.'N' )GOTO 6500
C ROW IS NOT FREE...GET ITS VERB
            CALL GETBND('ROW ',ROW,VL,VU)
            IF( (CHAR.EQ.'E' .AND. VL.EQ.0. ) .OR.
     1          (CHAR.EQ.'G' .AND. VL.EQ.0. ) .OR.
     2          (CHAR.EQ.'L' .AND. VU.EQ.0. )
     B        )THEN
                 STR8 = 'balances'
            ELSE IF( (CHAR.EQ.'E' .AND. VL.GT.0. ) .OR.
     1               (CHAR.EQ.'G' .AND. VL.GT.0. ) .OR.
     2               (CHAR.EQ.'L' .AND. VU.LT.0. )
     D        )THEN
                 STR8 = 'demands'
            ELSE IF( (CHAR.EQ.'E' .AND. VL.GT.0. ) .OR.
     1               (CHAR.EQ.'G' .AND. VL.LT.0. ) .OR.
     2               (CHAR.EQ.'L' .AND. VU.GT.0. )
     L        )THEN
                 STR8 = 'limits'
            ELSE
                 STR8 = 'requires'
            ENDIF
C STR8 = VERB FOR THIS ROW...SET FOR CLASS OR SEE IF CONFLICT
            IF( STR16.EQ.' ' )THEN
               STR16 = STR8
            ELSE IF( STR16(:8).NE.STR8 )THEN
               GOTO 7000
            ENDIF
C NO CONFLICT...PROCEED TO NEXT ROW IN CLASS
6500     CONTINUE
C   ::: END LOOP OVER ROWS :::
C
         IF( STR16.EQ.' ' )GOTO 7000
C ROW CLASS HAS VERB...INSERT
         CLIST = CNAME(:LC)//' '//STR16
         CALL FSLEN(CLIST,81,LC)
         CALL FLOOK(EXTABL(I),1,20,'&',ISET)
         IF( ISET.GT.0 )THEN
            CLIST(LC+2:) = EXTABL(I)(ISET:)
            CALL FSLEN(CLIST,81,LC)
            IF( LC.GT.79 )CLIST(77:) = '...'
         ENDIF
         EXTABL(I) = CLIST(:79)
7000  CONTINUE
C ::: END LOOP OVER ROW CLASSES :::
C
7090  CONTINUE
C
C NO COLUMN VERB (FORTHCOMING)
CC ============= END 7-23-94 ========================
C
9000  CONTINUE
      WRITE(DATFIL,'(10HROW SYNTAX)',ERR=1360)
      WRITE(DATFIL,'(1X,A79)',ERR=1360)(EXTABL(I),I=1,NR)
      WRITE(DATFIL,'(13HCOLUMN SYNTAX)',ERR=1360)
      WRITE(DATFIL,'(1X,A79)',ERR=1360)(EXTABL(I),I=NR+1,NR+NC)
      WRITE(DATFIL,'(6HENDATA)',ERR=1360)
      CLOSE(DATFIL)
      IF( SWMSG )PRINT *,' SYNTAX WRITTEN TO ',FILNAM(:LF)
      RETURN
C
C ERROR RETURNS...1300 REMOVED (WAS FOR DEBUG)
1320  PRINT *,' ** I/O ERROR READING ',FILNAM(:LF)
      GOTO 1390
1325  PRINT *,' ** PREMATURE END OF FILE READING ',FILNAM(:LF)
      GOTO 1390
1350  PRINT *,' ** I/O ERROR ATTEMPTING TO OPEN ',FILNAM(:LF)
      GOTO 1390
1360  PRINT *,' ** I/O ERROR WRITING ',FILNAM(:LF)
1390  RCODE = 1
      RETURN
C
C ** EXGENR ENDS HERE
      END
      SUBROUTINE EXPARS(CLIST,FIRST,LAST,EPOINT,NS,POSN,*)
C     =================
      IMPLICIT INTEGER (A-U), DOUBLE PRECISION (Z)
C
      INCLUDE 'DCANAL.'
CITSO      INCLUDE (DCANAL)
CI$$INSERT DCANAL
C
C This parses domain set in CLIST(FIRST:LAST)
C       EPOINT = Pointer to EXTABL (NR or NR+NC)
C       NS     = Number of sets (advanced)
C       POSN   = Position in name (advanced)
C ...Alternate return is syntax error in specification
C
      CHARACTER*(*) CLIST
C LOCAL
      CHARACTER*8   STR8,SETNAM
      CHARACTER*1   CHAR
C ::::::::::::::::::::::::::: BEGIN :::::::::::::::::::::::::::::::::
      LEX = POSN
100   CONTINUE
      CALL FTOKEN(CLIST,FIRST,LAST,SETNAM,8,CHAR)
      IF( NS.GT.0 )THEN
C CHECK IF SET ALREADY DEFINED
         DO 150 I=1,NS
150      IF( SETNAM.EQ.EXKEY(I) )GOTO 190
      ENDIF
C ADD NEW SET
      NS = NS+1
      EXKEY(NS) = SETNAM
C
190   CONTINUE
C PUT SET REFERENCE IN SYNTAX MAP
      CALL FSLEN(SETNAM,8,LS)
      CALL FI2C(STR8,POSN,F)
      EXTABL(EPOINT)(LEX+2:) = '&'//SETNAM(:LS)//':'//STR8(F:)
      CALL FSLEN(EXTABL(EPOINT),80,LEX)
      POSN = POSN+LS
C
      IF( CHAR.EQ.',' )GOTO 100
      IF( CHAR.NE.')' )THEN
         PRINT *,' ** ?',CHAR,' IN ',CLIST(:LAST)
         RETURN 1
      ENDIF
C
      RETURN
C
C ** EXPARS ENDS HERE
      END
      SUBROUTINE EXAMEM(NS,NMEM,MEMBER,*)
C     =================
      IMPLICIT INTEGER (A-U), DOUBLE PRECISION (Z)
C
      INCLUDE 'DCANAL.'
CITSO      INCLUDE (DCANAL)
CI$$INSERT DCANAL
C
C This adds (MEMBER) to EXKEY(NS+1),...,EXKEY(NS+NMEM)
C       NMEM is incremented if member not already present
C ...Alternate return is overflow
C
      CHARACTER*(*) MEMBER
C ::::::::::::::::::::::::::: BEGIN :::::::::::::::::::::::::::::::::
      IF( NMEM.EQ.0 )THEN
         NMEM = 1
         EXKEY(NS+1) = MEMBER
         RETURN
      ENDIF
C SEE IF MEMBER IS ALREADY IN LIST
      DO 100 I=NS+1,NS+NMEM
100   IF( MEMBER.EQ.EXKEY(I) )RETURN
C IT ISN'T, SO WE MUST ADD IT
      IF( NS+NMEM.GE.PMXSYN )THEN
         PRINT *,' ** TOO MANY SET MEMBERS...MAX =',PMXSYN-NS
         RETURN 1
      ENDIF
      NMEM = NMEM+1
      EXKEY(NS+NMEM) = MEMBER
      RETURN
C
C ** EXAMEM ENDS HERE
      END
