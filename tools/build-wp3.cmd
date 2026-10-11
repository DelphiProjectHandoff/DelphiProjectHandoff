@echo off
setlocal
cd /d "%~dp0.."
call "C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat"
dcc32 -B -Q -U"%BDS%\lib\Win32\release;.;dependencies\DelphiAppTranslation" -NSSystem;Data;Xml;Winapi -N0dcu\Win32\Debug -Ebin\Win32\Debug tests\DPH.Tests.Semantics.dpr
exit /b %errorlevel%
