from pathlib import Path
import subprocess,json
root=Path(__file__).resolve().parents[2]
out=root/'bin/guided-task-regressions';out.mkdir(exist_ok=True)
prefs=Path.home()/'AppData/Local/DPH/workspace.json'
old=prefs.read_bytes() if prefs.exists() else None
reference=json.loads((root/'docs/learning-refocus-learning-validation.json').read_text(encoding='utf-8-sig')).get('reference_cache','')
try:
 for suite in ['Phase1','Publishing','LearningRefocus']:
  source=(root/f'tests/DPH.Tests.{suite}.dpr').read_text(encoding='utf-8-sig')
  source=source.replace("in '..\\", "in '..\\..\\")
  for prefix in ['phase1-','wp6-','learning-refocus-']:
   source=source.replace('docs\\'+prefix,'bin\\guided-task-regressions\\'+prefix)
  target=out/f'DPH.Tests.{suite}.dpr';target.write_text(source,encoding='utf-8-sig')
  args=' "%CD%"'+(' "'+reference+'"' if suite=='LearningRefocus' else '')
  build='\n'.join(['@echo off','call "C:\\Program Files (x86)\\Embarcadero\\Studio\\37.0\\bin\\rsvars.bat"',
   f'dcc32 -B -Q -U"%BDS%\\lib\\Win32\\release;.;dependencies\\DelphiAppTranslation" -NSSystem;FMX;Data;Xml;Winapi -N0dcu\\Win32\\Debug -Ebin\\Win32\\Debug bin\\guided-task-regressions\\DPH.Tests.{suite}.dpr',
   'if errorlevel 1 exit /b 1',f'bin\\Win32\\Debug\\DPH.Tests.{suite}.exe'+args,'exit /b %errorlevel%'])
  (out/f'{suite}.cmd').write_text(build,encoding='ascii')
  result=subprocess.run(['cmd','/d','/c',f'bin\\guided-task-regressions\\{suite}.cmd'],cwd=root,capture_output=True,text=True,errors='replace')
  (out/f'{suite}.log').write_text(result.stdout+result.stderr,encoding='utf-8')
  print(suite,result.returncode,(result.stdout+result.stderr)[-1800:],flush=True)
  if result.returncode: raise SystemExit(result.returncode)
finally:
 if old is not None: prefs.parent.mkdir(parents=True,exist_ok=True);prefs.write_bytes(old)
 elif prefs.exists():prefs.unlink()
 print('Original workspace preferences restored',flush=True)
