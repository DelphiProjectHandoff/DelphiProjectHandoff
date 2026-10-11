@echo off
setlocal
cd /d "%~dp0.."
call "C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat"
if errorlevel 1 exit /b 1
dcc32 -B -Q -U"%BDS%\lib\Win32\release;." -NSSystem;FMX;Data;Xml;Winapi -N0dcu\Win32\Debug -Ebin\Win32\Debug tests\DPH.Tests.Layout.dpr
if errorlevel 1 exit /b 1
bin\Win32\Debug\DPH.Tests.Layout.exe "%CD%"
exit /b %errorlevel%
