from pathlib import Path
import json,csv,collections,subprocess,hashlib
r=Path.cwd(); git=r'C:\Program Files\Git\cmd\git.exe'
def run(*a):return subprocess.check_output([git,*a])
# Index-only refresh of files proven identical after line-ending normalization.
historical=[]
for name in run('diff','--name-only').decode().splitlines():
 if name.startswith(('docs/phase1-data-rules-','docs/phase1-database-engines-','docs/phase1-database-operations-','docs/phase1-database-transactions-','docs/phase1-dataset-bindings-')) or name in ['docs/wp0-validation.json','docs/wp2-input-validation.json','docs/wp3-input-validation.json']:
  assert (r/name).read_bytes().replace(b'\r\n',b'\n')==run('show','HEAD:'+name).replace(b'\r\n',b'\n'),name
  historical.append(name)
if historical:
 subprocess.run([git,'add','--renormalize','--',*historical],check=True)
 assert not run('diff','--cached','--name-only').strip()
p=r/'docs/Phase1_Requirements_Traceability.json';doc=json.loads(p.read_text(encoding='utf-8-sig'));base=json.loads(run('show','e548176:docs/Phase1_Requirements_Traceability.json'))
assert len(doc['requirements'])==533
assert [(x['id'],x['requirement']) for x in doc['requirements']]==[(x['id'],x['requirement']) for x in base['requirements']]
labels={'validation':174,'data-rules-regression':130,'database-transactions-regression':402,'database-operations-regression':232,'dataset-bindings-regression':92,'database-engines-regression':66,'semantics':134,'parser':88}
for label,count in labels.items():
 v=json.loads((r/f'docs/phase1-data-lineage-{label}.json').read_text(encoding='utf-8-sig'));assert v.get('checks_passed',v.get('checks'))==count,(label,v)
assert 'PASS WP0-TEST' in (r/'docs/phase1-data-lineage-build.log').read_text(encoding='utf-8-sig')
guide=json.loads((r/'bin/data-lineage-guide-check.json').read_text());assert sum(x['pages'] for x in guide['guides'])==64;assert sum(x['toc_entries'] for x in guide['guides'])==108;assert guide['guide_sources_verified']==58
qualification='Scoped captured source candidates only. Directed lexical dependencies remain distinct from serialized bindings, handler and routine context. No reaching-definition, runtime-value, execution, server-effect or final-success proof. Missing targets, incomplete dataset chains, connection boundaries and traversal limits remain explicit. Bounds: 50000 indexed symbols, 100000 indexed edges, 200 returned nodes, 800 edges and 12 hops. No selected target, SQL, driver or production server executes.'
evidence=['DPH.Workspace.DatabaseConnections.pas','DPH.Analysis.Explanations.pas','DPH.UI.Main.pas','DPH.UI.Main.fmx','tests/DPH.Tests.DataLineage.dpr','tools/build-data-lineage.cmd','docs/phase1-data-lineage-validation.json','docs/phase1-data-lineage-validation.log','docs/guides/Data_Lineage_Run_and_Test.txt']
for row in doc['requirements']:
 if row['id']!='05.15':continue
 assert row['implementation']=='partial';row.setdefault('audit_at_reconciliation',dict(row['reconciliation']));row['implementation']='implemented';row['evidence']=evidence;row['limitation']=qualification
 row['reconciliation'].update(finding='Trace lineage and Data lineage diagrams connect captured controls, persistent fields, validation/transformation candidates, procedures and output artifacts. Directional traversal distinguishes lexical dependencies from labeled context, preserves exact source/hash/generation and exposes unresolved breaks. Nodes navigate to inventory or Explain. Native controls remain IDE-editable; HTML renders the same projection. Incomplete mixed dataset chains cannot invent field targets.',remaining_work='',verification='174 focused plus 1144 regression checks pass; actual app and FMX baseline pass. Real parsing, persisted/reopened captures, directional and cyclic chains, output writers, redaction, unresolved bindings, limits, native navigation, browser allowlisting and unchanged source/catalog verified. All 64 guide pages and three native renders reviewed; 58 source hashes and 108 TOC destinations verified.')
 row['implementation_update']={'date':'2026-10-12','batch':'Data lineage','validation':'docs/phase1-data-lineage-validation.json','prior_audit_status':'partial'}
assert [x['id'] for x,b in zip(doc['requirements'],base['requirements']) if x!=b]==['05.15']
counts=dict(collections.Counter(x['implementation'] for x in doc['requirements']));assert counts=={'implemented_manual_capture':18,'partial':227,'implemented':193,'missing':95},counts
doc['completion']='RECONCILIATION COMPLETE; PRODUCT IMPLEMENTATION INCOMPLETE. Zero unassessed requirements. Data lineage 05.15 implemented as qualified scoped source candidates; 322 partial or missing records remain.'
doc['current_implementation']={'date':'2026-10-12','completed_batch':'Data lineage','completed_requirement_ids':['05.15'],'counts':counts,'unassessed':0,'incomplete_requirement_records':322,'completion_record':'docs/Phase1_Data_Lineage_Completion.txt','next_bounded_batch':{'requirement':'05.16','title':'Migration and schema-version history','scope':'Discover referenced migration files and capture ordering, target schema versions and verification evidence.'}}
p.write_text(json.dumps(doc,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
with (r/'docs/Phase1_Implementation_Backlog.csv').open('w',encoding='utf-8-sig',newline='') as out:
 w=csv.writer(out);w.writerow(['ID','Domain','Requirement / purpose','Status','Existing behavior','Remaining work','Batch','Evidence'])
 for row in doc['requirements']:
  if row['implementation'] in ('partial','missing'):
   a=row['reconciliation'];w.writerow([row['id'],row['domain'],row['requirement'],row['implementation'],a['finding'],a['remaining_work'],a['batch'],'; '.join(row['evidence'])])
p=r/'docs/Implementation_Completion_Tracker.txt';s=p.read_text(encoding='utf-8-sig');old='Current live backlog: 323 incomplete requirement records; 0 unassessed.';assert old in s;p.write_text(s.replace(old,'Data lineage completed (05.15): scoped inputs, fields, procedures and destination\ncandidates with explicit unresolved breaks and navigable diagrams.\n174 focused and 1144 regression checks passed; actual app/FMX passed.\nSee Phase1_Data_Lineage_Completion.txt.\nCurrent live backlog: 322 incomplete requirement records; 0 unassessed.'),encoding='utf-8')
backup={'path':r'H:\DPH Backups\DataLineage_PreChange_20261012_164236','files':5703,'bytes':2376172510,'sha256_verified':True}
completion='DPH REQUIREMENT 05.15 COMPLETION: DATA LINEAGE\nLast changed: 12 October 2026\n\nTrace lineage and Lineage diagram connect captured source candidates with exact\nsource evidence and explicit unresolved breaks. Inputs and Destinations respect\nlexical dependency direction; Both directions includes labeled context.\nInventory and semantic nodes navigate to their exact evidence.\nNo schema migration or new helper unit. Controls remain IDE-editable.\n\nValidation PASS: 174 focused + 1144 regression = 1318 checks.\nActual app and FMX baseline PASS. Three native renders reviewed.\nAll 64 final guide pages visually reviewed; 58 hashes and 108 TOC destinations\nverified. Editable DOCX guides and companion PDFs updated.\nDirections: docs/guides/Data_Lineage_Run_and_Test.txt\n\n'+qualification+'\n\nPre-change backup: '+backup['path']+'\n5703 files, 2376172510 bytes; every SHA256 verified. No post-change backup.\n\nOnly 05.15 promoted; all 533 original requirement IDs and texts preserved.\n193 implemented; 18 implemented_manual_capture; 227 partial; 95 missing.\n322 incomplete; zero unassessed. Product implementation remains incomplete.\nNext: 05.16 Migration and schema-version history.\n'
(r/'docs/Phase1_Data_Lineage_Completion.txt').write_text(completion,encoding='utf-8')
files=evidence+['tools/build-guides.py','README.md','help/index.html','docs/guide-source-validation.json','docs/guides/DPH_User_Guide.docx','docs/guides/DPH_Engineering_Guide.docx','docs/pdf/DPH_User_Guide.pdf','docs/pdf/DPH_Engineering_Guide.pdf','docs/phase1-data-lineage-build.log','docs/Phase1_Data_Lineage_Completion.txt','docs/Phase1_Requirements_Traceability.json','docs/Phase1_Implementation_Backlog.csv','docs/Implementation_Completion_Tracker.txt']
for label in labels:
 for ext in ['json','log']:files.append(f'docs/phase1-data-lineage-{label}.{ext}')
for label in ['workspace','compact','diagram']:files.append(f'docs/phase1-data-lineage-{label}.png')
summary={'result':'PASS','requirement':'05.15','status':'implemented','checks':174,'regression_checks':1144,'requirements_preserved':533,'only_promoted_record':'05.15','counts':counts,'incomplete_requirement_records':322,'unassessed':0,'guides':guide,'guide_visual_review':'All 64 final pages reviewed; no clipping or broken TOC destinations observed.','backup':backup,'qualification':qualification,'evidence_hashes':{x:hashlib.sha256((r/x).read_bytes()).hexdigest() for x in dict.fromkeys(files)}}
(r/'docs/phase1-data-lineage-completion-validation.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'counts':counts,'incomplete':322,'historical_index_refresh':len(historical)}))
