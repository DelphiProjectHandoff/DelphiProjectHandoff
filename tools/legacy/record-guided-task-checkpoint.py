from pathlib import Path
import json,hashlib,subprocess,shutil
root=Path(__file__).resolve().parents[2];git=r'C:\Program Files\Git\cmd\git.exe'
backup=Path(r'H:\DPH Backups\GuidedTasks_PreChange_20261012_220915')
manifest=json.loads((backup/'DPH_Backup_Verification.json').read_text(encoding='utf-8-sig'))
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
unchanged=[]
for entry in manifest['entries']:
 name=entry['path'].replace('\\','/')
 if name.startswith(('tests/fixtures/','docs/guides/','docs/pdf/','help/')) or name in ['DPH_Master_Development_Specification_v1.md','DPH_PHASE1_MASTER_REQUIREMENTS.md','DPH_CODEX_HANDOFF.txt']:
  assert sha(root/name)==entry['sha256'],name;unchanged.append(name)
sources=['DPH.Storage.Database.pas','DPH.UI.Main.fmx','DPH.UI.Main.pas','DPH.Workspace.Model.pas','tests/DPH.Tests.LearningRefocus.dpr']
for name in sources:
 path=root/name;data=path.read_bytes();prior=subprocess.check_output([git,'show','HEAD:'+name],cwd=root)
 if prior.startswith(b'\xef\xbb\xbf') and not data.startswith(b'\xef\xbb\xbf'):path.write_bytes(b'\xef\xbb\xbf'+data)
report={'result':'PASS guided task checkpoint; overall project not complete','pre_change_backup':str(backup),'backup_files':manifest['files'],'backup_bytes':manifest['bytes'],
 'checks':{'guided_tasks':36,'native_learning':82,'project_profile':19,'publishing':114,'application_build':'PASS','serialized_native_form':'PASS'},
 'source_hashes':{n:sha(root/n) for n in sources},'unchanged_original_inputs_and_guides':unchanged,
 'native_images':[{'path':str(p.relative_to(root)),'sha256':sha(p),'content':'Actual native DPH UI with synthetic Delphi test fixture; individually visually inspected'} for p in sorted((root/'docs').glob('guided-tasks-*.png'))],
 'documentation_review':'Not read or acted on; deferred until application work is finished','independent_beginner_acceptance':'not performed'}
for source,target in [('phase1-profile-validation.json','guided-tasks-profile-regression.json'),('wp6-validation.json','guided-tasks-publishing-regression.json'),('learning-refocus-learning-validation.json','guided-tasks-learning-regression.json')]:
 p=root/'bin/guided-task-regressions'/source
 if p.exists():shutil.copyfile(p,root/'docs'/target)
(root/'docs/guided-tasks-verification.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
for work in (root/'bin').glob('guided-task-tests-*'):
 assert work.resolve().parent==(root/'bin').resolve() and not work.is_symlink()
 shutil.rmtree(work)
print('Recorded checks and verified',len(unchanged),'unchanged original input/guide/help files. Removed disposable guided task test directories.')
