from pathlib import Path
import collections,csv,hashlib,json,subprocess
from pypdf import PdfReader
from zipfile import ZipFile
from lxml import etree
r=Path.cwd();git=r'C:\Program Files\Git\cmd\git.exe';p=r/'docs/Phase1_Requirements_Traceability.json'
ledger=json.loads(p.read_text(encoding='utf-8-sig'));base=json.loads(subprocess.check_output([git,'show','c6b8edd:docs/Phase1_Requirements_Traceability.json'],cwd=r))
assert [(x['id'],x['requirement']) for x in ledger['requirements']]==[(x['id'],x['requirement']) for x in base['requirements']]
evidence=['DPH.Workspace.LayoutRules.pas','DPH.Workspace.Keyboard.pas','DPH.UI.Main.pas','DPH.UI.Main.fmx','tests/DPH.Tests.LayoutRules.dpr','tools/build-layout-rules.cmd','docs/phase1-layout-validation.json','docs/phase1-layout-validation.log','docs/guides/Layout_Rules_Run_and_Test.txt']
for row in ledger['requirements']:
 if row['id']!='04.16':continue
 row.setdefault('audit_at_reconciliation',dict(row['reconciliation']));row['implementation']='implemented';row['evidence']=evidence
 row['limitation']='Captured declarations and qualified basic anchor examples, not evaluated VCL/FMX layout or observed final geometry. Defaults, inheritance, sibling allocation, custom code, DPI, fonts, spacing and constraints remain relevant unknowns. Numeric examples require explicit Align=None, known anchors and an ordinary child with captured parent.'
 row['reconciliation'].update(finding='Dedicated IDE-editable Layout rules page explains captured VCL/FMX alignment, anchors, geometry, parent context, margins, padding, constraints, autosizing, wrapping, DPI and resize events. Positive/negative parent changes provide qualified anchor examples; unsupported/missing/inherited rules suppress numeric predictions. Filtering, pagination and guarded source navigation included.',remaining_work='',verification='56 focused checks, 55 keyboard regression checks, 51 dynamic-control regression checks and application/FMX baseline pass; normal/compact native renders and all 38 guide pages reviewed.')
 row['implementation_update']={'date':'2026-10-11','batch':'Responsive layout rules and educational resize examples','validation':'docs/phase1-layout-validation.json','prior_audit_status':'partial'}
counts=dict(collections.Counter(x['implementation'] for x in ledger['requirements']));assert counts=={'implemented_manual_capture':17,'partial':238,'implemented':176,'missing':102},counts
assert [x['id'] for x,b in zip(ledger['requirements'],base['requirements']) if x!=b]==['04.16']
ledger['completion']='RECONCILIATION COMPLETE; PRODUCT IMPLEMENTATION INCOMPLETE. Zero unassessed requirements. Glossary 06.12/12.09, keyboard/focus 04.13, command inventory 04.14, dynamic controls 04.15 and layout rules 04.16 implemented; 340 partial or missing requirement records remain.'
ledger['current_implementation']={'date':'2026-10-11','completed_batch':'Responsive layout rules and educational resize examples','completed_requirement_ids':['04.16'],'counts':counts,'unassessed':0,'incomplete_requirement_records':340,'completion_record':'docs/Phase1_Layout_Rules_Completion.txt','next_bounded_batch':{'requirement':'04.17','title':'Third-party UI components','scope':'Add component-to-package/vendor/version/support records and distinguish unresolved third-party dependencies.'}}
p.write_text(json.dumps(ledger,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
with (r/'docs/Phase1_Implementation_Backlog.csv').open('w',encoding='utf-8-sig',newline='') as out:
 w=csv.writer(out);w.writerow(['ID','Domain','Requirement / purpose','Status','Existing behavior','Remaining work','Batch','Evidence'])
 for row in ledger['requirements']:
  if row['implementation'] not in ('partial','missing'):continue
  a=row['reconciliation'];w.writerow([row['id'],row['domain'],row['requirement'],row['implementation'],a['finding'],a['remaining_work'],a['batch'],'; '.join(row['evidence'])])
assert len(list(csv.DictReader((r/'docs/Phase1_Implementation_Backlog.csv').open(encoding='utf-8-sig'))))==340
p=r/'docs/Implementation_Completion_Tracker.txt';s=p.read_text(encoding='utf-8-sig');assert 'Current live backlog: 341 incomplete requirement records; 0 unassessed.' in s
s=s.replace('Current live backlog: 341 incomplete requirement records; 0 unassessed.','Layout rules completed (04.16): captured alignments, anchors, parent context,\nspacing, constraints, DPI and qualified resize examples; native view and\n56 focused checks, 55 keyboard and 51 dynamic regression checks pass.\nSee Phase1_Layout_Rules_Completion.txt.\nCurrent live backlog: 340 incomplete requirement records; 0 unassessed.');p.write_text(s,encoding='utf-8')
for name in ['docs/Phase1_Reconciliation_Report.txt','docs/Phase1_Reconciliation_Batches.json','docs/Phase1_Reconciliation_Validation.json','docs/wp3-validation.json','DPH_Master_Development_Specification_v1.md','DPH_CODEX_HANDOFF.txt']:
 assert (r/name).read_bytes().replace(b'\r\n',b'\n')==subprocess.check_output([git,'show','c6b8edd:'+name],cwd=r).replace(b'\r\n',b'\n'),name
for name,checks in [('layout',56),('keyboard',55),('dynamic',51)]:
 v=json.loads((r/f'docs/phase1-{name}-validation.json').read_text(encoding='utf-8-sig'));assert v['result']=='PASS' and v['checks']==checks
g=json.loads((r/'docs/guide-source-validation.json').read_text());assert g['guide_version']==11
for x in g['sources']:assert hashlib.sha256((r/x['path']).read_bytes()).hexdigest()==x['sha256']
guides=[]
for name,count,toc,heading in [('DPH_User_Guide',21,40,'Inspect responsive layouts anchors and alignments'),('DPH_Engineering_Guide',17,32,'Layout rule explanations and validation')]:
 pdf=PdfReader(r/f'docs/pdf/{name}.pdf');assert len(pdf.pages)==count
 text='\n'.join(x.extract_text() for x in pdf.pages);assert heading in text
 assert ('340 requirement records' if name=='DPH_User_Guide' else '56 focused checks') in text
 with ZipFile(r/f'docs/guides/{name}.docx') as z:
  xml=etree.fromstring(z.read('word/document.xml'));assert any(' TOC ' in (x.text or '') for x in xml.findall('.//{http://schemas.openxmlformats.org/wordprocessingml/2006/main}instrText'))
 guides.append({'name':name,'pages':count,'toc_entries':toc,'all_pages_visually_reviewed':True})
files=evidence+['DelphiProjectHandoff.dproj','docs/Phase1_Layout_Rules_Completion.txt','docs/Phase1_Requirements_Traceability.json','docs/Phase1_Implementation_Backlog.csv','docs/guides/DPH_User_Guide.docx','docs/guides/DPH_Engineering_Guide.docx','docs/pdf/DPH_User_Guide.pdf','docs/pdf/DPH_Engineering_Guide.pdf','docs/phase1-layout-workspace.png','docs/phase1-layout-compact.png']
report={'result':'PASS','baseline_commit':'c6b8edd','completed_requirement_ids':['04.16'],'counts':counts,'incomplete':340,'unassessed':0,'requirements_preserved':533,'focused_checks':56,'keyboard_regression_checks':55,'dynamic_regression_checks':51,'application_and_fmx_baseline':'PASS','pre_change_backup':r'H:\DPH Backups\ResponsiveLayout_PreChange_20261011_214207','backup_files':3542,'backup_bytes':865165095,'guide_sources_verified':len(g['sources']),'guides':guides,'evidence':[{'path':f,'sha256':hashlib.sha256((r/f).read_bytes()).hexdigest()} for f in files]}
(r/'docs/phase1-layout-completion-validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8');print(json.dumps({k:report[k] for k in ['result','counts','incomplete','unassessed','guide_sources_verified']},indent=2))
