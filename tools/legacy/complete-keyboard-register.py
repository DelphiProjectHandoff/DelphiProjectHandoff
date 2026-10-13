from pathlib import Path
import collections,csv,hashlib,json,subprocess
root=Path(__file__).resolve().parent.parent.parent
git=r'C:\Program Files\Git\cmd\git.exe'
path=root/'docs/Phase1_Requirements_Traceability.json'
ledger=json.loads(path.read_text(encoding='utf-8-sig'))
baseline=json.loads(subprocess.check_output([git,'show','517e05b:docs/Phase1_Requirements_Traceability.json'],cwd=root))
assert [(r['id'],r['requirement']) for r in ledger['requirements']]==[(r['id'],r['requirement']) for r in baseline['requirements']]
evidence=['DPH.Workspace.Keyboard.pas','DPH.UI.Main.pas','DPH.UI.Main.fmx','tests/DPH.Tests.Keyboard.dpr','tools/build-keyboard.cmd','docs/phase1-keyboard-validation.json','docs/phase1-keyboard-validation.log','docs/guides/Keyboard_and_Focus_Run_and_Test.txt']
for row in ledger['requirements']:
    if row['id']!='04.13':continue
    row.setdefault('audit_at_reconciliation',dict(row['reconciliation']))
    row['implementation']='implemented'
    row['evidence']=evidence
    row['limitation']='Static captured declarations, not runtime traversal or accessibility proof. Missing/default/inherited properties remain unknown; external/custom/ambiguous actions remain unresolved. Secondary shortcut collections remain raw evidence and are excluded from decoded conflicts. Common key names follow Windows conventions.'
    row['reconciliation'].update(finding='Dedicated IDE-editable keyboard/focus inspector: DFM/FMX/binary declarations, parent-local TabOrder, focus flags, original/readable shortcuts, local action references, keyboard events, scoped duplicate/unknown diagnostics, filtering, 250-row paging and generation/hash/path-verified source navigation.',remaining_work='',verification='55 focused checks passed, native form resources and compact renders inspected; actual application build/FMX baseline and 57-check glossary regression passed.')
    row['implementation_update']={'date':'2026-10-11','batch':'Keyboard and focus inspector','validation':'docs/phase1-keyboard-validation.json','prior_audit_status':'partial'}
counts=dict(collections.Counter(r['implementation'] for r in ledger['requirements']))
assert counts=={'implemented_manual_capture':17,'partial':241,'implemented':173,'missing':102},counts
assert [r['id'] for r,b in zip(ledger['requirements'],baseline['requirements']) if r['implementation']!=b['implementation']]==['04.13']
ledger['completion']='RECONCILIATION COMPLETE; PRODUCT IMPLEMENTATION INCOMPLETE. Zero unassessed requirements. Glossary 06.12/12.09 and keyboard/focus 04.13 implemented; 343 partial or missing requirement records remain.'
ledger['current_implementation']={'date':'2026-10-11','completed_batch':'Keyboard and focus inspector','completed_requirement_ids':['04.13'],'counts':counts,'unassessed':0,'incomplete_requirement_records':343,'completion_record':'docs/Phase1_Keyboard_Completion.txt','next_bounded_batch':{'requirement':'04.14','title':'Menus, context menus, and toolbars','scope':'Dedicated command inventory and captured action-to-handler/shortcut relationships, source evidence, unresolved states, native views, acceptance checks and directions.'}}
path.write_text(json.dumps(ledger,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
with (root/'docs/Phase1_Implementation_Backlog.csv').open('w',encoding='utf-8-sig',newline='') as stream:
    writer=csv.writer(stream);writer.writerow(['ID','Domain','Requirement / purpose','Status','Existing behavior','Remaining work','Batch','Evidence'])
    for row in ledger['requirements']:
        if row['implementation'] not in ('partial','missing'):continue
        a=row['reconciliation'];writer.writerow([row['id'],row['domain'],row['requirement'],row['implementation'],a['finding'],a['remaining_work'],a['batch'],'; '.join(row['evidence'])])
tracker=root/'docs/Implementation_Completion_Tracker.txt'
t=tracker.read_text(encoding='utf-8-sig').replace('Current live backlog: 344 incomplete requirement records; 0 unassessed.','Keyboard and focus inspector completed (04.13): native view, scoped conflicts,\nsource safeguards, 55 focused checks; see Phase1_Keyboard_Completion.txt.\nCurrent live backlog: 343 incomplete requirement records; 0 unassessed.')
tracker.write_text(t,encoding='utf-8')
assert len(list(csv.DictReader((root/'docs/Phase1_Implementation_Backlog.csv').open(encoding='utf-8-sig'))))==343
for name in ['Phase1_Reconciliation_Report.txt','Phase1_Reconciliation_Batches.json','Phase1_Reconciliation_Validation.json']:
    assert (root/'docs'/name).read_bytes().replace(b'\r\n',b'\n')==subprocess.check_output([git,'show','517e05b:docs/'+name],cwd=root).replace(b'\r\n',b'\n'),name
guide=json.loads((root/'docs/guide-source-validation.json').read_text())
for item in guide['sources']:assert hashlib.sha256((root/item['path']).read_bytes()).hexdigest()==item['sha256']
validation=json.loads((root/'docs/phase1-keyboard-validation.json').read_text(encoding='utf-8-sig'))
assert validation['checks']==55 and validation['result']=='PASS'
files=evidence+['DelphiProjectHandoff.dproj','docs/Phase1_Keyboard_Completion.txt','docs/Phase1_Requirements_Traceability.json','docs/Phase1_Implementation_Backlog.csv','docs/guides/DPH_User_Guide.docx','docs/guides/DPH_Engineering_Guide.docx','docs/pdf/DPH_User_Guide.pdf','docs/pdf/DPH_Engineering_Guide.pdf','docs/phase1-keyboard-workspace.png','docs/phase1-keyboard-compact.png']
report={'result':'PASS','baseline_commit':'517e05b','completed_requirement_ids':['04.13'],'counts':counts,'incomplete':343,'unassessed':0,'requirements_preserved':533,'focused_checks':55,'glossary_regression_checks':57,'application_and_fmx_baseline':'PASS','pre_change_backup':r'H:\DPH Backups\KeyboardFocus_PreChange_20261011_210032','backup_files':3239,'backup_bytes':655656938,'guide_sources_verified':len(guide['sources']),'evidence':[{'path':f,'sha256':hashlib.sha256((root/f).read_bytes()).hexdigest()} for f in files]}
(root/'docs/phase1-keyboard-completion-validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:report[k] for k in ['result','completed_requirement_ids','counts','incomplete','unassessed','guide_sources_verified']},indent=2))
