from pathlib import Path
import subprocess
root=Path(__file__).resolve().parents[2]
python=r'C:\Users\marti\AppData\Local\Microsoft\WindowsApps\python.exe'
out=root/'bin/lesson-preparation'
result=subprocess.run([python,'bin/run-lesson-preparation.py'],cwd=root)
if result.returncode:raise SystemExit(result.returncode)
for suite in ['Phase1','Publishing']:
 source=(root/f'tests/DPH.Tests.{suite}.dpr').read_text(encoding='utf-8-sig').replace("in '..\\","in '..\\..\\")
 for prefix in ['phase1-','wp6-']:source=source.replace('docs\\'+prefix,'bin\\lesson-preparation\\'+prefix)
 (out/f'DPH.Tests.{suite}.dpr').write_text(source,encoding='utf-8-sig')
 script='\n'.join(['@echo off','call "C:\\Program Files (x86)\\Embarcadero\\Studio\\37.0\\bin\\rsvars.bat"',f'dcc32 -B -Q -U"%BDS%\\lib\\Win32\\release;.;dependencies\\DelphiAppTranslation" -NSSystem;FMX;Data;Xml;Winapi -N0dcu\\Win32\\Debug -Ebin\\Win32\\Debug bin\\lesson-preparation\\DPH.Tests.{suite}.dpr','if errorlevel 1 exit /b 1',f'bin\\Win32\\Debug\\DPH.Tests.{suite}.exe "%CD%"','exit /b %errorlevel%'])
 (out/f'{suite}.cmd').write_text(script,encoding='ascii')
 result=subprocess.run(['cmd','/d','/c',f'bin\\lesson-preparation\\{suite}.cmd'],cwd=root,capture_output=True,text=True,errors='replace')
 (out/f'{suite}.log').write_text(result.stdout+result.stderr,encoding='utf-8')
 print(suite,result.returncode,(result.stdout+result.stderr)[-1200:],flush=True)
 if result.returncode:raise SystemExit(result.returncode)
result=subprocess.run(['cmd','/d','/c','tools\\build-wp0.cmd'],cwd=root,capture_output=True,text=True,errors='replace')
(out/'Application.log').write_text(result.stdout+result.stderr,encoding='utf-8')
print('Application',result.returncode,(result.stdout+result.stderr)[-1500:],flush=True)
raise SystemExit(result.returncode)
