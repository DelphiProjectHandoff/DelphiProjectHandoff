from pathlib import Path
import subprocess,uuid,shutil
root=Path(__file__).resolve().parents[2];out=root/'bin/lesson-preparation';out.mkdir(exist_ok=True)
work=out/('task-fixture-'+str(uuid.uuid4()));work.mkdir()
prefs=Path.home()/'AppData/Local/DPH/workspace.json';old=prefs.read_bytes() if prefs.exists() else None
try:
 for suite in ['LearningRefocus','GuidedTasks']:
  source=(root/f'tests/DPH.Tests.{suite}.dpr').read_text(encoding='utf-8-sig').replace("in '..\\","in '..\\..\\")
  source=source.replace('docs\\learning-refocus-','docs\\lesson-preparation-learning-').replace('docs\\guided-tasks-','docs\\lesson-preparation-task-')
  (out/f'DPH.Tests.{suite}.dpr').write_text(source,encoding='utf-8-sig')
  args=' "%CD%" "'+str(out/'reference.dphdb')+'"' if suite=='LearningRefocus' and (out/'reference.dphdb').exists() else ' "%CD%"'
  if suite=='GuidedTasks':args=' "'+str(work/'fixture.dphdb')+'" "%CD%"'
  build='\n'.join(['@echo off','call "C:\\Program Files (x86)\\Embarcadero\\Studio\\37.0\\bin\\rsvars.bat"',
   f'dcc32 -B -Q -U"%BDS%\\lib\\Win32\\release;.;dependencies\\DelphiAppTranslation" -NSSystem;FMX;Data;Xml;Winapi -N0dcu\\Win32\\Debug -Ebin\\Win32\\Debug bin\\lesson-preparation\\DPH.Tests.{suite}.dpr',
   'if errorlevel 1 exit /b 1',f'bin\\Win32\\Debug\\DPH.Tests.{suite}.exe'+args,'exit /b %errorlevel%'])
  (out/f'{suite}.cmd').write_text(build,encoding='ascii')
  result=subprocess.run(['cmd','/d','/c',f'bin\\lesson-preparation\\{suite}.cmd'],cwd=root,capture_output=True,text=True,errors='replace')
  (out/f'{suite}.log').write_text(result.stdout+result.stderr,encoding='utf-8');print(suite,result.returncode,(result.stdout+result.stderr)[-2100:],flush=True)
  if result.returncode:raise SystemExit(result.returncode)
 assert work.resolve().parent==out.resolve() and not work.is_symlink();shutil.rmtree(work)
finally:
 if old is not None:prefs.parent.mkdir(parents=True,exist_ok=True);prefs.write_bytes(old)
 elif prefs.exists():prefs.unlink()
 print('Original workspace preferences restored',flush=True)
