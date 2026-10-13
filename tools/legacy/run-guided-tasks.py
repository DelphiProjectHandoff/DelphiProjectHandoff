from pathlib import Path
import subprocess,uuid,shutil
root=Path(__file__).resolve().parents[2]
work=root/'bin'/('guided-task-tests-'+str(uuid.uuid4()))
work.mkdir()
prefs=Path.home()/'AppData/Local/DPH/workspace.json'
old=prefs.read_bytes() if prefs.exists() else None
try:
    result=subprocess.run(['cmd','/d','/c','tools\\build-guided-tasks.cmd',str(work/'fixture.dphdb')],cwd=root,capture_output=True,text=True,errors='replace')
    (root/'bin/guided-tasks-test.log').write_text(result.stdout+result.stderr,encoding='utf-8')
    print(result.stdout+result.stderr,flush=True)
finally:
    if old is not None:
        prefs.parent.mkdir(parents=True,exist_ok=True);prefs.write_bytes(old)
    elif prefs.exists(): prefs.unlink()
    print('Original workspace preferences restored')
if result.returncode==0:
    assert work.resolve().parent==(root/'bin').resolve() and work.name.startswith('guided-task-tests-') and not work.is_symlink()
    shutil.rmtree(work)
    print('Disposable guided-task fixture removed')
raise SystemExit(result.returncode)
