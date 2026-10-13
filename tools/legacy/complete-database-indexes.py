from pathlib import Path
import json,csv,collections,subprocess,hashlib
r=Path.cwd();g=r'C:\Program Files\Git\cmd\git.exe';baseline='706c610'
base=json.loads(subprocess.check_output([g,'show',baseline+':docs/Phase1_Requirements_Traceability.json']))
p=r/'docs/Phase1_Requirements_Traceability.json';doc=json.loads(p.read_text(encoding='utf-8-sig'))
assert len(doc['requirements'])==533
assert [(x['id'],x['requirement']) for x in doc['requirements']]==[(x['id'],x['requirement']) for x in base['requirements']]
v=json.loads((r/'docs/phase1-database-indexes-validation.json').read_text(encoding='utf-8-sig'));assert v['result']=='PASS' and v['checks']==273
historical=[]
for name,count in [('keys',173),('schema',57)]:
 v=json.loads((r/f'docs/phase1-database-{name}-validation.json').read_text(encoding='utf-8-sig'));assert v['result']=='PASS' and v['checks']==count
 (r/f'docs/phase1-database-indexes-{name}-regression.json').write_text(json.dumps(v,indent=2)+'\n')
 historical.extend(f'docs/phase1-database-{name}-{suffix}' for suffix in ['validation.json','workspace.png','compact.png'])
historical.append('docs/phase1-database-keys-relationships.png')
subprocess.check_call([g,'restore','--worktree','--']+historical)
assert 'PASS WP0-TEST' in (r/'docs/phase1-database-indexes-build.log').read_text(encoding='utf-8-sig')
evidence=['DPH.Workspace.DatabaseSchema.pas','DPH.UI.Main.pas','DPH.UI.Main.fmx','tests/DPH.Tests.DatabaseIndexes.dpr','tools/build-database-indexes.cmd','docs/phase1-database-indexes-validation.json','docs/phase1-database-indexes-validation.log','docs/guides/Database_Indexes_Run_and_Test.txt']
qualification='Supported captured CREATE INDEX declarations only: ordered plain/expression members, includes, predicates and options with exact captured table/column/SQL reference links. Unsupported grammar and missing/ambiguous evidence remain explicit gaps. Expressions and predicates are unevaluated text. SQL references do not prove index use; optimizer plans, timing, storage, benefit, dialect validity, effective migration order and deployed enforcement remain unverified. No target SQL, application or server is executed. Usage links are bounded to 250 per index and 10000 per projection, with total and shown counts retained.'
for row in doc['requirements']:
 if row['id']!='05.06':continue
 row.setdefault('audit_at_reconciliation',dict(row['reconciliation']));row['implementation']='implemented';row['evidence']=evidence;row['limitation']=qualification
 row['reconciliation'].update(finding='Database schema exposes supported CREATE INDEX declarations with explicit names, table ownership, uniqueness/storage/method flags, ordered members and sort/null ordering, included columns, predicates, options and tablespace. Exact unique table/parent-owned column targets and captured SQL table references are navigable evidence. Expressions, missing/ambiguous targets, duplicate declarations and unsupported grammar remain qualified gaps. IDE-editable kind/state filters and Follow relationship support exact targets across pages. Total SQL reference counts survive bounded navigation lists; structural links are retained.',remaining_work='',verification='273 focused checks pass for actual captured resources, index structures/options, exact target IDs, unresolved/conflicting evidence, unsupported syntax, literal omission, persistence, source guards, unchanged catalog/source/workspace, usage navigation limits and native filtering/navigation/replacement/normal/compact renders. 173 key and 57 schema regression checks pass. Actual app build and FMX baseline pass. Both DOCX guides and PDFs rendered and visually reviewed; 56 source hashes and 92 TOC destinations verified.')
 row['implementation_update']={'date':'2026-10-12','batch':'Indexes and performance-related structures','validation':'docs/phase1-database-indexes-validation.json','prior_audit_status':'missing'}
assert [x['id'] for x,b in zip(doc['requirements'],base['requirements']) if x!=b]==['05.06']
counts=dict(collections.Counter(x['implementation'] for x in doc['requirements']));assert counts=={'implemented_manual_capture':18,'partial':231,'implemented':185,'missing':99},counts
doc['completion']='RECONCILIATION COMPLETE; PRODUCT IMPLEMENTATION INCOMPLETE. Zero unassessed requirements. Indexes and performance-related structures 05.06 implemented as captured declarations and evidence-backed relationships; 330 partial or missing records remain.'
doc['current_implementation']={'date':'2026-10-12','completed_batch':'Indexes and performance-related structures','completed_requirement_ids':['05.06'],'counts':counts,'unassessed':0,'incomplete_requirement_records':330,'completion_record':'docs/Phase1_Database_Indexes_Completion.txt','next_bounded_batch':{'requirement':'05.07','title':'Stored procedures, functions, and triggers','scope':'Parse/import stored-object definitions, parameters and dependencies with source references.'}}
p.write_text(json.dumps(doc,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
with (r/'docs/Phase1_Implementation_Backlog.csv').open('w',encoding='utf-8-sig',newline='') as out:
 w=csv.writer(out);w.writerow(['ID','Domain','Requirement / purpose','Status','Existing behavior','Remaining work','Batch','Evidence'])
 for row in doc['requirements']:
  if row['implementation'] not in ('partial','missing'):continue
  a=row['reconciliation'];w.writerow([row['id'],row['domain'],row['requirement'],row['implementation'],a['finding'],a['remaining_work'],a['batch'],'; '.join(row['evidence'])])
p=r/'docs/Implementation_Completion_Tracker.txt';s=p.read_text(encoding='utf-8-sig');old='Current live backlog: 331 incomplete requirement records; 0 unassessed.';assert old in s
s=s.replace(old,'Indexes and performance-related structures completed (05.06): captured ordered\nindex structures, exact table/column and SQL reference evidence links, bounded\nusage navigation and explicit unsupported/ambiguous evidence gaps.\n273 focused and 230 regression checks passed; actual app/FMX baseline passed.\nSee Phase1_Database_Indexes_Completion.txt.\nCurrent live backlog: 330 incomplete requirement records; 0 unassessed.');p.write_text(s,encoding='utf-8')
for name in ['docs/Phase1_Reconciliation_Report.txt','docs/Phase1_Reconciliation_Batches.json','docs/Phase1_Reconciliation_Validation.json','DPH_Master_Development_Specification_v1.md','DPH_CODEX_HANDOFF.txt','DPH_PHASE1_MASTER_REQUIREMENTS.md']+historical:
 assert (r/name).read_bytes().replace(b'\r\n',b'\n')==subprocess.check_output([g,'show',baseline+':'+name]).replace(b'\r\n',b'\n'),name
guide=json.loads((r/'bin/database-indexes-guide-check.json').read_text());assert guide['guide_sources_verified']==56
summary={'result':'PASS','requirement':'05.06','status':'implemented','checks':273,'regression_checks':230,'requirements_preserved':533,'only_promoted_record':'05.06','incomplete_requirement_records':330,'unassessed':0,'counts':counts,'guides':guide,'backup':{'path':r'H:\DPH Backups\DatabaseIndexes_PreChange_20261012_123320','files':4523,'bytes':1323473847,'sha256_verified':True},'qualification':qualification}
files=evidence+['docs/guide-source-validation.json','docs/guides/DPH_User_Guide.docx','docs/guides/DPH_Engineering_Guide.docx','docs/pdf/DPH_User_Guide.pdf','docs/pdf/DPH_Engineering_Guide.pdf','docs/phase1-database-indexes-build.log','docs/phase1-database-indexes-keys-regression.json','docs/phase1-database-indexes-schema-regression.json','docs/phase1-database-indexes-workspace.png','docs/phase1-database-indexes-compact.png','docs/phase1-database-indexes-relationships.png']
summary['evidence_hashes']={x:hashlib.sha256((r/x).read_bytes()).hexdigest() for x in files}
(r/'docs/phase1-database-indexes-completion-validation.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'counts':counts,'incomplete':330,'requirements_preserved':533,'only_promoted_record':'05.06'}))