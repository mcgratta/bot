@echo off

set CURDIR=%CD%
cd windows

echo making bundle for windows

echo -------------------------------------------------
echo -------------building fds------------------------
echo -------------------------------------------------
call make_fds
echo -------------------------------------------------
echo --- building smokeview and associated programs --
echo -------------------------------------------------
call make_smv
echo -------------------------------------------------
echo -------getting fds pubs -------------------------
echo -------------------------------------------------
call get_fds_pubs
echo -------------------------------------------------
echo -------getting smokeview pubs -------------------
echo -------------------------------------------------
call get_smv_pubs
echo -------------------------------------------------
echo -------getting fds release notes ----------------
echo -------------------------------------------------
call get_fds_release_notes bot
echo -------------------------------------------------
echo ------- making the bundle -----------------------
echo -------------------------------------------------
call make_bundle
echo -------------------------------------------------
echo ------- complete --------------------------------
echo -------------------------------------------------

cd %CURDIR%
