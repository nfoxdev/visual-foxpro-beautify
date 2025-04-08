********************************************************************************************************
* vfpBeautify
* Marco Plaza 2024 -  github.com/nfoxdev/visual-foxpro-beautify
********************************************************************************************************
Parameters lpars

Cd (Justpath(Fullpath('')))
#Define crlf Chr(13)+Chr(10)

lpars   = Alltrim(m.lpars,1,'"')
srcFile = Strextract(m.lpars,'','|')
fd3     = Strextract(m.lpars,'|','')

Set Library To (m.fd3) Additive

resultfile = doBeautify(m.srcFile)
resultText = Filetostr(m.resultfile)

Erase (m.resultfile)

stdOut(m.resultText)

*-----------------------------------------
Function stdOut( lcMessage )
*-----------------------------------------
* Declarar funciones de la API de Windows

Declare Integer WriteFile In kernel32;
   INTEGER hFile,;
   STRING @lpBuffer,;
   INTEGER nNumberOfBytesToWrite,;
   INTEGER @lpNumberOfBytesWritten,;
   INTEGER lpOverlapped

Declare Integer GetStdHandle In kernel32 Integer nStdHandle
#Define std_output_handle -11

* Obtener el handle de stdout
hstdout = GetStdHandle(std_output_handle)

* Mensaje a escribir
lnbyteswritten = 0

* Escribir el mensaje a stdout
WriteFile(hstdout, @lcMessage, Len(lcMessage), @lnbyteswritten, 0)


*-------------------------------------------------------------------
Function doBeautify( inFile )
*-------------------------------------------------------------------

*filetostr(m.options,'beautify2options.txt') && todo: read from vscode user preferences
options = Strconv("020000000300000002000000020000000000000000000000010000000000000000000000",16)

#Define Tab  Chr(9)

Private symbol, winname, winpos, File, filetype, done, Flags, sniplineno, ;
   classname, BaseClass, mtemp, temp, fpoutfile, mout, totallines

Local ox, retval, mdatasess

_vfp.LanguageOptions = 0

Set Talk Off
Set Trbetween Off

m.retval = ""

* These variables are needed by the FD3.FLL library
m.symbol = ""
m.winname = 0
m.winpos = 0
m.file = ""
m.filetype = ""
m.done = 0
m.flags = ""
m.sniplineno = 0
m.classname = ""
m.baseclass = ""
m.mtemp = ""
m.temp = ""
m.fpoutfile = -1
m.mout = ""
m.totallines = 0

ox = Createobject("CBeautify", m.inFile, @options)

If Type("OX") = "O"
   m.retval = ox.outfile
   ox = .Null.
Endif


Return (m.retval)   && output file name


*****************************************************
Define Class cbeautify As Session
*****************************************************
   DataSession = 2      &&private
   Visible = .F.
   Name = "Beautify"
   outfile = ""

*--------------------------------------------------------
   Procedure Init( m.inFile, m.options)
*--------------------------------------------------------
   Local fsuccess, outfile, libname, xrefname,mdbf
   Local m.errlogfile, moldlogerrors

   Local nwindowhandle
   Local nstartpos
   Local nendpos
   Local nstartline
   Local nendline
   Local nretcode
   Local npos
   Local ccodeblock
   Local ctempinfile
   Local cindenttext
   Local i, ncnt
   Local lselection
   Local nnewlen
   Local cfoxtoolslibrary
   Local Array aedenv[25]
   Local Array acodelines[1]

   Set Talk Off
   Set Safety Off      && scoped to datasession


   Use fdkeywrd.Dbf ;
      ORDER token ;
      ALIAS fdkeywrd In 0

   Set Message To ""

   Select fdkeywrd


* Generate a temp file in the temp file directory
   m.outfile = Sys(2023) + "\" + Substr(Sys(2015), 3, 10) + ".TMP"

   m.xrefname = "FDXREF"
   Create Cursor (m.xrefname) (;
      symbol c(65),;
      procname c(40),;
      FLAG c(1),;
      LINENO N(5),;
      sniprecno N(5),;
      snipfld c(10),;
      sniplineno N(5),;
      ADJUST N(5),;
      filename c(161);
      )
   Index On Flag Tag Flag                   && for rushmore
   Index On Upper(symbol)+Flag Tag symbol

   beautify(m.inFile, m.outfile, m.options)

   Select fdxref
   Use

   This.outfile = m.outfile


   Endproc &&Init

*************************************************************
Enddefine
*************************************************************
