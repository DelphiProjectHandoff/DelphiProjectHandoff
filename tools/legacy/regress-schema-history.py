from pathlib import Path
import subprocess
r=Path.cwd()
for label,stem,script in [('schema','DatabaseSchema','database-schema'),('er','DatabaseER','database-er'),('stored-objects','DatabaseStoredObjects','database-stored-objects'),('lineage','DataLineage','data-lineage')]:
 original=r/f'tests/DPH.Tests.{stem}.dpr';target=r/f'bin/DPH.Tests.{stem}.History.dpr'
 text=original.read_text(encoding='utf-8-sig').replace('phase1-'+script+'-','phase1-schema-history-'+label+'-regression-')
 # Existing test labels use database-stored-objects, database-er and data-lineage.
 target.write_text(text,encoding='utf-8')
 cmd=(r/f'tools/build-{script}.cmd').read_text().replace(f'tests\\DPH.Tests.{stem}.dpr',f'bin\\DPH.Tests.{stem}.History.dpr').replace(f'DPH.Tests.{stem}.exe',f'DPH.Tests.{stem}.History.exe')
 task=r/'bin/regress-schema-history.cmd';task.write_text(cmd,encoding='utf-8')
 with (r/f'docs/phase1-schema-history-{label}-regression.log').open('w',encoding='utf-8') as out:
  subprocess.run(['cmd','/c',str(task)],stdout=out,stderr=subprocess.STDOUT,check=True)
 print('PASS',label,flush=True)
