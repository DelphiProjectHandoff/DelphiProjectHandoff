from pathlib import Path
import json,csv,collections,subprocess,hashlib,shutil
r=Path.cwd();g=r'C:\Program Files\Git\cmd\git.exe';baseline='d123a43'
base=json.loads(subprocess.check_output([g,'show',baseline+':docs/Phase1_Requirements_Traceability.json']))
p=r/'docs/Phase1_Requirements_Traceability.json';doc=json.loads(p.read_text(encoding='utf-8-sig'))
assert len(doc['requirements'])==533
assert [(x['id'],x['requirement']) for x in doc['requirements']]==[(x['id'],x['requirement']) for x in base['requirements']]
v=json.loads((r/'docs/phase1-database-dictionary-validation.json').read_text(encoding='utf-8-sig'));assert v['result']=='PASS' and v['checks']==79
reg=[]
for label,path,key,count in [('er','docs/phase1-database-er-validation.json','checks',436),('glossary','docs/phase1-glossary-validation.json','checks_passed',57),('publish','docs/wp6-validation.json','checks_passed',114)]:
 v=json.loads((r/path).read_text(encoding='utf-8-sig'));assert v[key]==count
 dest=f'docs/phase1-database-dictionary-{label}-regression.json';shutil.copyfile(r/path,r/dest);reg.append(dest)
 dest=f'docs/phase1-database-dictionary-{label}-regression.log';shutil.copyfile(r/f'bin/database-dictionary-{label}-regression.log',r/dest);reg.append(dest)
historical=['docs/phase1-database-er-relationships.png','docs/phase1-database-er-schema-compact.png','docs/phase1-database-er-schema-workspace.png','docs/phase1-glossary-compact.png','docs/phase1-glossary-workspace.png','docs/wp6-canonical-fixture.json','docs/wp6-validation.json']
subprocess.check_call([g,'restore','--worktree','--']+historical)
assert 'PASS WP0-TEST' in (r/'docs/phase1-database-dictionary-build.log').read_text(encoding='utf-8-sig')
guide=json.loads((r/'bin/database-dictionary-guide-check.json').read_text());assert guide['guide_sources_verified']==58 and sum(x['toc_entries'] for x in guide['guides'])==98
evidence=['DPH.Workspace.DatabaseSchema.pas','DPH.Storage.Database.pas','DPH.Publish.Model.pas','DPH.UI.Main.pas','DPH.UI.Main.fmx','DPH.UI.DatabaseDictionary.pas','DPH.UI.DatabaseDictionary.fmx','DelphiProjectHandoff.dproj','tests/DPH.Tests.DatabaseDictionary.dpr','tools/build-database-dictionary.cmd','docs/phase1-database-dictionary-validation.json','docs/phase1-database-dictionary-validation.log','docs/guides/Database_Dictionary_Run_and_Test.txt']
qualification='Business definitions, ownership, sensitivity, evidence and usage are attributed human claims with independent review state. Exact captured table/column identity, source SHA256, generation and statement line do not establish live deployment or business truth. Changed source bytes never automatically inherit a definition; historical and unmatched records remain available in Knowledge. Sensitivity text is descriptive, not access control. Fourteen text fields are limited to 4096 characters each and 64 KiB per record. No target SQL, program or database server executes.'
for row in doc['requirements']:
 if row['id']!='05.09':continue
 prior=row['implementation'];row.setdefault('audit_at_reconciliation',dict(row['reconciliation']));row['implementation']='implemented';row['evidence']=evidence;row['limitation']=qualification
 row['reconciliation'].update(finding='Native IDE-editable table/column dictionary editor captures business definition, owner/steward, sensitivity/handling, evidence/unknowns and optional units/usage. Read-only identity preserves exact captured schema ID, file, SHA256, generation, kind, name, owning table and statement line. Apply prepares a protected Knowledge draft; explicit Save persists attributed immutable history and independent review. Storage validates new anchors against persisted captured schema, rejects forged/duplicate anchors and prevents identity changes or loss of structured fields. Schema details show business meaning first; filtering searches current saved definitions. Exact current and qualified historical lookup, history navigation and source-scoped hash-matching publication are implemented.',remaining_work='',verification='79 focused checks and 607 regression checks pass (436 ER, 114 publishing, 57 glossary). Actual application build and FMX baseline pass. Checks cover persisted source anchors, field types/bounds, forged/duplicate anchors, immutable identity/history, stale edits/review, attribution, reopening, publication exclusions/hash mismatches, native modal Apply-to-draft, search/history and compact layouts. Both guides rendered and all 57 pages visually reviewed; 58 source hashes and 98 TOC destinations verified.')
 row['implementation_update']={'date':'2026-10-12','batch':'Data dictionaries and business meanings','validation':'docs/phase1-database-dictionary-validation.json','prior_audit_status':prior}
assert [x['id'] for x,b in zip(doc['requirements'],base['requirements']) if x!=b]==['05.09']
counts=dict(collections.Counter(x['implementation'] for x in doc['requirements']));assert counts=={'implemented_manual_capture':18,'partial':231,'implemented':188,'missing':96},counts
doc['completion']='RECONCILIATION COMPLETE; PRODUCT IMPLEMENTATION INCOMPLETE. Zero unassessed requirements. Data dictionaries and business meanings 05.09 implemented with attributed definitions and exact captured source links; 327 partial or missing records remain.'
doc['current_implementation']={'date':'2026-10-12','completed_batch':'Data dictionaries and business meanings','completed_requirement_ids':['05.09'],'counts':counts,'unassessed':0,'incomplete_requirement_records':327,'completion_record':'docs/Phase1_Database_Dictionary_Completion.txt','next_bounded_batch':{'requirement':'05.11','title':'Dataset components and bindings','scope':'Resolve dataset/connection/datasource/control bindings and persistent fields.'}}
p.write_text(json.dumps(doc,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
with (r/'docs/Phase1_Implementation_Backlog.csv').open('w',encoding='utf-8-sig',newline='') as out:
 w=csv.writer(out);w.writerow(['ID','Domain','Requirement / purpose','Status','Existing behavior','Remaining work','Batch','Evidence'])
 for row in doc['requirements']:
  if row['implementation'] not in ('partial','missing'):continue
  a=row['reconciliation'];w.writerow([row['id'],row['domain'],row['requirement'],row['implementation'],a['finding'],a['remaining_work'],a['batch'],'; '.join(row['evidence'])])
p=r/'docs/Implementation_Completion_Tracker.txt';s=p.read_text(encoding='utf-8-sig');old='Current live backlog: 328 incomplete requirement records; 0 unassessed.';assert old in s
s=s.replace(old,'Data dictionaries and business meanings completed (05.09): attributed table/column\nbusiness definitions, ownership, sensitivity, evidence and usage with exact\ncaptured source links, immutable Knowledge history, independent review, search\nand source-scoped publication. Native controls remain IDE-editable.\n79 focused and 607 regression checks passed; actual app/FMX baseline passed.\nSee Phase1_Database_Dictionary_Completion.txt.\nCurrent live backlog: 327 incomplete requirement records; 0 unassessed.');p.write_text(s,encoding='utf-8')
for name in ['docs/Phase1_Reconciliation_Report.txt','docs/Phase1_Reconciliation_Batches.json','docs/Phase1_Reconciliation_Validation.json','DPH_Master_Development_Specification_v1.md','DPH_CODEX_HANDOFF.txt','DPH_PHASE1_MASTER_REQUIREMENTS.md']+historical:
 assert (r/name).read_bytes().replace(b'\r\n',b'\n')==subprocess.check_output([g,'show',baseline+':'+name]).replace(b'\r\n',b'\n'),name
completion='''DPH REQUIREMENT 05.09 COMPLETION - DATA DICTIONARIES AND BUSINESS MEANINGS
Last changed: 12 October 2026

Completed: native table/column business dictionary editor, attributed definition,
owner/steward, sensitivity/handling, evidence/unknowns and optional units/usage.
Captured source/schema identity is read only and validated against the persisted
workspace. Apply prepares a draft; Save persists it; named review remains separate.
Duplicate/forged anchors, stale revisions, conflicting rendered bodies and identity
changes are rejected. Edits reopen review and preserve immutable attributed history.
Business meaning appears first in schema details and participates in filtering.
Historical definitions remain accessible, but changed source bytes do not inherit
them. Publication includes only definitions whose captured source and SHA256 match
the included publication files. Existing exclusion/redaction rules apply.

Validation: PASS 79 focused + 436 ER + 114 publishing + 57 glossary = 686 checks.
Actual application build and FMX resource baseline PASS. Native editor, compact
editor, source fields and normal/compact schema layouts visually reviewed.
User Guide: 30 pages; Engineering Guide: 27 pages. All final pages visually reviewed.
58 guide source hashes and 98 TOC destinations verified; no blank guide pages.
Exact run and test directions: docs/guides/Database_Dictionary_Run_and_Test.txt.

Pre-change backup: H:\\DPH Backups\\DatabaseDictionary_PreChange_20261012_135552
4486 files, 1746035298 bytes, every SHA256 verified. No post-change backup made.

Limits: business statements require actual human knowledge and review. Unknown is
an explicit acceptable answer. Sensitivity text does not enforce access control.
The schema remains captured evidence, not a validated live database. Fourteen text
fields have 4096-character per-field and 64 KiB total bounds. No target SQL,
application or server executes. No schema migration or runtime controls introduced.

Only 05.09 promoted. All 533 original requirement IDs and texts preserved.
188 implemented; 18 implemented_manual_capture; 231 partial; 96 missing.
327 incomplete; zero unassessed. This does not complete the entire product.
Next incomplete record: 05.11 Dataset components and bindings. 05.10 was already
implemented. Next scope: resolve dataset/connection/datasource/control bindings
and persistent fields.
'''
(r/'docs/Phase1_Database_Dictionary_Completion.txt').write_text(completion,encoding='utf-8')
summary={'result':'PASS','requirement':'05.09','status':'implemented','checks':79,'regression_checks':607,'requirements_preserved':533,'only_promoted_record':'05.09','incomplete_requirement_records':327,'unassessed':0,'counts':counts,'guides':guide,'guide_visual_review':'All 57 final pages reviewed individually; no clipping or broken TOC destinations observed.','backup':{'path':r'H:\DPH Backups\DatabaseDictionary_PreChange_20261012_135552','files':4486,'bytes':1746035298,'sha256_verified':True},'qualification':qualification}
files=evidence+reg+['tools/build-guides.py','README.md','help/index.html','docs/guide-source-validation.json','docs/guides/DPH_User_Guide.docx','docs/guides/DPH_Engineering_Guide.docx','docs/pdf/DPH_User_Guide.pdf','docs/pdf/DPH_Engineering_Guide.pdf','docs/phase1-database-dictionary-build.log','docs/Phase1_Database_Dictionary_Completion.txt','docs/Phase1_Requirements_Traceability.json','docs/Phase1_Implementation_Backlog.csv','docs/Implementation_Completion_Tracker.txt']+[f'docs/phase1-database-dictionary-{x}.png' for x in ['workspace','compact','editor','editor-compact','fields']]
summary['evidence_hashes']={x:hashlib.sha256((r/x).read_bytes()).hexdigest() for x in files}
(r/'docs/phase1-database-dictionary-completion-validation.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'counts':counts,'incomplete':327,'requirements_preserved':533,'only_promoted_record':'05.09','evidence_files':len(files)}))
