from pathlib import Path
import subprocess
root=Path(__file__).resolve().parents[2]
prefs=Path.home()/'AppData/Local/DPH/workspace.json'
old=prefs.read_bytes() if prefs.exists() else None
try:
    result=subprocess.run(['cmd','/c',str(root/'tools/build-learning-refocus.cmd')],cwd=root,capture_output=True,text=True,errors='replace')
    (root/'bin/learning-refocus-test.log').write_text(result.stdout+result.stderr,encoding='utf-8')
    print((result.stdout+result.stderr)[-8000:])
finally:
    if old is not None:
        prefs.parent.mkdir(parents=True,exist_ok=True)
        prefs.write_bytes(old)
    elif prefs.exists(): prefs.unlink()
    print('Original workspace preferences restored')
raise SystemExit(result.returncode)
