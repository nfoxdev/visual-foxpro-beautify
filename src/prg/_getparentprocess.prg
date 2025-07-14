*----------------------------------------------------
* get parentProcess up to topmost or specified name
* Marco Plaza, nfoxdev 2025
*----------------------------------------------------
lparameters locateName

locateName = evl(m.locateName,'')

set library to vfp2c32 additive

local locatename,pid,nrow,procname,x,ptree(1)

local array aa(1)
aprocesses('aa')

spid = _vfp.ProcessId

local array ptree(1,2)

for x = 1 to 20

  nRow = ascan(aa,m.spId,1,-1,2,8)

  if nRow = 0
    exit
  endif

  procName = aa(m.nRow,1)
  pid      = aa(m.nRow,2)

  dimension ptree(m.x,2)
  ptree(m.x,1) = m.procName
  ptree(m.x,2) = m.pid

  spid = aa(m.nRow,3)

endfor

if !empty(m.locatename)
  pid  = 0
  for y = m.x-1 to 1 step -1
    if lower(ptree(m.y,1)) = lower(m.locateName)
      pid = ptree(m.y,2)
      exit
    endif
  endfor
endif

return m.pid
