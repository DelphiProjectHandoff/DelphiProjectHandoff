from pathlib import Path
import subprocess,json,hashlib
root=Path(__file__).resolve().parents[2]
source=(root/'tests/DPH.Tests.Publishing.dpr').read_text(encoding='utf-8-sig').replace("in '..\\","in '..\\..\\").replace('docs\\wp6-','bin\\learner-sharing\\wp6-')
(root/'bin/learner-sharing/DPH.Tests.Publishing.dpr').write_text(source,encoding='utf-8-sig')
result=subprocess.run(['cmd','/d','/c','bin\\learner-sharing\\Publishing.cmd'],cwd=root,capture_output=True,text=True,errors='replace')
(root/'bin/learning-guides/publishing-final.log').write_text(result.stdout+result.stderr,encoding='utf-8')
print(result.returncode,(result.stdout+result.stderr)[-1100:])
if result.returncode:raise SystemExit(result.returncode)
validation=json.loads((root/'docs/guide-source-validation.json').read_text(encoding='utf-8-sig'))
validation['sources']['DPH.Publish.Export.pas']=hashlib.sha256((root/'DPH.Publish.Export.pas').read_bytes()).hexdigest()
(root/'docs/guide-source-validation.json').write_text(json.dumps(validation,indent=2)+'\n',encoding='utf-8')
print('Guide source evidence refreshed without changing finalized DOCX files')
