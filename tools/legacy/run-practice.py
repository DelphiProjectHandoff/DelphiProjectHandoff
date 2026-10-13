from pathlib import Path
import subprocess,uuid
root=Path(__file__).resolve().parents[2]
prefs=Path.home()/'AppData/Local/DPH/workspace.json';original=prefs.read_bytes() if prefs.exists() else None
out=root/'bin/learning-completion';work=out/('practice-'+str(uuid.uuid4()))
try:
 prefs.parent.mkdir(parents=True,exist_ok=True);prefs.write_text('{}',encoding='utf-8')
 result=subprocess.run(['cmd','/d','/c','tools\\build-practice.cmd',str(work)],cwd=root,capture_output=True,text=True,errors='replace')
 (out/'Practice.log').write_text(result.stdout+result.stderr,encoding='utf-8')
 print(result.returncode,(result.stdout+result.stderr)[-5000:]);raise SystemExit(result.returncode)
finally:
 if original is not None:prefs.write_bytes(original)
 elif prefs.exists():prefs.unlink()
 print('Owner workspace preferences restored')
