from pathlib import Path
import subprocess
r=Path.cwd()
for label,stem,script,prefix in [('knowledge','Knowledge','wp5','wp5-'),('publishing','Publishing','wp6','wp6-'),('quality','DataQuality','data-quality','phase1-data-quality-')]:
 target=r/f'bin/DPH.Tests.{stem}.Recovery.dpr'
 text=(r/f'tests/DPH.Tests.{stem}.dpr').read_text(encoding='utf-8-sig').replace(prefix,'phase1-target-recovery-'+label+'-regression-')
 target.write_text(text,encoding='utf-8-sig')
 cmd=(r/f'tools/build-{script}.cmd').read_text().replace(f'tests\\DPH.Tests.{stem}.dpr',f'bin\\DPH.Tests.{stem}.Recovery.dpr').replace(f'DPH.Tests.{stem}.exe',f'DPH.Tests.{stem}.Recovery.exe')
 task=r/'bin/regress-target-recovery.cmd';task.write_text(cmd,encoding='utf-8')
 with (r/f'docs/phase1-target-recovery-{label}-regression.log').open('w',encoding='utf-8') as out: subprocess.run(['cmd','/c',str(task)],stdout=out,stderr=subprocess.STDOUT,check=True)
 print('PASS',label,flush=True)
with (r/'docs/phase1-target-recovery-build.log').open('w',encoding='utf-8') as out: subprocess.run(['cmd','/c',r'tools\build-wp0.cmd'],stdout=out,stderr=subprocess.STDOUT,check=True)
print('PASS actual application and FMX',flush=True)
