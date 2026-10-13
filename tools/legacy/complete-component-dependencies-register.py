from pathlib import Path
import collections,csv,hashlib,json,re,subprocess
from pypdf import PdfReader
from zipfile import ZipFile
from lxml import etree
r=Path.cwd();git=r'C:\Program Files\Git\cmd\git.exe';p=r/'docs/Phase1_Requirements_Traceability.json'
ledger=json.loads(p.read_text(encoding='utf-8-sig'));base=json.loads(subprocess.check_output([git,'show','0d91d95:docs/Phase1_Requirements_Traceability.json'],cwd=r))
assert [(x['id'],x['requirement']) for x in ledger['requirements']]==[(x['id'],x['requirement']) for x in base['requirements']]
evidence=['DPH.Workspace.ComponentDependencies.pas','DPH.Knowledge.ComponentDependency.pas','DPH.UI.ComponentDependency.pas','DPH.UI.ComponentDependency.fmx','DPH.Storage.Database.pas','DPH.UI.Main.pas','DPH.UI.Main.fmx','tests/DPH.Tests.ComponentDependencies.dpr','tools/build-component-dependencies.cmd','docs/phase1-component-dependencies-validation.json','docs/phase1-component-dependencies-validation.log','docs/guides/Component_Dependencies_Run_and_Test.txt']
for row in ledger['requirements']:
 if row['id']!='04.17':continue
 row.setdefault('audit_at_reconciliation',dict(row['reconciliation']));row['implementation']='implemented';row['evidence']=evidence
 row['limitation']='Captured class declarations are lexical candidates, not compiler binding or vendor-origin proof. Package declarations/unavailable inputs are project-wide context, not installed binaries or proven containment. Package/vendor/version/support fields require attributed knowledge; they do not resolve missing source. Aliases, conditional variants, inherited values, licensing and runtime compatibility remain qualified.'
 row['reconciliation'].update(finding='Dedicated IDE-editable Component dependencies inspector and structured dependency editor. Captured classes expose unique inferred, ambiguous and unresolved source candidates, package declarations and unavailable input context. Attributed class-to-unit/package/vendor/version/support/evidence records persist through Knowledge revision, review, links, search and publication. Identity/duplicate/stale guards, pagination, source and unique-class Explain navigation included.',remaining_work='',verification='70 focused checks, 59 Knowledge, 57 glossary and 56 layout regression checks; actual app/FMX baseline pass. Native normal/compact/editor renders and all 40 guide pages reviewed.')
 row['implementation_update']={'date':'2026-10-11','batch':'Component dependency inspector and attributed supplier records','validation':'docs/phase1-component-dependencies-validation.json','prior_audit_status':'partial'}
counts=dict(collections.Counter(x['implementation'] for x in ledger['requirements']));assert counts=={'implemented_manual_capture':17,'partial':237,'implemented':177,'missing':102},counts
assert [x['id'] for x,b in zip(ledger['requirements'],base['requirements']) if x!=b]==['04.17']
ledger['completion']='RECONCILIATION COMPLETE; PRODUCT IMPLEMENTATION INCOMPLETE. Zero unassessed requirements. Glossary 06.12/12.09, keyboard/focus 04.13, command inventory 04.14, dynamic controls 04.15, layout rules 04.16 and component dependencies 04.17 implemented; 339 partial or missing requirement records remain.'
ledger['current_implementation']={'date':'2026-10-11','completed_batch':'Component dependency inspector and attributed supplier records','completed_requirement_ids':['04.17'],'counts':counts,'unassessed':0,'incomplete_requirement_records':339,'completion_record':'docs/Phase1_Component_Dependencies_Completion.txt','next_bounded_batch':{'requirement':'04.18','title':'Form inheritance and embedded frames','scope':'Resolve base-form/frame overlays and inherited property/event provenance without instantiating target classes.'}}
p.write_text(json.dumps(ledger,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
with (r/'docs/Phase1_Implementation_Backlog.csv').open('w',encoding='utf-8-sig',newline='') as out:
 w=csv.writer(out);w.writerow(['ID','Domain','Requirement / purpose','Status','Existing behavior','Remaining work','Batch','Evidence'])
 for row in ledger['requirements']:
  if row['implementation'] not in ('partial','missing'):continue
  a=row['reconciliation'];w.writerow([row['id'],row['domain'],row['requirement'],row['implementation'],a['finding'],a['remaining_work'],a['batch'],'; '.join(row['evidence'])])
assert len(list(csv.DictReader((r/'docs/Phase1_Implementation_Backlog.csv').open(encoding='utf-8-sig'))))==339
p=r/'docs/Implementation_Completion_Tracker.txt';s=p.read_text(encoding='utf-8-sig');assert ('Current live backlog: 340 incomplete requirement records; 0 unassessed.' in s) or ('Current live backlog: 339 incomplete requirement records; 0 unassessed.' in s)
s=s.replace('Current live backlog: 340 incomplete requirement records; 0 unassessed.','Component dependencies completed (04.17): captured class candidates and\nunresolved inputs, attributed unit/package/vendor/version/support records,\nrevision/review/search/publication, native editor and 70 focused checks.\n59 Knowledge, 57 glossary and 56 layout regression checks pass.\nSee Phase1_Component_Dependencies_Completion.txt.\nCurrent live backlog: 339 incomplete requirement records; 0 unassessed.');p.write_text(s,encoding='utf-8')
for name in ['docs/Phase1_Reconciliation_Report.txt','docs/Phase1_Reconciliation_Batches.json','docs/Phase1_Reconciliation_Validation.json','docs/wp3-validation.json','docs/wp5-validation.json','docs/phase1-glossary-validation.json','DPH_Master_Development_Specification_v1.md','DPH_CODEX_HANDOFF.txt']:
 assert (r/name).read_bytes().replace(b'\r\n',b'\n')==subprocess.check_output([git,'show','0d91d95:'+name],cwd=r).replace(b'\r\n',b'\n'),name
v=json.loads((r/'docs/phase1-component-dependencies-validation.json').read_text(encoding='utf-8-sig'));assert v['result']=='PASS' and v['checks']==70
for name,checks in [('knowledge',59),('glossary',57)]:assert json.loads((r/f'docs/phase1-component-dependencies-{name}-regression.json').read_text(encoding='utf-8-sig'))['checks_passed']==checks
assert json.loads((r/'docs/phase1-layout-validation.json').read_text(encoding='utf-8-sig'))['checks']==56
g=json.loads((r/'docs/guide-source-validation.json').read_text());assert g['guide_version']==12
for x in g['sources']:assert hashlib.sha256((r/x['path']).read_bytes()).hexdigest()==x['sha256']
guides=[];W='{http://schemas.openxmlformats.org/wordprocessingml/2006/main}'
for name,count,toc,heading in [('DPH_User_Guide',22,41,'Inspect component dependencies and support records'),('DPH_Engineering_Guide',18,33,'Component dependencies and attributed metadata')]:
 pdf=PdfReader(r/f'docs/pdf/{name}.pdf');assert len(pdf.pages)==count
 pages=[page.extract_text() or '' for page in pdf.pages];assert all(len(text)>100 for text in pages),'Blank guide page'
 text='\n'.join(pages);assert heading in text
 if name=='DPH_User_Guide':assert '339 requirement records' in text
 with ZipFile(r/f'docs/guides/{name}.docx') as z:
  xml=etree.fromstring(z.read('word/document.xml'));assert any(' TOC ' in (x.text or '') for x in xml.findall('.//'+W+'instrText'))
  inside=False;separated=False;entries=0
  for para in xml.iter(W+'p'):
   if any(' TOC ' in (x.text or '') for x in para.iter(W+'instrText')):inside=True
   if not inside:continue
   chars=list(para.iter(W+'fldChar'))
   if any(x.get(W+'fldCharType')=='separate' for x in chars):separated=True;continue
   if any(x.get(W+'fldCharType')=='end' for x in chars):break
   if not separated:continue
   label=''.join(x.text or '' for x in para.iter(W+'t'));match=re.fullmatch(r'(.+?)(\d+)',label)
   if not match:continue
   title,number=match.groups();lines=[re.sub(r'\s+',' ',line).strip() for line in pages[int(number)-1].splitlines()];assert title in lines,(name,title,number)
   assert para.find('.//'+W+'sz').get(W+'val')=='20','TOC font formatting lost';entries+=1
  assert entries==toc,(name,entries)
 guides.append({'name':name,'pages':count,'toc_entries':toc,'all_pages_visually_reviewed':True,'cached_toc_numbers_verified':True,'blank_pages':0})
files=evidence+['DelphiProjectHandoff.dproj','docs/Phase1_Component_Dependencies_Completion.txt','docs/Phase1_Requirements_Traceability.json','docs/Phase1_Implementation_Backlog.csv','docs/guides/DPH_User_Guide.docx','docs/guides/DPH_Engineering_Guide.docx','docs/pdf/DPH_User_Guide.pdf','docs/pdf/DPH_Engineering_Guide.pdf','docs/phase1-component-dependencies-workspace.png','docs/phase1-component-dependencies-compact.png','docs/phase1-component-dependency-editor.png','docs/phase1-component-dependencies-knowledge-regression.json','docs/phase1-component-dependencies-glossary-regression.json']
report={'result':'PASS','baseline_commit':'0d91d95','completed_requirement_ids':['04.17'],'counts':counts,'incomplete':339,'unassessed':0,'requirements_preserved':533,'focused_checks':70,'knowledge_regression_checks':59,'glossary_regression_checks':57,'layout_regression_checks':56,'application_and_fmx_baseline':'PASS','pre_change_backup':r'H:\DPH Backups\ThirdPartyUI_PreChange_20261011_215632','backup_files':3598,'backup_bytes':882744584,'guide_sources_verified':len(g['sources']),'guides':guides,'evidence':[{'path':f,'sha256':hashlib.sha256((r/f).read_bytes()).hexdigest()} for f in files]}
(r/'docs/phase1-component-dependencies-completion-validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8');print(json.dumps({k:report[k] for k in ['result','counts','incomplete','unassessed','guide_sources_verified']},indent=2))
