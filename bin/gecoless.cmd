:: See ../share/gtags/geco.rc for details.
@if not defined GECO_SELECTOR @(
  for %%G in (percol percol.py peco fzf) do @(
    %%G --version >nul 2>&1 && set GECO_SELECTOR=%%G&& goto okay
  )
  echo geco: percol, peco or fzf is required.
  goto :eof
)
:okay
@more > %TEMP%\global.tags
@for %%T in (%TEMP%\global.tags) do @(
  if %%~zT LEQ 2 (
    echo No such tag in tags file
  ) else (
    %GECO_SELECTOR% < %TEMP%\global.tags | less -T-
  )
)
@del %TEMP%\global.tags
