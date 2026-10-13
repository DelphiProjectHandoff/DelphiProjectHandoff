from pathlib import Path
import json,csv,collections,subprocess,hashlib
r=Path.cwd();g=r'C:\Program Files\Git\cmd\git.exe';baseline='f58176c'
base=json.loads(subprocess.check_output([g,'show',baseline+':docs/Phase1_Requirements_Traceability.json']))
p=r/'docs/Phase1_Requirements_Traceability.json';doc=json.loads(p.read_text(encoding='utf-8-sig'))
assert len(doc['requirements'])==533
assert [(x['id'],x['requirement']) for x in doc['requirements']]==[(x['id'],x['requirement']) for x in base['requirements']]
v=json.loads((r/'docs/phase1-database-er-validation.json').read_text(encoding='utf-8-sig'));assert v['result']=='PASS' and v['checks']==436
historical=[]
for name,count in [('stored-objects',363),('keys',173)]:
 v=json.loads((r/f'docs/phase1-database-{name}-validation.json').read_text(encoding='utf-8-sig'));assert v['result']=='PASS' and v['checks']==count
 (r/f'docs/phase1-database-er-{name}-regression.json').write_text(json.dumps(v,indent=2)+'\n')
 historical.extend(f'docs/phase1-database-{name}-{suffix}' for suffix in ['validation.json','workspace.png','compact.png','relationships.png'])
subprocess.check_call([g,'restore','--worktree','--']+historical)
assert 'PASS WP0-TEST' in (r/'docs/phase1-database-er-build.log').read_text(encoding='utf-8-sig')
guide=json.loads((r/'bin/database-er-guide-check.json').read_text());assert guide['guide_sources_verified']==56
assert sum(x['toc_entries'] for x in guide['guides'])==96
evidence=['DPH.Workspace.DatabaseSchema.pas','DPH.UI.Main.pas','DPH.UI.Main.fmx','tests/DPH.Tests.DatabaseER.dpr','tools/build-database-er.cmd','docs/phase1-database-er-validation.json','docs/phase1-database-er-validation.log','docs/guides/Database_ER_Diagrams_Run_and_Test.txt']
qualification='Interactive ER diagrams project supported captured table headers, ordered columns and exact key ownership/links only. Every view remains PARTIAL CAPTURED SCHEMA. Missing/ambiguous targets, duplicates, unsupported schema evidence, off-page endpoints and display truncation remain explicit; no inferred entities, cardinality, migration winner or deployed enforcement is invented. SQL dialect validity, referenced uniqueness, type compatibility and business semantics are unverified. At most 60 table cards, 32 column summaries per card and 120 related FK entries per projection; native defaults summarize seven columns. No target SQL, target application or database server is executed.'
for row in doc['requirements']:
 if row['id']!='05.08':continue
 row.setdefault('audit_at_reconciliation',dict(row['reconciliation']));row['implementation']='implemented';row['evidence']=evidence;row['limitation']=qualification
 row['reconciliation'].update(finding='Dedicated native ER page draws captured tables, ordered column names/types and deduplicated PK/FK/UQ badges, with numbered directed foreign-key routes. Exact evidence IDs retain source/hash/generation/range and ordered local/referenced key membership. Unresolved, duplicate and truncated evidence is qualified, absent targets do not invent nodes, and off-page relations remain inspectable in the selector. Table hits and FK selection open exact schema evidence across inventory pages. IDE-editable controls/styles provide focus on one-hop neighbors, text filtering, 15/30/60-table paging, 75..200 percent zoom, separate drawing/details scrolling and a details splitter. Capture replacement rebuilds the diagram.',remaining_work='',verification='436 focused checks pass for actual SQL resource capture, exact ownership/provenance, badges, stable order, limits, duplicates/self/missing targets, focus/filter/paging, immutable source/catalog/workspace, SQLite reopening and native table/key evidence navigation across pages, page selector, zoom, compact scrolling and capture replacement. 363 stored-object and 173 key regression checks pass. Actual application and FMX baseline pass. Both DOCX guides and companion PDFs rendered and visually reviewed; 56 source hashes and 96 TOC destinations verified.')
 row['implementation_update']={'date':'2026-10-12','batch':'Entity relationship diagrams','validation':'docs/phase1-database-er-validation.json','prior_audit_status':'missing'}
assert [x['id'] for x,b in zip(doc['requirements'],base['requirements']) if x!=b]==['05.08']
counts=dict(collections.Counter(x['implementation'] for x in doc['requirements']));assert counts=={'implemented_manual_capture':18,'partial':231,'implemented':187,'missing':97},counts
doc['completion']='RECONCILIATION COMPLETE; PRODUCT IMPLEMENTATION INCOMPLETE. Zero unassessed requirements. Entity-relationship diagrams 05.08 implemented from captured table/key evidence with explicit incomplete-schema qualification; 328 partial or missing records remain.'
doc['current_implementation']={'date':'2026-10-12','completed_batch':'Entity relationship diagrams','completed_requirement_ids':['05.08'],'counts':counts,'unassessed':0,'incomplete_requirement_records':328,'completion_record':'docs/Phase1_Database_ER_Completion.txt','next_bounded_batch':{'requirement':'05.09','title':'Data dictionaries and business meanings','scope':'Add table/column business definitions, ownership, sensitivity and source/schema links.'}}
p.write_text(json.dumps(doc,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
with (r/'docs/Phase1_Implementation_Backlog.csv').open('w',encoding='utf-8-sig',newline='') as out:
 w=csv.writer(out);w.writerow(['ID','Domain','Requirement / purpose','Status','Existing behavior','Remaining work','Batch','Evidence'])
 for row in doc['requirements']:
  if row['implementation'] not in ('partial','missing'):continue
  a=row['reconciliation'];w.writerow([row['id'],row['domain'],row['requirement'],row['implementation'],a['finding'],a['remaining_work'],a['batch'],'; '.join(row['evidence'])])
p=r/'docs/Implementation_Completion_Tracker.txt';s=p.read_text(encoding='utf-8-sig');old='Current live backlog: 329 incomplete requirement records; 0 unassessed.';assert old in s
s=s.replace(old,'Entity relationship diagrams completed (05.08): interactive captured table/column/\nkey cards and numbered FK arrows with exact evidence navigation, qualified gaps,\none-hop focus, filtering, paging, zoom and serialized IDE-editable controls.\n436 focused and 536 regression checks passed; actual app/FMX baseline passed.\nSee Phase1_Database_ER_Completion.txt.\nCurrent live backlog: 328 incomplete requirement records; 0 unassessed.');p.write_text(s,encoding='utf-8')
for name in ['docs/Phase1_Reconciliation_Report.txt','docs/Phase1_Reconciliation_Batches.json','docs/Phase1_Reconciliation_Validation.json','DPH_Master_Development_Specification_v1.md','DPH_CODEX_HANDOFF.txt','DPH_PHASE1_MASTER_REQUIREMENTS.md']+historical:
 assert (r/name).read_bytes().replace(b'\r\n',b'\n')==subprocess.check_output([g,'show',baseline+':'+name]).replace(b'\r\n',b'\n'),name
summary={'result':'PASS','requirement':'05.08','status':'implemented','checks':436,'regression_checks':536,'requirements_preserved':533,'only_promoted_record':'05.08','incomplete_requirement_records':328,'unassessed':0,'counts':counts,'guides':guide,'backup':{'path':r'H:\DPH Backups\DatabaseERDiagrams_PreChange_20261012_132042','files':4699,'bytes':1610957252,'sha256_verified':True},'qualification':qualification}
files=evidence+['docs/guide-source-validation.json','docs/guides/DPH_User_Guide.docx','docs/guides/DPH_Engineering_Guide.docx','docs/pdf/DPH_User_Guide.pdf','docs/pdf/DPH_Engineering_Guide.pdf','docs/phase1-database-er-build.log','docs/phase1-database-er-stored-objects-regression.json','docs/phase1-database-er-keys-regression.json','docs/phase1-database-er-workspace.png','docs/phase1-database-er-diagram.png','docs/phase1-database-er-compact.png','docs/phase1-database-er-commands.png','docs/phase1-database-er-schema-workspace.png','docs/phase1-database-er-schema-compact.png','docs/phase1-database-er-relationships.png','docs/Phase1_Database_ER_Completion.txt']
summary['evidence_hashes']={x:hashlib.sha256((r/x).read_bytes()).hexdigest() for x in files}
(r/'docs/phase1-database-er-completion-validation.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'counts':counts,'incomplete':328,'requirements_preserved':533,'only_promoted_record':'05.08'}))
