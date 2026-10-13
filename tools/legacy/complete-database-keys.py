from pathlib import Path
import json,csv,collections,subprocess,hashlib
r=Path.cwd();g=r'C:\Program Files\Git\cmd\git.exe';baseline='33d9806'
base=json.loads(subprocess.check_output([g,'show',baseline+':docs/Phase1_Requirements_Traceability.json']))
p=r/'docs/Phase1_Requirements_Traceability.json';doc=json.loads(p.read_text(encoding='utf-8-sig'))
assert [(x['id'],x['requirement']) for x in doc['requirements']]==[(x['id'],x['requirement']) for x in base['requirements']]
v=json.loads((r/'docs/phase1-database-keys-validation.json').read_text(encoding='utf-8-sig'));assert v['result']=='PASS' and v['checks']==173
historical=[]
for name,count in [('columns',121),('schema',57)]:
 v=json.loads((r/f'docs/phase1-database-{name}-validation.json').read_text(encoding='utf-8-sig'));assert v['result']=='PASS' and v['checks']==count
 (r/f'docs/phase1-database-keys-{name}-regression.json').write_text(json.dumps(v,indent=2)+'\n')
 historical.extend(f'docs/phase1-database-{name}-{suffix}' for suffix in ['validation.json','workspace.png','compact.png'])
subprocess.check_call([g,'restore','--worktree','--']+historical)
assert 'PASS WP0-TEST' in (r/'docs/phase1-database-keys-build.log').read_text(encoding='utf-8-sig')
evidence=['DPH.Workspace.DatabaseSchema.pas','DPH.UI.Main.pas','DPH.UI.Main.fmx','tests/DPH.Tests.DatabaseKeys.dpr','tools/build-database-keys.cmd','docs/phase1-database-keys-validation.json','docs/phase1-database-keys-validation.log','docs/guides/Database_Keys_Run_and_Test.txt']
qualification='Captured CREATE TABLE key declarations and exact-spelling evidence links only. Missing/ambiguous targets, omitted reference columns, arity differences, duplicate names and primary-key conflicts remain explained. Unsupported key grammar, expressions, ALTER statements and unsupported inline action tails remain gaps. Dialect validity, referenced uniqueness, type compatibility, effective migration order and deployed enforcement are unverified. No target SQL, application or server is executed.'
for row in doc['requirements']:
 if row['id']!='05.05':continue
 row.setdefault('audit_at_reconciliation',dict(row['reconciliation']));row['implementation']='implemented';row['evidence']=evidence;row['limitation']=qualification
 row['reconciliation'].update(finding='Database schema exposes named and anonymous inline/table primary, foreign and unique keys with ordered members, reference table/columns, supported table referential actions and exact parent ownership. Indexed relationships link only unique captured tables/columns and explain missing/ambiguous evidence, omitted reference columns, arity mismatch, duplicate names and multiple primary keys. Unsupported key syntax remains explicit gaps. IDE-editable kind/state filters, relationship selector and Follow relationship support exact targets across 250-row pages; guarded source navigation and provenance remain.',remaining_work='',verification='173 focused checks pass for actual captured resources, composite/inline/self-referencing keys, ordered membership, exact target IDs, unresolved/conflicting evidence, unsupported syntax, literal omission, SQLite reopening, source guards, unchanged catalog/source/workspace and native filtering/navigation/replacement/normal/compact renders. 121 column and 57 schema regression checks pass. Actual app build and FMX baseline pass. Both DOCX guides and PDFs rendered and visually reviewed, 56 source hashes and 90 TOC destinations verified.')
 row['implementation_update']={'date':'2026-10-12','batch':'Primary foreign and unique keys','validation':'docs/phase1-database-keys-validation.json','prior_audit_status':'missing'}
assert [x['id'] for x,b in zip(doc['requirements'],base['requirements']) if x!=b]==['05.05']
counts=dict(collections.Counter(x['implementation'] for x in doc['requirements']));assert counts=={'implemented_manual_capture':18,'partial':231,'implemented':184,'missing':100},counts
doc['completion']='RECONCILIATION COMPLETE; PRODUCT IMPLEMENTATION INCOMPLETE. Zero unassessed requirements. Primary, foreign, and unique keys 05.05 implemented as captured declarations and evidence-backed relationships; 331 partial or missing records remain.'
doc['current_implementation']={'date':'2026-10-12','completed_batch':'Primary foreign and unique keys','completed_requirement_ids':['05.05'],'counts':counts,'unassessed':0,'incomplete_requirement_records':331,'completion_record':'docs/Phase1_Database_Keys_Completion.txt','next_bounded_batch':{'requirement':'05.06','title':'Indexes and performance-related structures','scope':'Parse/import index definitions and link them to tables, columns and usage evidence.'}}
p.write_text(json.dumps(doc,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
with (r/'docs/Phase1_Implementation_Backlog.csv').open('w',encoding='utf-8-sig',newline='') as out:
 w=csv.writer(out);w.writerow(['ID','Domain','Requirement / purpose','Status','Existing behavior','Remaining work','Batch','Evidence'])
 for row in doc['requirements']:
  if row['implementation'] not in ('partial','missing'):continue
  a=row['reconciliation'];w.writerow([row['id'],row['domain'],row['requirement'],row['implementation'],a['finding'],a['remaining_work'],a['batch'],'; '.join(row['evidence'])])
p=r/'docs/Implementation_Completion_Tracker.txt';s=p.read_text(encoding='utf-8-sig');old='Current live backlog: 332 incomplete requirement records; 0 unassessed.';assert old in s
s=s.replace(old,'Primary, foreign, and unique keys completed (05.05): captured ordered key\nmembership, exact evidence relationships, unresolved/conflicting target notes\nand native Follow relationship navigation across pages.\n173 focused and 178 regression checks passed; actual app/FMX baseline passed.\nSee Phase1_Database_Keys_Completion.txt.\nCurrent live backlog: 331 incomplete requirement records; 0 unassessed.');p.write_text(s,encoding='utf-8')
for name in ['docs/Phase1_Reconciliation_Report.txt','docs/Phase1_Reconciliation_Batches.json','docs/Phase1_Reconciliation_Validation.json','DPH_Master_Development_Specification_v1.md','DPH_CODEX_HANDOFF.txt','DPH_PHASE1_MASTER_REQUIREMENTS.md']+historical:
 assert (r/name).read_bytes().replace(b'\r\n',b'\n')==subprocess.check_output([g,'show',baseline+':'+name]).replace(b'\r\n',b'\n'),name
guide=json.loads((r/'bin/database-keys-guide-check.json').read_text());assert guide['guide_sources_verified']==56
summary={'result':'PASS','requirement':'05.05','status':'implemented','checks':173,'regression_checks':178,'requirements_preserved':533,'only_promoted_record':'05.05','incomplete_requirement_records':331,'unassessed':0,'counts':counts,'guides':guide,'backup':{'path':r'H:\DPH Backups\DatabaseKeys_PreChange_20261012_121444','files':4442,'bytes':1181999167,'sha256_verified':True},'qualification':qualification}
files=evidence+['docs/guide-source-validation.json','docs/guides/DPH_User_Guide.docx','docs/guides/DPH_Engineering_Guide.docx','docs/pdf/DPH_User_Guide.pdf','docs/pdf/DPH_Engineering_Guide.pdf','docs/phase1-database-keys-build.log','docs/phase1-database-keys-columns-regression.json','docs/phase1-database-keys-schema-regression.json','docs/phase1-database-keys-workspace.png','docs/phase1-database-keys-compact.png','docs/phase1-database-keys-relationships.png']
summary['evidence_hashes']={x:hashlib.sha256((r/x).read_bytes()).hexdigest() for x in files}
(r/'docs/phase1-database-keys-completion-validation.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'counts':counts,'incomplete':331,'requirements_preserved':533,'only_promoted_record':'05.05'}))
