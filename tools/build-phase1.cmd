@echo off
setlocal
cd /d "%~dp0.."
call "C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat"
if errorlevel 1 exit /b 1
dcc32 -B -Q -U"%BDS%\lib\Win32\release;.;dependencies\DelphiAppTranslation" -NSSystem;FMX;Data;Xml;Winapi -N0dcu\Win32\Debug -Ebin\Win32\Debug tests\DPH.Tests.Phase1.dpr
if errorlevel 1 exit /b 1
bin\Win32\Debug\DPH.Tests.Phase1.exe "%CD%"
if errorlevel 1 exit /b 1
dcc32 -B -Q -U"%BDS%\lib\Win32\release;.;dependencies\DelphiAppTranslation" -NSSystem;FMX;Data;Xml;Winapi -N0dcu\Win32\Debug -Ebin\Win32\Debug tests\DPH.Tests.SourceQuality.dpr
if errorlevel 1 exit /b 1
bin\Win32\Debug\DPH.Tests.SourceQuality.exe "%CD%"
if errorlevel 1 exit /b 1
dcc32 -B -Q -U"%BDS%\lib\Win32\release;.;dependencies\DelphiAppTranslation" -NSSystem;FMX;Data;Xml;Winapi -N0dcu\Win32\Debug -Ebin\Win32\Debug tests\DPH.Tests.Comparison.dpr
if errorlevel 1 exit /b 1
bin\Win32\Debug\DPH.Tests.Comparison.exe "%CD%"
exit /b %errorlevel%
