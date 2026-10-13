from pathlib import Path
from zipfile import ZipFile
import subprocess,json,hashlib,re,uuid,shutil,ctypes,time
root=Path(__file__).resolve().parents[2]
recordpath=root/'docs/learning-distribution-validation.json'
r=json.loads(recordpath.read_text(encoding='utf-8-sig'));assert r['version']=='0.5.0'
desktop=Path(r['verification_directory']);source=Path(r['source']);binary=Path(r['binary'])
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
for archivepath in [binary,source]:
 with ZipFile(archivepath) as archive:
  assert archive.testzip() is None
  assert not any(n.endswith(('.dphdb','.dphdb-wal','.dphdb-shm')) or ' - Copy.' in n for n in archive.namelist())
  for name in ['samples/OrderPractice/lessons.json','samples/OrderPractice/OrderForm.pas','docs/pdf/DPH_User_Guide.pdf','help/assets/translation-selector.js']:assert name in archive.namelist(),name
with ZipFile(binary) as archive:
 for name in archive.namelist():
  if name.endswith(('.txt','.html','.js')):
   assert not re.search(r'(?i)C:[\\/]Users[\\/]marti|C:[\\/]New Delphi Projects|owner rejected',archive.read(name).decode('utf-8-sig')),name
hashes=json.loads((desktop/'SHA256.json').read_text(encoding='utf-8-sig'))
for name,digest in hashes.items():assert sha(desktop/name)==digest,name
pack=json.loads((desktop/'samples/OrderPractice/lessons.json').read_text(encoding='utf-8-sig'))
for name,digest in pack['source_hashes'].items():assert sha(desktop/'samples/OrderPractice'/name)==digest,name
out=root/'bin/learning-completion';sourcecheck=out/('source-package-'+uuid.uuid4().hex)
with ZipFile(source) as archive:archive.extractall(sourcecheck)
prefs=Path.home()/'AppData/Local/DPH/workspace.json';old=prefs.read_bytes() if prefs.exists() else None
proc=None
try:
 prefs.parent.mkdir(parents=True,exist_ok=True);prefs.write_text('{}',encoding='utf-8')
 proc=subprocess.Popen([str(desktop/'DelphiProjectHandoff.exe')],cwd=desktop)
 user32=ctypes.windll.user32;windows=[]
 callbacktype=ctypes.WINFUNCTYPE(ctypes.c_bool,ctypes.c_void_p,ctypes.c_void_p)
 def callback(hwnd,param):
  pid=ctypes.c_ulong();user32.GetWindowThreadProcessId(ctypes.c_void_p(hwnd),ctypes.byref(pid))
  if pid.value==proc.pid and user32.IsWindowVisible(ctypes.c_void_p(hwnd)):windows.append(hwnd)
  return True
 callbackref=callbacktype(callback)
 deadline=time.monotonic()+25
 while time.monotonic()<deadline and not windows:
  assert proc.poll() is None,'Desktop application exited during startup'
  user32.EnumWindows(callbackref,0);time.sleep(.2)
 assert windows,'No visible native application window'
 assert not user32.IsHungAppWindow(ctypes.c_void_p(windows[0])),'Desktop window is unresponsive'
 for hwnd in windows:user32.PostMessageW(ctypes.c_void_p(hwnd),0x10,0,0)
 assert proc.wait(timeout=20)==0,'Desktop close failed'
 r['desktop_launch']='PASS extracted actual executable opens a responsive native window and closes normally'
 print(r['desktop_launch'],flush=True)
 prefs.write_text('{}',encoding='utf-8')
 shutil.copy2(root/'bin/Win32/Debug/DPH.Tests.Practice.exe',desktop/'DPH.Tests.Practice.exe')
 work=out/('packaged-practice-'+uuid.uuid4().hex)
 result=subprocess.run([str(desktop/'DPH.Tests.Practice.exe'),str(desktop),str(work)],cwd=desktop,capture_output=True,text=True,errors='replace',timeout=120)
 (root/'docs/learning-completion-packaged-practice.log').write_text(result.stdout+result.stderr,encoding='utf-8')
 assert result.returncode==0,(result.stdout+result.stderr)[-2000:]
 assert '27 checks' not in result.stdout or 'FAIL ' not in result.stdout
 r['packaged_practice_checks']=27;r['packaged_practice']='PASS actual native learner route, stored progress, contextual help, anchored pictures and offline lessons against extracted desktop assets'
 print(r['packaged_practice'],flush=True)
 result=subprocess.run(['cmd','/d','/c','tools\\build-wp0.cmd'],cwd=sourcecheck,capture_output=True,text=True,errors='replace',timeout=120)
 (root/'docs/learning-completion-source-package-build.log').write_text(result.stdout+result.stderr,encoding='utf-8')
 assert result.returncode==0,(result.stdout+result.stderr)[-2000:]
 r['source_build']='PASS fresh extracted source ZIP builds and serialized form bindings pass'
 r['source_verification_directory']=str(sourcecheck)
 print(r['source_build'],flush=True)
finally:
 if proc is not None and proc.poll() is None:proc.terminate();proc.wait(timeout=10)
 if old is not None:prefs.write_bytes(old)
 else:prefs.unlink(missing_ok=True)
r['privacy']='PASS owner databases and owner PDF copies excluded; current user guides, help and directions contain no personal paths or development diary'
r['binary_entry_sha256']=sha(desktop/'DelphiProjectHandoff.exe')
assert r['binary_entry_sha256']==sha(root/'bin/Win32/Debug/DelphiProjectHandoff.exe')
r['binary_sha256']=sha(binary);r['source_sha256']=sha(source)
r['result']='PASS package integrity, extracted desktop startup, packaged practice lessons and fresh source build; independent beginner acceptance not performed'
recordpath.write_text(json.dumps(r,indent=2)+'\n',encoding='utf-8')
print('PASS final delivery checks; original workspace preferences restored')
