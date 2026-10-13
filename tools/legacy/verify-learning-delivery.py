from pathlib import Path
from zipfile import ZipFile,ZIP_DEFLATED
from docx import Document
from pypdf import PdfReader
import subprocess,json,hashlib,re,uuid,os
root=Path(__file__).resolve().parents[2]
record_path=root/'docs/learning-distribution-validation.json'
record=json.loads(record_path.read_text(encoding='utf-8-sig'))
binary=Path(record['binary']);source=Path(record['source'])
assert source.resolve().parent==(root/'source distributions').resolve()
with ZipFile(source) as archive:parts={n:archive.read(n) for n in archive.namelist() if not n.endswith('/')}
# Refresh this phase's newly created source package with the final packager and sample test input.
parts['tools/package-dph.ps1']=(root/'tools/package-dph.ps1').read_bytes()
for p in (root/'samples/translation').rglob('*'):
 if p.is_file():parts[p.relative_to(root).as_posix()]=p.read_bytes()
updated=source.with_suffix('.updated.zip')
assert not updated.exists()
with ZipFile(updated,'w',ZIP_DEFLATED) as archive:
 for folder in ['bin/','dcu/','docs/guides/','docs/pdf/','export/','help/','images and icons/','samples/','source distributions/','tools/','Databases/']:archive.writestr(folder,b'')
 for name,data in parts.items():archive.writestr(name,data)
 assert archive.testzip() is None
updated.replace(source)
with ZipFile(binary) as archive:
 assert archive.testzip() is None
 names=archive.namelist()
 assert not any(n.endswith('.dphdb') or ' - Copy.' in n for n in names)
 assert 'help/assets/translation-selector.js' in names
 assert 'docs/guides/Developer_Test_Directions.txt' in names
 assert len([n for n in names if n.startswith('docs/guides/') and n.endswith('.txt')])==3
 for name in names:
  if name.endswith(('.txt','.html','.json','.js','.ps1','.py')):
   text=archive.read(name).decode('utf-8-sig')
   assert not re.search(r'(?i)C:[\\/]Users[\\/]marti|C:[\\/]New Delphi Projects|owner rejected|WP7 delivery',text),name
 record['privacy']='PASS current guides/help/directions contain no personal paths or development history; owner database and PDF copies excluded'
source_root=root/'bin'/('delivery-source-check-'+uuid.uuid4().hex)
source_root.mkdir();assert source_root.resolve().parent==(root/'bin').resolve()
with ZipFile(source) as archive:archive.extractall(source_root)
prefs=Path.home()/'AppData/Local/DPH/workspace.json';old=prefs.read_bytes() if prefs.exists() else None
try:
 result=subprocess.run(['cmd','/d','/c','tools\\build-wp0.cmd'],cwd=source_root,capture_output=True,text=True,errors='replace')
 (root/'bin/learning-guides/source-package-build.log').write_text(result.stdout+result.stderr,encoding='utf-8')
 print('Extracted source build',result.returncode,(result.stdout+result.stderr)[-900:],flush=True)
 if result.returncode:raise SystemExit(result.returncode)
finally:
 if old is not None:prefs.write_bytes(old)
 else:prefs.unlink(missing_ok=True)
record['source_sha256']=hashlib.sha256(source.read_bytes()).hexdigest()
record['source_build']='PASS extracted source package builds and serialized form baseline passes'
record['source_verification_directory']=str(source_root)
record['binary_entry_sha256']=hashlib.sha256((Path(record['verification_directory'])/'DelphiProjectHandoff.exe').read_bytes()).hexdigest()
assert record['binary_entry_sha256']==hashlib.sha256((root/'bin/Win32/Debug/DelphiProjectHandoff.exe').read_bytes()).hexdigest()
record_path.write_text(json.dumps(record,indent=2)+'\n',encoding='utf-8')
print('PASS package privacy, ZIP integrity and fresh extracted source build; owner preferences restored')
