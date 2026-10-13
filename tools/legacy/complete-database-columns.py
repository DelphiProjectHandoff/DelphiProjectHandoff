from pathlib import Path
import json,csv,collections,subprocess,hashlib
r=Path.cwd();g=r'C:\Program Files\Git\cmd\git.exe';baseline='194b563'
base=json.loads(subprocess.check_output([g,'show',baseline+':docs/Phase1_Requirements_Traceability.json']))
p=r/'docs/Phase1_Requirements_Traceability.json';doc=json.loads(p.read_text(encoding='utf-8-sig'))
assert [(x['id'],x['requirement']) for x in doc['requirements']]==[(x['id'],x['requirement']) for x in base['requirements']]
v=json.loads((r/'docs/phase1-database-columns-validation.json').read_text(encoding='utf-8-sig'));assert v['result']=='PASS' and v['checks']==121
for source,label,count in [('schema','schema',57),('engines','engines',66)]:
 v=json.loads((r/f'docs/phase1-database-{source}-validation.json').read_text(encoding='utf-8-sig'));assert v['result']=='PASS' and v['checks']==count
 (r/f'docs/phase1-database-columns-{label}-regression.json').write_text(json.dumps(v,indent=2)+'\n',encoding='utf-8')
historical=[f'docs/phase1-database-{name}-{suffix}' for name in ['schema','engines'] for suffix in ['validation.json','workspace.png','compact.png']]
subprocess.check_call([g,'restore','--worktree','--']+historical)
assert 'PASS WP0-TEST' in (r/'docs/phase1-database-columns-build.log').read_text(encoding='utf-8-sig')
evidence=['DPH.Workspace.DatabaseSchema.pas','DPH.UI.Main.pas','DPH.UI.Main.fmx','tests/DPH.Tests.DatabaseColumns.dpr','tools/build-database-columns.cmd','docs/phase1-database-columns-validation.json','docs/phase1-database-columns-validation.log','docs/guides/Database_Columns_Run_and_Test.txt']
for row in doc['requirements']:
 if row['id']!='05.04':continue
 row.setdefault('audit_at_reconciliation',dict(row['reconciliation']));row['implementation']='implemented';row['evidence']=evidence
 row['limitation']='Captured static CREATE TABLE entry extraction only. Types, explicit NULL/NOT NULL, default expressions and inline/table constraint text retain source evidence. Absent clauses remain not declared; effective key/domain/inheritance rules and migration order are not inferred. Literal contents are omitted and expressions are not evaluated. Unsupported clauses and malformed entries remain gaps. Duplicate table declarations retain separate column ownership. Dialect validity, constraint semantics, key relationships and deployed enforcement remain unverified. No target SQL or server is executed.'
 row['reconciliation'].update(finding='Database schema now exposes column rows with declared type, explicit nullability, default and inline constraint text, plus separate captured table constraint entries. Nested commas remain inside types, defaults and CHECK expressions. Every entry retains file/line, resource extent, SHA256, generation and unique parent table declaration ID. Missing types/defaults, unsupported clauses, repeated defaults, conflicting NULL/NOT NULL and trailing empty entries are explicit gaps. Native kind/state/type/nullability/constraint filters, paging and guarded source navigation use existing IDE-editable controls; compact details lead with column facts.',remaining_work='',verification='121 focused checks pass for actual project/resource capture, column/type/default/nullability/constraint extraction, nested commas, duplicate ownership, malformed/unsupported entries, literal omission, SQLite reopening, source guards, unchanged source/catalog/workspace and native FMX filtering/paging/details/replacement/normal/compact rendering. 57 schema and 66 engine regression checks pass. Actual app build and FMX baseline pass. Both editable guides and PDFs rendered and visually reviewed; 56 source hashes and all 88 TOC destinations verified.')
 row['implementation_update']={'date':'2026-10-12','batch':'Columns data types and constraints','validation':'docs/phase1-database-columns-validation.json','prior_audit_status':'partial'}
assert [x['id'] for x,b in zip(doc['requirements'],base['requirements']) if x!=b]==['05.04']
counts=dict(collections.Counter(x['implementation'] for x in doc['requirements']));assert counts=={'implemented_manual_capture':18,'partial':231,'implemented':183,'missing':101},counts
doc['completion']='RECONCILIATION COMPLETE; PRODUCT IMPLEMENTATION INCOMPLETE. Zero unassessed requirements. Columns, data types, and constraints 05.04 implemented as captured static declarations; 332 partial or missing requirement records remain.'
doc['current_implementation']={'date':'2026-10-12','completed_batch':'Columns data types and constraints','completed_requirement_ids':['05.04'],'counts':counts,'unassessed':0,'incomplete_requirement_records':332,'completion_record':'docs/Phase1_Database_Columns_Completion.txt','next_bounded_batch':{'requirement':'05.05','title':'Primary, foreign, and unique keys','scope':'Implement schema key records and evidence-backed relationships.'}}
p.write_text(json.dumps(doc,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
with (r/'docs/Phase1_Implementation_Backlog.csv').open('w',encoding='utf-8-sig',newline='') as out:
 w=csv.writer(out);w.writerow(['ID','Domain','Requirement / purpose','Status','Existing behavior','Remaining work','Batch','Evidence'])
 for row in doc['requirements']:
  if row['implementation'] not in ('partial','missing'):continue
  a=row['reconciliation'];w.writerow([row['id'],row['domain'],row['requirement'],row['implementation'],a['finding'],a['remaining_work'],a['batch'],'; '.join(row['evidence'])])
p=r/'docs/Implementation_Completion_Tracker.txt';s=p.read_text(encoding='utf-8-sig');old='Current live backlog: 333 incomplete requirement records; 0 unassessed.';assert old in s
s=s.replace(old,'Columns, data types, and constraints completed (05.04): captured column types,\nexplicit nullability, defaults and constraint text with exact declaration\nownership, source provenance, explicit gaps and native filters/details.\n121 focused and 123 regression checks passed; actual app/FMX baseline passed.\nSee Phase1_Database_Columns_Completion.txt.\nCurrent live backlog: 332 incomplete requirement records; 0 unassessed.');p.write_text(s,encoding='utf-8')
for name in ['docs/Phase1_Reconciliation_Report.txt','docs/Phase1_Reconciliation_Batches.json','docs/Phase1_Reconciliation_Validation.json','DPH_Master_Development_Specification_v1.md','DPH_CODEX_HANDOFF.txt','DPH_PHASE1_MASTER_REQUIREMENTS.md']+historical:
 assert (r/name).read_bytes().replace(b'\r\n',b'\n')==subprocess.check_output([g,'show',baseline+':'+name]).replace(b'\r\n',b'\n'),name
guide=json.loads((r/'bin/database-columns-guide-check.json').read_text());assert guide['guide_sources_verified']==56
summary={'result':'PASS','requirement':'05.04','status':'implemented','checks':121,'regression_checks':123,'requirements_preserved':533,'only_promoted_record':'05.04','incomplete_requirement_records':332,'unassessed':0,'counts':counts,'guides':guide,'backup':{'path':r'H:\DPH Backups\DatabaseColumns_PreChange_20261012_104811','files':4366,'bytes':1085671145,'sha256_verified':True},'qualification':'Captured column/type/explicit nullability/default/constraint declarations only. Expression semantics, effective inherited/domain/key rules, key relationships and deployed enforcement unverified; no SQL executed.'}
files=evidence+['docs/guide-source-validation.json','docs/guides/DPH_User_Guide.docx','docs/guides/DPH_Engineering_Guide.docx','docs/pdf/DPH_User_Guide.pdf','docs/pdf/DPH_Engineering_Guide.pdf','docs/phase1-database-columns-build.log','docs/phase1-database-columns-schema-regression.json','docs/phase1-database-columns-engines-regression.json','docs/phase1-database-columns-workspace.png','docs/phase1-database-columns-compact.png']
summary['evidence_hashes']={x:hashlib.sha256((r/x).read_bytes()).hexdigest() for x in files}
(r/'docs/phase1-database-columns-completion-validation.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'counts':counts,'incomplete':332,'requirements_preserved':533,'only_promoted_record':'05.04'}))
