@echo off
setlocal
cd /d "%~dp0.."
call "C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat"
dcc32 -B -Q -U"%BDS%\lib\Win32\release;.;dependencies\DelphiAppTranslation\source" -NSSystem;FMX;Data;Xml;Winapi -N0dcu\Win32\Debug -Ebin\Win32\Debug tests\DPH.Tests.UITranslation.dpr
if errorlevel 1 exit /b 1
bin\Win32\Debug\DPH.Tests.UITranslation.exe "%CD%\Localization\Languages"
exit /b %errorlevel%
