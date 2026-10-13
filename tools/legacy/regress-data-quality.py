from pathlib import Path
import subprocess
r=Path.cwd()
for label,stem,script,prefix in [('knowledge','Knowledge','wp5','wp5-'),('publishing','Publishing','wp6','wp6-'),('retention','DataRetention','data-retention','phase1-data-retention-')]:
 target=r/f'bin/DPH.Tests.{stem}.Quality.dpr'
 text=(r/f'tests/DPH.Tests.{stem}.dpr').read_text(encoding='utf-8-sig').replace(prefix,'phase1-data-quality-'+label+'-regression-')
 target.write_text(text,encoding='utf-8-sig')
 cmd=(r/f'tools/build-{script}.cmd').read_text().replace(f'tests\\DPH.Tests.{stem}.dpr',f'bin\\DPH.Tests.{stem}.Quality.dpr').replace(f'DPH.Tests.{stem}.exe',f'DPH.Tests.{stem}.Quality.exe')
 task=r/'bin/regress-data-quality.cmd';task.write_text(cmd,encoding='utf-8')
 with (r/f'docs/phase1-data-quality-{label}-regression.log').open('w',encoding='utf-8') as out: subprocess.run(['cmd','/c',str(task)],stdout=out,stderr=subprocess.STDOUT,check=True)
 print('PASS',label,flush=True)
with (r/'docs/phase1-data-quality-build.log').open('w',encoding='utf-8') as out: subprocess.run(['cmd','/c',r'tools\build-wp0.cmd'],stdout=out,stderr=subprocess.STDOUT,check=True)
print('PASS actual application and FMX',flush=True)
