@echo off
setlocal
cd /d "%~dp0.."
powershell -NoProfile -ExecutionPolicy Bypass -File tools\clear-validation-output.ps1
if errorlevel 1 exit /b 1
call tools\build-wp0.cmd
if errorlevel 1 exit /b 1
call "C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat"
for %%T in (Catalog Lifecycle) do (
  dcc32 -B -Q -U"%BDS%\lib\Win32\release;." -NSSystem;FMX;Data;Xml;Winapi -N0dcu\Win32\Debug -Ebin\Win32\Debug tests\DPH.Tests.%%T.dpr
  if errorlevel 1 exit /b 1
  bin\Win32\Debug\DPH.Tests.%%T.exe "%CD%"
  if errorlevel 1 exit /b 1
)
call tools\build-wp4.cmd no-report
if errorlevel 1 exit /b 1
call tools\build-wp5.cmd
if errorlevel 1 exit /b 1
call tools\build-selection.cmd
if errorlevel 1 exit /b 1
powershell -NoProfile -ExecutionPolicy Bypass -File tools\clear-validation-output.ps1
exit /b %errorlevel%
