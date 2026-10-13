from pathlib import Path
import json,csv,collections,subprocess,hashlib
r=Path.cwd();g=r'C:\Program Files\Git\cmd\git.exe';baseline='36c0220'
base=json.loads(subprocess.check_output([g,'show',baseline+':docs/Phase1_Requirements_Traceability.json']))
p=r/'docs/Phase1_Requirements_Traceability.json';doc=json.loads(p.read_text(encoding='utf-8-sig'))
assert len(doc['requirements'])==533
assert [(x['id'],x['requirement']) for x in doc['requirements']]==[(x['id'],x['requirement']) for x in base['requirements']]
for label,count in [('validation',402),('operations-regression',232),('bindings-regression',92),('engines-regression',66),('semantics-regression',134)]:
 v=json.loads((r/f'docs/phase1-database-transactions-{label}.json').read_text(encoding='utf-8-sig'))
 assert v.get('checks_passed',v.get('checks'))==count
 if label!='semantics-regression':assert v['result']=='PASS'
assert 'PASS WP0-TEST' in (r/'docs/phase1-database-transactions-build.log').read_text(encoding='utf-8-sig')
guide=json.loads((r/'bin/database-transactions-guide-check.json').read_text())
assert guide['guide_sources_verified']==58 and sum(x['toc_entries'] for x in guide['guides'])==104
assert sum(x['pages'] for x in guide['guides'])==62
qualification='Captured API requests and conservative intraprocedural CFG possibilities only. No successful activation, commit, rollback, feasible branch or server outcome is inferred. Supported FireDAC, ADO, dbExpress, BDE and IBX declared receivers and captured descendants are recognized; aliases, factories, within-with receivers, interprocedural transaction propagation, implicit SQL transactions, savepoint identity and unsupported providers remain unverified. Missing, ambiguous and truncated CFG stays explicit. No target application, SQL, driver or database server runs.'
evidence=['DPH.Analysis.Model.pas','DPH.Analysis.Symbols.pas','DPH.Workspace.DatabaseConnections.pas','DPH.UI.Main.fmx','tests/DPH.Tests.DatabaseTransactions.dpr','tools/build-database-transactions.cmd','docs/phase1-database-transactions-validation.json','docs/phase1-database-transactions-validation.log','docs/guides/Database_Transactions_Run_and_Test.txt']
for row in doc['requirements']:
 if row['id']!='05.13':continue
 prior=row['implementation'];row.setdefault('audit_at_reconciliation',dict(row['reconciliation']));row['implementation']='implemented';row['evidence']=evidence;row['limitation']=qualification
 row['reconciliation'].update(finding='Database connections inventories begin, commit, rollback, retaining and savepoint API requests. Captured routine CFG routes connect the same declared receiver to its next explicit boundary or normal/exception exit. Error, conditional/loop and finalizer-copy paths remain distinguished. Exact receiver, source hash, generation, conditional evidence, forward/reverse references and hash-checked Source remain inspectable through IDE-editable controls. Local framework-name shadows and ordinary methods are excluded.',remaining_work='',verification='402 focused checks and 524 regressions pass (232 operations, 92 bindings, 66 engines, 134 semantics). Actual app and FMX baseline pass. Persisted/reopened captures, normal/error/cleanup and early-return routes, differing receivers, all five provider families, descendants, shadows, unordered calls, absent/oversized CFG, redaction, native navigation and source/catalog immutability verified. All 62 final guide pages and two native renders reviewed; 58 source hashes and 104 TOC destinations verified.')
 row['implementation_update']={'date':'2026-10-12','batch':'Database transaction paths','validation':'docs/phase1-database-transactions-validation.json','prior_audit_status':prior}
assert [x['id'] for x,b in zip(doc['requirements'],base['requirements']) if x!=b]==['05.13']
counts=dict(collections.Counter(x['implementation'] for x in doc['requirements']));assert counts=={'implemented_manual_capture':18,'partial':229,'implemented':191,'missing':95},counts
doc['completion']='RECONCILIATION COMPLETE; PRODUCT IMPLEMENTATION INCOMPLETE. Zero unassessed requirements. Transaction boundaries and rollback behavior 05.13 implemented as qualified API requests and source CFG possibilities; 324 partial or missing records remain.'
doc['current_implementation']={'date':'2026-10-12','completed_batch':'Database transaction paths','completed_requirement_ids':['05.13'],'counts':counts,'unassessed':0,'incomplete_requirement_records':324,'completion_record':'docs/Phase1_Database_Transactions_Completion.txt','next_bounded_batch':{'requirement':'05.14','title':'Data validation and transformation rules','scope':'Add field-level validation/transformation rules with input/output/constraint evidence.'}}
p.write_text(json.dumps(doc,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
with (r/'docs/Phase1_Implementation_Backlog.csv').open('w',encoding='utf-8-sig',newline='') as out:
 w=csv.writer(out);w.writerow(['ID','Domain','Requirement / purpose','Status','Existing behavior','Remaining work','Batch','Evidence'])
 for row in doc['requirements']:
  if row['implementation'] not in ('partial','missing'):continue
  a=row['reconciliation'];w.writerow([row['id'],row['domain'],row['requirement'],row['implementation'],a['finding'],a['remaining_work'],a['batch'],'; '.join(row['evidence'])])
p=r/'docs/Implementation_Completion_Tracker.txt';s=p.read_text(encoding='utf-8-sig');old='Current live backlog: 325 incomplete requirement records; 0 unassessed.';assert old in s
s=s.replace(old,'Database transaction paths completed (05.13): explicit API requests with\nnormal, exception, conditional and cleanup CFG possibilities and exact navigation.\n402 focused and 524 regression checks passed; actual app/FMX baseline passed.\nSee Phase1_Database_Transactions_Completion.txt.\nCurrent live backlog: 324 incomplete requirement records; 0 unassessed.');p.write_text(s,encoding='utf-8')
for name in ['docs/Phase1_Reconciliation_Report.txt','docs/Phase1_Reconciliation_Batches.json','docs/Phase1_Reconciliation_Validation.json','DPH_Master_Development_Specification_v1.md','DPH_CODEX_HANDOFF.txt','DPH_PHASE1_MASTER_REQUIREMENTS.md']:
 assert (r/name).read_bytes().replace(b'\r\n',b'\n')==subprocess.check_output([g,'show',baseline+':'+name]).replace(b'\r\n',b'\n'),name
backup={'path':r'H:\DPH Backups\DatabaseTransactions_PreChange_20261012_152832','files':5378,'bytes':1979277005,'sha256_verified':True}
completion=f'''DPH REQUIREMENT 05.13 COMPLETION DATABASE TRANSACTION PATHS
Last changed: 12 October 2026

Database connections now inventories explicit begin, commit, rollback, retaining
and savepoint API requests on supported declared database receivers. Captured
routine CFG routes identify the next same-receiver boundary or normal/exception
exit. Conditional and loop possibilities, exception paths and duplicated finally
cleanup copies remain distinct. Different receiver declarations are not paired.
Multiple calls in one statement are not assigned invented evaluation order.
Missing or oversized CFG remains explicitly unavailable or truncated.
Native transaction-operation filter, forward/reverse references, receiver links
and hash-checked Source use IDE-editable controls. Analyzer version DPH-WP3-14.

Validation PASS: 402 focused + 232 operations + 92 bindings + 66 engines +
134 semantics = 926 checks. Actual application and FMX baseline PASS.
Normal and compact native renders reviewed. All 62 final guide pages visually
reviewed; 58 source hashes and 104 TOC destinations verified.
Explicit directions: docs/guides/Database_Transactions_Run_and_Test.txt.

Pre-change backup: {backup['path']}
5378 files, 1979277005 bytes; every SHA256 verified. No post-change backup.

{qualification}

API evidence: installed RAD Studio 37 Data.Win.ADODB, Data.SqlExpr and
IBX.IBDatabase source declarations, and official FireDAC reference pages:
https://docwiki.embarcadero.com/Libraries/Florence/en/FireDAC.Comp.Client.TFDCustomConnection.StartTransaction
https://docwiki.embarcadero.com/Libraries/Sydney/en/FireDAC.Comp.Client.TFDCustomTransaction.CommitRetaining

Only 05.13 promoted. All 533 original requirement IDs and texts preserved.
191 implemented; 18 implemented_manual_capture; 229 partial; 95 missing.
324 incomplete; zero unassessed. The entire product is not complete.
Next: 05.14 Data validation and transformation rules.
'''
(r/'docs/Phase1_Database_Transactions_Completion.txt').write_text(completion,encoding='utf-8')
summary={'result':'PASS','requirement':'05.13','status':'implemented','checks':402,'regression_checks':524,'requirements_preserved':533,'only_promoted_record':'05.13','incomplete_requirement_records':324,'unassessed':0,'counts':counts,'guides':guide,'guide_visual_review':'All 62 final pages reviewed; no clipping or broken TOC destinations observed.','backup':backup,'qualification':qualification}
files=evidence+['tools/build-guides.py','README.md','help/index.html','docs/guide-source-validation.json','docs/guides/DPH_User_Guide.docx','docs/guides/DPH_Engineering_Guide.docx','docs/pdf/DPH_User_Guide.pdf','docs/pdf/DPH_Engineering_Guide.pdf','docs/phase1-database-transactions-build.log','docs/Phase1_Database_Transactions_Completion.txt','docs/Phase1_Requirements_Traceability.json','docs/Phase1_Implementation_Backlog.csv','docs/Implementation_Completion_Tracker.txt','docs/phase1-database-transactions-workspace.png','docs/phase1-database-transactions-compact.png']
for label in ['operations','bindings','engines','semantics']:
 for ext in ['json','log']:files.append(f'docs/phase1-database-transactions-{label}-regression.{ext}')
summary['evidence_hashes']={x:hashlib.sha256((r/x).read_bytes()).hexdigest() for x in files}
(r/'docs/phase1-database-transactions-completion-validation.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'counts':counts,'incomplete':324,'requirements_preserved':533,'only_promoted_record':'05.13','evidence_files':len(files)}))
