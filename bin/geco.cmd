:: See ../share/gtags/geco.rc for details.
@SetLocal EnableDelayedExpansion
@set arg=
@for %%O in (%*) do @(
  set opt=%%O
  if not "!opt:~0,1!" == "-" set arg=1
)
@if not defined arg (
  for /f "delims=" %%L in ('global 2^>^&1') do @(
    set line=%%L
    if not "!line:~7,10!"=="global -p[" if not "!line:~7,10!"=="global -u[" (
      set line=!line:global=geco!
      echo !line!
    )
  )
  goto :eof
)
@set GTAGSBLANKENCODE=
@global %* --result=ctags-x | gecoless
