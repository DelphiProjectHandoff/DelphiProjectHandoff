from pathlib import Path
import json,csv,collections,subprocess,hashlib
r=Path.cwd();g=r'C:\Program Files\Git\cmd\git.exe'
p=r/'docs/Phase1_Requirements_Traceability.json';doc=json.loads(p.read_text(encoding='utf-8-sig'))
base=json.loads(subprocess.check_output([g,'show','ee8444c:docs/Phase1_Requirements_Traceability.json']))
assert [(x['id'],x['requirement']) for x in doc['requirements']]==[(x['id'],x['requirement']) for x in base['requirements']]
evidence=['DPH.Workspace.FormInheritance.pas','DPH.UI.Main.pas','DPH.UI.Main.fmx','tests/DPH.Tests.FormInheritance.dpr','tools/build-form-inheritance.cmd','docs/phase1-form-inheritance-validation.json','docs/phase1-form-inheritance-validation.log','docs/guides/Form_Inheritance_Run_and_Test.txt']
for row in doc['requirements']:
 if row['id']!='04.18':continue
 row.setdefault('audit_at_reconciliation',dict(row['reconciliation']));row['implementation']='implemented';row['evidence']=evidence
 row['limitation']='Static serialized overlays only. Missing, ambiguous and conditional ancestors, partial forms, orphan/incompatible children and cycles remain explicit. Class-to-form lookup uses matching Pascal file stems; aliases/custom resource mappings can remain unresolved. Framework defaults, collection-item merging and runtime dispatch/layout are unobserved. Work/output bounds reject excessive operations explicitly. Other inspectors retain their own captured-evidence qualifications.'
 row['reconciliation'].update(finding='Dedicated IDE-editable Form inheritance inspector resolves multi-level inherited forms and inherited inline frames, independent instance overlays, base-only components and renamed roots. Component/property/event origins retain exact source, fingerprint, range, condition and generation with base-to-derived histories, explicit nil event clearing, unresolved diagnostics, filter/pagination and guarded origin source navigation.',remaining_work='',verification='54 focused checks; 70 component dependency, 55 keyboard and 56 layout regression checks. Actual application and native FMX baseline pass; normal/compact/origin toolbar renders inspected.')
 row['implementation_update']={'date':'2026-10-11','batch':'Form inheritance and embedded frame overlays','validation':'docs/phase1-form-inheritance-validation.json','prior_audit_status':'partial'}
assert [x['id'] for x,b in zip(doc['requirements'],base['requirements']) if x!=b]==['04.18']
counts=dict(collections.Counter(x['implementation'] for x in doc['requirements']));assert counts=={'implemented_manual_capture':17,'partial':236,'implemented':178,'missing':102},counts
doc['completion']='RECONCILIATION COMPLETE; PRODUCT IMPLEMENTATION INCOMPLETE. Zero unassessed requirements. Form inheritance and embedded frames 04.18 implemented; 338 partial or missing requirement records remain.'
doc['current_implementation']={'date':'2026-10-11','completed_batch':'Form inheritance and embedded frame overlays','completed_requirement_ids':['04.18'],'counts':counts,'unassessed':0,'incomplete_requirement_records':338,'completion_record':'docs/Phase1_Form_Inheritance_Completion.txt','next_bounded_batch':{'requirement':'04.19','title':'User-visible actions and business purposes','scope':'Structured attributed action/task purpose mappings and review workflow; actual business outcomes require a knowledgeable contributor.'}}
p.write_text(json.dumps(doc,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
with (r/'docs/Phase1_Implementation_Backlog.csv').open('w',encoding='utf-8-sig',newline='') as out:
 w=csv.writer(out);w.writerow(['ID','Domain','Requirement / purpose','Status','Existing behavior','Remaining work','Batch','Evidence'])
 for row in doc['requirements']:
  if row['implementation'] not in ('partial','missing'):continue
  a=row['reconciliation'];w.writerow([row['id'],row['domain'],row['requirement'],row['implementation'],a['finding'],a['remaining_work'],a['batch'],'; '.join(row['evidence'])])
p=r/'docs/Implementation_Completion_Tracker.txt';s=p.read_text(encoding='utf-8-sig');s=s.replace('Current live backlog: 339 incomplete requirement records; 0 unassessed.','Form inheritance and embedded frames completed (04.18): multi-level form/frame\noverlays with property/event provenance, guarded origin navigation and native\ninspector; 54 focused and 181 regression checks.\nSee Phase1_Form_Inheritance_Completion.txt.\nCurrent live backlog: 338 incomplete requirement records; 0 unassessed.');p.write_text(s,encoding='utf-8')
for n,c in [('validation',54),('dependencies-regression',70),('keyboard-regression',55),('layout-regression',56)]:
 v=json.loads((r/f'docs/phase1-form-inheritance-{n}.json').read_text(encoding='utf-8-sig'));assert v['result']=='PASS' and v['checks']==c
for name in ['docs/Phase1_Reconciliation_Report.txt','docs/Phase1_Reconciliation_Batches.json','docs/Phase1_Reconciliation_Validation.json','DPH_Master_Development_Specification_v1.md','DPH_CODEX_HANDOFF.txt','DPH_PHASE1_MASTER_REQUIREMENTS.md']:
 assert (r/name).read_bytes().replace(b'\r\n',b'\n')==subprocess.check_output([g,'show','ee8444c:'+name]).replace(b'\r\n',b'\n'),name
print(json.dumps({'counts':counts,'incomplete':338,'requirements_preserved':533,'only_promoted_record':'04.18'}))
