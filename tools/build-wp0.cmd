@echo off
setlocal
cd /d "%~dp0.."
call "C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat"
if errorlevel 1 exit /b 1
if not exist bin\Win32\Debug mkdir bin\Win32\Debug
if not exist dcu\Win32\Debug mkdir dcu\Win32\Debug
msbuild DelphiProjectHandoff.dproj /t:Build /p:Config=Debug /p:Platform=Win32 /verbosity:minimal /nologo
if errorlevel 1 exit /b 1
dcc32 -B -Q -U"%BDS%\lib\Win32\release" -NSSystem;FMX -N0dcu\Win32\Debug -Ebin\Win32\Debug tests\DPH.Tests.Baseline.dpr
if errorlevel 1 exit /b 1
bin\Win32\Debug\DPH.Tests.Baseline.exe "%CD%"
exit /b %errorlevel%
