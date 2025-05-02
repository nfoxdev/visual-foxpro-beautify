********************************************************************************************************
* vfpBeautify
* Marco Plaza 2024,2025 -  github.com/nfoxdev/visual-foxpro-beautify
********************************************************************************************************
parameters lpars

#define crlf chr(13)+chr(10)

lpars   = alltrim(m.lpars,1,'"')
srcFile = strextract(m.lpars,'','|')
fd3     = strextract(m.lpars,'|','')

resultText = filetostr(m.srcFile)

try

  curPath = justpath(m.fd3)
  cd (m.curPath)
  set library to (m.fd3)     
  set library to vfp2c32.fll additive

  options = loadOptions(m.curPath)

  if !isnull(m.options)
    resultfile = doBeautify(m.srcFile,m.options)
    resultText = filetostr(m.resultfile)
    erase (m.resultfile)
  endif

catch
  messagebox('An error occurred - try restart/reinstall extension' + message(),32,'vfp Beautify',5000)

endtry


stdOut(m.resultText)

*-----------------------------------------
function stdOut( lcMessage )
*-----------------------------------------
* Declarar funciones de la API de Windows

  declare integer WriteFile in kernel32;
    integer hFile,;
    string @lpBuffer,;
    integer nNumberOfBytesToWrite,;
    integer @lpNumberOfBytesWritten,;
    integer lpOverlapped

  declare integer GetStdHandle in kernel32 integer nStdHandle
  #define std_output_handle -11

* Obtener el handle de stdout
  hstdout = GetStdHandle(std_output_handle)

* Mensaje a escribir
  lnbyteswritten = 0

* Escribir el mensaje a stdout
  WriteFile(hstdout, @lcMessage, len(lcMessage), @lnbyteswritten, 0)


*-------------------------------------------------------------------
function doBeautify( inFile, options )
*-------------------------------------------------------------------


  #define tab  chr(9)

  private symbol, winname, winpos, file, filetype, done, flags, sniplineno, ;
    classname, baseclass, mtemp, temp, fpoutfile, mout, totallines

  local ox, retval, mdatasess

  _vfp.languageoptions = 0

  set talk off
  set trbetween off

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

  ox = createobject("CBeautify", m.inFile, @options)

  if type("OX") = "O"
    m.retval = ox.outfile
    ox = .null.
  endif


  return (m.retval)   && output file name


*****************************************************
define class cbeautify as session
*****************************************************
  datasession = 2      &&private
  visible = .f.
  name = "Beautify"
  outfile = ""

*--------------------------------------------------------
  procedure init( m.inFile, m.options)
*--------------------------------------------------------
    local fsuccess, outfile, libname, xrefname,mdbf
    local m.errlogfile, moldlogerrors

    local nwindowhandle
    local nstartpos
    local nendpos
    local nstartline
    local nendline
    local nretcode
    local npos
    local ccodeblock
    local ctempinfile
    local cindenttext
    local i, ncnt
    local lselection
    local nnewlen
    local cfoxtoolslibrary
    local array aedenv[25]
    local array acodelines[1]

    set talk off
    set safety off      && scoped to datasession


    use fdkeywrd.dbf ;
      order token ;
      alias fdkeywrd in 0

    set message to ""

    select fdkeywrd


* Generate a temp file in the temp file directory
    m.outfile = sys(2023) + "\" + substr(sys(2015), 3, 10) + ".TMP"

    m.xrefname = "FDXREF"
    create cursor (m.xrefname) (;
      symbol c(65),;
      procname c(40),;
      flag c(1),;
      lineno n(5),;
      sniprecno n(5),;
      snipfld c(10),;
      sniplineno n(5),;
      adjust n(5),;
      filename c(161);
      )
    index on flag tag flag                   && for rushmore
    index on upper(symbol)+flag tag symbol

    beautify(m.inFile, m.outfile, m.options)

    select fdxref
    use

    this.outfile = m.outfile


  endproc &&Init

*************************************************************
enddefine
*************************************************************

*-----------------------------------------
function loadOptions(cPath)
*-----------------------------------------
  #define configfilename 'beautifyOptions.txt'
  #define defaultconfig "040000000300000002000000020000000000000000000000000000000000000001000000"

  coptions = DEFAULTCONFIG
  optfile  = forcepath(configfilename,m.cPath)

  if file(m.optfile)
    try
      coptions = filetostr(m.optfile)
    catch
    endtry
  endif


  do form options name oConfig linked
  centerWindow(m.oConfig)

  with oConfig
    .symbolsCap.listIndex 	= val(substr(m.coptions,1,2))
    .keywordsCap.listIndex 	= val(substr(m.coptions,9,2))
    .spaces.value 			= val(substr(m.coptions,17,2))
    .indentUsing.listIndex 	= val(substr(m.coptions,25,2))
    .indentComments.value 	= val(substr(m.coptions,41,2))
    .indentProcedure.value 	= val(substr(m.coptions,57,2))
    .indentDocase.value 	= val(substr(m.coptions,65,2))
    .visible = .t.
  endwith
  read events

  if !oConfig.run.ok
    return null
  endif


  with oConfig
    options = ;
      pr(.symbolsCap.listIndex)+;
      pr(.keywordsCap.listIndex)+;
      pr(.spaces.value)+;
      pr(.indentUsing.listIndex)+;
      pr(0)+;
      pr(.indentComments.value)+;
      pr(0)+;
      pr(.indentProcedure.value)+;
      pr(.indentDocase.value;
      )
  endwith

  strtofile(m.options,m.optfile)
  return strconv(m.options,16)

*-------------------------------------------------
function pr(vv)
*-------------------------------------------------
  return transform(m.vv,'@l 99')+replicate('0',6)


*----------------------------------------
function centerWindow( oForm )
*----------------------------------------
* get code process Id:
  pid = _getParentprocess('Code.exe')
  codeHwnd = 0

  if pid > 0
* get Code hwnd
    local array wp(1)
    aWindowsEx('wp','WO',1)
    pidRow = ascan(wp,m.pid,1,-1,2,8)
    codeHwnd = wp( m.pidRow,1)
  endif

  CenterWindowEx(oForm.hwnd, m.codeHwnd) && vfp2c32
