from pathlib import Path
import json,csv,collections,subprocess,hashlib
r=Path.cwd();git=r'C:\Program Files\Git\cmd\git.exe';baseline='08c7d8d'
base=json.loads(subprocess.check_output([git,'show',baseline+':docs/Phase1_Requirements_Traceability.json']))
p=r/'docs/Phase1_Requirements_Traceability.json';doc=json.loads(p.read_text(encoding='utf-8-sig'))
assert len(doc['requirements'])==533
assert [(x['id'],x['requirement']) for x in doc['requirements']]==[(x['id'],x['requirement']) for x in base['requirements']]
for label,count in [('validation',130),('database-transactions-regression',402),('database-operations-regression',232),('dataset-bindings-regression',92),('database-engines-regression',66),('semantics-regression',134),('parser-regression',88)]:
 v=json.loads((r/f'docs/phase1-data-rules-{label}.json').read_text(encoding='utf-8-sig'))
 assert v.get('checks_passed',v.get('checks'))==count,(label,v)
 if label not in ('semantics-regression','parser-regression'):assert v['result']=='PASS'
assert 'PASS WP0-TEST' in (r/'docs/phase1-data-rules-build.log').read_text(encoding='utf-8-sig')
guide=json.loads((r/'bin/data-rules-guide-check.json').read_text())
assert guide['guide_sources_verified']==58 and sum(x['toc_entries'] for x in guide['guides'])==106
assert sum(x['pages'] for x in guide['guides'])==62
qualification='Captured field declarations and handler-context rule candidates only. Lexical input/output references do not establish reaching definitions, actual values, successful validation or event execution. Missing or ambiguous handlers and unavailable syntax remain explicit. Inherited defaults, runtime assignments, aliases, factories, unsupported external validation and server enforcement remain unverified. Combined inventory is bounded to 10000 rows with explicit truncation. Target source remains passive; no target application, SQL, driver or database server executes.'
evidence=['DPH.Analysis.Model.pas','DPH.Parse.Forms.pas','DPH.Parse.Model.pas','DPH.Workspace.DatabaseConnections.pas','DPH.UI.Main.pas','DPH.UI.Main.fmx','tests/DPH.Tests.DataRules.dpr','tools/build-data-rules.cmd','docs/phase1-data-rules-validation.json','docs/phase1-data-rules-validation.log','docs/guides/Data_Rules_Run_and_Test.txt']
for row in doc['requirements']:
 if row['id']!='05.14':continue
 prior=row['implementation'];assert prior=='partial'
 row.setdefault('audit_at_reconciliation',dict(row['reconciliation']));row['implementation']='implemented';row['evidence']=evidence;row['limitation']=qualification
 row['reconciliation'].update(finding='Database connections exposes field constraints and validation/transformation hooks with exact source evidence. Captured handler conditions, raises, early exits and assignment expressions show constraint, input and output expressions, conditional compilation, context and handler identity. Exact lexical input/output declaration links and reverse references are navigable. Missing handlers/syntax and inventory truncation remain explicit. Text and binary form parsers recognize BeforePost and related dataset hooks. Native filters, labeled details and hash-checked Source use IDE-editable controls.',remaining_work='',verification='130 focused and 1014 regression checks pass (402 transactions, 232 operations, 92 bindings, 66 engines, 134 semantics, 88 parser). Actual app and FMX baseline pass. Real parser output, persisted/reopened captures, numeric/text transformations, constraints, missing handlers/syntax, literal redaction, semicolon-in-call regression, inventory limits, native navigation and source/catalog immutability verified. All 62 final guide pages and two native renders reviewed; 58 source hashes and 106 TOC destinations verified.')
 row['implementation_update']={'date':'2026-10-12','batch':'Data validation and transformation rules','validation':'docs/phase1-data-rules-validation.json','prior_audit_status':prior}
assert [x['id'] for x,b in zip(doc['requirements'],base['requirements']) if x!=b]==['05.14']
counts=dict(collections.Counter(x['implementation'] for x in doc['requirements']));assert counts=={'implemented_manual_capture':18,'partial':228,'implemented':192,'missing':95},counts
doc['completion']='RECONCILIATION COMPLETE; PRODUCT IMPLEMENTATION INCOMPLETE. Zero unassessed requirements. Data validation and transformation rules 05.14 implemented as qualified field declarations and handler-context candidates; 323 partial or missing records remain.'
doc['current_implementation']={'date':'2026-10-12','completed_batch':'Data validation and transformation rules','completed_requirement_ids':['05.14'],'counts':counts,'unassessed':0,'incomplete_requirement_records':323,'completion_record':'docs/Phase1_Data_Rules_Completion.txt','next_bounded_batch':{'requirement':'05.15','title':'Data lineage from input to final destination','scope':'Connect input controls, database fields, procedures and destinations into scoped lineage chains with unresolved breaks.'}}
p.write_text(json.dumps(doc,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
with (r/'docs/Phase1_Implementation_Backlog.csv').open('w',encoding='utf-8-sig',newline='') as out:
 w=csv.writer(out);w.writerow(['ID','Domain','Requirement / purpose','Status','Existing behavior','Remaining work','Batch','Evidence'])
 for row in doc['requirements']:
  if row['implementation'] not in ('partial','missing'):continue
  a=row['reconciliation'];w.writerow([row['id'],row['domain'],row['requirement'],row['implementation'],a['finding'],a['remaining_work'],a['batch'],'; '.join(row['evidence'])])
p=r/'docs/Implementation_Completion_Tracker.txt';s=p.read_text(encoding='utf-8-sig');old='Current live backlog: 324 incomplete requirement records; 0 unassessed.';assert old in s
s=s.replace(old,'Data validation and transformation rules completed (05.14): field constraints,\nvalidation hooks and input/output candidates with exact source navigation.\n130 focused and 1014 regression checks passed; actual app/FMX baseline passed.\nSee Phase1_Data_Rules_Completion.txt.\nCurrent live backlog: 323 incomplete requirement records; 0 unassessed.');p.write_text(s,encoding='utf-8')
for name in ['docs/Phase1_Reconciliation_Report.txt','docs/Phase1_Reconciliation_Batches.json','docs/Phase1_Reconciliation_Validation.json','DPH_Master_Development_Specification_v1.md','DPH_CODEX_HANDOFF.txt','DPH_PHASE1_MASTER_REQUIREMENTS.md']:
 assert (r/name).read_bytes().replace(b'\r\n',b'\n')==subprocess.check_output([git,'show',baseline+':'+name]).replace(b'\r\n',b'\n'),name
backup={'path':r'H:\DPH Backups\DataRules_PreChange_20261012_155630','files':5506,'bytes':2150426199,'sha256_verified':True}
completion=f'''DPH REQUIREMENT 05.14 COMPLETION DATA VALIDATION AND TRANSFORMATION RULES
Last changed: 12 October 2026

Database connections now exposes persistent-field constraints and recognized
validation/conversion hooks. Handler conditions, raises, early exits and
assignment candidates retain source, SHA256, generation and conditional context.
Input, output, constraint and captured expression appear first in labeled details.
Exact field/dataset context, handler and lexical declarations can be followed;
reverse references return to rules. Source uses existing attached-hash guards.
BeforePost and related dataset hooks are captured from text and binary forms.
Missing/ambiguous handler, unavailable syntax and truncation remain explicit.
Analyzer versions: DPH-WP2-6 and DPH-WP3-15. No schema migration.

Validation PASS: 130 focused + 402 transactions + 232 operations + 92 bindings +
66 engines + 134 semantics + 88 parser = 1144 checks.
Actual application and FMX baseline PASS. Normal and compact native renders
reviewed. All 62 final guide pages visually reviewed; 58 source hashes and
106 TOC destinations verified. Guides remain editable with companion PDFs.
Explicit directions: docs/guides/Data_Rules_Run_and_Test.txt.

Pre-change backup: {backup['path']}
5506 files, 2150426199 bytes; every SHA256 verified. No post-change backup.

{qualification}

Only 05.14 promoted. All 533 original requirement IDs and texts preserved.
192 implemented; 18 implemented_manual_capture; 228 partial; 95 missing.
323 incomplete; zero unassessed. The entire product is not complete.
Next: 05.15 Data lineage from input to final destination.
'''
(r/'docs/Phase1_Data_Rules_Completion.txt').write_text(completion,encoding='utf-8')
summary={'result':'PASS','requirement':'05.14','status':'implemented','checks':130,'regression_checks':1014,'requirements_preserved':533,'only_promoted_record':'05.14','incomplete_requirement_records':323,'unassessed':0,'counts':counts,'guides':guide,'guide_visual_review':'All 62 final pages reviewed; no clipping or broken TOC destinations observed.','backup':backup,'qualification':qualification}
files=evidence+['tools/build-guides.py','README.md','help/index.html','docs/guide-source-validation.json','docs/guides/DPH_User_Guide.docx','docs/guides/DPH_Engineering_Guide.docx','docs/pdf/DPH_User_Guide.pdf','docs/pdf/DPH_Engineering_Guide.pdf','docs/phase1-data-rules-build.log','docs/Phase1_Data_Rules_Completion.txt','docs/Phase1_Requirements_Traceability.json','docs/Phase1_Implementation_Backlog.csv','docs/Implementation_Completion_Tracker.txt','docs/phase1-data-rules-workspace.png','docs/phase1-data-rules-compact.png','tests/DPH.Tests.DatabaseTransactions.dpr','tests/DPH.Tests.DatabaseOperations.dpr','tests/DPH.Tests.DatasetBindings.dpr','tests/fixtures/syntax/expected-ir.json']
for label in ['database-transactions','database-operations','dataset-bindings','database-engines','semantics','parser']:
 for ext in ['json','log']:files.append(f'docs/phase1-data-rules-{label}-regression.{ext}')
summary['evidence_hashes']={x:hashlib.sha256((r/x).read_bytes()).hexdigest() for x in files}
(r/'docs/phase1-data-rules-completion-validation.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'counts':counts,'incomplete':323,'requirements_preserved':533,'only_promoted_record':'05.14','evidence_files':len(files)}))
