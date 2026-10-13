from pathlib import Path
import subprocess
r=Path.cwd()
for label,stem,script,prefix in [('knowledge','Knowledge','wp5','wp5-'),('publishing','Publishing','wp6','wp6-'),('quality','DataQuality','data-quality','phase1-data-quality-'),('process','BusinessProcess','business-process','phase1-business-process-'),('workflow','DepartmentalWorkflow','departmental-workflow','phase1-departmental-workflow-'),('workspace','Workspace','wp4','wp4-')]:
 target=r/f'bin/DPH.Tests.{stem}.Diagram.dpr'
 text=(r/f'tests/DPH.Tests.{stem}.dpr').read_text(encoding='utf-8-sig').replace(prefix,'phase1-process-diagram-'+label+'-regression-')
 target.write_text(text,encoding='utf-8-sig')
 cmd=(r/f'tools/build-{script}.cmd').read_text().replace(f'tests\\DPH.Tests.{stem}.dpr',f'bin\\DPH.Tests.{stem}.Diagram.dpr').replace(f'DPH.Tests.{stem}.exe',f'DPH.Tests.{stem}.Diagram.exe')
 task=r/'bin/regress-process-diagram.cmd';task.write_text(cmd,encoding='utf-8')
 with (r/f'docs/phase1-process-diagram-{label}-regression.log').open('w',encoding='utf-8') as out: subprocess.run(['cmd','/c',str(task)],stdout=out,stderr=subprocess.STDOUT,check=True)
 print('PASS',label,flush=True)
with (r/'docs/phase1-process-diagram-build.log').open('w',encoding='utf-8') as out: subprocess.run(['cmd','/c',r'tools\build-wp0.cmd'],stdout=out,stderr=subprocess.STDOUT,check=True)
print('PASS actual application and FMX',flush=True)
