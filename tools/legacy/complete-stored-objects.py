from pathlib import Path
import json,csv,collections,subprocess,hashlib
r=Path.cwd();g=r'C:\Program Files\Git\cmd\git.exe';baseline='96e87c7'
base=json.loads(subprocess.check_output([g,'show',baseline+':docs/Phase1_Requirements_Traceability.json']))
p=r/'docs/Phase1_Requirements_Traceability.json';doc=json.loads(p.read_text(encoding='utf-8-sig'))
assert len(doc['requirements'])==533
assert [(x['id'],x['requirement']) for x in doc['requirements']]==[(x['id'],x['requirement']) for x in base['requirements']]
v=json.loads((r/'docs/phase1-database-stored-objects-validation.json').read_text(encoding='utf-8-sig'));assert v['result']=='PASS' and v['checks']==363
historical=[]
for name,count in [('indexes',273),('schema',57)]:
 v=json.loads((r/f'docs/phase1-database-{name}-validation.json').read_text(encoding='utf-8-sig'));assert v['result']=='PASS' and v['checks']==count
 (r/f'docs/phase1-database-stored-objects-{name}-regression.json').write_text(json.dumps(v,indent=2)+'\n')
 historical.extend(f'docs/phase1-database-{name}-{suffix}' for suffix in ['validation.json','workspace.png','compact.png'])
historical.append('docs/phase1-database-indexes-relationships.png')
subprocess.check_call([g,'restore','--worktree','--']+historical)
assert 'PASS WP0-TEST' in (r/'docs/phase1-database-stored-objects-build.log').read_text(encoding='utf-8-sig')
evidence=['DPH.Workspace.DatabaseSchema.pas','DPH.UI.Main.pas','DPH.UI.Main.fmx','tests/DPH.Tests.DatabaseStoredObjects.dpr','tools/build-database-stored-objects.cmd','docs/phase1-database-stored-objects-validation.json','docs/phase1-database-stored-objects-validation.log','docs/guides/Database_Stored_Objects_Run_and_Test.txt']
qualification='Supported captured CREATE procedure/function/trigger definitions only: named ordered parameters, scalar returns, trigger structure and sanitized body text with supported literal table/explicit call evidence. Unsupported grammar, dynamic execution, complex/CTE binding, missing/ambiguous declarations and overloads remain explained gaps. Body grammar, expression/column/alias binding, dialect validity, permissions, migration order and deployed effects are unverified. Dependency display is capped at 1000 per object and 10000 per projection; body display is approximately 16000 characters. No target SQL, application or server is executed.'
for row in doc['requirements']:
 if row['id']!='05.07':continue
 row.setdefault('audit_at_reconciliation',dict(row['reconciliation']));row['implementation']='implemented';row['evidence']=evidence;row['limitation']=qualification
 row['reconciliation'].update(finding='Database schema exposes captured procedures, functions and triggers with explicit names, header operations, ordered parameter names/modes/types/defaults/source lines, scalar returns, language and sanitized inline/single-quoted/dollar-quoted bodies. Trigger timing/events/table/scope/WHEN and supported explicit trigger-function calls are retained. Supported body table/explicit routine references receive exact unique captured-name links; missing/ambiguous evidence, overloads, dynamic execution and CTE/complex binding remain explained. Internal DDL stays inside stored bodies, batch separators preserve following definitions, and bounds prevent unbounded projections. IDE-editable selectors, parameter/body filtering, exact-ID Follow relationship and guarded source reading remain.',remaining_work='',verification='363 focused checks pass for actual captured resources, ordered parameters/defaults/returns, trigger structure, quoted bodies, nested blocks, exact source references and dependency targets, missing/ambiguous evidence, overloads, unsupported syntax, literal omission, bounds, batch boundaries, SQLite reopening, source guards, unchanged catalog/source/workspace and native filtering/navigation/replacement/normal/compact renders. 273 index and 57 schema regression checks pass. Actual app build and FMX baseline pass. Both DOCX guides and PDFs rendered and visually reviewed; 56 source hashes and 94 TOC destinations verified.')
 row['implementation_update']={'date':'2026-10-12','batch':'Stored procedures functions and triggers','validation':'docs/phase1-database-stored-objects-validation.json','prior_audit_status':'missing'}
assert [x['id'] for x,b in zip(doc['requirements'],base['requirements']) if x!=b]==['05.07']
counts=dict(collections.Counter(x['implementation'] for x in doc['requirements']));assert counts=={'implemented_manual_capture':18,'partial':231,'implemented':186,'missing':98},counts
doc['completion']='RECONCILIATION COMPLETE; PRODUCT IMPLEMENTATION INCOMPLETE. Zero unassessed requirements. Stored procedures, functions, and triggers 05.07 implemented as captured definitions, parameters and evidence-backed dependencies; 329 partial or missing records remain.'
doc['current_implementation']={'date':'2026-10-12','completed_batch':'Stored procedures functions and triggers','completed_requirement_ids':['05.07'],'counts':counts,'unassessed':0,'incomplete_requirement_records':329,'completion_record':'docs/Phase1_Database_Stored_Objects_Completion.txt','next_bounded_batch':{'requirement':'05.08','title':'Entity-relationship diagrams','scope':'Generate an ER diagram from verified table/key metadata and label incomplete schemas.'}}
p.write_text(json.dumps(doc,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
with (r/'docs/Phase1_Implementation_Backlog.csv').open('w',encoding='utf-8-sig',newline='') as out:
 w=csv.writer(out);w.writerow(['ID','Domain','Requirement / purpose','Status','Existing behavior','Remaining work','Batch','Evidence'])
 for row in doc['requirements']:
  if row['implementation'] not in ('partial','missing'):continue
  a=row['reconciliation'];w.writerow([row['id'],row['domain'],row['requirement'],row['implementation'],a['finding'],a['remaining_work'],a['batch'],'; '.join(row['evidence'])])
p=r/'docs/Implementation_Completion_Tracker.txt';s=p.read_text(encoding='utf-8-sig');old='Current live backlog: 330 incomplete requirement records; 0 unassessed.';assert old in s
s=s.replace(old,'Stored procedures, functions, and triggers completed (05.07): captured definitions,\nordered parameters/defaults/returns, trigger structure, sanitized bodies and\nsupported exact-name dependency evidence with unresolved cases and limits.\n363 focused and 330 regression checks passed; actual app/FMX baseline passed.\nSee Phase1_Database_Stored_Objects_Completion.txt.\nCurrent live backlog: 329 incomplete requirement records; 0 unassessed.');p.write_text(s,encoding='utf-8')
for name in ['docs/Phase1_Reconciliation_Report.txt','docs/Phase1_Reconciliation_Batches.json','docs/Phase1_Reconciliation_Validation.json','DPH_Master_Development_Specification_v1.md','DPH_CODEX_HANDOFF.txt','DPH_PHASE1_MASTER_REQUIREMENTS.md']+historical:
 assert (r/name).read_bytes().replace(b'\r\n',b'\n')==subprocess.check_output([g,'show',baseline+':'+name]).replace(b'\r\n',b'\n'),name
guide=json.loads((r/'bin/database-stored-objects-guide-check.json').read_text());assert guide['guide_sources_verified']==56
assert sum(x['toc_entries'] for x in guide['guides'])==94
summary={'result':'PASS','requirement':'05.07','status':'implemented','checks':363,'regression_checks':330,'requirements_preserved':533,'only_promoted_record':'05.07','incomplete_requirement_records':329,'unassessed':0,'counts':counts,'guides':guide,'backup':{'path':r'H:\DPH Backups\DatabaseStoredObjects_PreChange_20261012_125632','files':4605,'bytes':1435720789,'sha256_verified':True},'qualification':qualification}
files=evidence+['docs/guide-source-validation.json','docs/guides/DPH_User_Guide.docx','docs/guides/DPH_Engineering_Guide.docx','docs/pdf/DPH_User_Guide.pdf','docs/pdf/DPH_Engineering_Guide.pdf','docs/phase1-database-stored-objects-build.log','docs/phase1-database-stored-objects-indexes-regression.json','docs/phase1-database-stored-objects-schema-regression.json','docs/phase1-database-stored-objects-workspace.png','docs/phase1-database-stored-objects-compact.png','docs/phase1-database-stored-objects-relationships.png','docs/Phase1_Database_Stored_Objects_Completion.txt']
summary['evidence_hashes']={x:hashlib.sha256((r/x).read_bytes()).hexdigest() for x in files}
(r/'docs/phase1-database-stored-objects-completion-validation.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'counts':counts,'incomplete':329,'requirements_preserved':533,'only_promoted_record':'05.07'}))
