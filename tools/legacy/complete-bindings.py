from pathlib import Path
import json,csv,collections,subprocess,hashlib,shutil
r=Path.cwd();g=r'C:\Program Files\Git\cmd\git.exe';baseline='bdb18c0'
base=json.loads(subprocess.check_output([g,'show',baseline+':docs/Phase1_Requirements_Traceability.json']))
p=r/'docs/Phase1_Requirements_Traceability.json';doc=json.loads(p.read_text(encoding='utf-8-sig'))
assert len(doc['requirements'])==533
assert [(x['id'],x['requirement']) for x in doc['requirements']]==[(x['id'],x['requirement']) for x in base['requirements']]
v=json.loads((r/'docs/phase1-dataset-bindings-validation.json').read_text(encoding='utf-8-sig'));assert v['result']=='PASS' and v['checks']==92
reg=[]
for label in ['connections','engines']:
 src=f'docs/phase1-database-{label}-validation.json';v=json.loads((r/src).read_text(encoding='utf-8-sig'));assert v['result']=='PASS' and v['checks']==66
 for ext,source in [('json',src),('log',f'bin/dataset-bindings-{label}-regression.log')]:
  dest=f'docs/phase1-dataset-bindings-{label}-regression.{ext}';shutil.copyfile(r/source,r/dest);reg.append(dest)
historical=['docs/phase1-database-connections-compact.png','docs/phase1-database-connections-workspace.png','docs/phase1-database-engines-compact.png','docs/phase1-database-engines-validation.json','docs/phase1-database-engines-workspace.png']
subprocess.check_call([g,'restore','--worktree','--']+historical)
assert 'PASS WP0-TEST' in (r/'docs/phase1-dataset-bindings-build.log').read_text(encoding='utf-8-sig')
guide=json.loads((r/'bin/dataset-bindings-guide-check.json').read_text(encoding='utf-8-sig'));assert guide['guide_sources_verified']==58 and sum(x['toc_entries'] for x in guide['guides'])==100
qualification='Captured serialized lexical candidates only. Dynamic fields, runtime assignments, general LiveBindings expressions, custom field classes and uncaptured inherited values remain unknown. A persistent field name does not establish a live database column. Duplicate or incomplete reference chains receive no invented target. No target application, SQL, driver or database server executes. Existing 10000-row bound applies.'
evidence=['DPH.Workspace.DatabaseConnections.pas','DPH.UI.Main.fmx','tests/DPH.Tests.DatasetBindings.dpr','tools/build-dataset-bindings.cmd','docs/phase1-dataset-bindings-validation.json','docs/phase1-dataset-bindings-validation.log','docs/guides/Dataset_Bindings_Run_and_Test.txt']
for row in doc['requirements']:
 if row['id']!='05.11':continue
 prior=row['implementation'];row.setdefault('audit_at_reconciliation',dict(row['reconciliation']));row['implementation']='implemented';row['evidence']=evidence;row['limitation']=qualification
 row['reconciliation'].update(finding='Database connections inventory resolves captured dataset/connection/data-source/control references, persistent TField ownership and dataset-scoped field names. VCL DataSource/DataField and FMX TLinkControlToField DataSource/FieldName/Control chains retain exact property evidence, unique targets and reverse links. TBindSourceDB and referenced visual controls are included. Persistent field metadata and binding explanations appear first. IDE-editable kind filters and existing Follow reference navigate exact IDs across pages; ambiguous, missing and incomplete chains remain explicit.',remaining_work='',verification='92 focused checks and 132 regressions pass (66 connection and 66 engine). Actual application build and FMX resource baseline pass. Real text/binary DFM and FMX fixtures cover ownership, source/field chains, reverse links, duplicates, missing/nil sources, lookup datasets, property provenance, filtering, navigation, compact layouts, persistence/reopening and unchanged source/catalog. All 59 final guide pages individually visually reviewed; 58 source hashes and 100 TOC destinations verified.')
 row['implementation_update']={'date':'2026-10-12','batch':'Dataset components and bindings','validation':'docs/phase1-dataset-bindings-validation.json','prior_audit_status':prior}
assert [x['id'] for x,b in zip(doc['requirements'],base['requirements']) if x!=b]==['05.11']
counts=dict(collections.Counter(x['implementation'] for x in doc['requirements']));assert counts=={'implemented_manual_capture':18,'partial':230,'implemented':189,'missing':96},counts
doc['completion']='RECONCILIATION COMPLETE; PRODUCT IMPLEMENTATION INCOMPLETE. Zero unassessed requirements. Dataset components and bindings 05.11 implemented with captured field/control chains; 326 partial or missing records remain.'
doc['current_implementation']={'date':'2026-10-12','completed_batch':'Dataset components and bindings','completed_requirement_ids':['05.11'],'counts':counts,'unassessed':0,'incomplete_requirement_records':326,'completion_record':'docs/Phase1_Dataset_Bindings_Completion.txt','next_bounded_batch':{'requirement':'05.12','title':'Read, insert, update, and delete operations','scope':'Expand operation records and dataset API recognition beyond the supported single-table SQL subset.'}}
p.write_text(json.dumps(doc,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
with (r/'docs/Phase1_Implementation_Backlog.csv').open('w',encoding='utf-8-sig',newline='') as out:
 w=csv.writer(out);w.writerow(['ID','Domain','Requirement / purpose','Status','Existing behavior','Remaining work','Batch','Evidence'])
 for row in doc['requirements']:
  if row['implementation'] not in ('partial','missing'):continue
  a=row['reconciliation'];w.writerow([row['id'],row['domain'],row['requirement'],row['implementation'],a['finding'],a['remaining_work'],a['batch'],'; '.join(row['evidence'])])
p=r/'docs/Implementation_Completion_Tracker.txt';s=p.read_text(encoding='utf-8-sig');old='Current live backlog: 327 incomplete requirement records; 0 unassessed.';assert old in s
s=s.replace(old,'Dataset components and bindings completed (05.11): captured dataset/source/control\nchains, persistent fields, FMX bindings, reverse references and exact navigation.\n92 focused and 132 regression checks passed; actual app/FMX baseline passed.\nSee Phase1_Dataset_Bindings_Completion.txt.\nCurrent live backlog: 326 incomplete requirement records; 0 unassessed.');p.write_text(s,encoding='utf-8')
for name in ['docs/Phase1_Reconciliation_Report.txt','docs/Phase1_Reconciliation_Batches.json','docs/Phase1_Reconciliation_Validation.json','DPH_Master_Development_Specification_v1.md','DPH_CODEX_HANDOFF.txt','DPH_PHASE1_MASTER_REQUIREMENTS.md']+historical:
 assert (r/name).read_bytes().replace(b'\r\n',b'\n')==subprocess.check_output([g,'show',baseline+':'+name]).replace(b'\r\n',b'\n'),name
completion='''DPH REQUIREMENT 05.11 COMPLETION - DATASET COMPONENTS AND BINDINGS
Last changed: 12 October 2026

Captured dataset/connection/data-source/control chains and persistent field
ownership are implemented in the existing Database connections inventory.
VCL DataField and FMX FieldName resolve through unique captured dataset chains.
FMX Control references expose their actual visual target. Persistent TField
metadata, property line/byte evidence, lookup datasets and reverse references
remain inspectable. Duplicate, incomplete, missing and nil chains stay explicit.
Binding details appear first; IDE-editable kind choices and Follow reference
provide exact navigation across 250-row pages. No runtime controls/helper units
or storage migrations were introduced.

Validation: PASS 92 focused + 66 connection + 66 engine = 224 checks.
Actual application build and FMX resource baseline PASS. Normal and compact
native PaintTo renders reviewed. These depict running DPH controls, not target
application screenshots. All 59 final manual pages individually reviewed.
58 source hashes and 100 TOC destinations verified; no blank guide pages.
Directions: docs/guides/Dataset_Bindings_Run_and_Test.txt.

Pre-change backup: H:\\DPH Backups\\DatasetBindings_PreChange_20261012_143022
5174 files, 1790230671 bytes; every SHA256 verified. No post-change backup.

'''+qualification+'''

Only 05.11 promoted. All 533 original requirement IDs and texts preserved.
189 implemented; 18 implemented_manual_capture; 230 partial; 96 missing.
326 incomplete; zero unassessed. The entire product is not complete.
Next: 05.12 Read, insert, update, and delete operations.
'''
(r/'docs/Phase1_Dataset_Bindings_Completion.txt').write_text(completion,encoding='utf-8')
summary={'result':'PASS','requirement':'05.11','status':'implemented','checks':92,'regression_checks':132,'requirements_preserved':533,'only_promoted_record':'05.11','incomplete_requirement_records':326,'unassessed':0,'counts':counts,'guides':guide,'guide_visual_review':'All 59 final pages reviewed individually; no clipping or broken TOC destinations observed.','backup':{'path':r'H:\DPH Backups\DatasetBindings_PreChange_20261012_143022','files':5174,'bytes':1790230671,'sha256_verified':True},'qualification':qualification}
files=evidence+reg+['tools/build-guides.py','README.md','help/index.html','docs/guide-source-validation.json','docs/guides/DPH_User_Guide.docx','docs/guides/DPH_Engineering_Guide.docx','docs/pdf/DPH_User_Guide.pdf','docs/pdf/DPH_Engineering_Guide.pdf','docs/phase1-dataset-bindings-build.log','docs/Phase1_Dataset_Bindings_Completion.txt','docs/Phase1_Requirements_Traceability.json','docs/Phase1_Implementation_Backlog.csv','docs/Implementation_Completion_Tracker.txt','docs/phase1-dataset-bindings-workspace.png','docs/phase1-dataset-bindings-compact.png']
summary['evidence_hashes']={x:hashlib.sha256((r/x).read_bytes()).hexdigest() for x in files}
(r/'docs/phase1-dataset-bindings-completion-validation.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'counts':counts,'incomplete':326,'requirements_preserved':533,'only_promoted_record':'05.11','evidence_files':len(files)}))
