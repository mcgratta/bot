@echo off

:: setup environment variables (defining where repository resides etc) 

set envfile="%userprofile%"\fds_smv_env.bat
IF EXIST %envfile% GOTO endif_envexist
echo ***Fatal error.  The environment setup file %envfile% does not exist. 
echo Create a file named %envfile% and use smv/scripts/fds_smv_env_template.bat
echo as an example.
echo.
echo Aborting now...

pause>NUL
goto:eof

:endif_envexist

set CURDIR=%CD%
call %envfile%

%git_drive%

set fdsdir=%git_root%\fds\Manuals\Bibliography
set smvdir=%git_root%\smv\Manuals\Bibliography

call :COPY %fdsdir%\FDS_general.bib  %smvdir%
call :COPY %fdsdir%\FDS_mathcomp.bib %smvdir%
call :COPY %fdsdir%\FDS_refs.bib     %smvdir%
call :COPY %fdsdir%\authors.tex      %smvdir%

set fdsdir=%git_root%\fds\Source
set smvdir=%git_root%\smv\Source\smokeview

cd %CURDIR%
GOTO EOF

:COPY
set label=%~n1%~x1
set infile=%1
set outfile=%2
IF EXIST %infile% (
   echo copying %label% from fds to smv repo
   copy %infile% %outfile% >Nul
) ELSE (
   echo.
   echo *** warning: %infile% does not exist
   echo.
   pause
)
exit /b

:EOF
pause
