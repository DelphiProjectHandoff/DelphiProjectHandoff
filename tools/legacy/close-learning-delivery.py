from pathlib import Path
import json,shutil,re,hashlib
root=Path(__file__).resolve().parents[2]
record_path=root/'docs/learning-distribution-validation.json'
record=json.loads(record_path.read_text(encoding='utf-8-sig'))
for field in ['verification_directory','source_verification_directory']:
 p=Path(record[field]);assert p.resolve().parent==(root/'bin').resolve()
 assert p.name.startswith(('distribution-verify-','delivery-source-check-')) and not p.is_symlink() and not p.is_junction()
 assert not any(x.is_symlink() or x.is_junction() for x in p.rglob('*'))
 shutil.rmtree(p)
record['disposable_extractions_removed_after_checks']=True
record_path.write_text(json.dumps(record,indent=2)+'\n',encoding='utf-8')
# These are this phase's known generated test workspaces; source and owner stores are elsewhere.
for parent,pattern in [(root/'bin',r'(?:wp6|learning-refocus)-tests-\{[0-9A-Fa-f-]{36}\}'),(root/'bin/learner-sharing',r'task-fixture-[0-9a-f-]{36}')]:
 for p in parent.iterdir():
  if not p.is_dir() or not re.fullmatch(pattern,p.name):continue
  assert p.resolve().parent==parent.resolve() and not p.is_symlink() and not p.is_junction()
  assert not any(x.is_symlink() or x.is_junction() for x in p.rglob('*'))
  shutil.rmtree(p)
with (root/'docs/Learning_Refocus_Status.txt').open('a',encoding='utf-8',newline='') as f:f.write('''\r\nDelivery verification: 13 October 2026\r\nDPH 0.4.0 experimental desktop and source ZIPs were created. The desktop ZIP\r\nwas extracted, checksum-checked, launched as a new instance with an empty\r\ntemporary catalog, found responsive and closed normally. Owner preferences\r\nwere restored. The extracted source ZIP built successfully and passed the\r\nnative form baseline. Package text was checked for personal paths and\r\ndevelopment-history leakage; owner databases and PDF copies are excluded.\r\nDisposable extraction and test directories were removed after validation.\r\nReady-to-run folder: bin/distribution/DPH-0.4.0-experimental-Win32\r\nDesktop ZIP: export/DPH-0.4.0-experimental-Win32.zip\r\nSource ZIP: source distributions/DPH-0.4.0-experimental-source.zip\r\nStart DelphiProjectHandoff.exe. Follow docs/guides/Run_And_Test.txt for the\r\nrepeatable first session. Current PDF and editable guides are in docs/pdf and\r\ndocs/guides. Independent human learning acceptance remains unperformed.\r\nThis refocus does not relabel the old technical requirement ledger complete.\r\n''')
delivery={'result':'PASS refocused learning build and current manuals ready for owner use; no blanket legacy completion claim',
 'checks':{'learning_with_reference':121,'guided_tasks_and_export':43,'profile':19,'publishing':124,'application_build':'PASS','native_form_baseline':'PASS','extracted_desktop_launch':'PASS','extracted_source_build':'PASS'},
 'manuals':{'user_pages':13,'engineering_pages':10,'editable_contents':'populated','all_final_pages_visually_inspected':True,'personal_paths':'absent'},
 'package':record,'independent_beginner_acceptance':'not performed','legacy_requirements':'Historical 533-record ledger unchanged; scope and status are not silently rewritten',
 'older_technical_guides':'Remain in repository following broad-deletion auto-review rejection; excluded from current package',
 'ready_executable':'bin/distribution/DPH-0.4.0-experimental-Win32/DelphiProjectHandoff.exe','directions':'docs/guides/Run_And_Test.txt'}
(root/'docs/learning-delivery-validation.json').write_text(json.dumps(delivery,indent=2)+'\n',encoding='utf-8')
print('Recorded final learning delivery. Removed disposable test/extraction copies; ready-to-run distribution retained.')
