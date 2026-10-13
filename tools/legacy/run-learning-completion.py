from pathlib import Path
import subprocess, uuid, shutil
root=Path(__file__).resolve().parents[2]
out=root/'bin/learning-completion'
out.mkdir(exist_ok=True)
git=r'C:\Program Files\Git\cmd\git.exe'
for name in ['DPH.UI.Main.pas','DPH.UI.Main.fmx','DPH.Workspace.Model.pas','DPH.Workspace.Catalog.pas','DPH.Analysis.Explanations.pas','tests/DPH.Tests.Catalog.dpr','tests/DPH.Tests.GuidedTasks.dpr']:
    p=root/name
    previous=subprocess.check_output([git,'show','HEAD:'+name],cwd=root)
    content=p.read_text(encoding='utf-8-sig')
    p.write_bytes((b'\xef\xbb\xbf' if previous.startswith(b'\xef\xbb\xbf') else b'')+content.replace('\r\n','\n').replace('\n','\r\n').encode('utf-8'))
prefs=Path.home()/'AppData/Local/DPH/workspace.json'
original=prefs.read_bytes() if prefs.exists() else None
work=out/('task-'+str(uuid.uuid4()))
work.mkdir()
try:
    for suite in ['Catalog','GuidedTasks']:
        source=(root/f'tests/DPH.Tests.{suite}.dpr').read_text(encoding='utf-8-sig').replace("in '..\\","in '..\\..\\")
        source=source.replace('docs\\guided-tasks-','docs\\learning-completion-tasks-')
        (out/f'DPH.Tests.{suite}.dpr').write_text(source,encoding='utf-8-sig')
        args=' "%CD%"' if suite=='Catalog' else f' "{work / "fixture.dphdb"}" "%CD%"'
        script='\n'.join(['@echo off','call "C:\\Program Files (x86)\\Embarcadero\\Studio\\37.0\\bin\\rsvars.bat"',f'dcc32 -B -Q -U"%BDS%\\lib\\Win32\\release;.;dependencies\\DelphiAppTranslation" -NSSystem;FMX;Data;Xml;Winapi -N0dcu\\Win32\\Debug -Ebin\\Win32\\Debug bin\\learning-completion\\DPH.Tests.{suite}.dpr','if errorlevel 1 exit /b 1',f'bin\\Win32\\Debug\\DPH.Tests.{suite}.exe'+args,'exit /b %errorlevel%'])
        (out/f'{suite}.cmd').write_text(script,encoding='ascii')
        result=subprocess.run(['cmd','/d','/c',f'bin\\learning-completion\\{suite}.cmd'],cwd=root,capture_output=True,text=True,errors='replace')
        (out/f'{suite}.log').write_text(result.stdout+result.stderr,encoding='utf-8')
        print(suite,result.returncode,(result.stdout+result.stderr)[-2800:],flush=True)
        if result.returncode:raise SystemExit(result.returncode)
finally:
    if original is not None:prefs.write_bytes(original)
    elif prefs.exists():prefs.unlink()
    print('Owner workspace preferences restored',flush=True)
