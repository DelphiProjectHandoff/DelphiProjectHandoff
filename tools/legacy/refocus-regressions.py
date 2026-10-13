from pathlib import Path
import subprocess, re
root=Path(__file__).resolve().parents[2]
git=r'C:\Program Files\Git\cmd\git.exe'
for name in ['DPH.UI.Main.fmx','DPH.UI.Main.pas','DPH.Analysis.Explanations.pas']:
    path=root/name
    text=path.read_text(encoding='utf-8-sig')
    if name.endswith('.fmx'): text=text.replace("'Knowledge'","'Saved explanations'")
    bom=subprocess.check_output([git,'show','HEAD:'+name],cwd=root).startswith(b'\xef\xbb\xbf')
    path.write_text('\n'.join(line.rstrip() for line in text.splitlines())+'\n',encoding='utf-8-sig' if bom else 'utf-8')
for suite in ['Phase1','Publishing']:
    source=(root/f'tests/DPH.Tests.{suite}.dpr').read_text(encoding='utf-8-sig')
    source=source.replace('docs\\phase1-','docs\\learning-refocus-phase1-').replace('docs\\rework-','docs\\learning-refocus-rework-').replace('docs\\completion-','docs\\learning-refocus-completion-').replace('docs\\publishing-','docs\\learning-refocus-publishing-')
    source=source.replace("in '..\\", "in '..\\..\\")
    out=root/'bin/refocus-regressions'
    out.mkdir(exist_ok=True)
    (out/f'DPH.Tests.{suite}.dpr').write_text(source,encoding='utf-8-sig')
    build='\n'.join(['@echo off','call "C:\\Program Files (x86)\\Embarcadero\\Studio\\37.0\\bin\\rsvars.bat"',
        f'dcc32 -B -Q -U"%BDS%\\lib\\Win32\\release;.;dependencies\\DelphiAppTranslation" -NSSystem;FMX;Data;Xml;Winapi -N0dcu\\Win32\\Debug -Ebin\\Win32\\Debug bin\\refocus-regressions\\DPH.Tests.{suite}.dpr',
        'if errorlevel 1 exit /b 1',f'bin\\Win32\\Debug\\DPH.Tests.{suite}.exe "%CD%"','exit /b %errorlevel%'])
    cmd=out/f'{suite}.cmd';cmd.write_text(build,encoding='ascii')
    result=subprocess.run(['cmd','/c',str(cmd)],cwd=root,capture_output=True,text=True,errors='replace')
    (out/f'{suite}.log').write_text(result.stdout+result.stderr,encoding='utf-8')
    print(suite,':',result.returncode, (result.stdout+result.stderr)[-1500:],flush=True)
    if result.returncode: raise SystemExit(result.returncode)
