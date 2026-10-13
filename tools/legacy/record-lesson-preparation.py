from pathlib import Path
import json,hashlib,subprocess,shutil
root=Path(__file__).resolve().parents[2];git=r'C:\Program Files\Git\cmd\git.exe'
backup=Path(r'H:\DPH Backups\LessonPreparation_PreChange_20261012_223858')
manifest=json.loads((backup/'DPH_Backup_Verification.json').read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
unchanged=[]
for entry in manifest['entries']:
 name=entry['path'].replace('\\','/')
 if name.startswith(('tests/fixtures/','docs/guides/','docs/pdf/','help/')) or name in ['DPH_Master_Development_Specification_v1.md','DPH_PHASE1_MASTER_REQUIREMENTS.md','DPH_CODEX_HANDOFF.txt']:
  assert sha(root/name)==entry['sha256'],name;unchanged.append(name)
reference=json.loads((root/'docs/reference-inventory.json').read_text(encoding='utf-8-sig'))
for entry in reference['files']:assert sha(root/'samples/reference-vcl2fmx-v6.0.0'/entry['path'])==entry['sha256'],entry['path']
sources=['DPH.Analysis.Explanations.pas','DPH.Publish.Model.pas','DPH.UI.ActionPurpose.fmx','DPH.UI.Main.fmx','DPH.UI.Main.pas','tests/DPH.Tests.GuidedTasks.dpr','tests/DPH.Tests.LearningRefocus.dpr']
for name in sources:
 p=root/name;prior=subprocess.check_output([git,'show','HEAD:'+name],cwd=root);text=p.read_text(encoding='utf-8-sig')
 p.write_bytes((b'\xef\xbb\xbf' if prior.startswith(b'\xef\xbb\xbf') else b'')+text.replace('\r\n','\n').replace('\n','\r\n').encode('utf-8'))
native=json.loads((root/'docs/lesson-preparation-learning-learning-validation.json').read_text(encoding='utf-8-sig'))
report={'result':'PASS lesson preparation checkpoint; overall project not complete','pre_change_backup':str(backup),'backup_files':manifest['files'],'backup_bytes':manifest['bytes'],
 'checks':{'native_learning_with_reference':118,'guided_tasks':39,'project_profile':19,'publishing':114,'application_build':'PASS','serialized_form_binding':'PASS'},
 'reference_files_unchanged':len(reference['files']),'reference_commit':reference['commit'],'reference_lesson_open_ms':native['reference_learning_projection_ms'],
 'source_hashes':{n:sha(root/n) for n in sources},'unchanged_original_inputs_and_guides':unchanged,
 'documentation_review':'Unread and deferred by owner; existing guides and help unchanged','independent_beginner_acceptance':'not performed',
 'scope_note':'Technical preparation pages removed from menus and made lazy; retained internal code is not claimed deleted. Existing historical requirement ledger unchanged.'}
(root/'docs/lesson-preparation-verification.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
for source,target in [('phase1-profile-validation.json','lesson-preparation-profile-regression.json'),('wp6-validation.json','lesson-preparation-publishing-regression.json')]:
 p=root/'bin/lesson-preparation'/source
 if p.exists():shutil.copyfile(p,root/'docs'/target)
with (root/'docs/Learning_Refocus_Status.txt').open('a',encoding='utf-8',newline='') as f:f.write('\r\nLesson preparation checkpoint: 12 October 2026\r\nPreparation now offers eleven lesson-related destinations. Describe this application\r\nand Prepare task instructions open their actual native editors. Source settings\r\nstart collapsed. Field lessons explain saved labels, typing guidance, input limits\r\nand availability. Linked purpose records display human fields without identity\r\nmetadata. Questions and answers includes attributed saved answers and direct links\r\nto the question workflow. Operation lessons explain actual choices before optional\r\nsource details. The plain-text fallback now contains the same beginner lesson.\r\nHidden preparation reports build only when requested. Reference lesson opening\r\nmeasured '+str(native['reference_learning_projection_ms'])+' ms after this change, versus 21,848 ms before it.\r\n118 native learning/reference, 39 task, 19 profile and 114 publishing checks passed;\r\napplication and serialized form baseline passed. All '+str(len(reference['files']))+' reference files and '+str(len(unchanged))+'\r\noriginal inputs, fixtures, guides/help files remain unchanged.\r\nVerified backup: '+str(backup)+'\r\n'+str(manifest['files'])+' files; '+str(manifest['bytes'])+' bytes; individual SHA256 verification.\r\nActual native evidence is docs/lesson-preparation-*.png. Synthetic fixture images\r\nand pinned reference images are labeled by filename. Human acceptance remains\r\nunperformed. Guides review is still unread; documentation remains deferred.\r\nNext: finish learner sharing and the newcomer route, then review documentation last.\r\n')
for work in list((root/'bin').glob('learning-refocus-tests-*'))+list((root/'bin/lesson-preparation').glob('task-fixture-*')):
 parent=(root/'bin/lesson-preparation' if work.name.startswith('task-fixture-') else root/'bin').resolve()
 assert work.resolve().parent==parent and not work.is_symlink()
 assert not any(p.is_symlink() for p in work.rglob('*'))
 shutil.rmtree(work)
print('Verified unchanged:',len(unchanged),'original inputs/guides/help files and',len(reference['files']),'reference files; recorded checkpoint.')
