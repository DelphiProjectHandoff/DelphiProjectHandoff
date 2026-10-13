from pathlib import Path
import json,csv,collections,subprocess,hashlib
r=Path.cwd();g=r'C:\Program Files\Git\cmd\git.exe';baseline='82f5f79'
base=json.loads(subprocess.check_output([g,'show',baseline+':docs/Phase1_Requirements_Traceability.json']))
p=r/'docs/Phase1_Requirements_Traceability.json';doc=json.loads(p.read_text(encoding='utf-8-sig'))
assert len(doc['requirements'])==533
assert [(x['id'],x['requirement']) for x in doc['requirements']]==[(x['id'],x['requirement']) for x in base['requirements']]
for label,count in [('validation',232),('bindings-regression',92),('engines-regression',66),('semantics-regression',134)]:
 v=json.loads((r/f'docs/phase1-database-operations-{label}.json').read_text(encoding='utf-8-sig'))
 assert v.get('checks_passed',v.get('checks'))==count
 if label!='semantics-regression':assert v['result']=='PASS'
assert 'PASS WP0-TEST' in (r/'docs/phase1-database-operations-build.log').read_text(encoding='utf-8-sig')
guide=json.loads((r/'bin/database-operations-guide-check.json').read_text(encoding='utf-8-sig'))
assert guide['guide_sources_verified']==58 and sum(x['toc_entries'] for x in guide['guides'])==102
qualification='Qualified source operation candidates only, not database execution or success evidence. Runtime dispatch, aliases, within-with and factory/indexed receivers, unsupported providers and SQL prefixes, dynamic/mixed SQL, implicit posts, cached updates, triggers, affected row counts and transaction outcome remain unobserved. SQL family recognition does not invent schema bindings. SQL values are omitted from the operation inventory. Existing 10000-row bound applies. No target application, SQL, driver or database server runs.'
evidence=['DPH.Analysis.Model.pas','DPH.Analysis.Symbols.pas','DPH.Workspace.DatabaseConnections.pas','DPH.UI.Main.pas','DPH.UI.Main.fmx','tests/DPH.Tests.DatabaseOperations.dpr','tools/build-database-operations.cmd','docs/phase1-database-operations-validation.json','docs/phase1-database-operations-validation.log','docs/guides/Database_Operations_Run_and_Test.txt']
for row in doc['requirements']:
 if row['id']!='05.12':continue
 prior=row['implementation'];row.setdefault('audit_at_reconciliation',dict(row['reconciliation']));row['implementation']='implemented';row['evidence']=evidence;row['limitation']=qualification
 row['reconciliation'].update(finding='Database operation inventory captures recognized framework/descendant dataset read, insert, edit, post, delete, cancel and cached-update API requests plus static/dynamic SQL. Effects distinguish buffer preparation, configured SQL, execution requests and unverified persistence. Receiver/source identity, generation, conditional context, reverse references and engine evidence remain inspectable. IDE-editable operation filter and Source command support native navigation. Complex single SQL CRUD families are retained without inventing schema bindings; mixed/dynamic SQL stays unknown. Local framework-name shadows and ordinary Delete calls are excluded.',remaining_work='',verification='232 focused checks and 292 regressions pass (92 bindings, 66 engine, 134 semantics). Actual app and FMX baseline pass. Persisted/reopened captures, CRUD families, SQL joins/mixed/dynamic SQL, descendant receivers, name-shadow exclusion, source identity, effects, redaction, native controls, detached-source refusal, normal/compact renders and source/catalog immutability verified. Final guide page images visually reviewed; 58 source hashes and 102 TOC destinations verified.')
 row['implementation_update']={'date':'2026-10-12','batch':'Database operation inventory','validation':'docs/phase1-database-operations-validation.json','prior_audit_status':prior}
assert [x['id'] for x,b in zip(doc['requirements'],base['requirements']) if x!=b]==['05.12']
counts=dict(collections.Counter(x['implementation'] for x in doc['requirements']));assert counts=={'implemented_manual_capture':18,'partial':229,'implemented':190,'missing':96},counts
doc['completion']='RECONCILIATION COMPLETE; PRODUCT IMPLEMENTATION INCOMPLETE. Zero unassessed requirements. Database operation inventory 05.12 implemented with qualified source effects and receiver/source navigation; 325 partial or missing records remain.'
doc['current_implementation']={'date':'2026-10-12','completed_batch':'Database operation inventory','completed_requirement_ids':['05.12'],'counts':counts,'unassessed':0,'incomplete_requirement_records':325,'completion_record':'docs/Phase1_Database_Operations_Completion.txt','next_bounded_batch':{'requirement':'05.13','title':'Transaction boundaries and rollback behavior','scope':'Recognize selected-program begin/commit/rollback APIs and connect success/error/cleanup paths.'}}
p.write_text(json.dumps(doc,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
with (r/'docs/Phase1_Implementation_Backlog.csv').open('w',encoding='utf-8-sig',newline='') as out:
 w=csv.writer(out);w.writerow(['ID','Domain','Requirement / purpose','Status','Existing behavior','Remaining work','Batch','Evidence'])
 for row in doc['requirements']:
  if row['implementation'] not in ('partial','missing'):continue
  a=row['reconciliation'];w.writerow([row['id'],row['domain'],row['requirement'],row['implementation'],a['finding'],a['remaining_work'],a['batch'],'; '.join(row['evidence'])])
p=r/'docs/Implementation_Completion_Tracker.txt';s=p.read_text(encoding='utf-8-sig');old='Current live backlog: 326 incomplete requirement records; 0 unassessed.';assert old in s
s=s.replace(old,'Database operation inventory completed (05.12): recognized dataset CRUD and\nSQL candidates, requested effects, exact receiver and source navigation.\n232 focused and 292 regression checks passed; actual app/FMX baseline passed.\nSee Phase1_Database_Operations_Completion.txt.\nCurrent live backlog: 325 incomplete requirement records; 0 unassessed.');p.write_text(s,encoding='utf-8')
for name in ['docs/Phase1_Reconciliation_Report.txt','docs/Phase1_Reconciliation_Batches.json','docs/Phase1_Reconciliation_Validation.json','DPH_Master_Development_Specification_v1.md','DPH_CODEX_HANDOFF.txt','DPH_PHASE1_MASTER_REQUIREMENTS.md']:
 assert (r/name).read_bytes().replace(b'\r\n',b'\n')==subprocess.check_output([g,'show',baseline+':'+name]).replace(b'\r\n',b'\n'),name
backup={'path':r'H:\DPH Backups\DatabaseOperations_PreChange_20261012_145836','files':5253,'bytes':1810651908,'sha256_verified':True}
pages=sum(x['pages'] for x in guide['guides'])
completion=f'''DPH REQUIREMENT 05.12 COMPLETION DATABASE OPERATIONS
Last changed: 12 October 2026

Database connections now inventories recognized dataset read, insert, update
and delete requests with plain effects, exact source/generation evidence and
receiver links. Append/Insert/Edit preparation, Post, cached writes, cancellation,
SQL configuration and execution requests remain distinct. Literal CRUD SQL
families extend beyond the old single-table subset without inventing table or
column binding. Mixed batches and dynamic SQL remain unknown. Custom dataset
descendants retain receiver declarations; local name shadows are excluded.
Native kind/text filters, pagination, reverse references, Follow reference and
hash-checked Source are implemented using IDE-editable controls.

Validation PASS: 232 focused + 92 bindings + 66 engine + 134 semantic = 524 checks.
Actual application and FMX baseline PASS. Normal and compact native renders
reviewed; these show running DPH controls, not selected-application screenshots.
All {pages} final guide pages visually reviewed. 58 source hashes and 102 TOC
destinations verified. User contents balanced across two readable pages.
Run/test directions: docs/guides/Database_Operations_Run_and_Test.txt.

Pre-change backup: {backup['path']}
5253 files, 1810651908 bytes; every SHA256 verified. No post-change backup.

{qualification}

Only 05.12 promoted. All 533 original requirement IDs and texts preserved.
190 implemented; 18 implemented_manual_capture; 229 partial; 96 missing.
325 incomplete; zero unassessed. The entire product is not complete.
Next: 05.13 Transaction boundaries and rollback behavior.
'''
(r/'docs/Phase1_Database_Operations_Completion.txt').write_text(completion,encoding='utf-8')
summary={'result':'PASS','requirement':'05.12','status':'implemented','checks':232,'regression_checks':292,'requirements_preserved':533,'only_promoted_record':'05.12','incomplete_requirement_records':325,'unassessed':0,'counts':counts,'guides':guide,'guide_visual_review':f'All {pages} final pages reviewed; no clipping or broken TOC destinations observed.','backup':backup,'qualification':qualification}
files=evidence+['tools/build-guides.py','README.md','help/index.html','docs/guide-source-validation.json','docs/guides/DPH_User_Guide.docx','docs/guides/DPH_Engineering_Guide.docx','docs/pdf/DPH_User_Guide.pdf','docs/pdf/DPH_Engineering_Guide.pdf','docs/phase1-database-operations-build.log','docs/Phase1_Database_Operations_Completion.txt','docs/Phase1_Requirements_Traceability.json','docs/Phase1_Implementation_Backlog.csv','docs/Implementation_Completion_Tracker.txt','docs/phase1-database-operations-workspace.png','docs/phase1-database-operations-compact.png']
for label in ['bindings','engines','semantics']:
 for ext in ['json','log']:files.append(f'docs/phase1-database-operations-{label}-regression.{ext}')
summary['evidence_hashes']={x:hashlib.sha256((r/x).read_bytes()).hexdigest() for x in files}
(r/'docs/phase1-database-operations-completion-validation.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'counts':counts,'incomplete':325,'requirements_preserved':533,'only_promoted_record':'05.12','evidence_files':len(files)}))
