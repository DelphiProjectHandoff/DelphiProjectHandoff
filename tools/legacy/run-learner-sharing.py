from pathlib import Path
import subprocess
root=Path(__file__).resolve().parents[2]
git=r'C:\Program Files\Git\cmd\git.exe'
for name in ['DPH.Analysis.Explanations.pas','DPH.Publish.Export.pas','DPH.Publish.Model.pas','DPH.Publish.BrowserPolicy.pas','DPH.UI.Main.fmx','DPH.UI.Main.pas','tests/DPH.Tests.Publishing.dpr','tests/DPH.Tests.LearningRefocus.dpr','tests/DPH.Tests.GuidedTasks.dpr']:
 p=root/name;prior=subprocess.check_output([git,'show','HEAD:'+name],cwd=root);text=p.read_text(encoding='utf-8-sig')
 p.write_bytes((b'\xef\xbb\xbf' if prior.startswith(b'\xef\xbb\xbf') else b'')+text.replace('\r\n','\n').replace('\n','\r\n').encode('utf-8'))
runner=(root/'bin/run-lesson-preparation.py').read_text(encoding='utf-8')
runner=runner.replace('bin/lesson-preparation','bin/learner-sharing').replace('bin\\\\lesson-preparation','bin\\\\learner-sharing')
runner=runner.replace('lesson-preparation-learning-','learner-sharing-learning-').replace('lesson-preparation-task-','learner-sharing-task-')
runner=runner.replace("out/'reference.dphdb'","root/'bin/lesson-preparation/reference.dphdb'")
(root/'bin/sharing-native-runner.py').write_text(runner,encoding='utf-8')
finish=(root/'bin/finish-lesson-preparation.py').read_text(encoding='utf-8')
finish=finish.replace('run-lesson-preparation.py','sharing-native-runner.py').replace('bin/lesson-preparation','bin/learner-sharing').replace('bin\\\\lesson-preparation','bin\\\\learner-sharing')
(root/'bin/sharing-finish-runner.py').write_text(finish,encoding='utf-8')
result=subprocess.run([r'C:\Users\marti\AppData\Local\Microsoft\WindowsApps\python.exe','bin/sharing-finish-runner.py'],cwd=root)
raise SystemExit(result.returncode)
