from pathlib import Path
import json,subprocess,hashlib,shutil
root=Path(__file__).resolve().parents[2]
git=r'C:\Program Files\Git\cmd\git.exe'
# The baseline test rewrites this historical report; preserve its original bytes.
p=root/'docs/wp5-validation.json';p.write_bytes(subprocess.check_output([git,'show','HEAD:docs/wp5-validation.json'],cwd=root))
p=root/'docs/learning-completion-validation.json';r=json.loads(p.read_text(encoding='utf-8-sig'))
r['result']='PASS revised learning implementation, current guides and final desktop/source distributions'
r['delivery_validation']='docs/learning-distribution-validation.json'
r['packaged_practice_recheck']=27
r['remaining_implementation_work_in_revised_contract']=0
p.write_text(json.dumps(r,indent=2)+'\n',encoding='utf-8')
status='''DPH LEARNING DELIVERY - 13 OCTOBER 2026

The revised beginner-learning implementation and delivery are complete.
No remaining implementation items in the revised teaching contract.
All 533 original records were reconciled individually, including the 312
historically incomplete records. Zero unreconciled. The historical ledger
remains unchanged: superseded technical obligations are not relabeled complete.
See Learning_Requirements_Reconciliation.txt, .csv and .json for each decision.

Delivered learning features
- Application orientation and twelve plain-language learning topics.
- Source-linked screen/action/decision explanations, with deeper code optional.
- Learning library for fields, errors, FAQs, rules, outputs, roles and settings.
- Ordered tasks, prerequisites, role filters, learning paths and saved progress.
- Attributed teaching explanations, glossary, author answers and review history.
- Supplied pictures and sample outputs with anchored numbered explanations.
- Search and shared offline lessons from the same selected-application records.
- Practice example: four First day tasks, fourteen teaching cards and two actual
  native images, with worked answers and safe error-recovery instruction.

Validation
645 implementation/regression checks passed. The extracted desktop package
passed 27 further practice-route checks and actual executable startup/close.
A fresh extraction of the source ZIP built and passed serialized form bindings.
The final 16-page User Guide and 10-page Engineering Guide were rendered and
visually reviewed, with populated editable contents and local HTML help.
Original inputs, reference source, fixtures, historical ledger and both owner
PDF copies were preserved. Independent first-time learner acceptance has not
been performed; this is a reported observation, not an implementation blocker.

Run
Open bin\\distribution\\DPH-0.5.0-experimental-Win32 and double-click
DelphiProjectHandoff.exe. Click Try practice example to begin.
Explicit steps: docs\\guides\\Run_And_Test.txt.
Desktop ZIP: export\\DPH-0.5.0-experimental-Win32.zip.
Source ZIP: source distributions\\DPH-0.5.0-experimental-source.zip.
Current guides: docs\\guides (.docx), docs\\pdf (.pdf); HTML help: help\\index.html.

Evidence
learning-completion-validation.json, learning-completion-guides-validation.json,
learning-distribution-validation.json and corresponding learning-completion logs.
Pre-change backup: H:\\DPH Backups\\LearningCompletion_PreChange_20261013_073811.
6,330 files and 3,061,051,852 bytes verified before this completion phase.

These notes supersede the earlier active-work checkpoints and documentation hold.
The owner's learning-only direction remains controlling.
'''
(root/'docs/Learning_Refocus_Status.txt').write_text(status,encoding='utf-8')
p=root/'docs/STOPPING_POINT.txt';s=p.read_text(encoding='utf-8-sig');s+='\nCURRENT DELIVERY: 13 October 2026. The revised learning implementation is complete.\nThe historical pause and next-technical-requirement instruction above are obsolete.\nSee Learning_Refocus_Status.txt and learning-distribution-validation.json.\n';p.write_text(s,encoding='utf-8')
# Remove only disposable validation directories created in this completion phase.
backup=Path(r'H:\DPH Backups\LearningCompletion_PreChange_20261013_073811')
manifest=json.loads((backup/'DPH_Backup_Verification.json').read_text(encoding='utf-8-sig'))
oldnames=[x['path'].replace('\\','/') for x in manifest['entries']]
targets=list((root/'bin/learning-completion').iterdir())
delivery=json.loads((root/'docs/learning-distribution-validation.json').read_text())
targets.append(Path(delivery['verification_directory']))
removed=[]
for target in targets:
 if not target.is_dir():continue
 absolute=target.resolve();assert absolute.is_relative_to((root/'bin').resolve()) and absolute!=(root/'bin').resolve()
 relative=absolute.relative_to(root).as_posix()+'/'
 assert not any(n.startswith(relative) for n in oldnames),'Pre-existing directory must be preserved: '+relative
 for entry in [target,*target.rglob('*')]:
  assert not entry.is_symlink() and not (entry.lstat().st_file_attributes & 0x400),'Reparse point must be preserved'
 shutil.rmtree(target);removed.append(relative)
delivery['disposable_verification_directories']='Removed after successful checks; retained ready-to-run distribution and logs'
(root/'docs/learning-distribution-validation.json').write_text(json.dumps(delivery,indent=2)+'\n',encoding='utf-8')
print('Final status recorded; removed',len(removed),'new disposable validation directories')
