from pathlib import Path
import subprocess,json
r=Path.cwd();git=r'C:\Program Files\Git\cmd\git.exe'
cases=[('data-rules','phase1-data-rules-validation.json'),('database-transactions','phase1-database-transactions-validation.json'),('database-operations','phase1-database-operations-validation.json'),('dataset-bindings','phase1-dataset-bindings-validation.json'),('database-engines','phase1-database-engines-validation.json'),('wp3','wp3-validation.json'),('wp2','wp2-validation.json'),('wp0',None)]
before={p:subprocess.check_output([git,'show','HEAD:'+p]) for p in subprocess.check_output([git,'ls-files','docs']).decode().splitlines()}
try:
 for name,report in cases:
  label={'wp3':'semantics','wp2':'parser','wp0':'build'}.get(name,name+'-regression')
  log=r/f'docs/phase1-data-lineage-{label}.log'
  with log.open('w') as out:
   x=subprocess.run(['cmd','/c',f'tools\\build-{name}.cmd'],stdout=out,stderr=subprocess.STDOUT)
   if x.returncode:raise RuntimeError(name+' build/test failed')
   if name=='wp3':
    x=subprocess.run([str(r/'bin/Win32/Debug/DPH.Tests.Semantics.exe'),str(r)],stdout=out,stderr=subprocess.STDOUT)
    if x.returncode:raise RuntimeError(name+' test failed')
  if report:
   dest=r/f'docs/phase1-data-lineage-{label}.json';dest.write_bytes((r/'docs'/report).read_bytes())
   j=json.loads(dest.read_text(encoding='utf-8-sig'));print(name,j.get('checks_passed',j.get('checks')),flush=True)
  else:assert 'PASS WP0-TEST' in log.read_text()
finally:
 # Restore only known historical test products, never current implementation or guide files.
 for p,data in before.items():
  if not p.endswith(('.png','.json')):continue
  if p.startswith(('docs/phase1-data-rules-','docs/phase1-database-transactions-','docs/phase1-database-operations-','docs/phase1-dataset-bindings-','docs/phase1-database-engines-','docs/wp2-','docs/wp3-','docs/wp0-')):
   (r/p).write_bytes(data)
