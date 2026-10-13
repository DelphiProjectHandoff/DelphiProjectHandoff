from pathlib import Path
import collections,csv,hashlib,json,subprocess
from pypdf import PdfReader
from zipfile import ZipFile
from lxml import etree
r=Path.cwd();git=r'C:\Program Files\Git\cmd\git.exe';p=r/'docs/Phase1_Requirements_Traceability.json'
ledger=json.loads(p.read_text(encoding='utf-8-sig'));base=json.loads(subprocess.check_output([git,'show','9da0486:docs/Phase1_Requirements_Traceability.json'],cwd=r))
assert [(x['id'],x['requirement']) for x in ledger['requirements']]==[(x['id'],x['requirement']) for x in base['requirements']]
evidence=['DPH.Analysis.Symbols.pas','DPH.Analysis.Model.pas','DPH.Workspace.DynamicControls.pas','DPH.UI.Main.pas','DPH.UI.Main.fmx','tests/DPH.Tests.DynamicControls.dpr','tools/build-dynamic-controls.cmd','docs/phase1-dynamic-validation.json','docs/phase1-dynamic-validation.log','docs/phase1-dynamic-semantics-regression.json','docs/phase1-dynamic-semantics-regression.log','docs/guides/Dynamic_Controls_Run_and_Test.txt']
for row in ledger['requirements']:
 if row['id']!='04.15':continue
 row.setdefault('audit_at_reconciliation',dict(row['reconciliation']));row['implementation']='implemented';row['evidence']=evidence
 row['limitation']='Supported lexical source relationships, not observed runtime instances, aliases, reaching definitions, order, lifetime or actual event dispatch. Factory/cast/indirect/with/cross-routine cases may remain unknown. Reused/overwritten handles and pre-construction assignments stay ambiguous. Older captures require reassessment with DPH-WP3-12.'
 row['reconciliation'].update(finding='Dedicated IDE-editable Dynamic controls page and semantic relationships: creation sites, result handles, constructor owners, Parent and event declaration references, captured expressions, source/condition/generation evidence, ambiguity guards, filtering, pagination and independent Explain navigation. Runtime instances remain explicitly unobserved.',remaining_work='',verification='51 focused checks, 134 semantic regression checks, 62 command regression checks and application/FM X baseline pass; normal/compact native renders and 38 guide pages reviewed.'.replace('FM X','FMX'))
 row['implementation_update']={'date':'2026-10-11','batch':'Dynamic control relationships and inspector','validation':'docs/phase1-dynamic-validation.json','prior_audit_status':'partial'}
counts=dict(collections.Counter(x['implementation'] for x in ledger['requirements']));assert counts=={'implemented_manual_capture':17,'partial':239,'implemented':175,'missing':102},counts
assert [x['id'] for x,b in zip(ledger['requirements'],base['requirements']) if x!=b]==['04.15']
ledger['completion']='RECONCILIATION COMPLETE; PRODUCT IMPLEMENTATION INCOMPLETE. Zero unassessed requirements. Glossary 06.12/12.09, keyboard/focus 04.13, command inventory 04.14 and dynamic controls 04.15 implemented; 341 partial or missing requirement records remain.'
ledger['current_implementation']={'date':'2026-10-11','completed_batch':'Dynamic control relationships and inspector','completed_requirement_ids':['04.15'],'counts':counts,'unassessed':0,'incomplete_requirement_records':341,'completion_record':'docs/Phase1_Dynamic_Controls_Completion.txt','next_bounded_batch':{'requirement':'04.16','title':'Responsive layouts, anchors, and alignments','scope':'Explain captured layout rules and responsive changes with qualified evidence, native views, acceptance checks and explicit directions; preserve limits of approximate reconstruction.'}}
p.write_text(json.dumps(ledger,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
with (r/'docs/Phase1_Implementation_Backlog.csv').open('w',encoding='utf-8-sig',newline='') as out:
 w=csv.writer(out);w.writerow(['ID','Domain','Requirement / purpose','Status','Existing behavior','Remaining work','Batch','Evidence'])
 for row in ledger['requirements']:
  if row['implementation'] not in ('partial','missing'):continue
  a=row['reconciliation'];w.writerow([row['id'],row['domain'],row['requirement'],row['implementation'],a['finding'],a['remaining_work'],a['batch'],'; '.join(row['evidence'])])
assert len(list(csv.DictReader((r/'docs/Phase1_Implementation_Backlog.csv').open(encoding='utf-8-sig'))))==341
p=r/'docs/Implementation_Completion_Tracker.txt';s=p.read_text(encoding='utf-8-sig').replace('Current live backlog: 342 incomplete requirement records; 0 unassessed.','Dynamic controls completed (04.15): owner, parent and event references,\ncreation-site distinction, ambiguity guards, native view and 51 focused checks;\n134 semantic and 62 command regression checks pass. See Phase1_Dynamic_Controls_Completion.txt.\nCurrent live backlog: 341 incomplete requirement records; 0 unassessed.');p.write_text(s,encoding='utf-8')
for name in ['docs/Phase1_Reconciliation_Report.txt','docs/Phase1_Reconciliation_Batches.json','docs/Phase1_Reconciliation_Validation.json','docs/wp3-validation.json','DPH_Master_Development_Specification_v1.md','DPH_CODEX_HANDOFF.txt']:
 assert (r/name).read_bytes().replace(b'\r\n',b'\n')==subprocess.check_output([git,'show','9da0486:'+name],cwd=r).replace(b'\r\n',b'\n'),name
validation=json.loads((r/'docs/phase1-dynamic-validation.json').read_text(encoding='utf-8-sig'));assert validation['result']=='PASS' and validation['checks']==51
regression=json.loads((r/'docs/phase1-dynamic-semantics-regression.json').read_text(encoding='utf-8-sig'));assert regression['checks_passed']==134 and regression['analyzer']=='DPH-WP3-12'
assert json.loads((r/'docs/phase1-commands-validation.json').read_text(encoding='utf-8-sig'))['checks']==62
g=json.loads((r/'docs/guide-source-validation.json').read_text());assert g['guide_version']==10
for x in g['sources']:assert hashlib.sha256((r/x['path']).read_bytes()).hexdigest()==x['sha256']
guides=[]
for name,count,toc in [('DPH_User_Guide',21,39),('DPH_Engineering_Guide',17,31)]:
 pdf=PdfReader(r/f'docs/pdf/{name}.pdf');assert len(pdf.pages)==count
 text='\n'.join(x.extract_text() for x in pdf.pages)
 assert ('Inspect dynamic and runtime created controls' if count==21 else 'Dynamic control relationships and validation') in text
 assert ('341 requirement records' if count==21 else '51 focused checks') in text
 with ZipFile(r/f'docs/guides/{name}.docx') as z:
  xml=etree.fromstring(z.read('word/document.xml'));assert any(' TOC ' in (x.text or '') for x in xml.findall('.//{http://schemas.openxmlformats.org/wordprocessingml/2006/main}instrText'))
 guides.append({'name':name,'pages':count,'toc_entries':toc,'all_pages_visually_reviewed':True})
files=evidence+['DelphiProjectHandoff.dproj','docs/Phase1_Dynamic_Controls_Completion.txt','docs/Phase1_Requirements_Traceability.json','docs/Phase1_Implementation_Backlog.csv','docs/guides/DPH_User_Guide.docx','docs/guides/DPH_Engineering_Guide.docx','docs/pdf/DPH_User_Guide.pdf','docs/pdf/DPH_Engineering_Guide.pdf','docs/phase1-dynamic-workspace.png','docs/phase1-dynamic-compact.png']
report={'result':'PASS','baseline_commit':'9da0486','completed_requirement_ids':['04.15'],'counts':counts,'incomplete':341,'unassessed':0,'requirements_preserved':533,'focused_checks':51,'semantic_regression_checks':134,'command_regression_checks':62,'application_and_fmx_baseline':'PASS','pre_change_backup':r'H:\DPH Backups\DynamicControls_PreChange_20261011_212931','backup_files':3433,'backup_bytes':693686621,'guide_sources_verified':len(g['sources']),'guides':guides,'evidence':[{'path':f,'sha256':hashlib.sha256((r/f).read_bytes()).hexdigest()} for f in files]}
(r/'docs/phase1-dynamic-completion-validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8');print(json.dumps({k:report[k] for k in ['result','counts','incomplete','unassessed','guide_sources_verified']},indent=2))
